function results = extractBaseline(logs, solveTimeAvailable)
%EXTRACTBASELINE Convert logged baseline signals to a stable result schema.

toColumn = @(data) ...
    reshape(squeeze(double(data)), [], 1);

vxSignal = logs.get("vx_meas").Values;
vxReferenceSignal = logs.get("vx_ref").Values;
axSignal = logs.get("ax_meas").Values;
xSignal = logs.get("x_pos").Values;
ySignal = logs.get("y_pos").Values;
torqueSignal = logs.get("torque_opt").Values;
steeringSignal = logs.get("steering_angle_opt").Values;
yawRateSignal = logs.get("yaw_rate_meas").Values;
eySignal = logs.get("ey_m").Values;
headingErrorSignal = logs.get("epsi_rad").Values;
statusSignal = logs.get("solve_status").Values;
frictionSignal = logs.get("road_friction_mu").Values;

assertAligned(vxSignal, vxReferenceSignal, "vx_ref");
assertAligned(vxSignal, eySignal, "ey_m");
assertAligned(vxSignal, headingErrorSignal, "epsi_rad");

results = struct();
results.schema_version = 1;
results.time_s = toColumn(vxSignal.Time);
results.vx_mps = toColumn(vxSignal.Data);
results.vx_ref_mps = toColumn(vxReferenceSignal.Data);
results.ax_mps2 = toColumn(axSignal.Data);
results.x_pos_m = toColumn(xSignal.Data);
results.y_pos_m = toColumn(ySignal.Data);
results.torque_Nm = toColumn(torqueSignal.Data);
results.steering_angle_rad = toColumn(steeringSignal.Data);
results.yaw_rate_radps = toColumn(yawRateSignal.Data);
results.solve_status = toColumn(statusSignal.Data);
results.road_friction_time_s = toColumn(frictionSignal.Time);
results.road_friction_mu = toColumn(frictionSignal.Data);

if solveTimeAvailable
    solveTimeSignal = logs.get("solve_time").Values;
    assertAligned(vxSignal, solveTimeSignal, "solve_time");
    results.solve_time_s = toColumn(solveTimeSignal.Data);
    results.solve_time_time_s = toColumn(solveTimeSignal.Time);
else
    results.solve_time_s = zeros(0,1);
    results.solve_time_time_s = zeros(0,1);
end

% Tracking-error convention: measured value minus reference value.
results.ev_mps = results.vx_mps - results.vx_ref_mps;
results.ey_m = toColumn(eySignal.Data);
results.epsi_rad = toColumn(headingErrorSignal.Data);

end

function assertAligned(referenceSignal, candidateSignal, candidateName)
%ASSERTALIGNED Require the same controller sample times.

referenceTime = reshape( ...
    squeeze(double(referenceSignal.Time)), [], 1);
candidateTime = reshape( ...
    squeeze(double(candidateSignal.Time)), [], 1);

sameLength = numel(referenceTime) == numel(candidateTime);

if sameLength
    timeTolerance_s = ...
        10 * eps(max(1, max(abs(referenceTime))));
    sameTimes = all( ...
        abs(referenceTime - candidateTime) <= timeTolerance_s);
else
    sameTimes = false;
end

assert(sameLength && sameTimes, ...
    "Logged signal '%s' is not aligned with vx_meas. " + ...
    "Log both signals at the controller sample rate.", ...
    candidateName);

end
