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
metrics.event_count = nnz(diff([false; anyViolation]) == 1);
metrics.duration_s = metrics.any_sample_count * sampleTime_s;
metrics.any_violation = any(anyViolation);

end
