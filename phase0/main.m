startup_project;

configuration = ...
    build_phase0_configuration("highway_cruise");

controller = configuration.controller;

% Check MATLAB products before attempting dependency installation.
check_runtime_requirements( ...
    controller, ...
    false);

if controller.controller_backend == controller.BACKEND_ACADOS

    [acadosAvailable, ~] = activate_acados(false);

    projectRoot = string( ...
        matlab.project.currentProject().RootFolder);

    solverFile = fullfile( ...
        projectRoot, ...
        "build", ...
        "acados", ...
        "sdv_dynamic_bicycle", ...
        "acados_solver_sfunction_sdv_dynamic_bicycle." ...
        + string(mexext));

    solverAvailable = isfile(solverFile);

    if ~acadosAvailable || ~solverAvailable

        response = input( ...
            [ ...
            "The acados backend is not ready.\n" ...
            "Install acados and generate the S-function now? [y/N]: " ...
            ], ...
            "s");

        continueSetup = any(strcmpi( ...
            strtrim(response), ...
            ["y","yes"]));

        if ~continueSetup
            error( ...
                "SDV:AcadosSetupDeclined", ...
                "acados setup was declined by the user.");
        end

        if ~acadosAvailable
            setup_acados_dependency;
        end

        if ~solverAvailable
            solverFile = s_fun_generation_acados();
        end

        startup_project;

        configuration = ...
            build_phase0_configuration("highway_cruise");

        controller = configuration.controller;
    end
end

check_runtime_requirements(controller);

%% execute simulation for 3 different scenario with 3 different road condition, total 9 simulation
%% Run three scenarios under three environment conditions

environmentNames = [
    "dry_road"
    "low_friction_road"
    "sudden_friction_drop"
    ];

for environmentName = environmentNames.'

    fprintf( ...
        "\nRunning environment: %s\n", ...
        environmentName);

    % run_urban_profile(environmentName);
    run_highway_cruise(environmentName);
    run_aggressive_maneuver(environmentName);
end
