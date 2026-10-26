function [ocp, metadata] = ...
    build_acados_ocp( ...
        modelParameters, ...
        controller, ...
        generateSimulinkBlock, ...
        modelName ...
        )
%BUILD_ACADOS_OCP Construct the nonlinear acados OCP.
%
% States:
%   x = [vx; vy; yaw_rate; lateral_error; heading_error; ...
%        front_axle_torque; road_wheel_angle]
%
% Inputs:
%   u = [front_axle_torque_rate; road_wheel_angle_rate]
%
% The generated solver always enforces input magnitude limits.
% Intermediate and terminal state constraints can be independently enabled
% using the switches defined below.

%% Backend parameters and prediction model

arguments
    modelParameters (1,1) struct
    controller (1,1) struct
    generateSimulinkBlock (1,1) logical
    modelName = 'sdv_dynamic_bicycle'
end

settings = acados_ocp_parameters(controller);

[model, ~] = ...
    build_acados_prediction_model( ...
                    modelParameters, ...
                    modelName ...
                    ); % it builds the bicycle dynamic model with parameters value for constant like lf, lr, ini_vel

nx = 7;
nu = 2;
N  = settings.number_of_intervals;

assert(numel(controller.initial_state) == nx);
assert(numel(controller.nominal_state) == nx);
assert(numel(settings.nominal_input) == nu);

%% Constraint-selection switches
%
% Keep both disabled while diagnosing unconstrained controller behavior.
% Changing either switch requires regenerating the acados solver.

enableIntermediateStateConstraints = ...
    controller.enableIntermediateStateConstraints;

enableTerminalStateConstraints = ...
    controller.enableTerminalStateConstraints;

%% Create OCP

ocp = AcadosOcp();
ocp.model = model;

%% Stage-zero cost
%
% The complete state at stage zero is fixed using lbx_0 = ubx_0. Penalize
% physical command effort and the first optimized command-rate move.

ocp.cost.cost_type_0 = 'NONLINEAR_LS';
ocp.model.cost_y_expr_0 = vertcat( ...
    model.x(6:7), ...
    model.u);
ocp.cost.W_0 = blkdiag( ...
    settings.R_command, ...
    settings.R_rate);
ocp.cost.yref_0 = zeros(4,1);

%% Intermediate-stage cost
%
% Cost output:
%   y_k = [vehicle_states_k; physical_commands_k; command_rates_k]
%
% The runtime S-function y_ref input replaces the default reference below.

ocp.cost.cost_type = 'NONLINEAR_LS'; % 

ocp.model.cost_y_expr = vertcat( ...
    model.x(1:5), ...   % Vehicle tracking states
    model.x(6:7), ...   % Physical torque and steering
    model.u);           % Torque and steering rates

ocp.cost.W = blkdiag( ...
    settings.Q_vehicle, ...
    settings.R_command, ...
    settings.R_rate);

ocp.cost.yref = [
    controller.nominal_state(1:5)
    zeros(2,1)    % Zero physical-command reference
    zeros(2,1)    % Zero command-rate reference
    ];

%% Terminal cost
%
% Only the terminal state is penalized.

ocp.cost.cost_type_e = 'NONLINEAR_LS';
ocp.model.cost_y_expr_e = model.x(1:5);
ocp.cost.W_e = settings.Q_terminal;
ocp.cost.yref_e = controller.nominal_state(1:5);

%% Optimizer-input rate constraints
%
% These are hard torque-rate and steering-rate constraints applied
% throughout the prediction horizon.
%
%   minimum_input <= u_k <= maximum_input

ocp.constraints.idxbu = (0:(nu - 1))';
ocp.constraints.lbu = settings.minimum_input;
ocp.constraints.ubu = settings.maximum_input;

%% Optional soft path-state constraints
%
% acados uses zero-based state indices:
%
%   x(3) in acados -> MATLAB state 4 -> lateral error
%   x(4) in acados -> MATLAB state 5 -> heading error
%
% idxsbx indexes entries within idxbx, not the complete state vector.

if enableIntermediateStateConstraints || ...
        enableTerminalStateConstraints

    constrainedStateIndices = [3; 4; 5; 6];
    softenedBoundIndices = [0; 1];

    pathStateMinimum = [
        settings.minimum_state(4)   % Minimum lateral error, m
        settings.minimum_state(5)   % Minimum heading error, rad
        settings.minimum_state(6)   % Minimum torque, Nm
        settings.minimum_state(7)   % Minimum steering, rad
        
        ];

    pathStateMaximum = [
        settings.maximum_state(4)   % Maximum lateral error, m
        settings.maximum_state(5)   % Maximum heading error, rad
        settings.maximum_state(6)   % Maximum torque, Nm
        settings.maximum_state(7)   % Maximum steering, rad
        ];
       
    slackPenalty = [
        settings.slack_penalty_ey
        settings.slack_penalty_epsi
        ];

    % An enabled soft constraint must have a positive penalty. A zero
    % penalty leaves the associated slack variable unregularized.
    assert( ...
        all(slackPenalty > 0), ...
        "Enabled soft constraints require positive slack penalties.");
