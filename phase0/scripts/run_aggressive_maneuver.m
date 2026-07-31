[results, config] = ...
    run_phase0_baseline("aggressive_maneuver");

if config.controller.controller_backend == 1
    disp(results.solve_time_metrics.summary_table);
end