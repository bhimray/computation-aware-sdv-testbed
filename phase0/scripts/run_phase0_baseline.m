function [results, config] = run_phase0_baseline(scenarioName)
%RUN_PHASE0_BASELINE Phase 0 closed-loop scenario.

arguments
    % defining default value for the arguments
    scenarioName (1,1) string = "highway_cruise"
end

startup_project;
rng(0, "twister");

modelName = "phase0_baseline";

%% Build complete run configuration

config = build_phase0_configuration(scenarioName);

vehicleParams = config.vehicle;
controllerParams = config.controller;
simulationParams = config.simulation;
adaptiveModelParams = config.adaptiveModel;

%% for Plant simulink model
UT = legacy_plant_parameters( ...
    vehicleParams, ...
    simulationParams);

% Required by MPC_backend_acados
acadosSettings = acados_ocp_parameters(controllerParams);
acados_nominal_input = acadosSettings.nominal_input;
acados_nominal_input = reshape(acados_nominal_input, 2, 1); % acados nominal input

track_ref_table = config.scenario.lookup_table;
scenario_stop_table = config.scenario.stop_event_table;

%% Configure selected controller backend

switch controllerParams.controller_backend

    case controllerParams.BACKEND_ACADOS
        disp("Running acados controller... ")
        % error("ACADOS backend is not implemented yet.");

    case controllerParams.BACKEND_MATLAB
        error("Fixed linear MATLAB MPC backend is not implemented yet.");

    case controllerParams.BACKEND_ADAPTIVE

        [Ad0, Bmv0, Emd0] = ...
            linearize_prediction_model(vehicleParams, simulationParams, controllerParams);

        mpc_adaptive = configure_baseline_mpc( ...
            Ad0, Bmv0, Emd0, controllerParams);

    otherwise
        error( ...
            "Unknown controller backend ID: %d", ...
            controllerParams.controller_backend);
end

%% Create one SimulationInput object

simInput = Simulink.SimulationInput(modelName);

simInput = simInput.setVariable( ...
    "vehicleParams", vehicleParams);

simInput = simInput.setVariable( ...
    "controllerParams", controllerParams);

simInput = simInput.setVariable( ...
    "simulationParams", simulationParams);

simInput = simInput.setVariable( ...
    "adaptiveModelParams", adaptiveModelParams);

simInput = simInput.setVariable( ...
    "track_ref_table", track_ref_table);

simInput = simInput.setVariable( ...
    "scenario_stop_table", scenario_stop_table);

simInput = simInput.setVariable("UT", UT);

simInput = simInput.setVariable( ...
    "acados_nominal_input", ...
    acados_nominal_input);

if controllerParams.controller_backend == ...
        controllerParams.BACKEND_ADAPTIVE

    simInput = simInput.setVariable( ...
        "mpc_adaptive", mpc_adaptive);
end

simInput = simInput.setModelParameter( ...
    StopTime=string(simulationParams.stop_time_s), ...
    ReturnWorkspaceOutputs="on");

%% Run simulation

simulationOutput = sim(simInput);

%% Validate logging

assert(isprop(simulationOutput, "logsout") || ...
    any(simulationOutput.who == "logsout"), ...
    "Simulation did not return logsout.");

logs = simulationOutput.logsout;

requiredSignals = [ ...
    "vx_meas"
    "vx_ref"
    "ax_meas"
    "x_pos"
    "y_pos"
    "torque_opt"
    "steering_angle_opt"
    "yaw_rate_meas"
    "ey_m"
    "epsi_rad"
    "solve_status"
    "solve_time"
    ];

availableSignals = string(logs.getElementNames);

missingSignals = setdiff(requiredSignals, availableSignals);

assert(isempty(missingSignals), ...
    "Missing logged signals: %s", ...
    strjoin(missingSignals, ", "));

%% Extract results

results = extract_phase0_baseline_results(logs);

%% Add reproducibility metadata

