function figures = plot_open_loop_drive_test(resultsSource)
%PLOT_OPEN_LOOP_DRIVE_TEST Plot saved open-loop drive-test results.

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

figures.air_drag = figure;
hold on;
for k = 1:numel(results)
    plot(results(k).time_s, results(k).Fax_N, linestyles{k});
end
grid on;
xlabel("Time (s)");
ylabel("Drag Force, Fax (N)");
title("Open-loop response to constant drive torque (Air drag force)");
legend(labels, Location="best");

figures.acceleration = figure;
hold on;
for k = 1:numel(results)
    plot(results(k).ax_time_s, results(k).ax_mps2, linestyles{k});
end
grid on;
xlabel("Time (s)");
ylabel("Acceleration, a_x (m/s2)");
title("Open-loop response to constant drive torque (acceleration)");
legend(labels, Location="best");

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
