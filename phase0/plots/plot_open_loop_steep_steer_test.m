function figures = plot_open_loop_steep_steer_test(resultsSource)
%PLOT_OPEN_LOOP_STEEP_STEER_TEST Plot saved step-steer results.

results = loadResults(resultsSource);
linestyles = {'-','--',':','-.', '--*'};
labels = strings(1, numel(results));

figures.velocity = figure;
hold on;
for k = 1:numel(results)
    plot(results(k).time_s, results(k).vx_mps, linestyles{k});
    labels(k) = sprintf("%d N.m", results(k).torque_Nm);
end
grid on;
xlabel("Time (s)");
ylabel("Longitudinal speed, V_x (m/s)");
title("Open-loop response to constant drive torque (velocity)");
legend(labels, Location="best");

figures.yaw_rate = figure;
hold on;
for k = 1:numel(results)
    plot(results(k).time_s, results(k).yaw_rate_radps, linestyles{k});
end
grid on;
xlabel("Time (s)");
ylabel("Yaw rate (rad/s)");
title("Open-loop response of yaw rate to constant velocity");
legend(labels, Location="best");

figures.yaw_angle = figure;
hold on;
for k = 1:numel(results)
    plot(results(k).time_s, results(k).yaw_angle_rad, linestyles{k});
end
grid on;
xlabel("Time (s)");
ylabel("Yaw angle (rad)");
title("Open-loop response of yaw angle at const velocity");
legend(labels, Location="best");

%% Optional acceleration plot retained from the original run script.
% figures.acceleration = figure;
% hold on;
% for k = 1:numel(results)
%     plot(results(k).time_s, results(k).ax_mps2, linestyles{k});
% end
% grid on;
% xlabel("Time (s)");
% ylabel("Acceleration, a_x (m/s2)");
% title("Open-loop response to constant drive torque (acceleration)");
% legend(labels, Location="best");

end

function results = loadResults(source)
if isstruct(source)
    results = source;
    return;
end
source = string(source);
assert(isfile(source), "Result file does not exist: %s", source);
stored = load(source, "results");
assert(isfield(stored, "results"), ...
    "Result file does not contain results.");
results = stored.results;
end
