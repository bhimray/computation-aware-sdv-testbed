%% Open-loop constant-drive-torque sanity test

startup_project;
controllerParams = controller_parameters(UT);
controllerParams.pose_x0_m = reference.X_ref_m(1); % initial state x0 for integrator
controllerParams.pose_y0_m = reference.Y_ref_m(1); % initial state y0 for integrator

modelName = "plant_open_loop_test";

% Test configuration
testStopTime_s = 100;
test_braking_cmd = 0;
test_steering_wheel_deg = 0;
test_slope = 0;
test_road_friction_mu = 0.95; % [1]

% torque range
torqueLevels_Nm = [100, 150, 200, 250, 300];

results = struct([]);

for k = 1:numel(torqueLevels_Nm)

    simInput = Simulink.SimulationInput(modelName);

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
    FaxSignal = logs.get("Fax").Values;


    results(k).torque_Nm = torqueLevels_Nm(k);
    results(k).time_s = vxSignal.Time;
    results(k).vx_mps = vxSignal.Data;
    results(k).ax_time_s = vxSignal.Time;
    results(k).ax_mps2 = axSignal.Data;
    results(k).Fax_N = FaxSignal.Data;
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

%% Air drag force
figure;
hold on;
labels = strings(1, numel(results));
for k = 1:numel(results)
    plot(...
        results(k).time_s, ...
        results(k).Fax_N, ...
        linestyles{k} ...
        );
    labels(k) = sprintf("%d N.m", results(k).torque_Nm);
end

grid on;
xlabel("Time (s)");
ylabel("Drag Force, Fax (N)");
title("Open-loop response to constant drive torque (Air drag force)");
legend(labels, Location = "best");

% % acceleration
figure;
hold on;
labels = strings(1, numel(results));
for k = 1:numel(results)
    plot( ...
        results(k).ax_time_s, ...
        results(k).ax_mps2, ...
        linestyles{k} ...
    );
    labels(k) = sprintf("%d N.m", results(k).torque_Nm);
end

grid on;
xlabel("Time (s)");
ylabel("Acceleration, a_x (m/s2)");
title("Open-loop response to constant drive torque (acceleration)");
legend(labels, Location = "best");
