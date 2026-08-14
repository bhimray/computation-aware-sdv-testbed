function [solver, metadata] = ...
    create_acados_analysis_solver(config)
%CREATE_ACADOS_ANALYSIS_SOLVER Create an isolated MATLAB acados solver.
%
% This solver uses a different model name and output directory so it does
% not overwrite or lock the generated Simulink S-function solver.

[ocp, metadata] = build_acados_ocp( ...
    config.adaptiveModel, ...
    config.controller, ...
    false);


% Accuracy matters more than real-time speed during offline gain analysis.
ocp.solver_options.nlp_solver_type = 'SQP';
ocp.solver_options.nlp_solver_max_iter = 50;

%% Give the analysis solver a unique name

analysisModelName = ...
    'sdv_dynamic_bicycle_gain_analysis';

ocp.model.name = analysisModelName;

%% Give it a separate generated-code directory

acadosFolder = fileparts( ...
    which('build_acados_ocp'));

controllersFolder = fileparts(acadosFolder);
commonFolder = fileparts(controllersFolder);
projectRoot = fileparts(commonFolder);

analysisDirectory = fullfile( ...
    projectRoot, ...
    'build', ...
    'acados', ...
    analysisModelName);

ocp.code_gen_opts.code_export_directory = ...
    analysisDirectory;

ocp.code_gen_opts.json_file = fullfile( ...
    analysisDirectory, ...
    [analysisModelName, '.json']);

metadata.generated_directory = analysisDirectory;

%% Generate the MATLAB-side solver
%% Reuse an existing compatible analysis solver

jsonFile = fullfile( ...
    analysisDirectory, ...
    [analysisModelName, '.json']);

sharedLibraryFile = fullfile( ...
    analysisDirectory, ...
    ['acados_ocp_solver_', ...
     analysisModelName, '.dll']);

analysisBuildExists = ...
    isfile(jsonFile) && ...
    isfile(sharedLibraryFile);

if analysisBuildExists

    solverCreationOptions = struct();

    solverCreationOptions.generate = false;
    solverCreationOptions.build = false;
    solverCreationOptions.compile_mex_wrapper = false;

    % acados verifies that the existing build matches the current OCP.
    solverCreationOptions.check_reuse_possible = true;

    solver = AcadosOcpSolver( ...
        ocp, ...
        solverCreationOptions);

else

    fprintf( ...
        "Generating Phase 1.4 analysis solver for the first time.\n");

    solver = AcadosOcpSolver(ocp);

end

%% Initialize solver trajectories

initialState = ...
    config.controller.initial_state(:);

nominalInput = ...
    metadata.settings.nominal_input(:);

solver.set( ...
    'init_x', ...
    repmat(initialState, 1, metadata.N + 1));

solver.set( ...
    'init_u', ...
    repmat(nominalInput, 1, metadata.N));

solver.set( ...
    'init_pi', ...
    zeros(metadata.nx, metadata.N));

end