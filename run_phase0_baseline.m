%% Phase 0 baseline regeneration entry point
clearvars;
% bdclose("all");
% clear functions;
% rehash;

startup_project;

disp("Phase 0 baseline runner initialized.");

% %% steady-state test
% run_open_loop_drive_test;
% %% step-steer test
% run_open_loop_steep_steer_test;


%% road profile: highway_cruise/urban_profile/aggressive_maneuver
projectRoot = fileparts(mfilename('fullpath'));
trackFile = fullfile( ...
    projectRoot, ...
    "phase0", ...
    "scenarios", ...
    "test_track.mat");
% Load the track data for further processing
reference = generate_ref(trackFile);

track_ref_table = ...
    reference.lookup_table;
%% controller parameter
controllerParams = controller_parameters(UT);
controllerParams.pose_x0_m = reference.X_ref_m(1); % initial state x0 for integrator
controllerParams.pose_y0_m = reference.Y_ref_m(1); % initial state y0 for integrator


%% Initialize adaptive MPC backend

[Ad0, Bmv0, Emd0] = ...
    linearize_prediction_model(controllerParams);

mpc_adaptive = configure_baseline_mpc( ...
    Ad0, ...
    Bmv0, ...
    Emd0, ...
    controllerParams);

adaptiveModelParams = ...
    adaptive_model_parameters(controllerParams);

load_system("MPC_backend_adaptive");

stateReferencePorts = get_param( ...
    "MPC_backend_adaptive/state_ref", ...
    "PortHandles");

set_param( ...
    stateReferencePorts.Outport, ...
    DataLogging="on", ...
    DataLoggingNameMode="Custom", ...
    DataLoggingName="state_ref");

save_system("MPC_backend_adaptive");

disp("state_ref logging enabled.");

simulationInput = Simulink.SimulationInput("phase0_baseline");
simulationInput = simulationInput.setModelParameter(StopTime="30");

simulationOutput = sim(simulationInput);

%% Adaptive MPC debugging and validation dashboard

%% Extract simulation results

logs = simulationOutput.logsout;

toColumn = @(data) ...
    reshape(squeeze(double(data)),[],1);

vxSignal = ...
    logs.get("vx_meas").Values;

axSignal = ...
    logs.get("ax_meas").Values;

xSignal = ...
    logs.get("x_pos").Values;

ySignal = ...
    logs.get("y_pos").Values;

torqueSignal = ...
    logs.get("torque_opt").Values;

steeringSignal = ...
    logs.get("steering_angle_opt").Values;

yawRateSignal = ...
    logs.get("yaw_rate_meas").Values;

statusSignal = ...
    logs.get("solve_status").Values;

%% Store results

results = struct();

results.time_s = ...
    toColumn(vxSignal.Time);

results.torque_Nm = ...
    toColumn(torqueSignal.Data);

results.vx_mps = ...
    toColumn(vxSignal.Data);

results.ax_mps2 = ...
    toColumn(axSignal.Data);

results.steering_angle_rad = ...
    toColumn(steeringSignal.Data);

results.yaw_rate_radps = ...
    toColumn(yawRateSignal.Data);

results.x_pos_m = ...
    toColumn(xSignal.Data);

results.y_pos_m = ...
    toColumn(ySignal.Data);

results.solve_status = ...
    toColumn(statusSignal.Data);

%% Prepare plot variables

time      = results.time_s;
torque    = results.torque_Nm;
steering  = results.steering_angle_rad;
yawRate   = results.yaw_rate_radps;
velocity  = results.vx_mps;
accel     = results.ax_mps2;
xPosition = results.x_pos_m;
yPosition = results.y_pos_m;

lineWidth = 1.4;

%% Create combined results figure

figure( ...
    Name="Adaptive MPC closed-loop results", ...
    Color="w", ...
    Position=[100 60 1400 850]);

layout = tiledlayout(3,2);
layout.TileSpacing = "compact";
layout.Padding = "compact";

%% Torque

nexttile;

plot(time,torque, ...
    LineWidth=lineWidth, ...
    DisplayName="Applied torque");

grid on;
xlabel("Time (s)");
ylabel("Torque (N·m)");
title("Applied Torque");
legend(Location="best");

%% Steering

nexttile;

plot(time,steering, ...
    LineWidth=lineWidth, ...
    DisplayName="Road-wheel command");

grid on;
xlabel("Time (s)");
ylabel("Steering angle (rad)");
title("Applied Road-Wheel Steering Command");
legend(Location="best");

%% Yaw rate

nexttile;

plot(time,yawRate, ...
    LineWidth=lineWidth, ...
    DisplayName="Measured yaw rate");

grid on;
xlabel("Time (s)");
ylabel("Yaw rate (rad/s)");
title("Measured Yaw Rate");
legend(Location="best");

%% Longitudinal velocity

nexttile;

plot(time,velocity, ...
    LineWidth=lineWidth, ...
    DisplayName="Measured speed");

grid on;
xlabel("Time (s)");
ylabel("Longitudinal speed, V_x (m/s)");
title("Closed-Loop Velocity Profile");
legend(Location="best");

%% Longitudinal acceleration

nexttile;

plot(time,accel, ...
    LineWidth=lineWidth, ...
    DisplayName="Measured acceleration");

grid on;
xlabel("Time (s)");
ylabel("Acceleration, a_x (m/s²)");
title("Closed-Loop Acceleration Profile");
legend(Location="best");

%% Trajectory

nexttile;

plot(reference.X_ref_m,reference.Y_ref_m, ...
    "k--", ...
    LineWidth=1.5, ...
    DisplayName="Reference track");

hold on;

plot(xPosition,yPosition, ...
    "b-", ...
    LineWidth=1.5, ...
    DisplayName="Vehicle trajectory");

scatter(xPosition(1),yPosition(1), ...
    50,"g","filled", ...
    DisplayName="Start");

scatter(xPosition(end),yPosition(end), ...
    50,"r","filled", ...
    DisplayName="End");

axis equal;
grid on;
xlabel("X position (m)");
ylabel("Y position (m)");
title("Reference and Closed-Loop Trajectories");
legend(Location="best");
hold off;

title(layout,"Adaptive MPC Closed-Loop Results");
disp("Adaptive MPC integration check completed.");