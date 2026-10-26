function figureHandle = ...
    plot_sampling_jitter_monte_carlo(statisticsSource, options)
%PLOT_SAMPLING_JITTER_MONTE_CARLO Plot a Phase 1.3 sweep summary.

arguments
    statisticsSource
    options.SaveFigure (1,1) logical = true
    options.ShowFigure (1,1) logical = true
end

statistics = loadStatistics(statisticsSource);
assert(~isempty(statistics), ...
    "No completed sampling-jitter statistics are available.");

figureHandle = createFigure(statistics);

if options.SaveFigure
    configuration = build_phase0_configuration("highway_cruise");
    controllerName = sdv.config.controllerName( ...
        configuration.controller);
    projectRoot = string(matlab.project.currentProject().RootFolder);
    figureFolder = fullfile( ...
        projectRoot, "phase1", "figures", controllerName, ...
        "sampling_jitter", "sweep");

    if ~isfolder(figureFolder)
        mkdir(figureFolder);
    end

    exportgraphics( ...
        figureHandle, ...
        fullfile(figureFolder, "sampling_jitter_sweep_summary.png"), ...
        Resolution=200);
    savefig( ...
        figureHandle, ...
        fullfile(figureFolder, "sampling_jitter_sweep_summary.fig"));
end

if ~options.ShowFigure
    close(figureHandle);
end

end

function statistics = loadStatistics(source)

if istable(source)
    statistics = source;
    return;
end

source = string(source);
assert(isfile(source), ...
    "Sampling-jitter statistics file does not exist: %s", source);
stored = load(source, "sweepStatistics");
assert(isfield(stored, "sweepStatistics") && ...
    istable(stored.sweepStatistics), ...
    "Statistics file does not contain sweepStatistics.");
statistics = stored.sweepStatistics;

end

function figureHandle = createFigure(statistics)

figureHandle = figure( ...
    Name="Phase 1.3 sampling-jitter sweep", ...
    Color="w");

layout = tiledlayout( ...
    figureHandle, 2, 2, ...
    TileSpacing="compact", ...
    Padding="compact");

title(layout, "Phase 1.3 Sampling Jitter: Mean \pm1\sigma");

seriesTable = unique( ...
    statistics(:, ["ScenarioName", "EnvironmentName"]), ...
    "rows", "stable");
colors = lines(height(seriesTable));

plotMetricStatistics( ...
    layout, statistics, seriesTable, colors, ...
    "LateralRmse_m", "Lateral RMSE (m)", ...
    "Lateral Tracking Error");
plotMetricStatistics( ...
    layout, statistics, seriesTable, colors, ...
    "HeadingRmse_deg", "Heading RMSE (deg)", ...
    "Heading Tracking Error");
plotConstraintStatistics( ...
    layout, statistics, seriesTable, colors);
plotMetricStatistics( ...
    layout, statistics, seriesTable, colors, ...
    "DeadlineMissCount", "Deadline-miss count", ...
    "Controller Deadline Misses");

xlabel(layout, "Jitter bound, J (ms)");

end

function plotMetricStatistics( ...
    layout, statistics, seriesTable, colors, ...
    metricName, yLabelText, titleText)

axesHandle = nexttile(layout);
hold(axesHandle, "on");

for seriesIndex = 1:height(seriesTable)
    selected = selectSeries(statistics, seriesTable, seriesIndex);
    x = selected.JitterBound_ms;
    meanValue = selected.(metricName + "_Mean");
    sigmaValue = selected.(metricName + "_Std");
    valid = isfinite(x) & isfinite(meanValue) & isfinite(sigmaValue);

    x = x(valid);
    meanValue = meanValue(valid);
    sigmaValue = sigmaValue(valid);

    if isempty(x)
        continue;
    end

    seriesColor = colors(seriesIndex, :);

    if numel(x) > 1
        fill( ...
            axesHandle, ...
            [x; flipud(x)], ...
            [meanValue - sigmaValue; ...
            flipud(meanValue + sigmaValue)], ...
            seriesColor, ...
            FaceAlpha=0.18, ...
            EdgeColor="none", ...
            HandleVisibility="off");
    end

    plot( ...
        axesHandle, x, meanValue, "-o", ...
        Color=seriesColor, ...
        MarkerFaceColor=seriesColor, ...
        LineWidth=1.5, ...
        MarkerSize=5, ...
        DisplayName=seriesDisplayName(seriesTable, seriesIndex));
end

hold(axesHandle, "off");
grid(axesHandle, "on");
ylabel(axesHandle, yLabelText);
title(axesHandle, titleText);
legend(axesHandle, Location="best");

end

function plotConstraintStatistics( ...
    layout, statistics, seriesTable, colors)

axesHandle = nexttile(layout);
yyaxis(axesHandle, "left");
hold(axesHandle, "on");
yyaxis(axesHandle, "right");
hold(axesHandle, "on");

for seriesIndex = 1:height(seriesTable)
    selected = selectSeries(statistics, seriesTable, seriesIndex);
    x = selected.JitterBound_ms;
    seriesColor = colors(seriesIndex, :);
    displayName = seriesDisplayName(seriesTable, seriesIndex);

    sampleMean = selected.ConstraintViolationSamples_Mean;
    sampleStd = selected.ConstraintViolationSamples_Std;
    valid = isfinite(x) & isfinite(sampleMean) & isfinite(sampleStd);

    if any(valid)
        yyaxis(axesHandle, "left");
        errorbar( ...
            axesHandle, x(valid), sampleMean(valid), sampleStd(valid), ...
            "-o", Color=seriesColor, ...
            MarkerFaceColor=seriesColor, ...
            LineWidth=1.4, MarkerSize=5, ...
            DisplayName=displayName + " / samples");
    end

    eventMean = selected.ConstraintEventCount_Mean;
    eventStd = selected.ConstraintEventCount_Std;
    valid = isfinite(x) & isfinite(eventMean) & isfinite(eventStd);

    if any(valid)
        yyaxis(axesHandle, "right");
        errorbar( ...
            axesHandle, x(valid), eventMean(valid), eventStd(valid), ...
            "--s", Color=seriesColor, ...
            LineWidth=1.4, MarkerSize=5, ...
            DisplayName=displayName + " / events");
    end
end

yyaxis(axesHandle, "left");
hold(axesHandle, "off");
grid(axesHandle, "on");
ylabel(axesHandle, "Violating samples");
yyaxis(axesHandle, "right");
ylabel(axesHandle, "Violation events");
title(axesHandle, "Constraint-Violating Samples and Events");
legend(axesHandle, Location="best");

end

function selected = selectSeries(statistics, seriesTable, seriesIndex)

matching = ...
    statistics.ScenarioName == seriesTable.ScenarioName(seriesIndex) & ...
    statistics.EnvironmentName == ...
        seriesTable.EnvironmentName(seriesIndex);
selected = sortrows( ...
    statistics(matching, :), "JitterBound_ms");

end

function displayName = seriesDisplayName(seriesTable, seriesIndex)

displayName = replace( ...
    seriesTable.ScenarioName(seriesIndex) + " / " + ...
    seriesTable.EnvironmentName(seriesIndex), ...
    "_", " ");

end
