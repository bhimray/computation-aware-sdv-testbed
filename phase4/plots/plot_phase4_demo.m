function [figureHandle, metrics] = plot_phase4_demo( ...
    fixedSource, ...
    supervisorSource, ...
    options)
%PLOT_PHASE4_DEMO Fixed-rate versus lookup-supervisor demo.
%
% Panels:
%   1. X and Y path references with supervisor Ts-mode bands
%   2. Observed CPU utilization for both runs
%   3. Lateral and heading errors for both runs

arguments
    fixedSource
    supervisorSource

    options.TrackingMetric (1,1) string ...
        {mustBeMember(options.TrackingMetric, ...
        ["lateral", "heading"])} = "lateral"

    options.TimeWindow_s (1,2) double = [NaN, NaN]

    options.FixedLabel (1,1) string = "Fixed 10 ms"
    options.SupervisorLabel (1,1) string = "Naive supervisor"
    options.Title (1,1) string = "Phase 3 Demo Experiment"

    options.FixedColor (1,3) double = [0.00, 0.45, 0.74]
    options.SupervisorColor (1,3) double = [0.85, 0.33, 0.10]

    options.LineWidth (1,1) double {mustBePositive} = 1.1
    options.FontSize_pt (1,1) double {mustBePositive} = 8
    options.FigureSize_in (1,2) double {mustBePositive} = [3.5, 5.2]
    options.Visible (1,1) logical = true

    options.ReferenceXColumn (1,1) double = 2
    options.ReferenceYColumn (1,1) double = 3

    options.SaveFile (1,1) string = ""
    options.ExportResolution (1,1) double = 300

    options.scenario (1, 1) string = ""
    options.env (1,1) string = ""
end

fixedArtifact = loadRunArtifact(fixedSource);
supervisorArtifact = loadRunArtifact(supervisorSource);

validateArtifact(fixedArtifact, "fixed run");
validateArtifact(supervisorArtifact, "supervisor run");

%% Common time window

fixedTime = double(fixedArtifact.results.time_s(:));
supervisorTime = double(supervisorArtifact.results.time_s(:));

timeWindow = [
    max(fixedTime(1), supervisorTime(1)), ...
    min(fixedTime(end), supervisorTime(end))
    ];

metricTimeWindow = timeWindow;

if all(isfinite(options.TimeWindow_s))
    timeWindow(1) = max(timeWindow(1), options.TimeWindow_s(1));
    timeWindow(2) = min(timeWindow(2), options.TimeWindow_s(2));
elseif any(isfinite(options.TimeWindow_s))
    error( ...
        "SDV:InvalidTimeWindow", ...
        "TimeWindow_s must be [NaN NaN] or two finite values.");
end

assert( ...
    timeWindow(2) > timeWindow(1), ...
    "The two runs do not share a valid time window.");

%% Observed CPU utilization

[fixedCpuTime, fixedCpu] = ...
    observedCpuTrace(fixedArtifact, timeWindow);

[supervisorCpuTime, supervisorCpu] = ...
    observedCpuTrace(supervisorArtifact, timeWindow);

[~, fixedCpuFull] = ...
    observedCpuTrace(fixedArtifact, metricTimeWindow);

[~, supervisorCpuFull] = ...
    observedCpuTrace(supervisorArtifact, metricTimeWindow);

fixedMeanUtilization = finiteMean(fixedCpuFull);
supervisorMeanUtilization = finiteMean(supervisorCpuFull);

utilizationReduction = relativeChange( ...
    fixedMeanUtilization, ...
    supervisorMeanUtilization, ...
    "reduction");

%% Lateral error

[fixedLateralTime, fixedLateralError] = windowSignal( ...
    fixedArtifact.results.time_s, ...
    fixedArtifact.results.ey_m, ...
    timeWindow);

[supervisorLateralTime, supervisorLateralError] = ...
    windowSignal( ...
        supervisorArtifact.results.time_s, ...
        supervisorArtifact.results.ey_m, ...
        timeWindow);

fixedLateralRms = finiteRms(fixedArtifact.results.ey_m);
supervisorLateralRms = finiteRms(supervisorArtifact.results.ey_m);

lateralRmsDegradation = relativeChange( ...
    fixedLateralRms, ...
    supervisorLateralRms, ...
    "increase");

%% Heading error

[fixedHeadingTime, fixedHeadingError] = windowSignal( ...
    fixedArtifact.results.time_s, ...
    rad2deg(fixedArtifact.results.epsi_rad), ...
    timeWindow);