end

%% Optional intermediate-state constraints
%
% When enabled, these constraints are applied at intermediate prediction
% nodes. They are softened using separate lower and upper slacks:
%
%   stateMinimum - lowerSlack <= state
%   state <= stateMaximum + upperSlack

if enableIntermediateStateConstraints

    ocp.constraints.idxbx = ...
        constrainedStateIndices;

    ocp.constraints.lbx = ...
        pathStateMinimum;

    ocp.constraints.ubx = ...
        pathStateMaximum;

    ocp.constraints.idxsbx = ...
        softenedBoundIndices;

    % Quadratic penalties on lower and upper constraint violations.
    ocp.cost.Zl = slackPenalty;
    ocp.cost.Zu = slackPenalty;

    % No additional linear slack penalties.
    ocp.cost.zl = zeros(2,1);
    ocp.cost.zu = zeros(2,1);
end

%% Optional terminal-state constraints
%
% Terminal constraints are disabled by default because they previously
% caused QP solver status 4. Re-enable only after the unconstrained and
% intermediate-constrained controllers solve reliably.

if enableTerminalStateConstraints

    ocp.constraints.idxbx_e = ...
        constrainedStateIndices;

    ocp.constraints.lbx_e = ...
        pathStateMinimum;

    ocp.constraints.ubx_e = ...
        pathStateMaximum;

    ocp.constraints.idxsbx_e = ...
        softenedBoundIndices;

    ocp.cost.Zl_e = slackPenalty;
    ocp.cost.Zu_e = slackPenalty;

    ocp.cost.zl_e = zeros(2,1);
    ocp.cost.zu_e = zeros(2,1);
end

%% Default initial condition
%
% The generated S-function runtime inputs lbx_0 and ubx_0 replace this
% default with the current measured state.

ocp.constraints.x0 = controller.initial_state;

%% Online model parameter
%
% Reference-path curvature is the single online model parameter.

ocp.parameter_values = 0;

%% Prediction horizon

ocp.solver_options.N_horizon = N;
ocp.solver_options.tf = ...
    settings.prediction_horizon_s;

%% NLP solver configuration

ocp.solver_options.nlp_solver_type = ...
    settings.nlp_solver_type;

ocp.solver_options.hessian_approx = ...
    settings.hessian_approximation;

ocp.solver_options.globalization = ...
    settings.globalization;

ocp.solver_options.nlp_solver_max_iter = ...
    settings.maximum_nlp_iterations;

ocp.solver_options.nlp_solver_tol_stat = ...
    settings.nlp_solver_tol_stat;

ocp.solver_options.nlp_solver_tol_eq = ...
    settings.nlp_solver_tol_eq;

ocp.solver_options.nlp_solver_tol_ineq = ...
    settings.nlp_solver_tol_ineq;

ocp.solver_options.nlp_solver_tol_comp = ...
    settings.nlp_solver_tol_comp;

%% Numerical integration

ocp.solver_options.integrator_type = ...
    settings.integrator_type;

ocp.solver_options.sim_method_num_stages = ...
    settings.integration_stages;

ocp.solver_options.sim_method_num_steps = ...
    settings.integration_steps;

%% QP solver configuration

ocp.solver_options.qp_solver = ...
    settings.qp_solver;

ocp.solver_options.qp_solver_cond_N = ...
    settings.condensing_intervals;

%% Warm-start configuration

ocp.solver_options.nlp_solver_warm_start_first_qp = true;

ocp.solver_options.nlp_solver_warm_start_first_qp_from_nlp = ...
    true;

ocp.solver_options.qp_solver_warm_start = 2;

%% Generated-code configuration

ocp.solver_options.ext_fun_compile_flags = '-O2';

acadosFolder = fileparts(mfilename('fullpath'));
controllersFolder = fileparts(acadosFolder);
commonFolder = fileparts(controllersFolder);
projectRoot = fileparts(commonFolder);

generatedDirectory = fullfile( ...
    projectRoot, ...
    'build', ...
    'acados', ...
    model.name);

ocp.code_gen_opts.code_export_directory = ...
    generatedDirectory;

ocp.code_gen_opts.json_file = fullfile( ...
    generatedDirectory, ...
    [model.name, '.json']);

%% Simulink interface

if generateSimulinkBlock
    ocp.simulink_opts = ...
        acados_simulink_options(controller);
else
    ocp.simulink_opts = [];
end

%% Metadata

metadata.nx = nx;
metadata.nu = nu;
metadata.N = N;
metadata.settings = settings;
metadata.generated_directory = generatedDirectory;
metadata.model_name = modelName;

end
