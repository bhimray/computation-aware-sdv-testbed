function figureHandle = schedulerProbe(probe, options)
%SCHEDULERPROBE Plot a reusable Phase 2/3 scheduler-effect probe.

arguments
    probe (1,1) struct
    options.ComputedTorqueScale (1,1) double = 0.5
    options.AppliedTorqueScale (1,1) double = 1.0
    options.ComputedSteeringScale (1,1) double = 180/pi
    options.AppliedSteeringScale (1,1) double = 1/24
    options.Title (1,1) string = ""
    options.Visible (1,1) logical = true
end

visibility = "off";
if options.Visible
    visibility = "on";
end

figureHandle = figure( ...
    Name="Scheduler-effect probe", ...
    Color="white", ...
    Position=[70 35 1500 1050], ...
    Visible=visibility);

layout = tiledlayout(figureHandle, 5, 2, ...
    TileSpacing="compact", Padding="compact");
timeAxes = gobjects(7,1);

%% Command age and scheduler events

schedulerAxes = nexttile(layout, [1 2]);
timeAxes(1) = schedulerAxes;
hold(schedulerAxes, "on");

plot(schedulerAxes, probe.time_s, ...
    1e3*probe.command_hold_age_s, ...
    LineWidth=1.3, DisplayName="Command hold age");

if ~isempty(probe.controlPeriodTime_s)
    stairs(schedulerAxes, probe.controlPeriodTime_s, ...
        1e3*probe.controlPeriod_s, "--", ...
        Color=[0.35 0.35 0.35], LineWidth=1.1, ...
        DisplayName="Active control period");
end

plot(schedulerAxes, probe.controlCompletionTime_s, ...
    zeros(size(probe.controlCompletionTime_s)), ...
    LineStyle="none", Marker="|", MarkerSize=10, ...
    Color=[0.20 0.60 0.30], ...
    DisplayName="Control completion");

controlTask = probe.tasks(string({probe.tasks.Name}) == "ControlTask");
finiteAge_ms = 1e3*probe.command_hold_age_s( ...
    isfinite(probe.command_hold_age_s));
period_ms = 1e3*probe.controlPeriod_s(isfinite(probe.controlPeriod_s));
markerHeight_ms = 1.08*max([1; finiteAge_ms; period_ms]);

scatter(schedulerAxes, controlTask.OverrunTime_s, ...
    markerHeight_ms*ones(size(controlTask.OverrunTime_s)), ...
    45, "^", MarkerEdgeColor=[0.85 0.52 0.05], ...
    LineWidth=1.2, DisplayName="Control overrun");

scatter(schedulerAxes, controlTask.DropTime_s, ...
    markerHeight_ms*ones(size(controlTask.DropTime_s)), ...
    55, "x", MarkerEdgeColor=[0.82 0.12 0.12], ...
    LineWidth=1.5, DisplayName="Control drop");

hold(schedulerAxes, "off");
formatTimeAxes(schedulerAxes, probe.window_s);
ylim(schedulerAxes, [0 1.16*markerHeight_ms]);
ylabel(schedulerAxes, "Age or period (ms)");
title(schedulerAxes, "Command Hold Age and Control-Task Events");
legend(schedulerAxes, Location="bestoutside");
shadeExposureWindows(schedulerAxes, probe.eventWindows);

%% Computed and applied torque

torqueAxes = nexttile(layout);
timeAxes(2) = torqueAxes;
stairs(torqueAxes, probe.time_s, ...
    options.ComputedTorqueScale*probe.torque_Nm, "--", ...
    LineWidth=1.1, DisplayName="Controller-computed");
hold(torqueAxes, "on");
stairs(torqueAxes, probe.torque_applied_time_s, ...
    options.AppliedTorqueScale*probe.torque_applied_Nm, ...
    LineWidth=1.5, DisplayName="Plant-applied");
hold(torqueAxes, "off");
formatTimeAxes(torqueAxes, probe.window_s);
ylabel(torqueAxes, "Torque (N m)");
title(torqueAxes, "Torque Publication and Hold");
legend(torqueAxes, Location="best");
shadeExposureWindows(torqueAxes, probe.eventWindows);

%% Computed and applied steering

steeringAxes = nexttile(layout);
timeAxes(3) = steeringAxes;
stairs(steeringAxes, probe.time_s, ...
    options.ComputedSteeringScale*probe.steering_angle_rad, "--", ...
    LineWidth=1.1, DisplayName="Controller-computed");
hold(steeringAxes, "on");
stairs(steeringAxes, probe.steering_applied_time_s, ...
    options.AppliedSteeringScale*probe.steering_applied_angle_deg, ...
    LineWidth=1.5, DisplayName="Plant-applied");
