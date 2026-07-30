%% Run Phase 0 highway-cruise scenario

[results, config] = run_phase0_baseline("highway_cruise");

disp(results.solve_time_metrics.summary_table);