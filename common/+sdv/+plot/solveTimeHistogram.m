function [figureHandle, metrics] = solveTimeHistogram( ...
    results, scenario, environmentName, controlSampleTime_s)
%SOLVETIMEHISTOGRAM Create the standard solve-time histogram.

[figureHandle, metrics] = plot_phase0_solve_time( ...
    results, scenario, environmentName, controlSampleTime_s);

end
