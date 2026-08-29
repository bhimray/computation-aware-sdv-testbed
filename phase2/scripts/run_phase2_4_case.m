function [runArtifact, summaryRow, loadTaskRow] = run_phase2_4_case( ...
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
loadTaskDuration = [
    loadReleaseTime_s, ...
    repmat(scheduledLoadExecutionTime_s, numel(loadReleaseTime_s), 1)
    ];

scheduledControlDurations_s = ...
    double(controlTaskDuration.Data(:));

scheduledControlDurations_s = ...
    scheduledControlDurations_s( ...
        isfinite(scheduledControlDurations_s) ...
        & scheduledControlDurations_s > 0);

assert(~isempty(scheduledControlDurations_s), ...
    "No valid scheduled ControlTask durations exist.");

scheduledMeanControlExecutionTime_s = ...
    mean(scheduledControlDurations_s);

nominalUtilization = ...
    scheduledMeanControlExecutionTime_s ...
        / controlTaskPeriod_s ...
    + communicationTaskExecutionTime_s ...
        / communicationTaskPeriod_s ...
    + scheduledLoadExecutionTime_s ...
        / loadTaskPeriod_s;

fprintf( ...
    "Running Phase 2.4: %s | %s | load %.3f ms | U %.3f\n", ...
    scenarioName, ...
    environmentName, ...
    loadExecutionTime_ms, ...
    nominalUtilization);

simulationInput = Simulink.SimulationInput(options.ModelName);

simulationInput = simulationInput.setVariable("vehicleParams", vehicleParams);
simulationInput = simulationInput.setVariable("controllerParams", controllerParams);
simulationInput = simulationInput.setVariable("simulationParams", simulationParams);
simulationInput = simulationInput.setVariable("adaptiveModelParams", adaptiveModelParams);
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
simulationInput = simulationInput.setVariable( ...
    "loadTaskDuration", loadTaskDuration);
simulationInput = simulationInput.setVariable( ...
    "initialControllerMeasurement", initialControllerMeasurement);

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

newRunIds = setdiff( ...
    runIdsAfter, ...
    runIdsBefore, ...
    "stable");

assert(~isempty(newRunIds), ...
    "This simulation did not create an SDI run.");

latestRun = Simulink.sdi.getRun(newRunIds(end));

taskData = socTaskTimes( ...
    options.ModelName, ...
    latestRun.Name, ...
    "SuppressPlot");

taskSummary = createTaskSummary(taskData);

controlTask = findTask(taskData, "ControlTask");
controlResponseTime_s = finiteColumn(controlTask.Turnaround);
controlExecutionTime_s = finiteColumn(controlTask.Duration);

loadTask = findTask(taskData, "LoadTask");
loadResponseTime_s = finiteColumn(loadTask.Turnaround);
loadExecutionTime_s = finiteColumn(loadTask.Duration);

deadlineMissMask = controlResponseTime_s > controlTaskPeriod_s;
loadDeadlineMissMask = loadResponseTime_s > loadTaskPeriod_s;

loadTask = findTask(taskData, "LoadTask");
loadResponseTime_s = finiteColumn(loadTask.Turnaround);
loadExecutionTime_s = finiteColumn(loadTask.Duration);
loadDeadlineMissMask = loadResponseTime_s > loadTaskPeriod_s;

runArtifact = struct();
runArtifact.schema_version = 1;
runArtifact.phase = "2.4";
runArtifact.results = results;
runArtifact.reference = track_ref_table;
runArtifact.taskData = taskData;
runArtifact.taskSummary = taskSummary;
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
runArtifact.controlResponseTime_s = controlResponseTime_s;
runArtifact.controlExecutionTime_s = controlExecutionTime_s;
runArtifact.controlDeadlineMissMask = deadlineMissMask;
runArtifact.loadResponseTime_s = loadResponseTime_s;
runArtifact.loadExecutionTime_s = loadExecutionTime_s;
runArtifact.loadDeadlineMissMask = loadDeadlineMissMask;
runArtifact.scheduledMeanControlExecutionTime_s = ...
    scheduledMeanControlExecutionTime_s;

summaryRow = createSummaryRow(runArtifact);
loadTaskRow = create_phase2_4_load_task_row(runArtifact);

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
    loadTaskRow.RunFile = string(runFile);

    save(runFile, "runArtifact", "-v7.3");
    writetable(taskSummary, fullfile(caseFolder, "scheduler_summary.csv"));
    writetable(summaryRow, fullfile(caseFolder, "metrics_summary.csv"));
    writetable( ...
        loadTaskRow, ...
        fullfile(caseFolder, "load_task_metrics_summary.csv"));
end

end

function taskSummary = createTaskSummary(taskData)

numberOfTasks = numel(taskData);
taskName = strings(numberOfTasks,1);
meanExecution_ms = nan(numberOfTasks,1);
maximumExecution_ms = nan(numberOfTasks,1);
meanResponse_ms = nan(numberOfTasks,1);
maximumResponse_ms = nan(numberOfTasks,1);
numberOfOverruns = zeros(numberOfTasks,1);
overrunPercent = zeros(numberOfTasks,1);
numberOfDroppedJobs = zeros(numberOfTasks,1);

for taskIndex = 1:numberOfTasks
    task = taskData(taskIndex);
    taskName(taskIndex) = string(task.Name);
    meanExecution_ms(taskIndex) = 1e3*scalarOrDefault(task.Mean, NaN);
    maximumExecution_ms(taskIndex) = ...
        1e3*scalarOrDefault(task.MaxDuration, NaN);
    meanResponse_ms(taskIndex) = ...
        1e3*scalarOrDefault(task.MeanTurnaround, NaN);
    maximumResponse_ms(taskIndex) = ...
        1e3*scalarOrDefault(task.MaxTurnaround, NaN);
    numberOfOverruns(taskIndex) = scalarOrDefault(task.NumOverran, 0);
    overrunPercent(taskIndex) = scalarOrDefault(task.PercentOverran, 0);
    numberOfDroppedJobs(taskIndex) = scalarOrDefault(task.NumDropped, 0);
end

taskSummary = table( ...
    taskName, ...
    meanExecution_ms, ...
    maximumExecution_ms, ...
    meanResponse_ms, ...
    maximumResponse_ms, ...
    numberOfOverruns, ...
    overrunPercent, ...
    numberOfDroppedJobs, ...
    VariableNames=[ ...
        "Task", ...
        "MeanExecution_ms", ...
        "MaximumExecution_ms", ...
        "MeanResponse_ms", ...
        "MaximumResponse_ms", ...
        "Overruns", ...
        "OverrunPercent", ...
        "DroppedJobs"]);

end

function row = createSummaryRow(runArtifact)

results = runArtifact.results;
controlTask = findTask(runArtifact.taskData, "ControlTask");
response_s = runArtifact.controlResponseTime_s;

numberOfResponses = numel(response_s);
deadlineMissCount = sum(runArtifact.controlDeadlineMissMask);

if numberOfResponses == 0
    deadlineMissPercent = NaN;
else
    deadlineMissPercent = 100*deadlineMissCount/numberOfResponses;
end

row = table( ...
    runArtifact.scenarioName, ...
    runArtifact.environmentName, ...
    runArtifact.loadExecutionTime_ms, ...
    runArtifact.nominalUtilization, ...
    finiteRms(results.ev_mps), ...
    finiteRms(results.ey_m), ...
    rad2deg(finiteRms(results.epsi_rad)), ...
    1e3*finiteMean(response_s), ...
    1e3*empiricalPercentile(response_s, 95), ...
    1e3*finiteMaximum(response_s), ...
    deadlineMissCount, ...
    deadlineMissPercent, ...
    scalarOrDefault(controlTask.NumOverran, 0), ...
    scalarOrDefault(controlTask.NumDropped, 0), ...
    runArtifact.randomSeed, ...
    "completed", ...
    "", ...
    "", ...
    "", ...
    VariableNames=[ ...
        "Scenario", ...
        "Environment", ...
        "LoadExecution_ms", ...
        "NominalUtilization", ...
        "SpeedRMS_mps", ...
        "LateralRMS_m", ...
        "HeadingRMS_deg", ...
        "ControlMeanResponse_ms", ...
        "ControlP95Response_ms", ...
        "ControlMaximumResponse_ms", ...
        "DeadlineMissCount", ...
        "DeadlineMissPercent", ...
        "ControlOverrunCount", ...
        "ControlDroppedJobs", ...
        "RandomSeed", ...
        "Status", ...
        "ErrorIdentifier", ...
        "ErrorMessage", ...
        "RunFile"]);

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

function value = finiteMean(inputValues)

values = finiteColumn(inputValues);
if isempty(values)
    value = NaN;
else
    value = mean(values);
end

end

function value = finiteMaximum(inputValues)

values = finiteColumn(inputValues);
if isempty(values)
    value = NaN;
else
    value = max(values);
end

end

function value = empiricalPercentile(inputValues, percentile)

values = sort(finiteColumn(inputValues));
if isempty(values)
    value = NaN;
    return;
end

index = max(1, ceil((percentile/100)*numel(values)));
value = values(index);

end
