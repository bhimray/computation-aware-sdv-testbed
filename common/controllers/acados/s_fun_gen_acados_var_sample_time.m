function solverFile = s_fun_gen_acados_var_sample_time()
%S_FUN_GENERATION_ACADOS Generate the acados Simulink S-function.

bdclose("all");
clear mex;

startup_project; % add necessary folders path
activate_acados(true); % check acados installation

configuration = ...
    build_phase0_configuration("highway_cruise"); % all the parameters required for simulation and building ocp model
for t = [10, 20, 50] % in ms
    configuration.controller.Ts_s = t/1000; % in s
    switch t
        case 10
            modelName = ...
                'sdv_dynamic_bicycle_10';
        case 20
            modelName = ...
                'sdv_dynamic_bicycle_20';
        case 50
            modelName = 'sdv_dynamic_bicycle_50';
    end
    disp("model name");
    disp(modelName);
    disp(t)
    [ocp, metadata] = build_acados_ocp( ...
        configuration.adaptiveModel, ...
        configuration.controller, ...
        true, ...
        modelName);

    solver = AcadosOcpSolver(ocp);

    addModelReferenceInheritanceRule( ...
        metadata.generated_directory, ...
    "acados_solver_sfunction_" + metadata.model_name + ".c");

    originalDirectory = pwd;
    directoryCleanup = ...
        onCleanup(@() cd(originalDirectory));

    generatedDirectory = metadata.generated_directory;
    cd(generatedDirectory);

    run("make_sfun.m");

    solverFile = fullfile( ...
        generatedDirectory, ...
        "acados_solver_sfunction_" + metadata.model_name + "." ...
        + string(mexext));

    assert( ...
        isfile(solverFile), ...
        "acados S-function generation did not create:\n%s", ...
        solverFile);

    fprintf( ...
        "Generated acados S-function:\n%s\n", ...
        solverFile);

    solverFolder = fileparts(solverFile);
    addpath(solverFolder);
    rehash;
end

end
