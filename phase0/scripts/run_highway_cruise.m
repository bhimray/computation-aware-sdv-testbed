%% Run Phase 0 highway-cruise scenario

[results, config] = run_phase0_baseline("highway_cruise");

if config.controller.controller_backend == 1
    disp(results.solve_time_metrics.summary_table);
end