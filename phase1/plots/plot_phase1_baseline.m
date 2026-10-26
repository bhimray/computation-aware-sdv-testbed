function [figures, results, config] = ...
    plot_phase1_baseline(resultsFile, options)
%PLOT_PHASE1_BASELINE Plot one saved Phase 1 timing run.

arguments
    resultsFile (1,1) string
    options.SaveFigures (1,1) logical = true
    options.ShowFigures (1,1) logical = true
end

[figures, results, config] = sdv.plot.standardRunArtifact( ...
    resultsFile, ...
    ExpectedPhases=["phase1", "phase1_trigger"], ...
    SaveFigures=options.SaveFigures, ...
    ShowFigures=options.ShowFigures);

end
