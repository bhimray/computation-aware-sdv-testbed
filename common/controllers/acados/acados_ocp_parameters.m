function settings = acados_ocp_parameters(controller)
%ACADOS_OCP_PARAMETERS Backend-specific OCP configuration.

%% Horizon
settings.sample_time_s = controller.Ts_s;
settings.prediction_horizon_s = ...
    controller.prediction_horizon_s;

settings.number_of_intervals = round( ...
    settings.prediction_horizon_s / ...
    settings.sample_time_s);

assert(settings.number_of_intervals >= 2);

actualHorizon_s = ...
    settings.number_of_intervals ...
    * settings.sample_time_s;

assert( ...
    abs(actualHorizon_s - settings.prediction_horizon_s) ...
    < 1e-10, ...
    "Prediction horizon must be divisible by the sample time.");

%% State, command, and command-rate scales

settings.state_scale = max( ...
    abs([ ...
        controller.minimumState(:), ...
        controller.maximumState(:)]), ...
    [], ...
    2);

settings.input_scale = max( ...
    abs([ ...
        controller.minimumSignedTorque_Nm, ...
        controller.maximumSignedTorque_Nm
        controller.minimumRoadWheelAngle_rad, ...
        controller.maximumRoadWheelAngle_rad]), ...
    [], ...
    2);

settings.input_rate_scale = max( ...
    abs([ ...
        controller.minimumSignedTorqueRate_Nmps, ...
        controller.maximumSignedTorqueRate_Nmps
        controller.minimumRoadWheelRate_radps, ...
        controller.maximumRoadWheelRate_radps]), ...
    [], ...
    2);

assert(all(settings.state_scale > 0));
assert(all(settings.input_scale > 0));
assert(all(settings.input_rate_scale > 0));

%% Dimensionless tracking, command-effort, and command-rate weights

settings.Q_vehicle = diag( ...
    controller.output_weights(:) ...
    ./ settings.state_scale(1:5).^2);

settings.Q_terminal = diag( ...
    controller.terminal_output_weights(:) ...
    ./ settings.state_scale(1:5).^2);

settings.R_command = diag( ...
    controller.input_weights(:) ...
    ./ settings.input_scale.^2);

settings.R_rate = diag( ...
    controller.input_rate_weights(:) ...
    ./ settings.input_rate_scale.^2);

%% Nominal optimizer-input reference
% The optimizer inputs are torque rate and road-wheel-angle rate. Their
% reference is zero because the controller should avoid unnecessary command
% motion; the physical torque and steering angle are states x(6:7).
settings.nominal_input = [
    0
    0
    ];

%% Optimizer-input rate limits

settings.minimum_input = [
    controller.minimumSignedTorqueRate_Nmps
    controller.minimumRoadWheelRate_radps
    ];

settings.maximum_input = [
    controller.maximumSignedTorqueRate_Nmps
    controller.maximumRoadWheelRate_radps
    ];

%% State limits retained for later soft constraints

settings.minimum_state = controller.minimumState(:);
settings.maximum_state = controller.maximumState(:);

settings.slack_penalty_ey = controller.slackPenalty_ey;
settings.slack_penalty_epsi = controller.slackPenalty_epsi;

%% acados solver configuration

% Nonlinear solver
settings.nlp_solver_type = 'SQP';   % use 'SQP_RTI'/'SQP' for debugging

% Hessian approximation
% Equivalent to:
% nlp_solver_exact_hessian = false
settings.hessian_approximation = 'GAUSS_NEWTON';

% Numerical integration
settings.integrator_type = 'ERK'; % 'IRK', 'ERK', 'LIFTED_IRK'
settings.integration_stages = 4;
settings.integration_steps = 3;

% QP solver
settings.qp_solver = 'PARTIAL_CONDENSING_HPIPM';
settings.condensing_intervals = min( ...
    10, ...
    settings.number_of_intervals);

% NLP tolerances
settings.nlp_solver_tol_stat = 1e-4;
settings.nlp_solver_tol_eq   = 1e-4;
settings.nlp_solver_tol_ineq = 1e-4;
settings.nlp_solver_tol_comp = 1e-4;

% Mainly relevant when using full SQP
settings.maximum_nlp_iterations = 50;

settings.globalization = 'FIXED_STEP';
settings.alpha_min = controller.Ts_s;
settings.print_level = 1;

end
