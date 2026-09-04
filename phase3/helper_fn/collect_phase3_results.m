function [runArtifact, summaryRow] = ...
    collect_phase3_results( ...
        simulationOutput, ...
        modelName, ...
        runIdsBefore, ...
        reference, ...
        metadata)

arguments
    simulationOutput
    modelName (1,1) string
    runIdsBefore (:,1) double
    reference
    metadata (1,1) struct
end

%% Extract logged controller/plant results

logs = simulationOutput.logsout;
signalNames = string(logs.getElementNames);

requiredSignals = [
    "controller_selected_id"
    "selected_control_task_dur_s"
    ];

missingSignals = setdiff(requiredSignals, signalNames);

assert( ...
    isempty(missingSignals), ...
    "Missing Phase 3 logged signals: %s", ...
    strjoin(missingSignals, ", "));

solveTimeAvailable = ...
    ismember("solve_time", signalNames);

results = sdv.results.extractBaseline( ...
    logs, ...
    solveTimeAvailable, ...
    IrregularControllerTiming=true);

%% Extract Phase 3 signals

modeSignal = ...
    getLoggedSignal(logs, "controller_selected_id");

selectedDurationSignal = ...
    getLoggedSignal(logs, "selected_control_task_dur_s");

%% Extract SDI task information

runIdsAfter = Simulink.sdi.getAllRunIDs;

newRunIds = setdiff( ...
    runIdsAfter, ...
    runIdsBefore, ...
    "stable");

assert( ...
    ~isempty(newRunIds), ...
    "The simulation did not create an SDI run.");

latestRun = ...
    Simulink.sdi.getRun(newRunIds(end));

taskData = socTaskTimes( ...
    modelName, ...
    latestRun.Name, ...
    "SuppressPlot");

controlTask = findTask(taskData, "ControlTask");
loadTask = findTask(taskData, "LoadTask");

%% Completed ControlTask jobs

controlJobs = completedJobs(controlTask);

controlJobs.Mode = sampleHeld( ...
    modeSignal.Time_s, ...
    modeSignal.Data, ...
    controlJobs.ReleaseTime_s);

%% Dynamic deadline from selected controller mode

% Mode convention:
% 1 = LOW, 2 = MEDIUM, 3 = HIGH
relativeDeadlineLookup_s = [
    0.050
    0.020
    0.010
    ];

controlJobs.RelativeDeadline_s = ...
    nan(height(controlJobs), 1);

validMode = ismember( ...
    controlJobs.Mode, ...
    [1 2 3]);

modeIndex = round( ...
    controlJobs.Mode(validMode));

controlJobs.RelativeDeadline_s(validMode) = ...
    relativeDeadlineLookup_s(modeIndex);

controlJobs.AbsoluteDeadline_s = ...
    controlJobs.ReleaseTime_s ...
    + controlJobs.RelativeDeadline_s;

controlJobs.DeadlineMiss = ...
    controlJobs.CompletionTime_s ...
    > controlJobs.AbsoluteDeadline_s;

controlLateCount = sum( ...
    controlJobs.DeadlineMiss, ...
    "omitmissing");

controlDroppedJobs = scalarOrDefault( ...
    controlTask.NumDropped, ...
    numel(finiteColumn(controlTask.DropTime)));

controlOverrunCount = scalarOrDefault( ...
    controlTask.NumOverran, ...
    numel(finiteColumn(controlTask.OverrunTime)));

controlReleasedJobs = ...
    height(controlJobs) + controlDroppedJobs;

controlDeadlineMissCount = ...
    controlLateCount + controlDroppedJobs;

controlDeadlineMissPercent = percentage( ...
    controlDeadlineMissCount, ...
    controlReleasedJobs);

%% Completed LoadTask jobs

loadJobs = completedJobs(loadTask);

loadJobs.Mode = sampleHeld( ...
    modeSignal.Time_s, ...
    modeSignal.Data, ...
    loadJobs.ReleaseTime_s);

loadDeadline_s = 0.050;

loadLateCount = sum( ...
    loadJobs.ResponseTime_s > loadDeadline_s);

loadDroppedJobs = scalarOrDefault( ...
    loadTask.NumDropped, ...
    numel(finiteColumn(loadTask.DropTime)));

loadOverrunCount = scalarOrDefault( ...
    loadTask.NumOverran, ...
    numel(finiteColumn(loadTask.OverrunTime)));