[supervisorHeadingTime, supervisorHeadingError] = ...
    windowSignal( ...
        supervisorArtifact.results.time_s, ...
        rad2deg(supervisorArtifact.results.epsi_rad), ...
        timeWindow);

fixedHeadingRms = finiteRms( ...
    rad2deg(fixedArtifact.results.epsi_rad));
supervisorHeadingRms = finiteRms( ...
    rad2deg(supervisorArtifact.results.epsi_rad));

headingRmsDegradation = relativeChange( ...
    fixedHeadingRms, ...
    supervisorHeadingRms, ...
    "increase");

%% Summary table

metrics = table( ...
    fixedMeanUtilization, ...
    supervisorMeanUtilization, ...
    utilizationReduction, ...
    fixedLateralRms, ...
    supervisorLateralRms, ...
    lateralRmsDegradation, ...
    fixedHeadingRms, ...
    supervisorHeadingRms, ...
    headingRmsDegradation, ...
    VariableNames =[ ...
        "FixedMeanCpuUtilization_pct", ...
        "SupervisorMeanCpuUtilization_pct", ...
        "AverageUtilizationReduction_pct", ...
        "FixedLateralRms_m", ...
        "SupervisorLateralRms_m", ...
        "LateralRmsDegradation_pct", ...
        "FixedHeadingRms_deg", ...
        "SupervisorHeadingRms_deg", ...
        "HeadingRmsDegradation_pct" ...
        ]);

%% Create figure

if options.Visible
    figureVisibility = "on";
else
    figureVisibility = "off";
end

figureHandle = figure( ...
    Name=options.Title, ...
    Color="white", ...
    Visible=figureVisibility, ...
    Units="inches", ...
    Position=[1, 1, options.FigureSize_in]);

layout = tiledlayout( ...
    figureHandle, ...
    3, ...
    1, ...
    TileSpacing="compact", ...
    Padding="compact");

%% Panel 1: active sampling period

modeAxes = nexttile(layout);
hold(modeAxes, "on");

[modeTime_s, sampleTime_ms] = ...
    modeSampleTimeTrace(supervisorArtifact.mode,timeWindow);

stairs( ...
    modeAxes, ...
    modeTime_s, ...
    sampleTime_ms, ...
    Color=[0.20, 0.20, 0.20], ...
    LineWidth=options.LineWidth, ...
    HandleVisibility="off");

ylabel(modeAxes,"$T_s$ (ms)",Interpreter="latex");
yticks(modeAxes,[10,20,50]);
ylim(modeAxes,[5,55]);
title(modeAxes,"(a) Active sampling period");
grid(modeAxes,"on");
box(modeAxes,"on");
xlim(modeAxes,timeWindow);
modeAxes.XTickLabel = [];

%% Panel 2: lateral and heading errors

errorAxes = nexttile(layout);
hold(errorAxes, "on");

yyaxis(errorAxes, "left");

fixedLateralLine = plot( ...
    errorAxes, ...
    fixedLateralTime, ...
    fixedLateralError, ...
    Color=options.FixedColor, ...
    LineStyle="-", ...
    LineWidth=options.LineWidth, ...
    DisplayName=options.FixedLabel + " lateral");

supervisorLateralLine = plot( ...
    errorAxes, ...
    supervisorLateralTime, ...
    supervisorLateralError, ...
    Color=options.SupervisorColor, ...
    LineStyle="-", ...
    LineWidth=options.LineWidth, ...
    DisplayName=options.SupervisorLabel + " lateral");

ylabel(errorAxes,"$e_y$ (m)",Interpreter="latex");

yyaxis(errorAxes, "right");

fixedHeadingLine = plot( ...
    errorAxes, ...
    fixedHeadingTime, ...
    fixedHeadingError, ...
    Color=options.FixedColor, ...
    LineStyle="--", ...
    LineWidth=options.LineWidth, ...
    DisplayName=options.FixedLabel + " heading");

supervisorHeadingLine = plot( ...
    errorAxes, ...
    supervisorHeadingTime, ...
    supervisorHeadingError, ...
    Color=options.SupervisorColor, ...
    LineStyle="--", ...
    LineWidth=options.LineWidth, ...
    DisplayName=options.SupervisorLabel + " heading");

ylabel(errorAxes,"$e_\psi$ (deg)",Interpreter="latex");
title(errorAxes,"(b) Tracking errors");

grid(errorAxes, "on");
box(errorAxes, "on");
xlim(errorAxes, timeWindow);

commonLegend = legend( ...
    errorAxes, ...
    [ ...
    fixedLateralLine, ...
    supervisorLateralLine, ...
    fixedHeadingLine, ...
    supervisorHeadingLine], ...
    Location="southoutside", ...
    NumColumns=2, ...
    Interpreter="none", ...
    FontSize=options.FontSize_pt);

