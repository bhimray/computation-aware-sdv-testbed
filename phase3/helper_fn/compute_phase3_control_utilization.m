function [meanUtilization, trace] = compute_phase3_control_utilization( ...
    durationSignal, activePeriodSignal, observationWindow_s)
%COMPUTE_PHASE3_CONTROL_UTILIZATION Time-weighted nominal C(t)/T_active(t).
% Signals have Time_s and Data columns, in seconds, held between samples.
% This is a demand estimate, not completed-job accounting or CPU busy time.

arguments
    durationSignal (1,1) struct
    activePeriodSignal (1,1) struct
    observationWindow_s (2,1) double
end

assert(all(isfinite(observationWindow_s)) ...
    && observationWindow_s(2) > observationWindow_s(1), ...
    "Phase3:InvalidUtilizationWindow", ...
    "CPU utilization requires a finite, positive observation window.");

[durationTime_s, executionTime_s] = signalColumns(durationSignal);
[periodTime_s, activePeriod_s] = signalColumns(activePeriodSignal);

assert(all(executionTime_s >= 0) && all(activePeriod_s > 0), ...
    "Phase3:InvalidUtilizationSignal", ...
    "Execution durations must be nonnegative and periods positive.");

assert(durationTime_s(1) <= observationWindow_s(2) ...
    && periodTime_s(1) <= observationWindow_s(2), ...
    "Phase3:InvalidUtilizationSignal", ...
    "Both utilization signals must begin within the observation window.");

% These are piecewise-constant configuration signals. Simulink may log the
% first sample after t = observationWindow_s(1), even though that initial
% value is already active from the beginning of the run. Extend the first
% value backward so the complete observation window is represented.
[durationTime_s, executionTime_s] = extendToWindowStart( ...
    durationTime_s, executionTime_s, observationWindow_s(1));
[periodTime_s, activePeriod_s] = extendToWindowStart( ...
    periodTime_s, activePeriod_s, observationWindow_s(1));

% Split at either signal's changes; never interpolate across a mode switch.
boundaries_s = unique([ ...
    observationWindow_s; durationTime_s; periodTime_s]);
boundaries_s = boundaries_s( ...
    boundaries_s >= observationWindow_s(1) ...
    & boundaries_s <= observationWindow_s(2));
intervalTime_s = boundaries_s(1:end-1);
intervalDuration_s = diff(boundaries_s);

correspondingExecutionTime_s = heldValues( ...
    durationTime_s, executionTime_s, intervalTime_s);
correspondingActivePeriod_s = heldValues( ...
    periodTime_s, activePeriod_s, intervalTime_s);
utilization = correspondingExecutionTime_s ./ correspondingActivePeriod_s;

% A terminal sample has zero duration and must not bias the mean.
meanUtilization = sum(utilization .* intervalDuration_s) ...
    / diff(observationWindow_s);

trace = struct( ...
    Time_s=intervalTime_s, ...
    IntervalEndTime_s=boundaries_s(2:end), ...
    ObservationWindow_s=observationWindow_s, ...
    ExecutionTime_s=correspondingExecutionTime_s, ...
    CorrespondingActivePeriod_s=correspondingActivePeriod_s, ...
    ControlUtilization=utilization, ...
    MeanControlUtilization=meanUtilization);

end


function [time_s, data] = extendToWindowStart( ...
    time_s, data, windowStart_s)

if time_s(1) > windowStart_s
    time_s = [windowStart_s; time_s];
    data = [data(1); data];
end

end


function [time_s, data] = signalColumns(signal)

time_s = double(signal.Time_s(:));
data = double(signal.Data(:));
assert(~isempty(time_s) && numel(time_s) == numel(data) ...
    && all(isfinite(time_s)) && all(isfinite(data)) ...
    && all(diff(time_s) >= 0), ...
    "Phase3:InvalidUtilizationSignal", ...
    "Utilization signals must be finite, aligned, and ordered by time.");

% Simulink can log pre/post-update values at the same timestamp.
[time_s, indices] = unique(time_s, "last");
data = data(indices);

end


function values = heldValues(time_s, data, queryTime_s)

if isscalar(time_s)
    values = repmat(data, numel(queryTime_s), 1);
else
    % Match the model's hold-final-value behavior after the last tag.
    values = interp1(time_s, data, queryTime_s, "previous", "extrap");
end

end
