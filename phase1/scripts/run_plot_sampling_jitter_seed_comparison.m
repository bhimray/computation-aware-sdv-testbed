function [figureHandle, jitterData, sourceTable] = ...
    run_plot_sampling_jitter_seed_comparison( ...
    jitterBound_ms, failingSeed, timeWindow_s)
%RUN_PLOT_SAMPLING_JITTER_SEED_COMPARISON Compare all saved seeds.

arguments
    jitterBound_ms (1,1) double {mustBeNonnegative}
    failingSeed (1,1) double {mustBeInteger, mustBePositive}
    timeWindow_s (1,:) double = []
end

startup_project;

projectRoot = string(matlab.project.currentProject().RootFolder);
scenarioName = "highway_cruise";
environmentName = "dry_road";

resultsFolder = fullfile( ...
    projectRoot, "phase1", "results", "ACADOS_MPC", ...
    "sampling_jitter", "jitter_bound_" + jitterBound_ms + "_ms");

seedFolders = dir(fullfile(resultsFolder, "seed_*"));
seedFolders = seedFolders([seedFolders.isdir]);
assert(~isempty(seedFolders), ...
    "No seed folders found for jitter bound %g ms.", jitterBound_ms);

seedNumbers = zeros(numel(seedFolders),1);
for index = 1:numel(seedFolders)
    token = regexp(seedFolders(index).name, ...
        '^seed_(\d+)$', 'tokens', 'once');
    seedNumbers(index) = str2double(token{1});
end
[seedNumbers, order] = sort(seedNumbers);
seedFolders = seedFolders(order);

jitterTables = cell(numel(seedFolders),1);
sourceFiles = strings(numel(seedFolders),1);
availableSeeds = zeros(numel(seedFolders),1);
numberAvailable = 0;

for index = 1:numel(seedFolders)
    resultFile = fullfile( ...
        seedFolders(index).folder, seedFolders(index).name, ...
        scenarioName, environmentName, ...
        scenarioName + "_results.mat");

    if ~isfile(resultFile)
        continue;
    end

    savedData = load(resultFile, "results");
    executionLog = savedData.results.controller_execution_log;
    executionTime_s = getExecutionTime(executionLog);
    actualJitter_ms = 1e3 * executionLog.ActualJitter_s(:);

    sampleCount = min(numel(executionTime_s), numel(actualJitter_ms));
    numberAvailable = numberAvailable + 1;
    availableSeeds(numberAvailable) = seedNumbers(index);
    sourceFiles(numberAvailable) = resultFile;
    jitterTables{numberAvailable} = table( ...
        executionTime_s(1:sampleCount), ...
        actualJitter_ms(1:sampleCount), ...
        repmat(seedNumbers(index), sampleCount, 1), ...
        VariableNames=["time_s", "actual_jitter_ms", "seed"]);
end

assert(numberAvailable > 0, "No saved jitter result files were found.");
jitterTables = jitterTables(1:numberAvailable);
jitterData = vertcat(jitterTables{:});
sourceTable = table( ...
    availableSeeds(1:numberAvailable), ...
    sourceFiles(1:numberAvailable), ...
    VariableNames=["seed", "results_file"]);

figureHandle = sdv.plot.jitterSeedScatter( ...
    jitterData, jitterBound_ms, failingSeed, ...
    TimeWindow_s=timeWindow_s, ...
    FigureTitle=sprintf( ...
        "Highway cruise / dry road: J = %g ms", jitterBound_ms));

end


function executionTime_s = getExecutionTime(executionLog)

candidateNames = [ ...
    "ExecutionTime_s", "ActualExecutionTime_s", ...
    "ObservedTime_s", "ActualTime_s", "Time_s"];
availableNames = string(executionLog.Properties.VariableNames);

for candidateName = candidateNames
    if any(availableNames == candidateName)
        executionTime_s = executionLog.(candidateName)(:);
        return;
    end
end

error("Could not locate execution time in controller_execution_log.");

end
