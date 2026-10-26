function [results, resultsFile] = run_open_loop_steep_steer_test()
%RUN_OPEN_LOOP_STEEP_STEER_TEST Run and save the step-steer sanity test.

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

projectRoot = string(matlab.project.currentProject().RootFolder);
resultsFolder = fullfile( ...
    projectRoot, "phase0", "results", "open_loop");

if ~isfolder(resultsFolder)
    mkdir(resultsFolder);
end

resultsFile = fullfile(resultsFolder, "open_loop_steep_steer_test.mat");
save(resultsFile, "results", "torqueLevels_Nm", ...
    "testStopTime_s", "test_step_time_s");

fprintf("Open-loop steer results saved to:\n%s\n", resultsFile);
fprintf("Relevant plot file:\n%s\n", fullfile( ...
    projectRoot, "phase0", "plots", ...
    "plot_open_loop_steep_steer_test.m"));

end
