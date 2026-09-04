function figures = plot_phase3_load_task_sweep(summaryTable, options)
%PLOT_PHASE3_LOAD_TASK_SWEEP Plot LoadTask response and scheduling data.
%
% The aggregate summary table provides one row per simulation. Raw
% response-time samples remain in each run_data.mat file and are loaded
% only while producing the box plots.

arguments
    summaryTable table
    options.Deadline_ms (1,1) double {mustBePositive} = 50 % sampling period is always 50ms in our project
    options.SaveFigure (1,1) logical = true
end

requiredVariables = [ ...
    "Scenario", "Environment", "NominalUtilization", ...
    "LoadDeadlineMissPercent", "LoadOverrunCount", ...
    "LoadDroppedJobs", "Status", "RunFile"];
missingVariables = setdiff(requiredVariables, ...
    string(summaryTable.Properties.VariableNames));
assert(isempty(missingVariables), ...
    "Summary table is missing: %s", strjoin(missingVariables, ", "));

completed = summaryTable(summaryTable.Status == "completed",:);
assert(~isempty(completed), ...
    "No completed Phase 3 cases are available to plot.");

scenarioNames = unique(completed.Scenario, "stable");
environmentNames = unique(completed.Environment, "stable");
colors = lines(numel(environmentNames));

figures = struct();
figures.Response = plotResponseDistributions( ...
    completed, scenarioNames, environmentNames, options.Deadline_ms);
figures.Scheduling = plotSchedulingMetrics( ...
    completed, scenarioNames, environmentNames, colors);

if options.SaveFigure
    projectRoot = string(matlab.project.currentProject().RootFolder);
    figureFolder = fullfile(projectRoot, "phase3", "figures", "phase3");
    if ~isfolder(figureFolder)
        mkdir(figureFolder);
    end

    exportgraphics( ...
        figures.Response, ...
        fullfile(figureFolder, "load_task_response_distributions.png"), ...
        Resolution=200);
    exportgraphics( ...
        figures.Scheduling, ...
        fullfile(figureFolder, "load_task_schedulability.png"), ...
        Resolution=200);
end

end


function figureHandle = plotResponseDistributions( ...
    summaryTable, scenarioNames, environmentNames, deadline_ms)

figureHandle = figure( ...
    Name="LoadTask response distributions", ...
    Color="white");
layout = tiledlayout( ...
    numel(environmentNames), ...
    numel(scenarioNames), ...
    TileSpacing="compact", ...
    Padding="compact");
title(layout, "LoadTask Response-Time Distributions");

for environmentIndex = 1:numel(environmentNames)
    for scenarioIndex = 1:numel(scenarioNames)
        axisHandle = nexttile(layout);
        scenarioName = scenarioNames(scenarioIndex);
        environmentName = environmentNames(environmentIndex);
        caseRows = summaryTable( ...
            summaryTable.Scenario == scenarioName ...
            & summaryTable.Environment == environmentName,:);
        caseRows = sortrows(caseRows, "NominalUtilization");

        [utilization, responseTime_ms] = loadResponseSamples(caseRows);
        if ~isempty(responseTime_ms)
            boxchart( ...
                axisHandle, utilization, responseTime_ms, ...
                BoxFaceColor=[0.15 0.45 0.75], ...
                MarkerStyle=".");
        end

        hold(axisHandle, "on");
        yline( ...
            axisHandle, deadline_ms, "r--", ...
            "LoadTask deadline", LabelHorizontalAlignment="left");
        xline(axisHandle, 1, "k:", "U = 1");
        hold(axisHandle, "off");
        grid(axisHandle, "on");
        xlabel(axisHandle, "Nominal task-set utilization, U");
        ylabel(axisHandle, "Response time (ms)");
        title(axisHandle, cleanLabel(scenarioName) + " | " ...
            + cleanLabel(environmentName));
    end
end

end


function figureHandle = plotSchedulingMetrics( ...
    summaryTable, scenarioNames, environmentNames, colors)

figureHandle = figure( ...
    Name="LoadTask schedulability", ...
    Color="white");
layout = tiledlayout( ...
    2, numel(scenarioNames), ...
    TileSpacing="compact", ...
    Padding="compact");
title(layout, "LoadTask Schedulability Across Processor Utilization");

