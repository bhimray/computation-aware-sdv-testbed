function figures = plot_phase2_3_results( ...
    results, reference, taskData, ...
    scenarioName, environmentName, loadCase)

time_s = results.time_s;

scenarioTitle = replace(string(scenarioName), "_", " ");
environmentTitle = replace(string(environmentName), "_", " ");

%% Control performance

figures.control = figure( ...
    Name="Phase 2.3 control performance", ...
    Color="w", ...
    Position=[100 60 1300 800]);

layout = tiledlayout(figures.control, 2, 3);
layout.TileSpacing = "compact";
layout.Padding = "compact";

nexttile;
plot(time_s, results.ev_mps, LineWidth=1.2);
yline(0, "k-");
grid on;
xlabel("Time (s)");
ylabel("e_v (m/s)");
title("Speed tracking error");

nexttile;
plot(time_s, results.ey_m, LineWidth=1.2);
yline(0, "k-");
grid on;
xlabel("Time (s)");
ylabel("e_y (m)");
title("Lateral tracking error");

nexttile;
plot(time_s, rad2deg(results.epsi_rad), LineWidth=1.2);
yline(0, "k-");
grid on;
xlabel("Time (s)");
ylabel("e_\psi (deg)");
title("Heading tracking error");

nexttile;
plot( ...
    time_s, results.vx_mps, ...
    LineWidth=1.2, ...
    DisplayName="Measured");

hold on;

plot( ...
    time_s, results.vx_ref_mps, ...
    "--", ...
    LineWidth=1.2, ...
    DisplayName="Reference");

hold off;
grid on;
xlabel("Time (s)");
ylabel("V_x (m/s)");
title("Longitudinal speed");
legend(Location="best");

nexttile;
plot(time_s, results.yaw_rate_radps, LineWidth=1.2);
grid on;
xlabel("Time (s)");
ylabel("Yaw rate (rad/s)");
title("Yaw-rate response");

nexttile;
plot( ...
    reference(:,2), ...
    reference(:,3), ...
    "k--", ...
    LineWidth=1.3, ...
    DisplayName="Reference");

hold on;

plot( ...
    results.x_pos_m, ...
    results.y_pos_m, ...
    "b-", ...
    LineWidth=1.3, ...
    DisplayName="Vehicle");

hold off;
axis equal;
grid on;
xlabel("X (m)");
ylabel("Y (m)");
title("Vehicle trajectory");
legend(Location="best");

title( ...
    layout, ...
    "Phase 2.3: " + scenarioTitle + ...
    " — " + environmentTitle + ...
    " — " + string(loadCase));

%% Scheduler timing

numberOfTasks = numel(taskData);
taskNames = strings(numberOfTasks,1);
taskColors = lines(numberOfTasks);

figures.scheduler = figure( ...
    Name="Phase 2.3 scheduler timing", ...
    Color="w", ...
    Position=[130 80 1200 850]);

layout = tiledlayout(figures.scheduler, 3, 1);
layout.TileSpacing = "compact";
layout.Padding = "compact";

%% Completed-job execution times

nexttile;
hold on;

for taskIndex = 1:numberOfTasks

    taskNames(taskIndex) = ...
        string(taskData(taskIndex).Name);

    executionTime_ms = ...
        1e3*reshape(taskData(taskIndex).Duration, [], 1);

    completionTime_s = ...
        reshape(taskData(taskIndex).EndTime, [], 1);

    numberOfSamples = min( ...
        numel(executionTime_ms), ...
        numel(completionTime_s));

    if numberOfSamples > 0
        plot( ...
            completionTime_s(1:numberOfSamples), ...
            executionTime_ms(1:numberOfSamples), ...
            ".-", ...
            Color=taskColors(taskIndex,:), ...
            LineWidth=1.1, ...
            MarkerSize=10, ...
            DisplayName=taskNames(taskIndex));
    end
end

hold off;
grid on;
xlabel("Completion time (s)");
ylabel("Execution time (ms)");
title("Completed-job execution time");
legend(Location="best");

%% Completed-job response times

nexttile;
hold on;

for taskIndex = 1:numberOfTasks

    responseTime_ms = ...
        1e3*reshape(taskData(taskIndex).Turnaround, [], 1);

    completionTime_s = ...
        reshape(taskData(taskIndex).EndTime, [], 1);

    numberOfSamples = min( ...
        numel(responseTime_ms), ...
        numel(completionTime_s));

    if numberOfSamples > 0
        plot( ...
            completionTime_s(1:numberOfSamples), ...
            responseTime_ms(1:numberOfSamples), ...
            ".-", ...
            Color=taskColors(taskIndex,:), ...
            LineWidth=1.1, ...
            MarkerSize= 10, ...
            DisplayName=taskNames(taskIndex));
    end

    deadline_ms = taskDeadline_ms(taskNames(taskIndex));

    yline( ...
        deadline_ms, ...
        ":", ...
        Color=taskColors(taskIndex,:), ...
        LineWidth=1.1, ...
        DisplayName=taskNames(taskIndex) + " deadline");
end

hold off;
grid on;
xlabel("Completion time (s)");
ylabel("Response time (ms)");
title("Completed-job response time");
legend(Location="best");

%% Dropped and overrun task instances

nexttile;
hold on;

for taskIndex = 1:numberOfTasks

    droppedTime_s = ...
        reshape(taskData(taskIndex).DropTime, [], 1);

    overrunTime_s = ...
        reshape(taskData(taskIndex).OverrunTime, [], 1);

    if ~isempty(droppedTime_s)
        scatter( ...
            droppedTime_s, ...
            taskIndex*ones(size(droppedTime_s)), ...
            55, ...
            "rx", ...
            LineWidth=1.5, ...
            DisplayName=taskNames(taskIndex) + " dropped");
    end

    if ~isempty(overrunTime_s)
        scatter( ...
            overrunTime_s, ...
            taskIndex*ones(size(overrunTime_s)), ...
            45, ...
            "^", ...
            MarkerEdgeColor=taskColors(taskIndex,:), ...
            DisplayName=taskNames(taskIndex) + " overrun");
    end
end

hold off;
grid on;
xlabel("Time (s)");
ylabel("Task");
yticks(1:numberOfTasks);
yticklabels(taskNames);
ylim([0.5, numberOfTasks + 0.5]);
title("Dropped and overrun task instances");
legend(Location="bestoutside");

title( ...
    layout, ...
    "Scheduler Timing: " + scenarioTitle + ...
    " — " + environmentTitle + ...
    " — " + string(loadCase));

end

function deadline_ms = taskDeadline_ms(taskName)

switch string(taskName)
    case "CommTask"
        deadline_ms = 5;

    case "ControlTask"
        deadline_ms = 10;

    case "LoadTask"
        deadline_ms = 50;

    otherwise
        deadline_ms = NaN;
end

end