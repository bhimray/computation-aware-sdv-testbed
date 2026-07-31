function controller = controller_parameters(vehicle, simulation)
%CONTROLLER_PARAMETERS Parameters for the low-order MPC prediction model.

actuator = actuator_parameters();

%% Execution configuration

controller.Ts_s = simulation.Ts_s;
controller.integration_substeps = 10;

controller.initial_speed_mps = ...
    simulation.initial_speed_mps;
%% for adaptive model linearization
controller.minimum_linearization_speed_mps = 0.5;

%% Initial MPC horizon values in second

controller.prediction_horizon_s = 1.0;
controller.control_horizon_s = 0.10;

%% Backend selection
controller.BACKEND_ACADOS = 1;
controller.BACKEND_MATLAB = 2; %% NOT WORKING
controller.BACKEND_ADAPTIVE = 3;

controller.controller_backend = ...
    controller.BACKEND_ADAPTIVE;

%% Prediction-model dimensions

controller.num_states = 5;
controller.num_inputs = 2;
controller.num_disturbances = 1;

% All states are initially exposed as model outputs.
controller.num_outputs = 5;

%% Prediction-model signal definitions

controller.state_names = [ ...
    "longitudinal_speed_mps"
    "lateral_speed_mps"
    "yaw_rate_radps"
    "lateral_error_m"
    "heading_error_rad"];

controller.input_names = [ ...
    "signed_front_axle_torque_Nm"
    "front_road_wheel_angle_rad"];

controller.disturbance_names = ...
    "path_curvature_1pm";

controller.output_names = controller.state_names;

%% Initial prediction-model state

controller.rolling_resistance_smoothing_speed_mps = 0.10;

controller.initial_state = [ ...
    controller.initial_speed_mps    % vx, m/s
    0                   % vy, m/s
    0                   % yaw rate, rad/s
    0                   % lateral error, m
    0];                 % heading error, rad

% [vx, vy, yaw rate, lateral error, heading error]
controller.nominal_state = [
    controller.initial_speed_mps
    0
    0
    0
    0
    ];

%% weights
controller.output_weights = [1 1 10 100 100] * 0.1;
controller.input_weights = [1 1];
controller.input_rate_weights = [1 0.1];

%% Nominal linearization operating point

rollingResistance_N = ...
    vehicle.rolling_resistance_coefficient ...
    * vehicle.mass_kg ...
    * vehicle.gravity_mps2;

aerodynamicDrag_N = ...
    0.5 ...
    * vehicle.air_density_kgpm3 ...
    * vehicle.drag_coefficient ...
    * vehicle.frontal_area_m2 ...
    * controller.initial_speed_mps^2;

% Total torque across the front axle required for steady straight driving
controller.nominal_signed_front_axle_torque_Nm = ...
    vehicle.wheel_radius_m ...
    * (rollingResistance_N + aerodynamicDrag_N);

controller.nominal_road_wheel_angle_rad = 0;
controller.nominal_curvature_1pm = 0;

%% Linear tire-model parameters

% These are axle cornering stiffnesses, not individual-tire values.
% Replace NaN using the small-slip slope obtained from the course
% vehicle's tire model.
controller.Cf_Nprad = 160e3; % N/rad
controller.Cr_Nprad = 180e3; % N/rad

%% Numerical protection
% Prevent division by zero in tire slip-angle calculations.
controller.minimum_speed_mps = 0.1;

%% Reference definitions
controller.reference_names = [ ...
    "speed_reference_mps"
    "lateral_speed_reference_mps"
    "yaw_rate_reference_radps"
    "lateral_error_reference_m"
    "heading_error_reference_rad"];

%% Backend interface

controller.backend_input_names = [ ...
    "measured_state"
    "reference_state"
    "path_curvature_1pm"];

controller.backend_output_names = [ ...
    "signed_front_axle_torque_Nm"
    "front_road_wheel_angle_rad"
    "solve_time_s"
    "solver_status"];

%% Standardized solver-status values

controller.status.SUCCESS = 1;
controller.status.MAX_ITERATIONS = 0;
controller.status.FAILURE = -1;

%% constraints
%% Manipulated-variable magnitude limits

% Signed torque
controller.minimumSignedTorque_Nm = ...
    actuator.minimum_signed_front_axle_torque_Nm;
controller.maximumSignedTorque_Nm = ...
    actuator.maximum_signed_front_axle_torque_Nm;

% Front road-wheel angle
controller.minimumRoadWheelAngle_rad = ...
    actuator.minimum_road_wheel_angle_rad;
controller.maximumRoadWheelAngle_rad = ...
    actuator.maximum_road_wheel_angle_rad;

%% Manipulated-variable physical rate limits
%
% These are continuous rates per second. They will be multiplied
% by Ts when configuring the MPC object.

controller.minimumSignedTorqueRate_Nmps = ...
    actuator.minimum_signed_torque_rate_Nmps;
controller.maximumSignedTorqueRate_Nmps = ...
    actuator.maximum_signed_torque_rate_Nmps;

controller.minimumRoadWheelRate_radps = ...
    actuator.minimum_road_wheel_rate_radps;
controller.maximumRoadWheelRate_radps = ...
    actuator.maximum_road_wheel_rate_radps;

%% State/output constraints
%
% State order:
% [vx, vy, yaw_rate, lateral_error, heading_error]
% Covers the 27 m/s highway reference with margin. The supplied plant is
% annotated around 0, 13, and 20 m/s, so 27 m/s remains an explicit
% extrapolation that must pass the highway feasibility gate.
controller.maximumSpeed_mps = 32;
controller.maximumLateralSpeed_mps = 1.0;
controller.maximumYawRate_radps = deg2rad(45);
controller.maximumLateralError_m = 0.5;
controller.maximumHeadingError_rad = deg2rad(15);

controller.minimumState = [
    0                         % vx, m/s
    -controller.maximumLateralSpeed_mps % vy, m/s
    -controller.maximumYawRate_radps    % yaw rate, rad/s
    -controller.maximumLateralError_m   % lateral error, m
    -controller.maximumHeadingError_rad % heading error, rad
    ];

controller.maximumState = [
    controller.maximumSpeed_mps
    controller.maximumLateralSpeed_mps
    controller.maximumYawRate_radps
    controller.maximumLateralError_m
    controller.maximumHeadingError_rad
    ];

%% Constraint softening

% Zero means hard; a positive value means soft.
controller.stateConstraintECR = ones(5,1);

% Penalty applied to constraint violation.
controller.slackPenalty = 1e8;

end
