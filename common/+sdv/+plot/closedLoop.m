function figureHandle = closedLoop(results, scenario, environmentName, ...
    actuation_delay_s)
%CLOSEDLOOP Create the standard closed-loop result figure.

figureHandle = plot_phase0_results( ...
    results, scenario, environmentName, actuation_delay_s);

end
