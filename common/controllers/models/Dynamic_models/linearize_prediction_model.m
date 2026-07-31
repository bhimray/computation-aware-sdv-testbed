function [Ad,Bmv,Emd,Ac,Bc,Ec,op] = ...
    linearize_prediction_model(v, s, c)
%LINEARIZE_PREDICTION_MODEL used by ADAPTIVE MPC
% Linearizes and discretizes the adapted Kong dynamic bicycle model.
%
% State order:
%   x = [vx; vy; yaw_rate; lateral_error; heading_error]
%
% Manipulated inputs:
%   u = [signed_front_axle_torque; road_wheel_angle]
%
% Measured disturbance:
%   d = path_curvature
%
% Cornering stiffnesses p.Cf_Nprad and p.Cr_Nprad must be
% combined axle stiffnesses.

%% Parameters

Ts  = s.Ts_s;
m   = v.mass_kg;
Iz  = v.yaw_inertia_kgm2;
lf  = v.lf_m;
lr  = v.lr_m;
Rw  = v.wheel_radius_m;
eta = v.drivetrain_efficiency;

rho = v.air_density_kgpm3;
Cd  = v.drag_coefficient;
Af  = v.frontal_area_m2;
Crr = v.rolling_resistance_coefficient;
g   = v.gravity_mps2;

Cf = c.Cf_Nprad;
Cr = c.Cr_Nprad;

V0 = s.initial_speed_mps;
Vx_safe = sqrt(V0^2 + c.minimum_speed_mps^2);

%% Basic validation

assert(Ts > 0, ...
    "Controller sample time must be positive.");

assert(Vx_safe >= 0, ...
    "Nominal speed must be greater than zero.");

assert(Cf > 0 && Cr > 0, ...
    "Cornering stiffness values must be positive.");

%% Nominal equilibrium

rollingResistance_N = Crr*m*g;

aerodynamicDrag_N = ...
    0.5*rho*Cd*Af*Vx_safe^2;

totalResistance_N = ...
    rollingResistance_N + aerodynamicDrag_N;

% T0 is the total torque applied across the front axle.
nominal_front_axle_torque_Nm = ...
    Rw*totalResistance_N/eta;

op.x = [ ...
    Vx_safe;
    0;
    0;
    0;
    0];

op.u = [ ...
    nominal_front_axle_torque_Nm;
    c.nominal_road_wheel_angle_rad];

op.curvature_1pm = c.nominal_curvature_1pm;

%% Continuous longitudinal coefficient

% Derivative of:
% 0.5*rho*Cd*Af*vx*abs(vx)
% evaluated at positive Vx_safe.
dragDerivative_N_per_mps = ...
    rho*Cd*Af*Vx_safe;

aV = -dragDerivative_N_per_mps/m;

% Input torque is the total applied torque across the front axle.
bTorque = eta/(m*Rw);

%% Continuous lateral coefficients

a22 = -(Cf + Cr)/(m*Vx_safe);

a23 = ...
    (lr*Cr - lf*Cf)/(m*Vx_safe) ...
    - Vx_safe;

a32 = ...
    (lr*Cr - lf*Cf)/(Iz*Vx_safe);

a33 = ...
    -(lf^2*Cf + lr^2*Cr)/(Iz*Vx_safe);

% Kong-model steering gains
bSteerVy = Cf/m;
bSteerR  = lf*Cf/Iz;

%% Continuous-time state matrix

% State order:
% [vx; vy; r; ey; epsi]

Ac = [ ...
    aV,  0,   0,   0,  0;
    0,  a22, a23,  0,  0;
    0,  a32, a33,  0,  0;
    0,  1,   0,    0,  Vx_safe;
    0,  0,   1,    0,  0];

%% Continuous manipulated-input matrix

% Input order:
% [signed torque; road-wheel steering angle]

Bc = [ ...
    bTorque,  0;
    0,        bSteerVy;
    0,        bSteerR;
    0,        0;
    0,        0];

%% Continuous measured-disturbance matrix

% heading_error_dot = yaw_rate - Vx_safe*curvature

Ec = [ ...
    0;
    0;
    0;
    0;
   -Vx_safe];

%% Exact zero-order-hold discretization

numberOfStates = size(Ac,1);
numberOfMV = size(Bc,2);
numberOfMD = size(Ec,2);

combinedInputMatrix = [Bc Ec];

augmentedContinuousMatrix = [ ...
    Ac, combinedInputMatrix;
    zeros(numberOfMV + numberOfMD, ...
          numberOfStates + numberOfMV + numberOfMD)];

augmentedDiscreteMatrix = ...
    expm(augmentedContinuousMatrix*Ts);

Ad = augmentedDiscreteMatrix( ...
    1:numberOfStates, ...
    1:numberOfStates);

allDiscreteInputs = augmentedDiscreteMatrix( ...
    1:numberOfStates, ...
    numberOfStates + 1:end);

Bmv = allDiscreteInputs(:,1:numberOfMV);

Emd = allDiscreteInputs(:, ...
    numberOfMV + 1:end);

%% Display operating-point information

fprintf("Prediction model discretized at Ts = %.4f s\n",Ts);
fprintf("Nominal speed: %.3f m/s\n",Vx_safe);
fprintf("Total nominal front-axle torque: %.3f N*m\n", ...
    nominal_front_axle_torque_Nm);

end
