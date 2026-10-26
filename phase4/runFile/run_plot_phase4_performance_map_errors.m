%% Plot Phase 4 performance-map errors by controller sampling period
% 
% clearvars;
% close all;
% clc;
%% to directly run this plot from preivous result and to initialize the req. var.
% startup_project;

% Change only these selections.
scenarioName = "aggressive_maneuver";
environmentName = "dry_road";

% Use [NaN, NaN] for the complete map duration.
timeWindow_s = [NaN, NaN];

projectRoot = string(fileparts(fileparts(fileparts(mfilename("fullpath")))));

mapFile = fullfile( ...
    projectRoot, ...
    "phase4", "data", "performance_maps", ...
    scenarioName, environmentName, ...
    "performance_map.mat");

assert(isfile(mapFile), ...
    "Performance map does not exist:\n%s", mapFile);

savedMap = load(mapFile, "performanceMapTable");

assert(isfield(savedMap, "performanceMapTable"), ...
    "performanceMapTable is missing from:\n%s", mapFile);

figures = plot_phase4_performance_map_errors( ...
    savedMap.performanceMapTable, ...
    TimeWindow_s=timeWindow_s, ...
    LineWidth=1.25, ...
    FontSize=8, ...
    FigureSize_cm=[17.8, 10.5], ...
    ShowFigureTitle=false);

outputFolder = fullfile(projectRoot, ...
    "phase4", "figures", "paper", scenarioName, environmentName);
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

exportPaperFigure( ...
    figures.PerformanceMapErrors, outputFolder, "performance_map_errors");

fprintf( ...
    "Plotted Phase 4 performance-map errors from:\n%s\n", ...
    mapFile);
fprintf("Saved paper figures to:\n%s\n", outputFolder);

function exportPaperFigure(figureHandle, outputFolder, fileName)
basePath = fullfile(outputFolder, fileName);
exportgraphics(figureHandle, basePath + ".pdf", ...
    ContentType="vector", BackgroundColor="white");
exportgraphics(figureHandle, basePath + ".png", ...
    Resolution=300, BackgroundColor="white");
savefig(figureHandle, basePath + ".fig");
end
