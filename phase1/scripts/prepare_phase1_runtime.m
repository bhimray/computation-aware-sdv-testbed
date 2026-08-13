function prepare_phase1_runtime(scenarioName)
%PREPARE_PHASE1_RUNTIME Check and optionally install Phase 1 dependencies.

arguments
    scenarioName (1,1) string = "highway_cruise"
end

startup_project;
configuration = build_phase0_configuration(scenarioName);
controller = configuration.controller;

check_runtime_requirements(controller, false);

if controller.controller_backend == controller.BACKEND_ACADOS
    [acadosAvailable, ~] = activate_acados(false);
    projectRoot = string(matlab.project.currentProject().RootFolder);
    solverFile = fullfile( ...
        projectRoot, "build", "acados", "sdv_dynamic_bicycle", ...
        "acados_solver_sfunction_sdv_dynamic_bicycle." + string(mexext));
    solverAvailable = isfile(solverFile);

    if ~acadosAvailable || ~solverAvailable
        response = input( ...
            "Install acados and generate the S-function now? [y/N]: ", ...
            "s");

        if ~any(strcmpi(strtrim(response), ["y", "yes"]))
            error("SDV:AcadosSetupDeclined", ...
                "acados setup was declined by the user.");
        end

        if ~acadosAvailable
            setup_acados_dependency;
        end
        if ~solverAvailable
            s_fun_generation_acados;
        end
        startup_project;
    end
end

check_runtime_requirements(controller);

end
