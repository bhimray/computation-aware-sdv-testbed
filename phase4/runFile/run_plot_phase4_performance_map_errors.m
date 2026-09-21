%% Plot Phase 4 performance-map errors by controller sampling period
% 
% clearvars;
% close all;
% clc;
%% to directly run this plot from preivous result and to initialize the req. var.
% startup_project;

% Change only these selections.
scenarioName = "aggressive_maneuver";
environmentName = "low_friction_road";

% Use [NaN, NaN] for the complete map duration.
timeWindow_s = [NaN, NaN];

projectRoot = string( ...
    matlab.project.currentProject().RootFolder);

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
    TimeWindow_s=timeWindow_s);

fprintf( ...
    "Plotted Phase 4 performance-map errors from:\n%s\n", ...
    mapFile);