loadReleasedJobs = ...
    height(loadJobs) + loadDroppedJobs;

loadDeadlineMissCount = ...
    loadLateCount + loadDroppedJobs;

loadDeadlineMissPercent = percentage( ...
    loadDeadlineMissCount, ...
    loadReleasedJobs);

%% Controller-mode occupancy

validModes = modeSignal.Data( ...
    isfinite(modeSignal.Data));

lowPercent = ...
    100*mean(validModes == 1);

mediumPercent = ...
    100*mean(validModes == 2);

highPercent = ...
    100*mean(validModes == 3);

%% Actual completed-job CPU demand

controlCpuUtilization_pct = ...
    100*sum(controlJobs.ExecutionTime_s) ...
    / metadata.StopTime_s;

loadCpuUtilization_pct = ...
    100*sum(loadJobs.ExecutionTime_s) ...
    / metadata.StopTime_s;

% constant cpu utilization
communicationTaskExecutionTime_s = 0.0005;
communicationTaskPeriod_s = 0.005;

supervisorExecutionTime_s = 0.00005;
supervisorPeriod_s = 0.010;

supervisorCpuUtilization_pct = ...
    100*supervisorExecutionTime_s ...
    / supervisorPeriod_s;

communicationCpuUtilization_pct = 100 * communicationTaskExecutionTime_s / communicationTaskPeriod_s;

nominalCpuUtilization_pct = controlCpuUtilization_pct + ...
                            loadCpuUtilization_pct + ...
                            communicationCpuUtilization_pct + ...
                            supervisorCpuUtilization_pct;
nominalCpuUtilization = nominalCpuUtilization_pct / 100;
%% Saved raw artifact

runArtifact = struct();

runArtifact.schema_version = 1;
runArtifact.phase = "3";
runArtifact.policy = metadata.Policy;

runArtifact.scenarioName = metadata.Scenario;
runArtifact.environmentName = metadata.Environment;
runArtifact.loadCase = metadata.LoadCase;
runArtifact.loadExecutionTime_ms = ...
    metadata.LoadExecutionTime_ms;

runArtifact.results = results;
runArtifact.reference = reference;
runArtifact.taskData = taskData;

runArtifact.mode = modeSignal;
runArtifact.selectedControlDuration = ...
    selectedDurationSignal;

runArtifact.controlJobs = controlJobs;
runArtifact.loadJobs = loadJobs;

runArtifact.controlDropTime_s = ...
    finiteColumn(controlTask.DropTime);

runArtifact.controlOverrunTime_s = ...
    finiteColumn(controlTask.OverrunTime);

runArtifact.loadDropTime_s = ...
    finiteColumn(loadTask.DropTime);

runArtifact.loadOverrunTime_s = ...
    finiteColumn(loadTask.OverrunTime);

runArtifact.randomSeed = metadata.RandomSeed;
runArtifact.stopTime_s = metadata.StopTime_s;

%% Aggregate summary row

record = struct();

record.Policy = metadata.Policy;
record.Scenario = metadata.Scenario;
record.Environment = metadata.Environment;
record.LoadCase = metadata.LoadCase;
record.LoadExecution_ms = ...
    metadata.LoadExecutionTime_ms;

record.LowModePercent = lowPercent;
record.MediumModePercent = mediumPercent;
record.HighModePercent = highPercent;

record.ControlReleaseCount = controlReleasedJobs;
record.NominalUtilization = ...
    nominalCpuUtilization;
record.communicationCpuUtilization_pct = ...
communicationCpuUtilization_pct;

record.supervisorCpuUtilization_pct = ...
    supervisorCpuUtilization_pct;

record.ControlCpuUtilization_pct = ...
    controlCpuUtilization_pct;

record.ControlMeanResponse_ms = ...
    1e3*finiteMean(controlJobs.ResponseTime_s);

record.ControlP95Response_ms = ...
    1e3*empiricalPercentile( ...
        controlJobs.ResponseTime_s, 95);

record.ControlMaximumResponse_ms = ...
    1e3*finiteMaximum( ...
        controlJobs.ResponseTime_s);

record.ControlDeadlineMissPercent = ...
    controlDeadlineMissPercent;

record.ControlOverrunCount = ...
    controlOverrunCount;

record.ControlDroppedJobs = ...
    controlDroppedJobs;

record.LoadCpuUtilization_pct = ...
    loadCpuUtilization_pct;

