function results = ...
    extract_phase0_baseline_results(logs, solveTimeAvailable)
%EXTRACT_PHASE0_BASELINE_RESULTS Compatibility wrapper for older scripts.

results = sdv.results.extractBaseline( ...
    logs, solveTimeAvailable);

end
