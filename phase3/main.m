

scenarioName = [ ...
    % sdv.enum.ScenarioName.urban_profile
    % sdv.enum.ScenarioName.highway_cruise
    sdv.enum.ScenarioName.aggressive_maneuver
    ];

environmentName = [ ...
    % sdv.enum.EnvironmentName.dry_road
    sdv.enum.EnvironmentName.low_friction_road
    ];

%% Build the normal Phase 0 configuration

configuration = ...
    build_phase0_configuration(scenarioName);

vehicleParams = configuration.vehicle;
controllerParams = configuration.controller;
simulationParams = configuration.simulation;
adaptiveModelParams = configuration.adaptiveModel;


initialControllerMeasurement = [
    simulationParams.initial_speed_mps
    0
    0
    simulationParams.initial_x_m
    simulationParams.initial_y_m
    simulationParams.initial_yaw_rad
    ];

check_runtime_requirements(controllerParams);

%% Variables required by the existing plant and controller

UT = legacy_plant_parameters( ...
    vehicleParams, ...
    simulationParams);

acadosSettings = ...
    acados_ocp_parameters(controllerParams);

acados_nominal_input = reshape( ...
    acadosSettings.nominal_input, ...
    2, ...
    1);

track_ref_table = ...
    configuration.scenario.lookup_table;

scenario_stop_table = ...
    configuration.scenario.stop_event_table; % applicable only for urban profile to drop the speed at turnings

stopTime_s = configuration.scenario.simulation_stop_time_s;
% stopTime_s = 2;
final_track_index = ...
    size(track_ref_table,1);

environment = load_env_profile( ...
    lower(environmentName), ...
    stopTime_s, ...
    FrictionDropTime_s=10);

roadFrictionProfile = ...
    environment.road_friction_profile;

%% CPU load
% off -> only comm and control task, maximum -> perception & communication
% included
loadTaskPeriod_s = 0.050;
loadCase = "maximum";

switch loadCase
    case "off"
        loadTaskDuration_s = 1e-6;

    case "maximum"
        loadTaskDuration_s = 0.030;  % 10-45 ms

    otherwise
        error("Unknown load case: %s", loadCase);
end

loadReleaseTime_s = (0:0.05:stopTime_s).';

loadTaskDuration = timeseries( ...
    repmat(loadTaskDuration_s, ...
    numel(loadReleaseTime_s), 1), ...
    loadReleaseTime_s);

loadTaskDuration = setinterpmethod( ...
    loadTaskDuration, ...
    "zoh");

switchTime_s = [
    0.00
    0.10
    0.31
    0.63
    0.80
    ];

switchMode = uint8([
    3       % HIGH
    2       % MEDIUM
    1       % LOW
    3       % HIGH
    3
    ]);

phase3_demand_mode_ts = timeseries( ...
    switchMode, ...
    switchTime_s);

phase3_demand_mode_ts.DataInfo.Interpolation = ...
    tsdata.interpolation('zoh');


%% Load empirical MPC execution times: solveTimeTelemetry
durationData = ...
    load_control_task_durations( ...
    scenarioName, ...
    environmentName);

randomSeed = 1001;
% resample solveTimeTelemetry
controlTaskDuration = ...
    create_control_task_duration_signal( ...
    durationData.samples_s, ...
    stopTime_s, ...
    randomSeed);


modelName = "phase3_scheduler_testbed";

simulationInput = ...
    Simulink.SimulationInput(modelName);

simulationInput = simulationInput.setVariable( ...
    "roadFrictionProfile",roadFrictionProfile);

simulationInput = simulationInput.setVariable( ...
    "controlTaskDuration",controlTaskDuration);

simulationInput = simulationInput.setVariable( ...
    "loadTaskDuration", ...
    loadTaskDuration);

simulationInput = simulationInput.setVariable( ...
    "vehicleParams",vehicleParams);

simulationInput = simulationInput.setVariable( ...
    "controllerParams",controllerParams);

simulationInput = simulationInput.setVariable( ...
    "simulationParams",simulationParams);

simulationInput = simulationInput.setVariable( ...
    "adaptiveModelParams",adaptiveModelParams);

simulationInput = simulationInput.setVariable( ...
    "UT",UT);

simulationInput = simulationInput.setVariable( ...
    "acados_nominal_input",acados_nominal_input);

simulationInput = simulationInput.setVariable( ...
    "track_ref_table",track_ref_table);

simulationInput = simulationInput.setVariable( ...
    "scenario_stop_table",scenario_stop_table);

simulationInput = simulationInput.setVariable( ...
    "final_track_index",final_track_index);

simulationInput = simulationInput.setVariable( ...
    "roadFrictionProfile",roadFrictionProfile);

simulationInput = simulationInput.setVariable( ...
    "phase3_demand_mode_ts", ...
    phase3_demand_mode_ts);

simulationInput = simulationInput.setModelParameter( ...
    StopTime="0.80");

simulationOutput = sim(simulationInput);