for scenarioIndex = 1:numel(scenarioNames)
    scenarioName = scenarioNames(scenarioIndex);

    deadlineAxis = nexttile(layout, scenarioIndex);
    plotByEnvironment( ...
        deadlineAxis, summaryTable, scenarioName, environmentNames, ...
        colors, "LoadDeadlineMissPercent", "Deadline misses (%)");

    eventAxis = nexttile(layout, numel(scenarioNames) + scenarioIndex);
    plotEvents( ...
        eventAxis, summaryTable, scenarioName, environmentNames, colors);
end

end


function plotByEnvironment( ...
    axisHandle, summaryTable, scenarioName, environmentNames, ...
    colors, variableName, yLabel)

hold(axisHandle, "on");
for environmentIndex = 1:numel(environmentNames)
    environmentName = environmentNames(environmentIndex);
    rows = selectRows(summaryTable, scenarioName, environmentName);
    plot( ...
        axisHandle, rows.NominalUtilization, rows.(variableName), ".-", ...
        Color=colors(environmentIndex,:), ...
        LineWidth=1.2, MarkerSize=12, ...
        DisplayName=cleanLabel(environmentName));
end
xline(axisHandle, 1, "k:", "U = 1", HandleVisibility="off");
hold(axisHandle, "off");
grid(axisHandle, "on");
xlabel(axisHandle, "Nominal task-set utilization, U");
ylabel(axisHandle, yLabel);
title(axisHandle, cleanLabel(scenarioName));
legend(axisHandle, Location="best");

end


function plotEvents( ...
    axisHandle, summaryTable, scenarioName, environmentNames, colors)

hold(axisHandle, "on");
for environmentIndex = 1:numel(environmentNames)
    environmentName = environmentNames(environmentIndex);
    rows = selectRows(summaryTable, scenarioName, environmentName);
    environmentLabel = cleanLabel(environmentName);

    plot( ...
        axisHandle, rows.NominalUtilization, rows.LoadOverrunCount, ".-", ...
        Color=colors(environmentIndex,:), ...
        LineWidth=1.2, MarkerSize=12, ...
        DisplayName=environmentLabel + " | overruns");

    if any(rows.LoadDroppedJobs > 0)
        plot( ...
            axisHandle, rows.NominalUtilization, rows.LoadDroppedJobs, "--", ...
            Color=colors(environmentIndex,:), ...
            LineWidth=1.2, ...
            DisplayName=environmentLabel + " | dropped");
    end
end
xline(axisHandle, 1, "k:", "U = 1", HandleVisibility="off");
hold(axisHandle, "off");
grid(axisHandle, "on");
xlabel(axisHandle, "Nominal task-set utilization, U");
ylabel(axisHandle, "Number of jobs");
title(axisHandle, cleanLabel(scenarioName));
legend(axisHandle, Location="best");

end


function rows = selectRows( ...
    summaryTable, scenarioName, environmentName)

rows = summaryTable( ...
    summaryTable.Scenario == scenarioName ...
    & summaryTable.Environment == environmentName,:);
rows = sortrows(rows, "NominalUtilization");

end


function [utilization, responseTime_ms] = loadResponseSamples(caseRows)

utilization = zeros(0,1);
responseTime_ms = zeros(0,1);

for rowIndex = 1:height(caseRows)
    runFile = string(caseRows.RunFile(rowIndex));
    if strlength(runFile) == 0 || ~isfile(runFile)
        warning("SDV:MissingPhase3Run", ...
            "Skipping missing run file: %s", runFile);
        continue;
    end

    savedData = load(runFile, "runArtifact");
    if ~isfield(savedData, "runArtifact") ...
            || ~isfield(savedData.runArtifact, "loadJobs")
        disp(savedData.runArtifact)
        warning("SDV:MissingLoadResponse", ...
            "Run file has no LoadTask response samples: %s", runFile);
        continue;
    end

    samples_ms = 1e3*double( ...
        savedData.runArtifact.loadJobs.ResponseTime_s(:));
    samples_ms = samples_ms(isfinite(samples_ms));
    responseTime_ms = [responseTime_ms; samples_ms]; %#ok<AGROW>
    utilization = [utilization; repmat( ...
        caseRows.NominalUtilization(rowIndex), ...
        numel(samples_ms), 1)]; %#ok<AGROW>
end

end


function label = cleanLabel(value)
label = replace(string(value), "_", " ");
end
