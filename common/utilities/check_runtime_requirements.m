function check_runtime_requirements(controller, checkBackend)
%CHECK_RUNTIME_REQUIREMENTS Check software needed by the selected backend.

arguments
    controller (1,1) struct
    checkBackend (1,1) logical = true
end

missing = strings(0,1);

%% Required MATLAB products

if isempty(ver("simulink")) || ~license("test","Simulink")
    missing(end+1) = "Simulink";
end

if isempty(ver("control")) || ~license("test","Control_Toolbox")
    missing(end+1) = "Control System Toolbox";
end

if isempty(ver("mpc")) || ~license("test","MPC_Toolbox")
    missing(end+1) = "Model Predictive Control Toolbox";
end

%% Optional acados backend

usingAcados = ...
    controller.controller_backend == ...
    controller.BACKEND_ACADOS;

if checkBackend && usingAcados
    [acadosAvailable, ~] = activate_acados(false);

    if ~acadosAvailable
        missing(end+1) = ...
            "acados v0.5.4: run setup_acados_dependency";
    end

    projectRoot = string( ...
        matlab.project.currentProject().RootFolder);

    solverDirectory = fullfile( ...
        projectRoot, ...
        "build", ...
        "acados", ...
        "sdv_dynamic_bicycle");

    solverFile = fullfile( ...
        solverDirectory, ...
        "acados_solver_sfunction_sdv_dynamic_bicycle." ...
        + string(mexext));

    if ~isfile(solverFile)
        missing(end+1) = ...
            "Generated acados S-function: run s_fun_generation_acados";
    else
        addpath(solverDirectory);
    end
end

%% Report

if ~isempty(missing)
    error( ...
        "SDV:MissingRuntimeRequirements", ...
        "Missing project requirements:\n - %s", ...
        strjoin(missing, "\n - "));
end

fprintf("Runtime requirement check passed.\n");

end
