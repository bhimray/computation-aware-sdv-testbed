function executionLog = extract_controller_execution_log( ...
    logs, eventTable, executionValidation, nominalSampleTime_s)
%EXTRACT_CONTROLLER_EXECUTION_LOG One row per actual controller execution.

arguments
    logs
    eventTable table
    executionValidation (1,1) struct
    nominalSampleTime_s (1,1) double {mustBePositive}
end

actualTime_s = ...
    executionValidation.actual_execution_times_s(:);
numberOfExecutions = numel(actualTime_s);

assert(height(eventTable) >= numberOfExecutions, ...
    "The event table is shorter than the execution log.");

eventTable = eventTable(1:numberOfExecutions,:);

solveTime_s = sampleHeldSignal( ...
    logs, "solve_time", actualTime_s);
solverStatus = sampleHeldSignal( ...
    logs, "solve_status", actualTime_s);
torque_Nm = sampleHeldSignal( ...
    logs, "torque_opt", actualTime_s);
steering_rad = sampleHeldSignal( ...
    logs, "steering_angle_opt", actualTime_s);

actualInterval_s = [NaN; diff(actualTime_s)];
actualJitter_s = ...
    actualInterval_s - nominalSampleTime_s;

executionLog = table( ...
    eventTable.EventIndex, ...
    eventTable.RequestedTime_s, ...
    eventTable.AppliedTime_s, ...
    actualTime_s, ...
    actualTime_s - eventTable.AppliedTime_s, ...
    actualInterval_s, ...
    actualJitter_s, ...
    solveTime_s, ...
    solverStatus, ...
    torque_Nm, ...
    steering_rad, ...
    VariableNames=[ ...
        "EventIndex"
        "RequestedTime_s"
        "ScheduledTime_s"
        "ActualTime_s"
        "SchedulingError_s"
        "ActualInterval_s"
        "ActualJitter_s"
        "SolveTime_s"
        "SolverStatus"
        "Torque_Nm"
        "Steering_rad"]);

assert(height(executionLog) == executionValidation.actual_count, ...
    "The controller execution log has the wrong number of rows.");

end

function data = sampleHeldSignal(logs, signalName, targetTime_s)
%SAMPLEHELDSIGNAL Sample a scalar held signal at execution instants.

availableSignals = string(logs.getElementNames);
assert(any(availableSignals == signalName), ...
    "Logged signal '%s' was not found.", signalName);

signal = logs.get(signalName).Values;
sourceTime_s = reshape(double(signal.Time), [], 1);
sourceData = reshape(squeeze(double(signal.Data)), [], 1);

assert(numel(sourceTime_s) == numel(sourceData), ...
    "Logged signal '%s' is not scalar-valued.", signalName);

[sourceTime_s, uniqueIndex] = unique(sourceTime_s, "last");
sourceData = sourceData(uniqueIndex);

if isscalar(sourceTime_s)
    data = repmat(sourceData, numel(targetTime_s), 1);
else
    data = interp1( ...
        sourceTime_s, sourceData, targetTime_s, ...
        "previous", "extrap");
end

data = reshape(data, [], 1);

end
