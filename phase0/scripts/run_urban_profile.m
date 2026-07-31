%% Run Phase 0 urban-profile scenario
[results, config] = ...
    run_phase0_baseline("urban_profile");

if config.controller.controller_backend == 1
    disp(results.solve_time_metrics.summary_table);
end