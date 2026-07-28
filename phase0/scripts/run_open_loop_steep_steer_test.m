%% Open-loop constant-drive-torque sanity test

startup_project;

modelName = "plant_open_loop_step_steer_test";

% Test configuration
testStopTime_s = 500;
test_step_time_s = 250; %for step response
test_braking_cmd = 0;
test_steering_wheel_deg = 20;
test_slope = 0;
test_road_friction_mu = 0.80; % [1]

% torque range
torqueLevels_Nm = 100;

results = struct([]);

for k = 1:numel(torqueLevels_Nm)

    simInput = Simulink.SimulationInput(modelName);
    
    simInput = simInput.setVariable( ...
        "test_step_time_s", test_step_time_s);

    simInput = simInput.setVariable( ...
        "test_drive_torque_Nm", torqueLevels_Nm(k));

    simInput = simInput.setVariable( ...
        "test_braking_cmd", test_braking_cmd);

    simInput = simInput.setVariable( ...
        "test_steering_wheel_deg", test_steering_wheel_deg);

    simInput = simInput.setVariable( ...
        "test_slope", test_slope);

    simInput = simInput.setVariable( ...
        "test_road_friction_mu", test_road_friction_mu);

    simInput = simInput.setModelParameter( ...
        StopTime=string(testStopTime_s));
    
    simOut = sim(simInput);
    
    logs = simOut.logsout;

    vxSignal = logs.get("vx_mps").Values;
    axSignal = logs.get("ax_mps2").Values;
    yawRateSignal = logs.get("yaw_rate_radps").Values;
    yawSignal = logs.get("yaw_angle_rad").Values;

    results(k).torque_Nm = torqueLevels_Nm(k);
    results(k).time_s = vxSignal.Time;
    results(k).vx_mps = vxSignal.Data;
    results(k).ax_mps2 = axSignal.Data;
    results(k).yaw_rate_radps = yawRateSignal.Data;
    results(k).yaw_angle_rad = yawSignal.Data;
end


linestyles = {'-','--',':','-.', '--*'};

%% velocity
figure;
hold on;
labels = strings(1, numel(results));
for k = 1:numel(results)
    plot(...
        results(k).time_s, ...
        results(k).vx_mps, ...
        linestyles{k} ...
        );
    labels(k) = sprintf("%d N.m", results(k).torque_Nm);
end

grid on;
xlabel("Time (s)");
ylabel("Longitudinal speed, V_x (m/s)");
title("Open-loop response to constant drive torque (velocity)");
legend(labels, Location = "best");

%% yaw rate
figure;
hold on;
labels = strings(1, numel(results));
for k = 1:numel(results)
    plot(...
        results(k).time_s, ...
        results(k).yaw_rate_radps, ...
        linestyles{k} ...
        );
    labels(k) = sprintf("%d N.m", results(k).torque_Nm);
end

grid on;
xlabel("Time (s)");
ylabel("Yaw rate (rad/s)");
title("Open-loop response of yaw rate to constant velocity");
legend(labels, Location = "best");

%% yaw angle
figure;
hold on;
labels = strings(1, numel(results));
for k = 1:numel(results)
    plot(...
        results(k).time_s, ...
        results(k).yaw_angle_rad, ...
        linestyles{k} ...
        );
    labels(k) = sprintf("%d N.m", results(k).torque_Nm);
end

grid on;
xlabel("Time (s)");
ylabel("Yaw angle (rad)");
title("Open-loop response of yaw angle at const velocity");
legend(labels, Location = "best");

%% acceleration
% figure;
% hold on;
% labels = strings(1, numel(results));
% for k = 1:numel(results)
%     plot( ...
%         results(k).time_s, ...
%         results(k).ax_mps2, ...
%         linestyles{k} ...
%     );
%     labels(k) = sprintf("%d N.m", results(k).torque_Nm);
% end
% 
% grid on;
% xlabel("Time (s)");
% ylabel("Acceleration, a_x (m/s2)");
% title("Open-loop response to constant drive torque (acceleration)");
% legend(labels, Location = "best");
