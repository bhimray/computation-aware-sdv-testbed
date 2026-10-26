function figureHandle = plot_random_delay_sweep(summarySource, options)
%PLOT_RANDOM_DELAY_SWEEP Plot a saved or in-memory Phase 1.2 summary.

arguments
    summarySource
    options.SaveFigure (1,1) logical = true
    options.ShowFigure (1,1) logical = true
end

summaryTable = loadSummary(summarySource, "summaryTable");

visibility = "off";
if options.ShowFigure
    visibility = "on";
end

figureHandle = sdv.plot.randomDelaySweepMetrics( ...
    summaryTable, ...
    FigureTitle= ...
        "Phase 1.2: Monte Carlo Metrics versus Random-Delay Bound", ...
    Visible=visibility);

if options.SaveFigure
    configuration = build_phase0_configuration("highway_cruise");
    controllerName = sdv.config.controllerName( ...
        configuration.controller);
    projectRoot = string(matlab.project.currentProject().RootFolder);
    figureFolder = fullfile( ...
        projectRoot, "phase1", "figures", controllerName, ...
        "random_delay_sweep");
    sdv.io.exportFigure( ...
        figureHandle, figureFolder, ...
        "random_delay_monte_carlo_metrics");
end

if ~options.ShowFigure
    close(figureHandle);
end

end

function summaryTable = loadSummary(source, variableName)

if istable(source)
    summaryTable = source;
    return;
end

source = string(source);
assert(isfile(source), "Summary file does not exist: %s", source);
stored = load(source, variableName);
assert(isfield(stored, variableName) && istable(stored.(variableName)), ...
    "Summary file does not contain table %s.", variableName);
summaryTable = stored.(variableName);

end
