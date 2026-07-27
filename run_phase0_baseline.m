%% Phase 0 baseline regeneration entry point
clearvars;
bdclose("all");
clear functions;
rehash;

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

[Ad,Bmv,Emd] = linearize_prediction_model( ...
    controllerParams);

mpc_baseline = configure_baseline_mpc( ...
    Ad,Bmv,Emd,controllerParams);

assignin("base","mpc_baseline", mpc_baseline);

simOut = sim("phase0\models\phase0_baseline.slx", StopTime = "15");
logs = simOut.logsout;

vxSignal = logs.get("vx_meas").Values;
axSignal = logs.get("ax_meas").Values;
torque = logs.get("torque_opt").Values;
steering_angle = logs.get("steering_angle_opt").Values;
yaw_rate_radps = logs.get("yaw_rate_meas").Values;
solve_status = logs.get("solve_status").Values;
x_pos = logs.get("x_pos").Values;
y_pos = logs.get("y_pos").Values;
est_states = logs.get("est_state").Values;

results = struct( ...
  'time_s', [], ...
  'torque_Nm', [], ...
  'vx_mps', [], ...
  'ax_mps2', [], ...
  'steering_angle_rad', [], ...
  'yaw_rate_radps',[], ...
  'x_pos_m', [], ...
  'y_pos_m', [], ...
  'est_state',[], ...
  'solve_status', [] ...
);


results.time_s = torque.Time;
results.torque_Nm = torque.Data;
results.vx_mps = vxSignal.Data;
results.ax_mps2 = axSignal.Data;
results.steering_angle_rad = steering_angle.Data;
results.yaw_rate_radps = yaw_rate_radps.Data;
results.x_pos_m = x_pos.Data;
results.y_pos_m = y_pos.Data;
results.est_state = est_states.Data;
results.solve_status = solve_status.Data;

%% torque
figure;
hold on;
plot(...
    results.time_s, ...
    results.torque_Nm ...
    );

grid on;
xlabel("Time (s)");
ylabel("Torque, Nm)");
title("Applied Torque (Nm)");
legend(Location = "best");

%% steering_angel_rad
figure;
hold on;
plot(...
    results.time_s, ...
    results.steering_angle_rad ...
    );

grid on;
xlabel("Time (s)");
ylabel("Applied steering angle, rad)");
title("Applied steering angle");
legend(Location = "best");

%% yaw_rate_radps
figure;
hold on;
plot(...
    results.time_s, ...
    results.yaw_rate_radps ...
    );

grid on;
xlabel("Time (s)");
ylabel("Yaw Rate, rad/s)");
title("Measured Yaw rate");
legend(Location = "best");

%% velocity
figure;
hold on;
plot(...
    results.time_s, ...
    results.vx_mps ...
    );

grid on;
xlabel("Time (s)");
ylabel("Longitudinal speed, V_x (m/s)");
title("Closed loop velocity profile");
legend(Location = "best");

%% acceleration
figure;
hold on;
plot(...
    results.time_s, ...
    results.ax_mps2 ...
    );

grid on;
xlabel("Time (s)");
ylabel("Acceleration , a_x (m/s2)");
title("Closed loop acceleration profile");
legend(Location = "best");

%% estimated states
figure;
hold on;
est = results.est_state;                % N x nStates (samples x states)
time = results.time_s;

nStates = min(5, size(est,2));
colors = lines(nStates);
for k = 1:nStates
    plot(time, est(:,k), 'Color', colors(k,:), 'LineWidth', 1.2, 'DisplayName', sprintf('State %d', k));
end

grid on;
xlabel("Time (s)");
ylabel("Estimated state value");
title("Estimated States vs Time");
legend("Location","best");
hold off;

%% trajectory
figure;
plot( ...
    reference.X_ref_m, ...
    reference.Y_ref_m, ...
    "k--", ...
    "LineWidth", 1.5, ...
    "DisplayName", "Reference track");

hold on;

plot( ...
    results.x_pos_m, ...
    results.y_pos_m, ...
    "b-", ...
    "LineWidth", 1.5, ...
    "DisplayName", "Vehicle trajectory");

plot( ...
    results.x_pos_m(1), ...
    results.y_pos_m(1), ...
    "go", ...
    "MarkerFaceColor", "g", ...
    "DisplayName", "Start");

plot( ...
    results.x_pos_m(end), ...
    results.y_pos_m(end), ...
    "ro", ...
    "MarkerFaceColor", "r", ...
    "DisplayName", "End");

hold off;
axis equal;
grid on;

xlabel("X position (m)");
ylabel("Y position (m)");
title("Reference and Closed-Loop Trajectories");
legend("Location", "best");

disp("Baseline simulation completed.");