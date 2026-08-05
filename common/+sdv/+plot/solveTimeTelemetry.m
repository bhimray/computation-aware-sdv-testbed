function [figureHandle, metrics] = solveTimeTelemetry( ...
    results, scenarioName, environmentName, controlSampleTime_s)
%SOLVETIMETELEMETRY Create the standard solve-time time-history plot.

[figureHandle, metrics] = plot_solve_time_telemetry( ...
    results, scenarioName, environmentName, controlSampleTime_s);

end
