function [results, config] = ...
    run_highway_cruise(environmentName)

arguments
    environmentName (1,1) string = "dry_road"
end

[results, config] = run_phase0_baseline( ...
    "highway_cruise", ...
    environmentName);

if config.controller.controller_backend == ...
        config.controller.BACKEND_ACADOS

    disp(results.solve_time_metrics.summary_table);
end

end