%% Panel 3: observed CPU utilization

cpuAxes = nexttile(layout);
hold(cpuAxes, "on");

fixedCpuLine = stairs( ...
    cpuAxes, ...
    fixedCpuTime, ...
    fixedCpu, ...
    Color=options.FixedColor, ...
    LineWidth=options.LineWidth, ...
    DisplayName=options.FixedLabel);

supervisorCpuLine = stairs( ...
    cpuAxes, ...
    supervisorCpuTime, ...
    supervisorCpu, ...
    Color=options.SupervisorColor, ...
    LineWidth=options.LineWidth, ...
    DisplayName=options.SupervisorLabel);

yline( ...
    cpuAxes, ...
    100, ...
    "k:", ...
    LineWidth=1.2, ...
    HandleVisibility="off");

ylabel(cpuAxes,"CPU (\%)",Interpreter="latex");
xlabel(cpuAxes,"Time (s)");
title(cpuAxes,"(c) CPU utilization");

grid(cpuAxes, "on");
box(cpuAxes, "on");
xlim(cpuAxes,timeWindow);

fixedCpuLine.HandleVisibility = "off";
supervisorCpuLine.HandleVisibility = "off";

linkaxes([modeAxes,errorAxes,cpuAxes],"x");

set( ...
    [modeAxes,errorAxes,cpuAxes], ...
    FontSize=options.FontSize_pt, ...
    LineWidth=0.75);

fontObjects = findall(figureHandle,"-property","FontSize");
for objectIndex = 1:numel(fontObjects)
    fontObjects(objectIndex).FontSize = max( ...
        options.FontSize_pt, ...
        fontObjects(objectIndex).FontSize);
end

commonLegend.Layout.Tile = "south";

%% Export

if strlength(options.SaveFile) > 0
    outputFolder = string(fileparts(options.SaveFile));

    if strlength(outputFolder) > 0 && ~isfolder(outputFolder)
        mkdir(outputFolder);
    end

    [~,~,extension] = fileparts(options.SaveFile);

    if any(strcmpi(extension,[".pdf",".eps"]))
        exportgraphics( ...
            figureHandle, ...
            options.SaveFile, ...
            ContentType="vector");
    else
        exportgraphics( ...
            figureHandle, ...
            options.SaveFile, ...
            Resolution=options.ExportResolution);
    end
end

disp(metrics);

end


function artifact = loadRunArtifact(source)

if ischar(source) || (isstring(source) && isscalar(source))
    sourceFile = string(source);

    assert(isfile(sourceFile), ...
        "Run-artifact file does not exist: %s", sourceFile);

    loadedData = load(sourceFile);

    assert(isfield(loadedData, "runArtifact"), ...
        "File does not contain runArtifact: %s", sourceFile);

    artifact = loadedData.runArtifact;

elseif isstruct(source) && isfield(source, "runArtifact")
    artifact = source.runArtifact;

elseif isstruct(source) && isfield(source, "results")
    artifact = source;

else
    error( ...
        "SDV:InvalidRunArtifact", ...
        "Input must be a runArtifact or MAT-file path.");
end

end


function validateArtifact(artifact, runName)

requiredArtifactFields = [
    "results"
    "reference"
    "mode"
    "controlJobs"
    "observedCpuUtilization"
    ];

assert( ...
    all(isfield(artifact, requiredArtifactFields)), ...
    "%s artifact is missing required fields.", ...
    runName);

requiredResultFields = [
    "time_s"
    "x_pos_m"
    "y_pos_m"
    "ey_m"
    "epsi_rad"
    ];

assert( ...
    all(isfield(artifact.results, requiredResultFields)), ...
    "%s results are missing required signals.", ...
    runName);

end


function [time, referenceX, referenceY] = ...
    timeAlignedPathReference( ...
        artifact, ...
        timeWindow, ...
        xColumn, ...
        yColumn)

results = artifact.results;

rawTime = double(results.time_s(:));
actualX = double(results.x_pos_m(:));
actualY = double(results.y_pos_m(:));

numberOfSamples = min( ...
    [numel(rawTime), numel(actualX), numel(actualY)]);

rawTime = rawTime(1:numberOfSamples);
actualX = actualX(1:numberOfSamples);
actualY = actualY(1:numberOfSamples);

valid = ...
    isfinite(rawTime) & ...
    isfinite(actualX) & ...
    isfinite(actualY) & ...
    rawTime >= timeWindow(1) & ...
    rawTime <= timeWindow(2);

