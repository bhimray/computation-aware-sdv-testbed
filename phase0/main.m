startup_project;

prepare_controller_runtime( ...
    sdv.enum.ScenarioName.highway_cruise);

environmentNames = [
    % sdv.enum.EnvironmentName.dry_road
    sdv.enum.EnvironmentName.low_friction_road
    ];

for environmentName = environmentNames.'
    fprintf( ...
        "\nRunning environment: %s\n", ...
        environmentName);
    % run_urban_profile(environmentName);
    % run_highway_cruise(environmentName);
    run_aggressive_maneuver(environmentName);
end
