function [runArtifact, summaryRow] = run_phase2_4_case( ...
    scenarioName, ...
    environmentName, ...
    loadExecutionTime_ms, ...
    options)
%RUN_PHASE2_4_CASE Run and save one Phase 2.4 utilization case.

arguments
    scenarioName (1,1) string
    environmentName (1,1) string
    loadExecutionTime_ms (1,1) double {mustBeNonnegative}
    options.RandomSeed (1,1) double = 1001
    options.ModelName (1,1) string = "phase2_scheduler_testbed"
    options.SaveResults (1,1) logical = true
end

configuration = build_phase0_configuration(scenarioName);

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

UT = legacy_plant_parameters(vehicleParams, simulationParams);
acadosSettings = acados_ocp_parameters(controllerParams);
acados_nominal_input = reshape(acadosSettings.nominal_input, 2, 1);

track_ref_table = configuration.scenario.lookup_table;
scenario_stop_table = configuration.scenario.stop_event_table;
stopTime_s = configuration.scenario.simulation_stop_time_s;
final_track_index = size(track_ref_table, 1);

environment = load_env_profile( ...
    lower(environmentName), ...
    stopTime_s, ...
    FrictionDropTime_s=10);
roadFrictionProfile = environment.road_friction_profile;

durationData = load_control_task_durations( ...
    scenarioName, ...
    environmentName);
controlTaskDuration = create_control_task_duration_signal( ...
    durationData.samples_s, ...
    stopTime_s, ...
    options.RandomSeed);

controlTaskPeriod_s = 0.010;
communicationTaskPeriod_s = 0.005;
communicationTaskExecutionTime_s = 0.0005;
loadTaskPeriod_s = 0.050;
loadTaskExecutionTime_s = loadExecutionTime_ms/1000;
scheduledLoadExecutionTime_s = max(loadTaskExecutionTime_s, 1e-6);

loadReleaseTime_s = (0:loadTaskPeriod_s:stopTime_s).';
loadTaskDuration = [ ...
    loadReleaseTime_s, ...
    repmat(scheduledLoadExecutionTime_s, numel(loadReleaseTime_s), 1)];

scheduledControlDurations_s = double(controlTaskDuration.Data(:));
scheduledControlDurations_s = scheduledControlDurations_s( ...
    isfinite(scheduledControlDurations_s) ...
    & scheduledControlDurations_s > 0);
assert(~isempty(scheduledControlDurations_s), ...
    "No valid scheduled ControlTask durations exist.");

scheduledMeanControlExecutionTime_s = mean(scheduledControlDurations_s);
nominalUtilization = ...
    scheduledMeanControlExecutionTime_s/controlTaskPeriod_s ...
    + communicationTaskExecutionTime_s/communicationTaskPeriod_s ...
    + scheduledLoadExecutionTime_s/loadTaskPeriod_s;

fprintf( ...
    "Running Phase 2.4: %s | %s | load %.3f ms | U %.3f\n", ...
    scenarioName, environmentName, loadExecutionTime_ms, nominalUtilization);

simulationInput = Simulink.SimulationInput(options.ModelName);
simulationInput = simulationInput.setVariable("vehicleParams", vehicleParams);
simulationInput = simulationInput.setVariable("controllerParams", controllerParams);
simulationInput = simulationInput.setVariable("simulationParams", simulationParams);
simulationInput = simulationInput.setVariable( ...
    "adaptiveModelParams", adaptiveModelParams);
simulationInput = simulationInput.setVariable("UT", UT);
simulationInput = simulationInput.setVariable( ...
    "acados_nominal_input", acados_nominal_input);
simulationInput = simulationInput.setVariable("track_ref_table", track_ref_table);
simulationInput = simulationInput.setVariable( ...
    "scenario_stop_table", scenario_stop_table);
simulationInput = simulationInput.setVariable("final_track_index", final_track_index);
simulationInput = simulationInput.setVariable( ...
    "roadFrictionProfile", roadFrictionProfile);
simulationInput = simulationInput.setVariable( ...
    "controlTaskDuration", controlTaskDuration);
simulationInput = simulationInput.setVariable("loadTaskDuration", loadTaskDuration);
simulationInput = simulationInput.setVariable( ...
    "initialControllerMeasurement", initialControllerMeasurement);