hold(steeringAxes, "off");
formatTimeAxes(steeringAxes, probe.window_s);
ylabel(steeringAxes, "Steering angle (deg)");
title(steeringAxes, "Steering Publication and Hold");
legend(steeringAxes, Location="bestoutside");
shadeExposureWindows(steeringAxes, probe.eventWindows);

%% Longitudinal response

longitudinalAxes = nexttile(layout);
timeAxes(4) = longitudinalAxes;
yyaxis(longitudinalAxes, "left");
plot(longitudinalAxes, probe.time_s, probe.vx_mps, ...
    LineWidth=1.2, DisplayName="Measured speed");
hold(longitudinalAxes, "on");
plot(longitudinalAxes, probe.time_s, probe.vx_ref_mps, "--", ...
    LineWidth=1.1, DisplayName="Reference speed");
ylabel(longitudinalAxes, "Speed (m/s)");
yyaxis(longitudinalAxes, "right");
plot(longitudinalAxes, probe.time_s, probe.ev_mps, ...
    LineWidth=1.1, DisplayName="Speed error");
yline(longitudinalAxes, 0, ":", HandleVisibility="off");
ylabel(longitudinalAxes, "e_v (m/s)");
hold(longitudinalAxes, "off");
formatTimeAxes(longitudinalAxes, probe.window_s);
title(longitudinalAxes, "Longitudinal Response");
legend(longitudinalAxes, Location="best");
yyaxis(longitudinalAxes, "left");
shadeExposureWindows(longitudinalAxes, probe.eventWindows);

%% Lateral response

lateralAxes = nexttile(layout);
timeAxes(5) = lateralAxes;
yyaxis(lateralAxes, "left");
plot(lateralAxes, probe.time_s, probe.ey_m, ...
    LineWidth=1.2, DisplayName="Lateral error");
yline(lateralAxes, 0, ":", HandleVisibility="off");
ylabel(lateralAxes, "e_y (m)");
hold(lateralAxes, "on");
yyaxis(lateralAxes, "right");
plot(lateralAxes, probe.time_s, rad2deg(probe.epsi_rad), ...
    LineWidth=1.2, DisplayName="Heading error");
yline(lateralAxes, 0, ":", HandleVisibility="off");
ylabel(lateralAxes, "e_psi (deg)");
hold(lateralAxes, "off");
formatTimeAxes(lateralAxes, probe.window_s);
title(lateralAxes, "Lateral Tracking Response");
legend(lateralAxes, Location="bestoutside");
yyaxis(lateralAxes, "left");
shadeExposureWindows(lateralAxes, probe.eventWindows);

%% Completed-job response time

responseAxes = nexttile(layout);
timeAxes(6) = responseAxes;
hold(responseAxes, "on");
taskColors = lines(numel(probe.tasks));
hasResponseData = false;
for taskIndex = 1:numel(probe.tasks)
    task = probe.tasks(taskIndex);
    if ~isempty(task.CompletionTime_s)
        hasResponseData = true;
        plot(responseAxes, task.CompletionTime_s, task.ResponseTime_ms, ...
            ".-", Color=taskColors(taskIndex,:), ...
            LineWidth=1.0, MarkerSize=10, DisplayName=task.Name);
    end
end
hold(responseAxes, "off");
formatTimeAxes(responseAxes, probe.window_s);
ylabel(responseAxes, "Response time (ms)");
title(responseAxes, "Completed-Job Response Time");
if hasResponseData
    legend(responseAxes, Location="best");
end
shadeExposureWindows(responseAxes, probe.eventWindows);

%% Dropped and overrun task releases

eventAxes = nexttile(layout);
timeAxes(7) = eventAxes;
hold(eventAxes, "on");
dropLegend = scatter(eventAxes, nan, nan, 55, "x", ...
    MarkerEdgeColor=[0.82 0.12 0.12], LineWidth=1.5, ...
    DisplayName="Dropped");
overrunLegend = scatter(eventAxes, nan, nan, 45, "^", ...
    MarkerEdgeColor=[0.85 0.52 0.05], LineWidth=1.2, ...
    DisplayName="Overrun");

for taskIndex = 1:numel(probe.tasks)
    task = probe.tasks(taskIndex);
    scatter(eventAxes, task.DropTime_s, ...
        taskIndex*ones(size(task.DropTime_s)), 55, "x", ...
        MarkerEdgeColor=[0.82 0.12 0.12], LineWidth=1.5, ...
        HandleVisibility="off");
    scatter(eventAxes, task.OverrunTime_s, ...
        taskIndex*ones(size(task.OverrunTime_s)), 45, "^", ...
        MarkerEdgeColor=[0.85 0.52 0.05], LineWidth=1.2, ...
        HandleVisibility="off");
