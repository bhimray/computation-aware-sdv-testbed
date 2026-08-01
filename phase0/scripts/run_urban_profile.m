function [results, config] = ...
    run_urban_profile(environmentName)

arguments
    environmentName (1,1) string = "dry_road"
end

[results, config] = run_phase0_baseline( ...
    "urban_profile", ...
    environmentName);

if config.controller.controller_backend == ...
        config.controller.BACKEND_ACADOS

    disp(results.solve_time_metrics.summary_table);
end

end