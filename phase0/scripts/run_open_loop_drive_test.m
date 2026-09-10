%% Open-loop constant-drive-torque sanity test
startup_project;

modelName = "plant_open_loop_test";

% Test configuration
testStopTime_s = 100;
test_braking_cmd = 0;
test_steering_wheel_deg = 0;
test_slope = 0;
test_road_friction_mu = 0.80; % [1]

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

projectRoot = string(matlab.project.currentProject().RootFolder);
resultsFolder = fullfile( ...
    projectRoot, "phase0", "results", "open_loop");

if ~isfolder(resultsFolder)
    mkdir(resultsFolder);
end

resultsFile = fullfile(resultsFolder, "open_loop_drive_test.mat");
save(resultsFile, "results", "torqueLevels_Nm", "testStopTime_s");

fprintf("Open-loop drive results saved to:\n%s\n", resultsFile);
fprintf("Relevant plot file:\n%s\n", fullfile( ...
    projectRoot, "phase0", "plots", ...
    "plot_open_loop_drive_test.m"));
