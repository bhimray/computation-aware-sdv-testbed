function [performanceMap, performanceMapTable, outputFile] = ...
    build_phase4_performance_map( ...
        scenarioName, environmentName, options)
%BUILD_PHASE4_PERFORMANCE_MAP Build one scenario/environment KNN map.

arguments
    scenarioName (1,1) string
    environmentName (1,1) string
    options.RunRoot (1,1) string = ""
    options.OutputRoot (1,1) string = ""
    options.PredictionHorizon_s (1,1) double ...
        {mustBePositive} = 1.0
    options.RowStride_s (1,1) double ...
        {mustBePositive} = 0.050
end

startup_project;

projectRoot = string( ...
    matlab.project.currentProject().RootFolder);

if strlength(options.RunRoot) == 0
    options.RunRoot = fullfile( ...
        projectRoot, "phase4", "results", ...
        "performance_map_runs");
end

if strlength(options.OutputRoot) == 0
    options.OutputRoot = fullfile( ...
        projectRoot, "phase4", "data", ...
        "performance_maps");
end

candidateSampleTimes_s = [0.05, 0.02, 0.010];
performanceMapTable = table();

meanControlExecutionTime_s = ...
    nan(numel(candidateSampleTimes_s), 1);
p95ControlExecutionTime_s = ...
    nan(numel(candidateSampleTimes_s), 1);

for candidateIndex = 1:numel(candidateSampleTimes_s)
    sampleTime_s = candidateSampleTimes_s(candidateIndex);

    periodLabel = sprintf( ...
        "sample_time_%03d_ms", round(1e3*sampleTime_s));

    runFile = fullfile( ...
        options.RunRoot, ...
        scenarioName, ...
        environmentName, ...
        periodLabel, ...
        "fixed_mode_run.mat");

    assert(isfile(runFile), ...
        "Fixed-mode run does not exist:\n%s", runFile);

    savedData = load(runFile, "runArtifact");

    assert(isfield(savedData, "runArtifact"), ...
        "runArtifact is missing from:\n%s", runFile);

    runArtifact = savedData.runArtifact;

    newRows = create_phase4_performance_map_rows( ...
        runArtifact, ...
        PredictionHorizon_s=options.PredictionHorizon_s, ...
        RowStride_s=options.RowStride_s);

    performanceMapTable = [
        performanceMapTable
        newRows
        ];

    executionTime_s = double( ...
        runArtifact.controlJobs.ExecutionTime_s(:));
    executionTime_s = executionTime_s( ...
        isfinite(executionTime_s));

    assert(~isempty(executionTime_s), ...
        "No completed control jobs exist in:\n%s", runFile);

    meanControlExecutionTime_s(candidateIndex) = ...
        mean(executionTime_s);

    p95ControlExecutionTime_s(candidateIndex) = ...
        empiricalPercentile(executionTime_s, 95);
end

assert(~isempty(performanceMapTable), ...
    "No performance-map rows were created.");

featureNames = [
    "AbsLateralError_m"
    "AbsHeadingError_rad"
    "LongitudinalSpeed_mps"
    "AbsLateralSpeed_mps"
    "AbsYawRate_radps"
    "CurvatureRms_1pm"
    "CurvatureMaximum_1pm"
    ];

outcomeNames = [
    "LateralRms_m"
    "HeadingRms_rad"
    "LateralPeak_m"
    "HeadingPeak_rad"
    "ResponseP95_s"
    "SolverFailure"
    ];

mapXRaw = double( ...
    performanceMapTable{:, featureNames});

mapY = double( ...
    performanceMapTable{:, outcomeNames});

mapSampleTimes_s = double( ...
    performanceMapTable.CandidateSampleTime_s);

normalizationMean = mean(mapXRaw, 1);
normalizationScale = std(mapXRaw, 0, 1);
normalizationScale(normalizationScale < eps) = 1;

mapX = ...
    (mapXRaw - normalizationMean) ...
    ./ normalizationScale;

rawMinimum = nan( ...
    numel(candidateSampleTimes_s), numel(featureNames));
rawMaximum = rawMinimum;
maximumNearestDistance = nan( ...
    numel(candidateSampleTimes_s), 1);

for candidateIndex = 1:numel(candidateSampleTimes_s)
    modeRows = abs( ...
        mapSampleTimes_s ...
        - candidateSampleTimes_s(candidateIndex)) < 1e-12;

    assert(nnz(modeRows) >= 15, ...
        "At least 15 map rows are required for %.0f ms mode.", ...
        1e3*candidateSampleTimes_s(candidateIndex));

    rawMinimum(candidateIndex, :) = ...
        min(mapXRaw(modeRows, :), [], 1);

    rawMaximum(candidateIndex, :) = ...
        max(mapXRaw(modeRows, :), [], 1);

    nearestNeighborDistance = ...
        leaveOneOutNearestDistance(mapX(modeRows, :));

    maximumNearestDistance(candidateIndex) = ...
        empiricalPercentile( ...
            nearestNeighborDistance, 95);
end

performanceMap = struct();
performanceMap.schemaVersion = 1;
performanceMap.scenarioName = scenarioName;
performanceMap.environmentName = environmentName;
performanceMap.predictionHorizon_s = ...
    options.PredictionHorizon_s;
performanceMap.rowStride_s = options.RowStride_s;
performanceMap.featureNames = featureNames;
performanceMap.outcomeNames = outcomeNames;
performanceMap.candidateSampleTimes_s = ...
    candidateSampleTimes_s;
performanceMap.mapX = mapX;
performanceMap.mapY = mapY;
performanceMap.mapSampleTimes_s = mapSampleTimes_s;
performanceMap.normalizationMean = normalizationMean;
performanceMap.normalizationScale = normalizationScale;
performanceMap.rawMinimum = rawMinimum;
performanceMap.rawMaximum = rawMaximum;
performanceMap.safetyMargins = zeros(1, numel(outcomeNames));
performanceMap.maximumNearestDistance = ...
    maximumNearestDistance;
performanceMap.meanControlExecutionTime_s = ...
    meanControlExecutionTime_s;
performanceMap.p95ControlExecutionTime_s = ...
    p95ControlExecutionTime_s;

outputFolder = fullfile( ...
    options.OutputRoot, scenarioName, environmentName);

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

outputFile = fullfile( ...
    outputFolder, "performance_map.mat");

outputCsv = fullfile( ...
    outputFolder, "performance_map_table.csv");

save( ...
    outputFile, ...
    "performanceMap", ...
    "performanceMapTable", ...
    "-v7.3");

writetable(performanceMapTable, outputCsv);

fprintf( ...
    "Created performance map: %s | %s | %d rows\n%s\n", ...
    scenarioName, ...
    environmentName, ...
    height(performanceMapTable), ...
    outputFile);

end


function nearestDistance = ...
    leaveOneOutNearestDistance(normalizedData)

numberOfRows = size(normalizedData, 1);
nearestDistance = inf(numberOfRows, 1);

for rowIndex = 1:numberOfRows
    difference = ...
        normalizedData - normalizedData(rowIndex, :);
    distanceSquared = sum(difference.^2, 2);
    distanceSquared(rowIndex) = inf;
    nearestDistance(rowIndex) = ...
        sqrt(min(distanceSquared));
end

end


function value = empiricalPercentile(data, percentile)

data = sort(double(data(:)));
data = data(isfinite(data));

assert(~isempty(data), ...
    "Cannot compute a percentile from empty data.");

sampleIndex = max( ...
    1, ceil((percentile/100)*numel(data)));

value = data(sampleIndex);

end