end
hold(eventAxes, "off");
formatTimeAxes(eventAxes, probe.window_s);
ylim(eventAxes, [0.5 numel(probe.tasks)+0.5]);
yticks(eventAxes, 1:numel(probe.tasks));
yticklabels(eventAxes, string({probe.tasks.Name}));
ylabel(eventAxes, "Task");
title(eventAxes, "Scheduler Events for All Tasks");
legend(eventAxes, [dropLegend overrunLegend], Location="bestoutside");
shadeExposureWindows(eventAxes, probe.eventWindows);

%% Local trajectory

trajectoryAxes = nexttile(layout, [1 2]);
plot(trajectoryAxes, probe.reference_x_m, probe.reference_y_m, "--", ...
    Color=[0.35 0.35 0.35], LineWidth=1.1, ...
    DisplayName="Reference path");
hold(trajectoryAxes, "on");
plotTrajectoryByExposure(trajectoryAxes, probe);
hold(trajectoryAxes, "off");
axis(trajectoryAxes, "equal");
grid(trajectoryAxes, "on");
xlabel(trajectoryAxes, "X (m)");
ylabel(trajectoryAxes, "Y (m)");
title(trajectoryAxes, "Local Trajectory by Scheduler Exposure");
legend(trajectoryAxes, Location="bestoutside");

linkaxes(timeAxes, "x");
xlim(timeAxes(1), probe.window_s);

figureTitle = options.Title;
if strlength(figureTitle) == 0
    figureTitle = sprintf( ...
        "Scheduler Probe: %.4f-%.4f s - %s - %s - %s", ...
        probe.window_s(1), probe.window_s(2), ...
        replace(probe.scenarioLabel, "_", " "), ...
        replace(probe.environmentLabel, "_", " "), ...
        replace(probe.loadLabel, "_", " "));
end
title(layout, figureTitle, Interpreter="none");

end


function formatTimeAxes(axesHandle, window_s)

grid(axesHandle, "on");
box(axesHandle, "on");
xlim(axesHandle, window_s);
xlabel(axesHandle, "Time (s)");

end


function shadeExposureWindows(axesHandle, eventWindows)

if isempty(eventWindows)
    return;
end

originalHold = ishold(axesHandle);
hold(axesHandle, "on");
for eventType = ["Overrun", "Drop"]
    rows = eventWindows(eventWindows.Type == eventType,:);
    if eventType == "Overrun"
        color = [1.00 0.72 0.15];
        alpha = 0.10;
    else
        color = [0.92 0.20 0.20];
        alpha = 0.12;
    end
    for rowIndex = 1:height(rows)
        region = xregion(axesHandle, rows.StartTime_s(rowIndex), ...
            rows.EndTime_s(rowIndex), FaceColor=color, ...
            FaceAlpha=alpha, EdgeAlpha=0, LineStyle="none");
        region.HandleVisibility = "off";
    end
end
if ~originalHold
    hold(axesHandle, "off");
end

end


function plotTrajectoryByExposure(axesHandle, probe)

status = ones(numel(probe.time_s),1);
for rowIndex = 1:height(probe.eventWindows)
    mask = probe.time_s >= probe.eventWindows.StartTime_s(rowIndex) ...
        & probe.time_s <= probe.eventWindows.EndTime_s(rowIndex);
    if probe.eventWindows.Type(rowIndex) == "Overrun"
        status(mask) = max(status(mask), 2);
    else
        status(mask) = 3;
    end
end

names = ["Normal", "Overrun exposure", "Drop exposure"];
colors = [0.00 0.45 0.74; 0.85 0.52 0.05; 0.82 0.12 0.12];
for statusIndex = 1:3
    plot(axesHandle, nan, nan, Color=colors(statusIndex,:), ...
        LineWidth=2, DisplayName=names(statusIndex));
end

segmentStart = [1; find(diff(status) ~= 0)+1];
segmentEnd = [segmentStart(2:end)-1; numel(status)];
for segmentIndex = 1:numel(segmentStart)
    first = segmentStart(segmentIndex);
    last = segmentEnd(segmentIndex);
    if first > 1
        first = first-1;
    end
    code = status(segmentStart(segmentIndex));
    plot(axesHandle, probe.x_pos_m(first:last), ...
        probe.y_pos_m(first:last), Color=colors(code,:), ...
        LineWidth=2, HandleVisibility="off");
end

end
