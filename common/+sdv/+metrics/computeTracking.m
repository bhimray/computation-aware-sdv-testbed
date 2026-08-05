function metrics = computeTracking(results)
%COMPUTETRACKING Compute baseline tracking metrics without plotting.

requiredFields = ["ev_mps", "ey_m", "epsi_rad"];
missingFields = setdiff(requiredFields, string(fieldnames(results)));

assert(isempty(missingFields), ...
    "Missing tracking-result fields: %s", ...
    strjoin(missingFields, ", "));

speedError = results.ev_mps(:);
lateralError = results.ey_m(:);
headingError = results.epsi_rad(:);

assert(all(isfinite( ...
    [speedError; lateralError; headingError])), ...
    "Tracking-error results contain NaN or Inf values.");

metrics = struct();
metrics.speed_rmse_mps = rmsFromSamples(speedError);
metrics.speed_peak_mps = max(abs(speedError));
metrics.lateral_rmse_m = rmsFromSamples(lateralError);
metrics.lateral_peak_m = max(abs(lateralError));
metrics.heading_rmse_rad = rmsFromSamples(headingError);
metrics.heading_peak_rad = max(abs(headingError));
metrics.heading_rmse_deg = rad2deg(metrics.heading_rmse_rad);
metrics.heading_peak_deg = rad2deg(metrics.heading_peak_rad);

end

function value = rmsFromSamples(signal)
%RMSFROMSAMPLES Calculate RMS without an additional toolbox dependency.

value = sqrt(mean(signal.^2));

end
