function figureHandle = plot_test_track(trackSource)
%PLOT_TEST_TRACK Plot one generated Phase 0 test track.

track = loadTrack(trackSource);

figureHandle = figure("Name", "Test Track");

subplot(3,1,1);
plot(track.X_ref_m, track.Y_ref_m, "LineWidth", 1.5);
axis equal;
grid on;
xlabel("X (m)");
ylabel("Y (m)");
title("Test Track");

subplot(3,1,2);
plot(track.station_m, track.curvature_1pm, "LineWidth", 1.5);
grid on;
xlabel("Path distance, s (m)");
ylabel("Curvature (1/m)");
title("Reference Curvature");

subplot(3,1,3);
plot( ...
    track.station_m, track.local_speed_limit_mps, "k--", ...
    DisplayName="Local speed limit");
hold on;
plot( ...
    track.station_m, track.curvature_speed_limit_mps, "r:", ...
    DisplayName="Pass 1: curvature limit");
plot( ...
    track.station_m, track.forward_pass_speed_mps, "g-.", ...
    DisplayName="Pass 2: forward");
plot( ...
    track.station_m, track.vx_ref_mps, "b", ...
    LineWidth=1.8, DisplayName="Pass 3: final");
hold off;
grid on;
xlabel("Path distance, s (m)");
ylabel("Speed (m/s)");
title("Three-Pass Speed Profile");
legend(Location="best");

end

function track = loadTrack(source)
if isstruct(source)
    track = source;
    return;
end
source = string(source);
assert(isfile(source), "Track file does not exist: %s", source);
stored = load(source, "track");
assert(isfield(stored, "track"), ...
    "Track file does not contain track.");
track = stored.track;
end
