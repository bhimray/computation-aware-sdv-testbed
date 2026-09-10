function figureHandle = randomDelaySweepMetrics(summaryData, options)
%RANDOMDELAYSWEEPMETRICS Plot Monte Carlo mean and standard deviation.
%
% This function only analyzes and plots the supplied summary table. It
% performs no simulation, file loading, or file saving.

arguments
    summaryData table
    options.FigureTitle (1,1) string = ...
        "Monte Carlo Metrics versus Random-Delay Bound"
    options.XLabel (1,1) string = ...
        "Maximum random actuation delay (ms)"
    options.Visible (1,1) string ...
        {mustBeMember(options.Visible, ["on", "off"])} = "on"
end

requiredVariables = [ ...
    "scenario_name"
    "environment_name"
    "maximum_delay_ms"
    "lateral_rmse_m"
    "heading_rmse_rad"
    "constraint_violation_samples"
    ];

missingVariables = setdiff( ...
    requiredVariables, string(summaryData.Properties.VariableNames));

assert(isempty(missingVariables), ...
    "Summary data is missing required variables: %s", ...
    strjoin(missingVariables, ", "));

completedData = summaryData;
if ismember( ...
        "simulation_completed", ...
        string(summaryData.Properties.VariableNames))
    completedMask = summaryData.simulation_completed;
    if ~islogical(completedMask)
        completedMask = completedMask == 1;
    end
    completedData = summaryData(completedMask, :);
end

assert(~isempty(completedData), ...
    "No completed simulations are available for plotting.");

completedData.heading_rmse_deg = ...
    rad2deg(completedData.heading_rmse_rad);

figureHandle = figure( ...
    Name=options.FigureTitle, ...
    Color="white", ...
    Visible=options.Visible);

layout = tiledlayout( ...
    figureHandle, 3, 1, ...
    TileSpacing="compact", ...
    Padding="compact");

lateralAxes = nexttile(layout);
plotMetric(lateralAxes, completedData, "lateral_rmse_m");
ylabel(lateralAxes, "Lateral RMSE (m)");
title(lateralAxes, "Lateral Tracking RMS");

headingAxes = nexttile(layout);
plotMetric(headingAxes, completedData, "heading_rmse_deg");
ylabel(headingAxes, "Heading RMSE (deg)");
title(headingAxes, "Heading Tracking RMS");

violationAxes = nexttile(layout);
plotMetric( ...
    violationAxes, completedData, ...
    "constraint_violation_samples");
ylabel(violationAxes, "Violating samples");
title(violationAxes, "Constraint-Violation Count");

commonLegend = legend( ...
    lateralAxes, "show", Interpreter="none");
commonLegend.Layout.Tile = "east";
commonLegend.Title.String = "Scenario / Environment";

xlabel(layout, options.XLabel);
title(layout, options.FigureTitle, FontWeight="bold");

end


function plotMetric(axesHandle, summaryData, variableName)
% Plot trial mean with plus/minus one standard deviation at each level.

hold(axesHandle, "on");

scenarioNames = unique( ...
    string(summaryData.scenario_name), "stable");
environmentNames = unique( ...
    string(summaryData.environment_name), "stable");

colors = lines(numel(scenarioNames));
styles = enumeration("sdv.enum.plotStyle");

for scenarioIndex = 1:numel(scenarioNames)
    scenarioName = scenarioNames(scenarioIndex);

    for environmentIndex = 1:numel(environmentNames)
        environmentName = environmentNames(environmentIndex);

        selectedRows = ...
            string(summaryData.scenario_name) == scenarioName & ...
            string(summaryData.environment_name) == environmentName;

        selectedData = summaryData(selectedRows, :);
        if isempty(selectedData)
            continue;
        end

        delayLevels_ms = unique( ...
            selectedData.maximum_delay_ms, "sorted");
        metricMean = zeros(size(delayLevels_ms));
        metricStd = zeros(size(delayLevels_ms));

        for levelIndex = 1:numel(delayLevels_ms)
            levelRows = selectedData.maximum_delay_ms == ...
                delayLevels_ms(levelIndex);
            values = selectedData.(variableName)(levelRows);
            metricMean(levelIndex) = mean(values, "omitnan");
            metricStd(levelIndex) = std(values, "omitnan");
        end

        styleIndex = mod( ...
            environmentIndex - 1, numel(styles)) + 1;

        errorbar( ...
            axesHandle, ...
            delayLevels_ms, ...
            metricMean, ...
            metricStd, ...
            styles(styleIndex).LineSpec, ...
            Color=colors(scenarioIndex, :), ...
            LineWidth=1.3, ...
            MarkerSize=5, ...
            DisplayName=replace( ...
                scenarioName + " / " + environmentName, ...
                "_", " "));
    end
end

hold(axesHandle, "off");
grid(axesHandle, "on");

end
