clear all;
bdclose("all");

startup_project;

config = build_phase0_configuration("highway_cruise");

[ocp, metadata] = build_acados_ocp( ...
    config.adaptiveModel, ...
    config.controller, ...
    false);

solver = AcadosOcpSolver(ocp);

x0 = config.controller.initial_state;
u0 = metadata.settings.nominal_input;
N  = metadata.N;
nx = metadata.nx;

% Provide the initialization currently missing from the S-function.
solver.set( ...
    'init_x', ...
    repmat(x0, 1, N + 1));

solver.set( ...
    'init_u', ...
    repmat(u0, 1, N));

% solver.set( ...
%     'init_pi', ...
%     zeros(nx, N));

stateReference = [
    config.scenario.vx_ref_mps(1)
    0
    0
    0
    0
    ];

[command, commonStatus, solveTime_s, diagnostics] = ...
    solve_acados_step( ...
    solver, ...
    metadata, ...
    x0, ...
    stateReference, ...
    0);

fprintf("Raw status:    %d\n", diagnostics.raw_status);
fprintf("Common status: %d\n", commonStatus);
fprintf("Torque:        %.6f N*m\n", command(1));
fprintf("Steering:      %.9f rad\n", command(2));
fprintf("Solve time:    %.6f ms\n", solveTime_s * 1e3);