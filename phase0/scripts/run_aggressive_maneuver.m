function [results, config, resultFile] = ...
    run_aggressive_maneuver(environmentName)

arguments
    environmentName (1,1) string = "dry_road"
end

[results, config, resultFile] = run_phase0_baseline( ...
    "aggressive_maneuver", ...
    environmentName);

if config.controller.controller_backend == ...
        config.controller.BACKEND_ACADOS

    disp(results.solve_time_metrics.summary_table);
end

end