record.LoadMeanResponse_ms = ...
    1e3*finiteMean(loadJobs.ResponseTime_s);

record.LoadP95Response_ms = ...
    1e3*empiricalPercentile( ...
        loadJobs.ResponseTime_s, 95);

record.LoadMaximumResponse_ms = ...
    1e3*finiteMaximum( ...
        loadJobs.ResponseTime_s);

record.LoadDeadlineMissPercent = ...
    loadDeadlineMissPercent;

record.LoadOverrunCount = ...
    loadOverrunCount;

record.LoadDroppedJobs = ...
    loadDroppedJobs;

record.SpeedRMS_mps = ...
    finiteRms(results.ev_mps);

record.LateralRMS_m = ...
    finiteRms(results.ey_m);

record.HeadingRMS_deg = ...
    rad2deg(finiteRms(results.epsi_rad));

record.RandomSeed = metadata.RandomSeed;
record.Status = "completed";
record.RunFile = "";

summaryRow = struct2table(record);

end


function signal = getLoggedSignal(logs, signalName)

element = logs.get(signalName);

signal = struct();

signal.Time_s = reshape( ...
    squeeze(double(element.Values.Time)), ...
    [], ...
    1);

signal.Data = reshape( ...
    squeeze(double(element.Values.Data)), ...
    [], ...
    1);

end


function jobs = completedJobs(task)

endTime_s = double(task.EndTime(:));
duration_s = double(task.Duration(:));
responseTime_s = double(task.Turnaround(:));

numberOfJobs = min([ ...
    numel(endTime_s), ...
    numel(duration_s), ...
    numel(responseTime_s)]);

endTime_s = endTime_s(1:numberOfJobs);
duration_s = duration_s(1:numberOfJobs);
responseTime_s = responseTime_s(1:numberOfJobs);

valid = ...
    isfinite(endTime_s) ...
    & isfinite(duration_s) ...
    & isfinite(responseTime_s);

endTime_s = endTime_s(valid);
duration_s = duration_s(valid);
responseTime_s = responseTime_s(valid);

releaseTime_s = ...
    endTime_s - responseTime_s;

jobs = table( ...
    releaseTime_s, ...
    endTime_s, ...
    duration_s, ...
    responseTime_s, ...
    'VariableNames', { ...
        'ReleaseTime_s', ...
        'CompletionTime_s', ...
        'ExecutionTime_s', ...
        'ResponseTime_s'});

end


function task = findTask(taskData, taskName)

taskNames = string({taskData.Name});

taskIndex = find( ...
    strcmpi(taskNames, taskName), ...
    1, ...
    "first");

assert( ...
    ~isempty(taskIndex), ...
    "Task '%s' was not found.", ...
    taskName);

task = taskData(taskIndex);

end


function sampledData = ...
    sampleHeld(sourceTime_s, sourceData, queryTime_s)

sourceTime_s = double(sourceTime_s(:));
sourceData = double(sourceData(:));
queryTime_s = double(queryTime_s(:));

[sourceTime_s, uniqueIndices] = unique( ...
    sourceTime_s, ...
    "last");

sourceData = sourceData(uniqueIndices);

sampledData = interp1( ...
    sourceTime_s, ...
    sourceData, ...
    queryTime_s, ...
    "previous", ...
    "extrap");

sampledData = sampledData(:);

end


function value = percentage(count, total)

if total == 0
    value = NaN;
else
    value = 100*count/total;
end

end


function value = scalarOrDefault(inputValue, defaultValue)

if isempty(inputValue) || ~isfinite(inputValue(1))
    value = defaultValue;
else
    value = double(inputValue(1));
end

end


function values = finiteColumn(inputValues)

values = double(inputValues(:));
values = values(isfinite(values));

end


function value = finiteMean(values)

values = finiteColumn(values);

if isempty(values)
    value = NaN;
else
    value = mean(values);
end

end


function value = finiteMaximum(values)

values = finiteColumn(values);

if isempty(values)
    value = NaN;
else
    value = max(values);
end

end


function value = finiteRms(values)

values = finiteColumn(values);

if isempty(values)
    value = NaN;
else
    value = sqrt(mean(values.^2));
end

end


function value = empiricalPercentile(values, percentile)

values = sort(finiteColumn(values));

if isempty(values)
    value = NaN;
    return;
end

sampleIndex = max( ...
    1, ...
    ceil((percentile/100)*numel(values)));

value = values(sampleIndex);

end