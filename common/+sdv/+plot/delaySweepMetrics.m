function figureHandle = delaySweepMetrics(summaryData, options)
%DELAYSWEEPMETRICS Plot tracking metrics from a delay-sweep summary table.
%
% The function performs no file loading or saving. Pass a summary table
% from a completed experiment or load one from disk before calling it.

arguments
    summaryData table
    options.FigureTitle (1,1) string = ...
        "Performance versus Constant Delay"
    options.XLabel (1,1) string = ...
        "Constant actuation delay, \tau (ms)"
    options.Visible (1,1) string ...
        {mustBeMember(options.Visible, ["on", "off"])} = "on"
end

requiredVariables = [ ...
    "scenario_name"
    "environment_name"
    "delay_ms"
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
title(lateralAxes, "Lateral Tracking Error");

headingAxes = nexttile(layout);
plotMetric(headingAxes, completedData, "heading_rmse_deg");
ylabel(headingAxes, "Heading RMSE (deg)");
title(headingAxes, "Heading Tracking Error");

violationAxes = nexttile(layout);

plotMetric( ...
    violationAxes, ...
    completedData, ...
    "constraint_violation_samples");

ylabel(violationAxes, "Number of violating samples");
title(violationAxes, "Total Constraint-Violating Samples");

%% One common legend for all tiles

commonLegend = legend( ...
    lateralAxes, ...
    "show", ...
    Interpreter="none");

commonLegend.Layout.Tile = "east";
commonLegend.Title.String = "Scenario / Environment";

xlabel(layout, options.XLabel);
title(layout, options.FigureTitle, FontWeight="bold");

end

function plotMetric(axesHandle, summaryData, variableName)
% Plot one metric for every scenario/environment combination.

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

        if ~any(selectedRows)
            continue;
        end

        selectedData = sortrows( ...
            summaryData(selectedRows, :), "delay_ms");

        styleIndex = mod( ...
            environmentIndex - 1, numel(styles)) + 1;

        plot( ...
            axesHandle, ...
            selectedData.delay_ms, ...
            selectedData.(variableName), ...
            styles(styleIndex).LineSpec, ...
            Color=colors(scenarioIndex, :), ...
            LineWidth=1.4, ...
            MarkerSize=5, ...
            DisplayName=replace( ...
                scenarioName + " / " + environmentName, ...
                "_", " "));
    end
end

hold(axesHandle, "off");
grid(axesHandle, "on");
end
