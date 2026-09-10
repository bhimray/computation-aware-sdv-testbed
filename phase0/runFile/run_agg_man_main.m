startup_project;

prepare_controller_runtime( ...
    sdv.enum.ScenarioName.aggressive_maneuver);

environmentNames = [
    % sdv.enum.EnvironmentName.dry_road
    sdv.enum.EnvironmentName.low_friction_road
    ];

for environmentName = environmentNames.'
    fprintf( ...
        "\nRunning environment: %s\n", ...
        environmentName);
    [results, ~, resultFile] = run_aggressive_maneuver(environmentName);
    plot_phase0_baseline(resultFile);
end
