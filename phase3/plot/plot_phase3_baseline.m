function [figures, results, config] = ...
    plot_phase3_baseline(resultsFile, options)
%PLOT_PHASE3_BASELINE Plot one saved fixed-rate Phase 3 baseline run.

arguments
    resultsFile (1,1) string
    options.SaveFigures (1,1) logical = true
    options.ShowFigures (1,1) logical = true
end

[figures, results, config] = sdv.plot.standardRunArtifact( ...
    resultsFile, ...
    ExpectedPhases=["phase3_20ms", "phase3_50ms"], ...
    SaveFigures=options.SaveFigures, ...
    ShowFigures=options.ShowFigures);

end
