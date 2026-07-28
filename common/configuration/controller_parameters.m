function controller = controller_parameters(UT)
%CONTROLLER_PARAMETERS Parameters for the low-order MPC prediction model.
%
% Prediction-model states:
%   x = [vx; vy; yaw_rate; lateral_error; heading_error]
%
% Manipulated inputs:
%   u = [signed_front_axle_torque; front_road_wheel_angle]
%
% Measured disturbance:
%   d = path_curvature
%
% UT contains nominal vehicle data. Values copied into controller.model
% represent the controller's nominal assumptions.

%% Execution configuration

controller.Ts_s = UT.Ts_Veh;
controller.integration_substeps = 10;
%% Backend selection

controller.BACKEND_MATLAB = 2;
controller.BACKEND_ACADOS = 1;

controller.controller_backend = ...
    controller.BACKEND_MATLAB;

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


controller.initial_speed_mps = UT.v_ini;

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
controller.output_weights = [10 0.1 10 1000 1000];
controller.input_weights = [10 10];
controller.input_rate_weights = [1 1];

%% Nominal controller-model vehicle parameters

controller.mass_kg = UT.Mv;
controller.yaw_inertia_kgm2 = UT.Iz;

controller.lf_m = UT.lf;
controller.lr_m = UT.lr;
controller.wheelbase_m = UT.lf + UT.lr;

controller.wheel_radius_m = UT.Rw;
controller.drivetrain_efficiency = 1.0;

%% Nominal resistance model

controller.gravity_mps2 = UT.g;
controller.air_density_kgpm3 = UT.rho;
controller.drag_coefficient = UT.Cd;
controller.frontal_area_m2 = UT.Awind;
controller.rolling_resistance_coefficient = UT.CRF;

%% Nominal linearization operating point

rolling_resistance_N = ...
    controller.rolling_resistance_coefficient ...
    * controller.mass_kg ...
    * controller.gravity_mps2;

aerodynamic_drag_N = ...
    0.5 ...
    * controller.air_density_kgpm3 ...
    * controller.drag_coefficient ...
    * controller.frontal_area_m2 ...
    * controller.initial_speed_mps^2;

% Total torque across the front axle required for steady straight driving.
controller.nominal_signed_front_axle_torque_Nm = ...
    controller.wheel_radius_m ...
    * (rolling_resistance_N + aerodynamic_drag_N) ...
    / controller.drivetrain_efficiency;

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

%% Initial MPC horizon values

controller.prediction_horizon_s = 3.0;
controller.control_horizon_s = 1.0;
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
controller.minimumSignedTorque_Nm = -300;
controller.maximumSignedTorque_Nm =  300;

% Front road-wheel angle
controller.minimumRoadWheelAngle_rad = -0.30;
controller.maximumRoadWheelAngle_rad =  0.30;

%% Manipulated-variable physical rate limits
%
% These are continuous rates per second. They will be multiplied
% by Ts when configuring the MPC object.

controller.minimumSignedTorqueRate_Nmps = -10;
controller.maximumSignedTorqueRate_Nmps =  10;

controller.minimumRoadWheelRate_radps = -deg2rad(1);
controller.maximumRoadWheelRate_radps =  deg2rad(1);

%% State/output constraints
%
% State order:
% [vx, vy, yaw_rate, lateral_error, heading_error]
controller.maximumSpeed_mps = 12;
controller.maximumLateralSpeed_mps = 1.0;
controller.maximumYawRate_radps = deg2rad(10);
controller.maximumLateralError_m = 0.2;
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
