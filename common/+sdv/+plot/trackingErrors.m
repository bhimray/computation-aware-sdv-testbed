function [figureHandle, metrics] = trackingErrors( ...
    results, scenario, environmentName, controller)
%TRACKINGERRORS Create standard tracking-error plots and metrics.

[figureHandle, metrics] = plot_phase0_tracking_errors( ...
    results, scenario, environmentName, controller);

end
