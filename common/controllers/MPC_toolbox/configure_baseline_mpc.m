function mpc_baseline = configure_baseline_mpc( ...
    Ad, Bmv, Emd, p)

Ts = p.Ts_s;

% Outputs are all five prediction states
Cd = eye(5);

% Inputs:
% 1 = signed torque
% 2 = road-wheel steering
% 3 = reference curvature, measured disturbance
Dd = zeros(5,3);

predictionPlant = ss( ...
    Ad, [Bmv Emd], Cd, Dd, Ts);

predictionPlant.InputName = [ ...
    "signed_front_axle_torque_Nm"; ...
    "road_wheel_angle_rad"; ...
    "curvature_ref_1pm"];

predictionPlant.OutputName = [ ...
    "vx_mps"; ...
    "vy_mps"; ...
    "yaw_rate_radps"; ...
    "lateral_error_m"; ...
    "heading_error_rad"];

predictionPlant.InputUnit = [ ...
    "N*m"; ...
    "rad"; ...
    "1/m"];

predictionPlant.OutputUnit = [ ...
    "m/s"; ...
    "m/s"; ...
    "rad/s"; ...
    "m"; ...
    "rad"];

predictionPlant = setmpcsignals( ...
    predictionPlant, ...
    "MV", [1 2], ...
    "MD", 3);

predictionSteps = round( ...
    p.prediction_horizon_s/Ts);

controlSteps = round( ...
    p.control_horizon_s/Ts);

mpc_baseline = mpc( ...
    predictionPlant, ...
    Ts, ...
    predictionSteps, ...
    controlSteps);

% Output weights: [vx, vy, r, ey, epsi]
mpc_baseline.Weights.OutputVariables = ...
    p.output_weights;

% Input magnitude weights: [torque, steering]
mpc_baseline.Weights.ManipulatedVariables = ...
    p.input_weights;

% Input-rate weights
mpc_baseline.Weights.ManipulatedVariablesRate = ...
    p.input_rate_weights;

% Nominal linearization condition
mpc_baseline.Model.Nominal.X = p.nominal_state;
mpc_baseline.Model.Nominal.Y = p.nominal_state;

mpc_baseline.Model.Nominal.U = [ ...
    p.nominal_signed_front_axle_torque_Nm;
    p.nominal_road_wheel_angle_rad;
    p.nominal_curvature_1pm];

%% -------------------constraints --------------------

%% Input magnitude constraints

mpc_baseline.MV(1).Min = ...
    p.minimumSignedTorque_Nm;

mpc_baseline.MV(1).Max = ...
    p.maximumSignedTorque_Nm;

mpc_baseline.MV(2).Min = ...
    p.minimumRoadWheelAngle_rad;

mpc_baseline.MV(2).Max = ...
    p.maximumRoadWheelAngle_rad;

%% Input-rate constraints

mpc_baseline.MV(1).RateMin = ...
    p.minimumSignedTorqueRate_Nmps * Ts;

mpc_baseline.MV(1).RateMax = ...
    p.maximumSignedTorqueRate_Nmps * Ts;

mpc_baseline.MV(2).RateMin = ...
    p.minimumRoadWheelRate_radps * Ts;

mpc_baseline.MV(2).RateMax = ...
    p.maximumRoadWheelRate_radps * Ts;

%% Hard actuator constraints

for inputIndex = 1:2
    mpc_baseline.MV(inputIndex).MinECR = 0;
    mpc_baseline.MV(inputIndex).MaxECR = 0;
    mpc_baseline.MV(inputIndex).RateMinECR = 0;
    mpc_baseline.MV(inputIndex).RateMaxECR = 0;
end

%% State constraints through output constraints

for stateIndex = 1:5

    mpc_baseline.OV(stateIndex).Min = ...
        p.minimumState(stateIndex);

    mpc_baseline.OV(stateIndex).Max = ...
        p.maximumState(stateIndex);

    mpc_baseline.OV(stateIndex).MinECR = ...
        p.stateConstraintECR(stateIndex);

    mpc_baseline.OV(stateIndex).MaxECR = ...
        p.stateConstraintECR(stateIndex);
end

mpc_baseline.Weights.ECR = ...
    p.slackPenalty;

%% operating point or scale factor
% Manipulated-variable operating spans
mpc_baseline.MV(1).ScaleFactor = ...
    p.maximumSignedTorque_Nm - p.minimumSignedTorque_Nm;

mpc_baseline.MV(2).ScaleFactor = ...
    p.maximumRoadWheelAngle_rad - p.minimumRoadWheelAngle_rad;

% Output operating spans
mpc_baseline.OV(1).ScaleFactor = p.maximumSpeed_mps;
mpc_baseline.OV(2).ScaleFactor = 2*p.maximumLateralSpeed_mps;
mpc_baseline.OV(3).ScaleFactor = 2*p.maximumYawRate_radps;
mpc_baseline.OV(4).ScaleFactor = 2*p.maximumLateralError_m;
mpc_baseline.OV(5).ScaleFactor = 2*p.maximumHeadingError_rad;

% Typical operating span: -0.05 to +0.05 rad
mpc_baseline.MV(2).ScaleFactor = 0.10; % rad

% Expected output spans
mpc_baseline.OV(4).ScaleFactor = 2.0;        % m, -1 to +1 m
mpc_baseline.OV(5).ScaleFactor = deg2rad(30); % rad, -15 to +15 deg
%% ---------------------- REVIEW
% review(mpc_baseline);
% mpc_baseline.MV
% mpc_baseline.OV

end
