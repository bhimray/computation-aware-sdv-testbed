function monitor = computePerformanceMonitor( ...
    results, scenario, initialYaw_rad)
%COMPUTEPERFORMANCEMONITOR Evaluate tracking on the plant time grid.
%
% The monitor is independent of the controller's held reference/error
% outputs. It projects measured plant position onto the reference path and
% reconstructs yaw from measured yaw rate.

arguments
    results (1,1) struct
    scenario (1,1) struct
    initialYaw_rad (1,1) double {mustBeFinite}
end

requiredResultFields = [ ...
    "time_s", "x_pos_m", "y_pos_m", ...
    "vx_mps", "yaw_rate_radps"];
missingResultFields = setdiff( ...
    requiredResultFields, string(fieldnames(results)));
assert(isempty(missingResultFields), ...
    "Missing performance-monitor inputs: %s", ...
    strjoin(missingResultFields, ", "));

requiredScenarioFields = [ ...
    "station_m", "X_ref_m", "Y_ref_m", ...
    "psi_ref_rad", "vx_ref_mps"];
missingScenarioFields = setdiff( ...
    requiredScenarioFields, string(fieldnames(scenario)));
assert(isempty(missingScenarioFields), ...
    "Missing scenario fields: %s", ...
    strjoin(missingScenarioFields, ", "));

time_s = results.time_s(:);
x_m = results.x_pos_m(:);
y_m = results.y_pos_m(:);
vx_mps = results.vx_mps(:);
yawRate_radps = results.yaw_rate_radps(:);

sampleCount = numel(time_s);
assert(all([numel(x_m), numel(y_m), numel(vx_mps), ...
        numel(yawRate_radps)] == sampleCount), ...
    "Plant signals are not aligned on the performance timeline.");
assert(all(isfinite([time_s; x_m; y_m; vx_mps; yawRate_radps])), ...
    "Performance-monitor inputs contain NaN or Inf.");
assert(all(diff(time_s) > 0), ...
    "Performance-monitor time must be strictly increasing.");

referenceX_m = zeros(sampleCount,1);
referenceY_m = zeros(sampleCount,1);
referenceYaw_rad = zeros(sampleCount,1);
referenceSpeed_mps = zeros(sampleCount,1);
referenceStation_m = zeros(sampleCount,1);
trackIndex = ones(sampleCount,1);

segmentIndex = 1;
for sampleIndex = 1:sampleCount
    [segmentIndex, fraction] = projectOntoPath( ...
        x_m(sampleIndex), y_m(sampleIndex), ...
        scenario, segmentIndex);

    nextIndex = segmentIndex + 1;
    referenceX_m(sampleIndex) = interpolateLinear( ...
        scenario.X_ref_m(segmentIndex), ...
        scenario.X_ref_m(nextIndex), fraction);
    referenceY_m(sampleIndex) = interpolateLinear( ...
        scenario.Y_ref_m(segmentIndex), ...
        scenario.Y_ref_m(nextIndex), fraction);
    referenceSpeed_mps(sampleIndex) = interpolateLinear( ...
        scenario.vx_ref_mps(segmentIndex), ...
        scenario.vx_ref_mps(nextIndex), fraction);
    referenceStation_m(sampleIndex) = interpolateLinear( ...
        scenario.station_m(segmentIndex), ...
        scenario.station_m(nextIndex), fraction);

    yawIncrement = wrapAngle( ...
        scenario.psi_ref_rad(nextIndex) ...
        - scenario.psi_ref_rad(segmentIndex));
    referenceYaw_rad(sampleIndex) = wrapAngle( ...
        scenario.psi_ref_rad(segmentIndex) ...
        + fraction*yawIncrement);
    trackIndex(sampleIndex) = segmentIndex;
end

measuredYaw_rad = initialYaw_rad + ...
    cumtrapz(time_s, yawRate_radps);

deltaX_m = x_m - referenceX_m;
deltaY_m = y_m - referenceY_m;

monitor = struct();
monitor.time_s = time_s;
monitor.reference_x_m = referenceX_m;
monitor.reference_y_m = referenceY_m;
monitor.reference_yaw_rad = referenceYaw_rad;
monitor.reference_speed_mps = referenceSpeed_mps;
monitor.reference_station_m = referenceStation_m;
monitor.track_index = trackIndex;
monitor.measured_yaw_rad = measuredYaw_rad;
monitor.ev_mps = vx_mps - referenceSpeed_mps;
monitor.ey_m = ...
    -deltaX_m.*sin(referenceYaw_rad) ...
    + deltaY_m.*cos(referenceYaw_rad);
monitor.epsi_rad = wrapAngle( ...
    measuredYaw_rad - referenceYaw_rad);

end

function [bestSegment, bestFraction] = projectOntoPath( ...
    x_m, y_m, scenario, previousSegment)
%PROJECTONTOPATH Find the closest local path segment monotonically.

numberOfSegments = numel(scenario.X_ref_m) - 1;
firstSegment = max(1, previousSegment - 5);
lastSegment = min(numberOfSegments, previousSegment + 100);

segmentIndices = (firstSegment:lastSegment).';
startX = scenario.X_ref_m(segmentIndices);
startY = scenario.Y_ref_m(segmentIndices);
deltaX = scenario.X_ref_m(segmentIndices + 1) - startX;
deltaY = scenario.Y_ref_m(segmentIndices + 1) - startY;
lengthSquared = max(deltaX.^2 + deltaY.^2, eps);

fraction = ((x_m - startX).*deltaX + ...
    (y_m - startY).*deltaY) ./ lengthSquared;
fraction = min(max(fraction,0),1);

projectedX = startX + fraction.*deltaX;
projectedY = startY + fraction.*deltaY;
distanceSquared = ...
    (x_m - projectedX).^2 + (y_m - projectedY).^2;

[~, localIndex] = min(distanceSquared);
bestSegment = segmentIndices(localIndex);
bestFraction = fraction(localIndex);

end

function value = interpolateLinear(firstValue, secondValue, fraction)
value = firstValue + fraction*(secondValue - firstValue);
end

function angle = wrapAngle(angle)
angle = atan2(sin(angle), cos(angle));
end
