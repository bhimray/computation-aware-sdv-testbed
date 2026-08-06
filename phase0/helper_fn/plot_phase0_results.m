function figureHandle = plot_phase0_results(results, scenario, environmentName, ...
    actuationDelay_s)
%PLOT_PHASE0_RESULTS Plot one Phase 0 closed-loop simulation.

arguments
    results
    scenario
    environmentName (1,1) string
    actuationDelay_s (1,1) double = NaN
end

%% Prepare plot variables

time = results.time_s;
torque = results.torque_Nm;
steering = results.steering_angle_rad;
yawRate = results.yaw_rate_radps;
velocity = results.vx_mps;
acceleration = results.ax_mps2;
xPosition = results.x_pos_m;
yPosition = results.y_pos_m;
actuator = actuator_parameters();

lineWidth = 1.4;

%% Create figure and return its handle

figureHandle = figure( ...
    Name="MPC closed-loop results", ...
    Color="w", ...
    Position=[100 60 1400 850]);

layout = tiledlayout(figureHandle, 3, 2);
layout.TileSpacing = "compact";
layout.Padding = "compact";

%% Torque

nexttile(layout);

plot( ...
    time, torque, ...
    LineWidth=lineWidth, ...
    DisplayName="Applied torque");
yline( ...
    actuator.maximum_signed_front_axle_torque_Nm, ...
    "r--", ...
    LineWidth=1.3, ...
    DisplayName="Input bounds");

yline( ...
    actuator.minimum_signed_front_axle_torque_Nm, ...
    "r--", ...
    LineWidth=1.3, ...
    HandleVisibility="off");

grid on;
xlabel("Time (s)");
ylabel("Torque (N·m)");
title("Applied Torque");
legend(Location="best");

%% Steering

nexttile(layout);

plot( ...
    time, steering, ...
    LineWidth=lineWidth, ...
    DisplayName="Road-wheel command");
yline( ...
    actuator.maximum_road_wheel_angle_rad, ...
    "r--", ...
    LineWidth=1.3, ...
    DisplayName="Input bounds");

yline( ...
    actuator.minimum_road_wheel_angle_rad, ...
    "r--", ...
    LineWidth=1.3, ...
    HandleVisibility="off");

grid on;
xlabel("Time (s)");
ylabel("Steering angle (rad)");
title("Applied Road-Wheel Steering Command");
legend(Location="best");

%% Yaw rate

nexttile(layout);

plot( ...
    time, yawRate, ...
    LineWidth=lineWidth, ...
    DisplayName="Measured yaw rate");

grid on;
xlabel("Time (s)");
ylabel("Yaw rate (rad/s)");
title("Measured Yaw Rate");
legend(Location="best");

%% Longitudinal velocity

nexttile(layout);

plot( ...
    time, velocity, ...
    LineWidth=lineWidth, ...
    DisplayName="Measured speed");

grid on;
xlabel("Time (s)");
ylabel("Longitudinal speed, V_x (m/s)");
title("Closed-Loop Velocity Profile");
legend(Location="best");

%% Longitudinal acceleration

nexttile(layout);

plot( ...
    time, acceleration, ...
    LineWidth=lineWidth, ...
    DisplayName="Measured acceleration");

grid on;
xlabel("Time (s)");
ylabel("Acceleration, a_x (m/s²)");
title("Closed-Loop Acceleration Profile");
legend(Location="best");

%% Trajectory

nexttile(layout);

plot( ...
    scenario.X_ref_m, ...
    scenario.Y_ref_m, ...
    "k--", ...
    LineWidth=1.5, ...
    DisplayName="Reference track");

hold on;

plot( ...
    xPosition, ...
    yPosition, ...
    "b-", ...
    LineWidth=1.5, ...
    DisplayName="Vehicle trajectory");

scatter( ...
    xPosition(1), ...
    yPosition(1), ...
    50, "g", "filled", ...
    DisplayName="Start");

scatter( ...
    xPosition(end), ...
    yPosition(end), ...
    50, "r", "filled", ...
    DisplayName="End");

axis equal;
grid on;
xlabel("X position (m)");
ylabel("Y position (m)");
title("Reference and Closed-Loop Trajectories");
legend(Location="best");
hold off;

scenarioTitle = replace(string(scenario.name), "_", " ");
environmentName = replace(string(environmentName), "_", " ");

if ~isnan(actuationDelay_s)
    delay_ms = actuationDelay_s * 1e3;
    titleText = "MPC Closed-Loop Results: " + scenarioTitle + " — " + environmentName + ...
                " (delay = " + num2str(delay_ms, '%.1f') + " ms)";
else
    titleText = "MPC Closed-Loop Results: " + scenarioTitle + " — " + environmentName;
end

title(layout, titleText);
end