time = rawTime(valid);
actualX = actualX(valid);
actualY = actualY(valid);

% Use explicitly logged reference coordinates when available.
if isfield(results, "x_ref_m") && isfield(results, "y_ref_m")
    rawReferenceX = double(results.x_ref_m(:));
    rawReferenceY = double(results.y_ref_m(:));

    rawReferenceX = rawReferenceX(1:numberOfSamples);
    rawReferenceY = rawReferenceY(1:numberOfSamples);

    referenceX = rawReferenceX(valid);
    referenceY = rawReferenceY(valid);
    return;
end

% Otherwise obtain the closest path-reference point for every sample.
referenceTable = artifact.reference;

if istable(referenceTable)
    referenceTable = table2array(referenceTable);
end

referenceTable = double(referenceTable);

assert( ...
    size(referenceTable, 2) >= max(xColumn, yColumn), ...
    "Reference table does not contain the configured X/Y columns.");

pathX = referenceTable(:, xColumn);
pathY = referenceTable(:, yColumn);

validReference = isfinite(pathX) & isfinite(pathY);
pathX = pathX(validReference);
pathY = pathY(validReference);

referenceX = zeros(size(time));
referenceY = zeros(size(time));

for sampleIndex = 1:numel(time)
    distanceSquared = ...
        (pathX - actualX(sampleIndex)).^2 + ...
        (pathY - actualY(sampleIndex)).^2;

    [~, nearestIndex] = min(distanceSquared);

    referenceX(sampleIndex) = pathX(nearestIndex);
    referenceY(sampleIndex) = pathY(nearestIndex);
end

end


function [time, utilization] = ...
    observedCpuTrace(artifact, timeWindow)

jobs = artifact.controlJobs;

assert( ...
    all(ismember( ...
    ["ReleaseTime_s", "ObservedCpuUtilization"], ...
    string(jobs.Properties.VariableNames))), ...
    "controlJobs must contain ReleaseTime_s and " + ...
    "ObservedCpuUtilization.");

time = double(jobs.ReleaseTime_s(:));

controlUtilization = ...
    100 * double(jobs.ObservedCpuUtilization(:));

observedSummary = artifact.observedCpuUtilization;

constantUtilization = ...
    double(observedSummary.Load_pct) ...
    + double(observedSummary.Communication_pct);

if isfield(artifact, "supervisorJobs") ...
        && istable(artifact.supervisorJobs) ...
        && all(ismember( ...
            ["ReleaseTime_s", "ObservedCpuUtilization"], ...
            string(artifact.supervisorJobs.Properties.VariableNames))) ...
        && ~isempty(artifact.supervisorJobs)

    supervisorUtilization = sampleHeldAt( ...
        artifact.supervisorJobs.ReleaseTime_s, ...
        100*artifact.supervisorJobs.ObservedCpuUtilization, ...
        time);
else
    % Compatibility with artifacts saved before supervisor-job timing was
    % added to the saved result.
    supervisorUtilization = repmat( ...
        double(observedSummary.Supervisor_pct), ...
        numel(time), ...
        1);
end

utilization = ...
    controlUtilization ...
    + supervisorUtilization ...
    + constantUtilization;

valid = ...
    isfinite(time) & ...
    isfinite(utilization) & ...
    time >= timeWindow(1) & ...
    time <= timeWindow(2);

time = time(valid);
utilization = utilization(valid);

[time, order] = sort(time);
utilization = utilization(order);

end


function sampledData = sampleHeldAt( ...
    sourceTime_s, sourceData, queryTime_s)

sourceTime_s = double(sourceTime_s(:));
sourceData = double(sourceData(:));
queryTime_s = double(queryTime_s(:));

valid = isfinite(sourceTime_s) & isfinite(sourceData);
sourceTime_s = sourceTime_s(valid);
sourceData = sourceData(valid);

assert(~isempty(sourceTime_s), ...
    "Observed supervisor timing contains no finite jobs.");

[sourceTime_s, uniqueIndices] = unique(sourceTime_s, "last");
sourceData = sourceData(uniqueIndices);

if isscalar(sourceTime_s)
    sampledData = repmat(sourceData, numel(queryTime_s), 1);
else
    sampledData = interp1( ...
        sourceTime_s, ...
        sourceData, ...
        queryTime_s, ...
        "previous", ...
        "extrap");
end

sampledData = sampledData(:);

end


function [time_s, sampleTime_ms] = ...
    modeSampleTimeTrace(modeSignal,timeWindow)

