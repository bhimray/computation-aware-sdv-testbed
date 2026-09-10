function [figures, results, config] = ...
    standardRunArtifact(resultsFile, options)
%STANDARDRUNARTIFACT Plot one saved ExperimentRunner result artifact.

arguments
    resultsFile (1,1) string
    options.ExpectedPhases (1,:) string = string.empty(1,0)
    options.SaveFigures (1,1) logical = true
    options.ShowFigures (1,1) logical = true
end

assert(isfile(resultsFile), ...
    "Saved run does not exist: %s", resultsFile);

stored = load(resultsFile, "results", "config");
assert(isfield(stored, "results") && isfield(stored, "config"), ...
    "Saved run must contain results and config.");

results = stored.results;
config = stored.config;

assert(isfield(config, "run"), ...
    "Saved configuration does not contain config.run.");

if ~isempty(options.ExpectedPhases)
    assert(any(config.run.phase_name == options.ExpectedPhases), ...
        "Expected phase %s, but artifact contains %s.", ...
        strjoin(options.ExpectedPhases, ", "), ...
        config.run.phase_name);
end

previousVisibility = get(groot, "defaultFigureVisible");
visibilityCleanup = onCleanup(@() set( ...
    groot, "defaultFigureVisible", previousVisibility));

if ~options.ShowFigures
    set(groot, "defaultFigureVisible", "off");
end

figures = sdv.plot.standardRunFigures(results, config);

if options.SaveFigures
    exportFigures(figures, config);
end

if ~options.ShowFigures
    closeFigures(figures);
end

end

function exportFigures(figures, config)

runConfig = config.run;
projectRoot = string(matlab.project.currentProject().RootFolder);
controllerName = sdv.config.controllerName(config.controller);

folders = sdv.io.createOutputFolders( ...
    projectRoot, runConfig, controllerName, ...
    CreateResults=false);

if any(runConfig.phase_name == ...
        ["phase0", "phase3_20ms", "phase3_50ms"])
    closedLoopName = runConfig.scenario_name + "_tracking";
else
    closedLoopName = ...
        runConfig.scenario_name + "_closed_loop_results";
end

sdv.io.exportFigure( ...
    figures.closed_loop, folders.figures, closedLoopName);
sdv.io.exportFigure( ...
    figures.tracking_errors, ...
    folders.figures, ...
    runConfig.scenario_name + "_tracking_errors");

if isfield(figures, "solve_time_histogram")
    sdv.io.exportFigure( ...
        figures.solve_time_histogram, ...
        folders.figures, ...
        runConfig.scenario_name + "_solve_time_histogram");
    sdv.io.exportFigure( ...
        figures.solve_time_telemetry, ...
        folders.figures, ...
        runConfig.scenario_name + "_solve_time_telemetry");
end

if isfield(figures, "sampling_jitter_profile")
    sdv.io.exportFigure( ...
        figures.sampling_jitter_profile, ...
        folders.figures, ...
        runConfig.scenario_name + "_sampling_jitter_profile");
end

end

function closeFigures(figures)

names = fieldnames(figures);

for index = 1:numel(names)
    figureHandle = figures.(names{index});

    if isgraphics(figureHandle, "figure")
        close(figureHandle);
    end
end

end
