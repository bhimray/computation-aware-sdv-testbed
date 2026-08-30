function figures = plot_phase2_4_utilization_sweep(summaryTable, options)
%PLOT_PHASE2_4_UTILIZATION_SWEEP Plot saved Phase 2.4 aggregate metrics.

arguments
    summaryTable table
    options.SaveFigure (1,1) logical = true
end

completed = summaryTable(summaryTable.Status == "completed",:);
% assert(~isempty(completed), "No completed Phase 2.4 cases are available.");

figures = struct();
figures.metrics = figure( ...
    Name="Phase 2.4 utilization sweep", ...
    Color="white");

layout = tiledlayout(2,2,TileSpacing="compact",Padding="compact");
title(layout, "Phase 2.4 Scheduler Utilization Sweep");

plotMetric(nexttile, completed, "LateralRMS_m", ...
    "Lateral RMS error (m)");
plotMetric(nexttile, completed, "HeadingRMS_deg", ...
    "Heading RMS error (deg)");
plotMetric(nexttile, completed, "SpeedRMS_mps", ...
    "Speed RMS error (m/s)");
plotMetric(nexttile, completed, "ControlDeadlineMissPercent", ...
    "Control deadline misses (%)");

if options.SaveFigure
    projectRoot = string(matlab.project.currentProject().RootFolder);
    figureFolder = fullfile(projectRoot, "phase2", "figures", "phase2_4");
    if ~isfolder(figureFolder)
        mkdir(figureFolder);
    end

    exportgraphics( ...
        figures.metrics, ...
        fullfile(figureFolder, "utilization_sweep_metrics.png"), ...
        Resolution=200);
end

end


function plotMetric(axisHandle, tableData, variableName, yLabel)

groups = unique(tableData(:,["Scenario", "Environment"]), "rows");

disp("groups");
disp(groups);


hold(axisHandle, "on");

for groupIndex = 1:height(groups)
    mask = ...
        tableData.Scenario == groups.Scenario(groupIndex) ...
        & tableData.Environment == groups.Environment(groupIndex);

    groupData = sortrows(tableData(mask,:), "NominalUtilization");
    scenarioLabel = replace( ...
    groups.Scenario(groupIndex), "_", " ");

    environmentLabel = replace( ...
        groups.Environment(groupIndex), "_", " ");
    
    label = scenarioLabel + " | " + environmentLabel;

    plot( ...
        axisHandle, ...
        groupData.NominalUtilization, ...
        groupData.(variableName), ...
        ".-", ...
        LineWidth=1.2, ...
        MarkerSize=12, ...
        DisplayName=label);
end

grid(axisHandle, "on");
xlabel(axisHandle, "Nominal task-set utilization, U");
ylabel(axisHandle, yLabel);
legend(axisHandle, Location="best");

end