assert(isstruct(modeSignal) && ...
    all(isfield(modeSignal,["Time_s","Data"])), ...
    "Mode signal must contain Time_s and Data.");

time_s = double(modeSignal.Time_s(:));
mode = round(double(modeSignal.Data(:)));

valid = isfinite(time_s) & isfinite(mode);

time_s = time_s(valid);
mode = mode(valid);

assert(~isempty(time_s), ...
    "Mode signal contains no finite samples.");

[time_s,uniqueIndices] = unique(time_s,"last");
mode = min(max(mode(uniqueIndices),1),3);

plotTime_s = [
    timeWindow(1)
    time_s(time_s > timeWindow(1) & time_s < timeWindow(2))
    timeWindow(2)
    ];

mode = interp1( ...
    time_s, ...
    mode, ...
    plotTime_s, ...
    "previous", ...
    "extrap");

time_s = plotTime_s;

% Logged modes 1, 2, and 3 correspond to 50, 20, and 10 ms.
modePeriods_ms = [50;20;10];
sampleTime_ms = modePeriods_ms(mode);

end


function drawModeBands(axesHandle, modeSignal, timeWindow)

if ~isstruct(modeSignal) || ...
        ~all(isfield(modeSignal, ["Time_s", "Data"]))
    return;
end

modeTime = double(modeSignal.Time_s(:));
modeData = round(double(modeSignal.Data(:)));

valid = isfinite(modeTime) & isfinite(modeData);
modeTime = modeTime(valid);
modeData = modeData(valid);

if isempty(modeTime)
    return;
end

[modeTime, uniqueIndices] = unique(modeTime, "last");
modeData = modeData(uniqueIndices);

changeTimes = modeTime([true; diff(modeData) ~= 0]);

boundaries = [
    timeWindow(1)
    changeTimes( ...
        changeTimes > timeWindow(1) & ...
        changeTimes < timeWindow(2))
    timeWindow(2)
    ];

modeColors = [
    0.18, 0.19, 0.23   % Low demand:    Ts = 50 ms
    0.95, 0.55, 0.00   % Medium demand: Ts = 20 ms
    0.78, 0.08, 0.10   % High demand:   Ts = 10 ms
    ];

yLimits = ylim(axesHandle);
bandHandles = gobjects(0);

for intervalIndex = 1:(numel(boundaries) - 1)
    startTime = boundaries(intervalIndex);
    endTime = boundaries(intervalIndex + 1);

    activeMode = interp1( ...
        modeTime, ...
        modeData, ...
        startTime, ...
        "previous", ...
        "extrap");

    activeMode = min(max(round(activeMode), 1), 3);

    bandHandles(end + 1) = patch( ... %#ok<AGROW>
        axesHandle, ...
        [startTime, endTime, endTime, startTime], ...
        [yLimits(1), yLimits(1), yLimits(2), yLimits(2)], ...
        modeColors(activeMode, :), ...
        FaceAlpha=0.20, ...
        EdgeColor="none", ...
        HandleVisibility="off");
end

% Do not call uistack here. With yyaxis, the left- and right-axis graphics
% share an Axes object but use different rulers, and uistack can fail while
% trying to reorder that mixed child list. The low FaceAlpha keeps the
% bands readable without obscuring the reference traces.

end


function [time, data] = windowSignal( ...
    rawTime, ...
    rawData, ...
    timeWindow)

rawTime = double(rawTime(:));
rawData = double(rawData(:));

numberOfSamples = min(numel(rawTime), numel(rawData));

rawTime = rawTime(1:numberOfSamples);
rawData = rawData(1:numberOfSamples);

valid = ...
    isfinite(rawTime) & ...
    isfinite(rawData) & ...
    rawTime >= timeWindow(1) & ...
    rawTime <= timeWindow(2);

time = rawTime(valid);
data = rawData(valid);

end


function value = finiteMean(data)

data = double(data(:));
data = data(isfinite(data));

if isempty(data)
    value = NaN;
else
    value = mean(data);
end

end


function value = finiteRms(data)

data = double(data(:));
data = data(isfinite(data));

if isempty(data)
    value = NaN;
else
    value = sqrt(mean(data.^2));
end

end


function percentage = relativeChange( ...
    referenceValue, ...
    newValue, ...
    calculationType)

if ~isfinite(referenceValue) || abs(referenceValue) < eps
    percentage = NaN;
    return;
end

switch calculationType
    case "reduction"
        percentage = ...
            100 * (referenceValue - newValue) / referenceValue;

    case "increase"
        percentage = ...
            100 * (newValue - referenceValue) / referenceValue;
end

end
