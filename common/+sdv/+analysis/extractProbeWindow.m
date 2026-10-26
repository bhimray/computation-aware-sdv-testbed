function probe = extractProbeWindow(runArtifact, window_s, options)
%EXTRACTPROBEWINDOW Compute reusable scheduler-probe data.

arguments
    runArtifact (1,1) struct
    window_s (1,2) double
    options.ControlPeriod_s (1,1) double = NaN
end

assert(window_s(1) < window_s(2), ...
    "window_s must be [startTime endTime].");

requiredArtifactFields = ["results", "reference", "taskData"];
assert(all(isfield(runArtifact, requiredArtifactFields)), ...
    "runArtifact must contain results, reference, and taskData.");

results = runArtifact.results;
requiredResultFields = [ ...
    "time_s", "vx_mps", "vx_ref_mps", "ev_mps", ...
    "ey_m", "epsi_rad", "x_pos_m", "y_pos_m", ...
    "torque_Nm", "steering_angle_rad", ...
    "torque_applied_time_s", "torque_applied_Nm", ...
    "steering_applied_time_s", "steering_applied_angle_deg"];

missing = setdiff(requiredResultFields, string(fieldnames(results)));
assert(isempty(missing), ...
    "Saved results are missing: %s", strjoin(missing, ", "));

time_s = toColumn(results.time_s);
controlMask = time_s >= window_s(1) & time_s <= window_s(2);
assert(any(controlMask), ...
    "No controller data exists inside the requested window.");

probe = struct();
probe.window_s = window_s;
probe.time_s = time_s(controlMask);
probe.vx_mps = toColumn(results.vx_mps(controlMask));
probe.vx_ref_mps = toColumn(results.vx_ref_mps(controlMask));
probe.ev_mps = toColumn(results.ev_mps(controlMask));
probe.ey_m = toColumn(results.ey_m(controlMask));
probe.epsi_rad = toColumn(results.epsi_rad(controlMask));
probe.x_pos_m = toColumn(results.x_pos_m(controlMask));
probe.y_pos_m = toColumn(results.y_pos_m(controlMask));
probe.torque_Nm = toColumn(results.torque_Nm(controlMask));
probe.steering_angle_rad = ...
    toColumn(results.steering_angle_rad(controlMask));

[probe.torque_applied_time_s, probe.torque_applied_Nm] = ...
    selectWindow(results.torque_applied_time_s, ...
    results.torque_applied_Nm, window_s);

[probe.steering_applied_time_s, ...
    probe.steering_applied_angle_deg] = ...
    selectWindow(results.steering_applied_time_s, ...
    results.steering_applied_angle_deg, window_s);

probe.scenarioLabel = artifactLabel( ...
    runArtifact, "scenarioName", "scenario");
probe.environmentLabel = artifactLabel( ...
    runArtifact, "environmentName", "environment");
probe.loadLabel = artifactLabel( ...
    runArtifact, "loadCase", "load");

probe.tasks = extractTasks(runArtifact.taskData, window_s);
taskNames = string({probe.tasks.Name}).';
controlIndex = find(taskNames == "ControlTask", 1);
assert(~isempty(controlIndex), "ControlTask was not found in taskData.");

controlTask = runArtifact.taskData(controlIndex);
controlCompletionTime_s = sort(toColumn(controlTask.EndTime));

probe.controlCompletionTime_s = controlCompletionTime_s( ...
    controlCompletionTime_s >= window_s(1) ...
    & controlCompletionTime_s <= window_s(2));
probe.eventWindows = buildExposureWindows(controlTask, window_s);
probe.command_hold_age_s = commandHoldAge( ...
    probe.time_s, controlCompletionTime_s, time_s(1));

[probe.controlPeriodTime_s, probe.controlPeriod_s] = ...
    controlPeriodTrace(runArtifact, window_s, options.ControlPeriod_s);

reference = runArtifact.reference;
if istable(reference)
    reference = table2array(reference);
end
assert(isnumeric(reference) && size(reference,2) >= 3, ...
    "reference must contain station, X, and Y columns.");
