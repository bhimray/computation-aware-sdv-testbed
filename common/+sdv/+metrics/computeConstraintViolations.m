function metrics = computeConstraintViolations( ...
    results, ...
    controller, ...
    sampleTime_s)
%COMPUTECONSTRAINTVIOLATIONS Measure observed tracking-limit violations.

arguments
    results (1,1) struct
    controller (1,1) struct
    sampleTime_s (1,1) double {mustBePositive}
end

lateralViolation = ...
    abs(results.ey_m(:)) > controller.maximumLateralError_m;

headingViolation = ...
    abs(results.epsi_rad(:)) > controller.maximumHeadingError_rad;

anyViolation = lateralViolation | headingViolation;

metrics = struct();
metrics.sample_count = numel(anyViolation);
metrics.lateral_sample_count = nnz(lateralViolation);
metrics.heading_sample_count = nnz(headingViolation);
metrics.any_sample_count = nnz(anyViolation);
metrics.event_count = nnz(diff([false; anyViolation]) == 1); % counting how many times violation happened after recovering

if isfield(results, "time_s") && ...
        numel(results.time_s) == numel(anyViolation) && ...
        numel(results.time_s) > 1
    time_s = results.time_s(:);
    interval_s = diff(time_s);
    assert(all(interval_s > 0), ...
        "Constraint-metric time must be strictly increasing.");
    sampleDuration_s = [interval_s; interval_s(end)];
    metrics.duration_s = sum(sampleDuration_s(anyViolation));
else
    metrics.duration_s = metrics.any_sample_count * sampleTime_s;
end

metrics.any_violation = any(anyViolation);

end