simulationInput = simulationInput.setModelParameter( ...
    StopTime=string(stopTime_s));

runIdsBefore = Simulink.sdi.getAllRunIDs;
simulationOutput = sim(simulationInput);
logs = simulationOutput.logsout;

availableSignals = string(logs.getElementNames);
solveTimeAvailable = ismember("solve_time", availableSignals);
results = sdv.results.extractBaseline( ...
    logs, ...
    solveTimeAvailable, ...
    IrregularControllerTiming=true);

runIdsAfter = Simulink.sdi.getAllRunIDs;
newRunIds = setdiff(runIdsAfter, runIdsBefore, "stable");
assert(~isempty(newRunIds), "This simulation did not create an SDI run.");

latestRun = Simulink.sdi.getRun(newRunIds(end));
taskData = socTaskTimes( ...
    options.ModelName, ...
    latestRun.Name, ...
    "SuppressPlot");

controlTask = findTask(taskData, "ControlTask");
loadTask = findTask(taskData, "LoadTask");
controlMetrics = summarizeTask(controlTask, controlTaskPeriod_s);
loadMetrics = summarizeTask(loadTask, loadTaskPeriod_s);

printTaskSummary("ControlTask", controlMetrics);
printTaskSummary("LoadTask", loadMetrics);

runArtifact = struct();
runArtifact.schema_version = 2;
runArtifact.phase = "2.4";
runArtifact.results = results;
runArtifact.reference = track_ref_table;
runArtifact.taskData = taskData;
runArtifact.scenarioName = scenarioName;
runArtifact.environmentName = environmentName;
runArtifact.loadExecutionTime_ms = loadExecutionTime_ms;
runArtifact.randomSeed = options.RandomSeed;
runArtifact.nominalUtilization = nominalUtilization;
runArtifact.controlTaskPeriod_s = controlTaskPeriod_s;
runArtifact.communicationTaskPeriod_s = communicationTaskPeriod_s;
runArtifact.communicationTaskExecutionTime_s = ...
    communicationTaskExecutionTime_s;
runArtifact.loadTaskPeriod_s = loadTaskPeriod_s;
runArtifact.controlTimingSource = durationData.source_file;
runArtifact.controlResponseTime_s = controlMetrics.ResponseTime_s;
runArtifact.loadResponseTime_s = loadMetrics.ResponseTime_s;
runArtifact.controlDropTime_s = controlMetrics.DropTime_s;
runArtifact.loadDropTime_s = loadMetrics.DropTime_s;
runArtifact.controlOverrunTime_s = controlMetrics.OverrunTime_s;
runArtifact.loadOverrunTime_s = loadMetrics.OverrunTime_s;
runArtifact.scheduledMeanControlExecutionTime_s = ...
    scheduledMeanControlExecutionTime_s;

summaryRow = createSummaryRow( ...
    runArtifact, ...
    controlMetrics, ...
    loadMetrics);

if options.SaveResults
    projectRoot = string(matlab.project.currentProject().RootFolder);
    caseFolder = phase2_4_case_folder( ...
        projectRoot, ...
        scenarioName, ...
        environmentName, ...
        loadExecutionTime_ms);
    if ~isfolder(caseFolder)
        mkdir(caseFolder);
    end

    runFile = fullfile(caseFolder, "run_data.mat");
    runArtifact.runFile = string(runFile);
    summaryRow.RunFile = string(runFile);
    save(runFile, "runArtifact", "-v7.3");
end

end


function metrics = summarizeTask(task, deadline_s)

responseTime_s = finiteColumn(task.Turnaround);
dropTime_s = finiteColumn(task.DropTime);
overrunTime_s = finiteColumn(task.OverrunTime);
droppedJobs = scalarOrDefault(task.NumDropped, numel(dropTime_s));
overrunCount = scalarOrDefault(task.NumOverran, numel(overrunTime_s));
lateCompletedJobs = sum(responseTime_s > deadline_s);
completedJobs = numel(responseTime_s);
releasedJobs = completedJobs + droppedJobs;
deadlineMissCount = lateCompletedJobs + droppedJobs;

if releasedJobs == 0
    deadlineMissPercent = NaN;
else
    deadlineMissPercent = 100*deadlineMissCount/releasedJobs;
end