referenceMask = localReferenceMask( ...
    reference, probe.x_pos_m, probe.y_pos_m);
probe.reference_x_m = toColumn(reference(referenceMask,2));
probe.reference_y_m = toColumn(reference(referenceMask,3));

end


function tasks = extractTasks(taskData, window_s)

tasks = repmat(struct( ...
    Name="", CompletionTime_s=[], ResponseTime_ms=[], ...
    DropTime_s=[], OverrunTime_s=[]), numel(taskData), 1);

for taskIndex = 1:numel(taskData)
    completion = toColumn(taskData(taskIndex).EndTime);
    response = 1e3*toColumn(taskData(taskIndex).Turnaround);
    count = min(numel(completion), numel(response));
    completion = completion(1:count);
    response = response(1:count);
    keep = completion >= window_s(1) & completion <= window_s(2);

    tasks(taskIndex).Name = string(taskData(taskIndex).Name);
    tasks(taskIndex).CompletionTime_s = completion(keep);
    tasks(taskIndex).ResponseTime_ms = response(keep);
    tasks(taskIndex).DropTime_s = ...
        windowEvents(taskData(taskIndex).DropTime, window_s);
    tasks(taskIndex).OverrunTime_s = ...
        windowEvents(taskData(taskIndex).OverrunTime, window_s);
end

end


function [time_s, period_s] = ...
    controlPeriodTrace(runArtifact, window_s, explicitPeriod_s)

if isfinite(explicitPeriod_s)
    assert(explicitPeriod_s > 0, "ControlPeriod_s must be positive.");
    time_s = window_s(:);
    period_s = explicitPeriod_s*ones(2,1);
    return;
end

if isfield(runArtifact, "cpuUtilization") ...
        && isfield(runArtifact.cpuUtilization, "Time_s") ...
        && isfield(runArtifact.cpuUtilization, ...
        "CorrespondingActivePeriod_s")
    [time_s, period_s] = selectWindowHeld( ...
        runArtifact.cpuUtilization.Time_s, ...
        runArtifact.cpuUtilization.CorrespondingActivePeriod_s, ...
        window_s);
    return;
end

if isfield(runArtifact, "mode") ...
        && isfield(runArtifact.mode, "Time_s") ...
        && isfield(runArtifact.mode, "Data")
    periodLookup_s = [0.050; 0.020; 0.010];
    mode = round(toColumn(runArtifact.mode.Data));
    assert(all(ismember(mode, [1 2 3])), ...
        "Controller modes must be 1, 2, or 3.");
    [time_s, period_s] = selectWindowHeld( ...
        runArtifact.mode.Time_s, periodLookup_s(mode), window_s);
    return;
end

time_s = zeros(0,1);
period_s = zeros(0,1);

end


function [selectedTime_s, selectedData] = ...
    selectWindow(time_s, data, window_s)

time_s = toColumn(time_s);
data = toColumn(data);
count = min(numel(time_s), numel(data));
time_s = time_s(1:count);
data = data(1:count);
keep = time_s >= window_s(1) & time_s <= window_s(2);
selectedTime_s = time_s(keep);
selectedData = data(keep);

end


function [selectedTime_s, selectedData] = ...
    selectWindowHeld(time_s, data, window_s)

time_s = toColumn(time_s);
data = toColumn(data);
[time_s, indices] = unique(time_s, "last");
data = data(indices);

if isscalar(time_s)
    selectedTime_s = window_s(:);
    selectedData = repmat(data, 2, 1);
    return;
end

interior = time_s > window_s(1) & time_s < window_s(2);
selectedTime_s = [window_s(1); time_s(interior); window_s(2)];
selectedData = interp1( ...
    time_s, data, selectedTime_s, "previous", "extrap");

end


function eventTime_s = windowEvents(eventTime_s, window_s)

eventTime_s = toColumn(eventTime_s);
eventTime_s = eventTime_s( ...
    eventTime_s >= window_s(1) & eventTime_s <= window_s(2));

