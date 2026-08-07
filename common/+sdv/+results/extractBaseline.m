function results = extractBaseline( ...
    logs, solveTimeAvailable, options)
%EXTRACTBASELINE Convert logged baseline signals to a stable result schema.

arguments
    logs
    solveTimeAvailable (1,1) logical
    options.IrregularControllerTiming (1,1) logical = false
end

toColumn = @(data) ...
    reshape(squeeze(double(data)), [], 1);

vxSignal = logs.get("vx_meas").Values;
vxReferenceSignal = logs.get("vx_ref").Values;
axSignal = logs.get("ax_meas").Values;
xSignal = logs.get("x_pos").Values;
ySignal = logs.get("y_pos").Values;
torqueSignal = logs.get("torque_opt").Values;
torqueAppliedSignal = logs.get("applied_torque").Values;
steeringSignal = logs.get("steering_angle_opt").Values;
steeringAppliedSignal = logs.get("applied_steering_angle").Values;
yawRateSignal = logs.get("yaw_rate_meas").Values;
eySignal = logs.get("ey_m").Values;
headingErrorSignal = logs.get("epsi_rad").Values;
statusSignal = logs.get("solve_status").Values;
frictionSignal = logs.get("road_friction_mu").Values;
cputimeQPSignal = logs.get("cpu_time_qp").Values;
cputtimeSIMSignal = logs.get("cpu_time_sim").Values;
cputtimeLINSignal = logs.get("cpu_time_lin").Values;
slackSignal = logs.get("slack_val").Values;

measurementTime_s = toColumn(vxSignal.Time);

if options.IrregularControllerTiming
    vxReferenceData = resampleHeldSignal( ...
        vxReferenceSignal, measurementTime_s);
    torqueData = resampleHeldSignal( ...
        torqueSignal, measurementTime_s);
    steeringData = resampleHeldSignal( ...
        steeringSignal, measurementTime_s);
    eyData = resampleHeldSignal( ...
        eySignal, measurementTime_s);
    headingErrorData = resampleHeldSignal( ...
        headingErrorSignal, measurementTime_s);
else
    assertAligned(vxSignal, vxReferenceSignal, "vx_ref");
    assertAligned(vxSignal, torqueSignal, "torque_opt");
    assertAligned(vxSignal, steeringSignal, "steering_angle_opt");
    assertAligned(vxSignal, eySignal, "ey_m");
    assertAligned(vxSignal, headingErrorSignal, "epsi_rad");

    vxReferenceData = toColumn(vxReferenceSignal.Data);
    torqueData = toColumn(torqueSignal.Data);
    steeringData = toColumn(steeringSignal.Data);
    eyData = toColumn(eySignal.Data);
    headingErrorData = toColumn(headingErrorSignal.Data);
end

slackData = squeeze(double(slackSignal.Data));
% Convert to: number of samples × 4 slack summaries.
if size(slackData, 1) == 4
    slackData = slackData.';
end

assert(size(slackData, 2) == 4, ...
    "Logged slack_val must contain four channels.");


results = struct();
results.schema_version = 1;
results.time_s = measurementTime_s;
results.vx_mps = toColumn(vxSignal.Data);
results.vx_ref_mps = vxReferenceData;
results.ax_mps2 = toColumn(axSignal.Data);
results.x_pos_m = toColumn(xSignal.Data);
results.y_pos_m = toColumn(ySignal.Data);
results.torque_Nm = torqueData;
results.steering_angle_rad = steeringData;
results.yaw_rate_radps = toColumn(yawRateSignal.Data);
results.solve_status = toColumn(statusSignal.Data);
results.solve_status_time_s = toColumn(statusSignal.Time);
results.road_friction_time_s = toColumn(frictionSignal.Time);
results.road_friction_mu = toColumn(frictionSignal.Data);
results.torque_applied_Nm = toColumn(torqueAppliedSignal.Data);
results.torque_applied_time = toColumn(torqueAppliedSignal.Time);
results.steering_applied_angle_rad = toColumn(steeringAppliedSignal.Data);
results.steering_applied_time = toColumn(steeringAppliedSignal.Time);
results.cput_time_qp_s = toColumn(cputimeQPSignal.Data);
results.cput_time_qp_time_s = toColumn(cputimeQPSignal.Time);
results.cput_time_sim_s = toColumn(cputtimeSIMSignal.Data);
results.cput_time_sim_time_s = toColumn(cputtimeSIMSignal.Time);
results.cput_time_lin_s = toColumn(cputtimeLINSignal.Data);
results.cput_time_lin_time_s = toColumn(cputtimeLINSignal.Time);

results.slack_time_s = ...
    toColumn(slackSignal.Time);

results.first_predicted_ey_slack_m = ...
    slackData(:,1);

results.first_predicted_epsi_slack_rad = ...
    slackData(:,2);

results.max_predicted_ey_slack_m = ...
    slackData(:,3);

results.max_predicted_epsi_slack_rad = ...
    slackData(:,4);
if solveTimeAvailable
    solveTimeSignal = logs.get("solve_time").Values;
    results.solve_time_s = toColumn(solveTimeSignal.Data);
    results.solve_time_time_s = toColumn(solveTimeSignal.Time);
else
    results.solve_time_s = zeros(0,1);
    results.solve_time_time_s = zeros(0,1);
end

% Tracking-error convention: measured value minus reference value.
results.ev_mps = results.vx_mps - results.vx_ref_mps;
results.ey_m = eyData;
results.epsi_rad = headingErrorData;

end

function resampledData = resampleHeldSignal(signal, targetTime_s)
%RESAMPLEHELDSIGNAL Evaluate an irregular signal using zero-order hold.

sourceTime_s = reshape( ...
    squeeze(double(signal.Time)), [], 1);
sourceData = reshape( ...
    squeeze(double(signal.Data)), [], 1);

assert(~isempty(sourceTime_s), ...
    "Cannot resample an empty logged signal.");

[sourceTime_s, uniqueIndices] = unique( ...
    sourceTime_s, "last");
sourceData = sourceData(uniqueIndices);

if isscalar(sourceTime_s)
    resampledData = repmat( ...
        sourceData, numel(targetTime_s), 1);
else
    resampledData = interp1( ...
        sourceTime_s, ...
        sourceData, ...
        targetTime_s, ...
        "previous", ...
        "extrap");
end

resampledData = reshape(resampledData, [], 1);

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