results.metadata.scenario_name = scenarioName;
results.metadata.matlab_version = string(version);
results.metadata.generated_at_utc = ...
    datetime("now", TimeZone="UTC");
results.metadata.controller_backend = ...
    controllerParams.controller_backend;
results.metadata.scenario_schema_version = ...
    config.scenario.schema_version;

%% Save deterministic deliverable

projectRoot = string(matlab.project.currentProject().RootFolder);
resultsFolder = fullfile(projectRoot, "phase0", "results");
figuresFolder = fullfile(projectRoot, "phase0", "figures");

if ~isfolder(resultsFolder)
    mkdir(resultsFolder);
end

if ~isfolder(figuresFolder)
    mkdir(figuresFolder);
end

resultsFile = fullfile( ...
    resultsFolder, scenarioName + "_results.mat");

figureHandle = plot_phase0_results( ...
    results, config.scenario);

% Generate tracking-error plots and metrics.
[errorFigureHandle, results.tracking_metrics] = ...
    plot_phase0_tracking_errors(results, config.scenario);

[solveTimeFigureHandle, results.solve_time_metrics] = ...
    plot_phase0_solve_time( ...
    results, ...
    config.scenario, ...
    simulationParams.Ts_s);
[solveTimeTelemetryFigureHandle, ...
    results.solve_time_tele_metrics] = ...
    plot_solve_time_telemetry( ...
        results, ...
        string(config.scenario.name), ...
        simulationParams.Ts_s);

save(resultsFile, "results", "config");

figureFile = fullfile( ...
    figuresFolder, scenarioName + "_tracking.png");

exportgraphics(figureHandle, figureFile, Resolution=200);
savefig( ...
    figureHandle, ...
    fullfile(figuresFolder, scenarioName + "_tracking.fig"));

errorFigureFile = fullfile( ...
    figuresFolder, scenarioName + "_tracking_errors.png");

exportgraphics( ...
    errorFigureHandle, errorFigureFile, Resolution=200);

savefig( ...
    errorFigureHandle, ...
    fullfile( ...
        figuresFolder, ...
        scenarioName + "_tracking_errors.fig"));

solveTimeFigureFile = fullfile( ...
    figuresFolder, ...
    scenarioName + "_solve_time_histogram.png");

exportgraphics( ...
    solveTimeFigureHandle, ...
    solveTimeFigureFile, ...
    Resolution=200);

savefig( ...
    solveTimeFigureHandle, ...
    fullfile( ...
    figuresFolder, ...
    scenarioName + "_solve_time_histogram.fig"));

solveTimeTeleFigureFile = fullfile( ...
    figuresFolder, ...
    scenarioName + "_solve_time_telemetry.png");

exportgraphics( ...
    solveTimeTelemetryFigureHandle, ...
    solveTimeTeleFigureFile, ...
    Resolution=200);

savefig( ...
    solveTimeTelemetryFigureHandle, ...
    fullfile( ...
    figuresFolder, ...
    scenarioName + "_solve_time_telemetry.fig"));

fprintf("Scenario completed: %s\n", scenarioName);
fprintf("Results: %s\n", resultsFile);
fprintf("Figure:  %s\n", figureFile);
fprintf("Errors:  %s\n", errorFigureFile);
fprintf( ...
    "Speed error:  RMS %.3f m/s, peak %.3f m/s\n", ...
    results.tracking_metrics.speed_rmse_mps, ...
    results.tracking_metrics.speed_peak_mps);
fprintf( ...
    "Lateral error: RMS %.3f m, peak %.3f m\n", ...
    results.tracking_metrics.lateral_rmse_m, ...
    results.tracking_metrics.lateral_peak_m);
fprintf( ...
    "Heading error: RMS %.3f deg, peak %.3f deg\n", ...
    results.tracking_metrics.heading_rmse_deg, ...
    results.tracking_metrics.heading_peak_deg);
end