end


function eventWindows = buildExposureWindows(controlTask, window_s)

completionTime_s = sort(toColumn(controlTask.EndTime));
overrunTime_s = toColumn(controlTask.OverrunTime);
dropTime_s = toColumn(controlTask.DropTime);
eventTime_s = [overrunTime_s; dropTime_s];
eventType = [repmat("Overrun", numel(overrunTime_s), 1); ...
    repmat("Drop", numel(dropTime_s), 1)];

startTime_s = zeros(0,1);
endTime_s = zeros(0,1);
windowType = strings(0,1);

for eventIndex = 1:numel(eventTime_s)
    eventTime = eventTime_s(eventIndex);
    if eventTime > window_s(2)
        continue;
    end
    nextCompletion = find(completionTime_s > eventTime, 1, "first");
    if isempty(nextCompletion)
        recoveryTime = window_s(2);
    else
        recoveryTime = completionTime_s(nextCompletion);
    end
    clippedStart = max(eventTime, window_s(1));
    clippedEnd = min(recoveryTime, window_s(2));
    if clippedEnd > clippedStart
        startTime_s(end+1,1) = clippedStart; %#ok<AGROW>
        endTime_s(end+1,1) = clippedEnd; %#ok<AGROW>
        windowType(end+1,1) = eventType(eventIndex); %#ok<AGROW>
    end
end

eventWindows = table(startTime_s, endTime_s, windowType, ...
    VariableNames=["StartTime_s", "EndTime_s", "Type"]);
eventWindows = mergeExposureWindows(eventWindows);

end


function merged = mergeExposureWindows(windows)

merged = table(zeros(0,1), zeros(0,1), strings(0,1), ...
    VariableNames=["StartTime_s", "EndTime_s", "Type"]);

for eventType = ["Overrun", "Drop"]
    rows = sortrows(windows(windows.Type == eventType,:), "StartTime_s");
    if isempty(rows)
        continue;
    end
    first = rows.StartTime_s(1);
    last = rows.EndTime_s(1);
    for rowIndex = 2:height(rows)
        if rows.StartTime_s(rowIndex) <= last
            last = max(last, rows.EndTime_s(rowIndex));
        else
            merged(end+1,:) = {first, last, eventType}; %#ok<AGROW>
            first = rows.StartTime_s(rowIndex);
            last = rows.EndTime_s(rowIndex);
        end
    end
    merged(end+1,:) = {first, last, eventType}; %#ok<AGROW>
end

if ~isempty(merged)
    merged = sortrows(merged, "StartTime_s");
end

end


function age_s = commandHoldAge(sampleTime_s, completionTime_s, initialTime_s)

publicationTime_s = unique([initialTime_s; completionTime_s]);
age_s = nan(size(sampleTime_s));
for sampleIndex = 1:numel(sampleTime_s)
    previous = find(publicationTime_s <= sampleTime_s(sampleIndex), ...
        1, "last");
    if ~isempty(previous)
        age_s(sampleIndex) = sampleTime_s(sampleIndex) ...
            - publicationTime_s(previous);
    end
end

end


function mask = localReferenceMask(reference, xPosition_m, yPosition_m)

xMinimum = min(xPosition_m);
xMaximum = max(xPosition_m);
yMinimum = min(yPosition_m);
yMaximum = max(yPosition_m);
margin_m = max(5, 0.25*max(xMaximum-xMinimum, yMaximum-yMinimum));
mask = reference(:,2) >= xMinimum-margin_m ...
    & reference(:,2) <= xMaximum+margin_m ...
    & reference(:,3) >= yMinimum-margin_m ...
    & reference(:,3) <= yMaximum+margin_m;
if ~any(mask)
    mask = true(size(reference,1),1);
end

end


function label = artifactLabel(artifact, fieldName, fallback)

if isfield(artifact, fieldName)
    label = string(artifact.(fieldName));
else
    label = string(fallback);
end

end


function values = toColumn(values)

values = reshape(squeeze(double(values)), [], 1);

end