metrics = struct( ...
    ResponseTime_s=responseTime_s, ...
    DropTime_s=dropTime_s, ...
    OverrunTime_s=overrunTime_s, ...
    CompletedJobs=completedJobs, ...
    LateCompletedJobs=lateCompletedJobs, ...
    DeadlineMissCount=deadlineMissCount, ...
    DeadlineMissPercent=deadlineMissPercent, ...
    OverrunCount=overrunCount, ...
    DroppedJobs=droppedJobs, ...
    MeanResponse_ms=1e3*finiteMean(responseTime_s), ...
    P95Response_ms=1e3*empiricalPercentile(responseTime_s, 95), ...
    MaximumResponse_ms=1e3*finiteMaximum(responseTime_s));

end


function printTaskSummary(taskName, metrics)

fprintf( ...
    "%s: completed=%d, late=%d, overruns=%d, dropped=%d, " + ...
    "mean response=%.3f ms, p95=%.3f ms, max=%.3f ms\n", ...
    taskName, ...
    metrics.CompletedJobs, ...
    metrics.LateCompletedJobs, ...
    metrics.OverrunCount, ...
    metrics.DroppedJobs, ...
    metrics.MeanResponse_ms, ...
    metrics.P95Response_ms, ...
    metrics.MaximumResponse_ms);

end


function row = createSummaryRow(runArtifact, controlMetrics, loadMetrics)

results = runArtifact.results;
record = struct();
record.Scenario = runArtifact.scenarioName;
record.Environment = runArtifact.environmentName;
record.LoadExecution_ms = runArtifact.loadExecutionTime_ms;
record.NominalUtilization = runArtifact.nominalUtilization;
record.SpeedRMS_mps = finiteRms(results.ev_mps);
record.LateralRMS_m = finiteRms(results.ey_m);
record.HeadingRMS_deg = rad2deg(finiteRms(results.epsi_rad));
record.ControlMeanResponse_ms = controlMetrics.MeanResponse_ms;
record.ControlP95Response_ms = controlMetrics.P95Response_ms;
record.ControlMaximumResponse_ms = controlMetrics.MaximumResponse_ms;
record.ControlDeadlineMissCount = controlMetrics.DeadlineMissCount;
record.ControlDeadlineMissPercent = controlMetrics.DeadlineMissPercent;
record.ControlOverrunCount = controlMetrics.OverrunCount;
record.ControlDroppedJobs = controlMetrics.DroppedJobs;
record.LoadMeanResponse_ms = loadMetrics.MeanResponse_ms;
record.LoadP95Response_ms = loadMetrics.P95Response_ms;
record.LoadMaximumResponse_ms = loadMetrics.MaximumResponse_ms;
record.LoadDeadlineMissCount = loadMetrics.DeadlineMissCount;
record.LoadDeadlineMissPercent = loadMetrics.DeadlineMissPercent;
record.LoadOverrunCount = loadMetrics.OverrunCount;
record.LoadDroppedJobs = loadMetrics.DroppedJobs;
record.RandomSeed = runArtifact.randomSeed;
record.Status = "completed";
record.ErrorIdentifier = "";
record.ErrorMessage = "";
record.RunFile = "";
row = struct2table(record);

end


function task = findTask(taskData, taskName)

names = string({taskData.Name});
index = find(strcmpi(names, taskName), 1, "first");
assert(~isempty(index), "Scheduler task '%s' was not found.", taskName);
task = taskData(index);

end


function value = scalarOrDefault(inputValue, defaultValue)

if isempty(inputValue)
    value = defaultValue;
else
    value = double(inputValue(1));
end

end


function values = finiteColumn(inputValues)
values = double(inputValues(:));
values = values(isfinite(values));
end


function value = finiteRms(inputValues)
values = finiteColumn(inputValues);
if isempty(values)
    value = NaN;
else
    value = sqrt(mean(values.^2));
end
end


function value = finiteMean(values)
if isempty(values)
    value = NaN;
else
    value = mean(values);
end
end


function value = finiteMaximum(values)
if isempty(values)
    value = NaN;
else
    value = max(values);
end
end


function value = empiricalPercentile(values, percentile)
values = sort(values);
if isempty(values)
    value = NaN;
else
    index = max(1, ceil((percentile/100)*numel(values)));
    value = values(index);
end
end
