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

stateWeights = controller.output_weights(:);
inputWeights = controller.input_weights(:);

settings.Q = diag( ...
    stateWeights ./ settings.state_scale.^2);

settings.R = diag( ...
    inputWeights ./ settings.input_scale.^2);

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

%% acados solver choices

settings.nlp_solver_type = 'SQP';
settings.qp_solver = 'PARTIAL_CONDENSING_HPIPM';
settings.integrator_type = 'ERK';
settings.hessian_approximation = 'GAUSS_NEWTON';
settings.globalization = 'MERIT_BACKTRACKING';

settings.maximum_nlp_iterations = 50;

settings.integration_stages = 4;
settings.integration_steps = 1;

settings.condensing_intervals = min( ...
    5, ...
    settings.number_of_intervals);

end