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

%% State and input scales

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

assert(all(settings.state_scale > 0));
assert(all(settings.input_scale > 0));

%% Dimensionless tracking and effort weights
% Q = [1 0.1 10 100 100];
% R = [1 1];
stateWeights = controller.output_weights(:);
inputWeights = controller.input_weights(:);

settings.Q = diag( ...
    stateWeights ./ settings.state_scale.^2);

settings.R = diag( ...
    inputWeights ./ settings.input_scale.^2);
% settings.Q = diag(stateWeights);
% settings.R = diag(inputWeights);

settings.Q_terminal = settings.Q;

%% Nominal input reference

settings.nominal_input = [
    controller.nominal_signed_front_axle_torque_Nm
    controller.nominal_road_wheel_angle_rad
    ];

%% Input magnitude limits

settings.minimum_input = [
    controller.minimumSignedTorque_Nm
    controller.minimumRoadWheelAngle_rad
    ];

settings.maximum_input = [
    controller.maximumSignedTorque_Nm
    controller.maximumRoadWheelAngle_rad
    ];

%% State limits retained for later soft constraints

settings.minimum_state = controller.minimumState(:);
settings.maximum_state = controller.maximumState(:);

settings.slack_penalty = controller.slackPenalty;

%% acados solver configuration

% Nonlinear solver
settings.nlp_solver_type = 'SQP';   % use 'SQP_RTI'/'SQP' for debugging

% Hessian approximation
% Equivalent to:
% nlp_solver_exact_hessian = false
settings.hessian_approximation = 'GAUSS_NEWTON';

% Numerical integration
settings.integrator_type = 'ERK';
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
settings.maximum_nlp_iterations = 5;

settings.globalization = 'MERIT_BACKTRACKING';

end