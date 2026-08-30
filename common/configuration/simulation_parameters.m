function simulation = simulation_parameters(scenario)
%SIMULATION_PARAMETERS Run-specific settings and initial conditions.

% Nominal controller sample period
simulation.Ts_s = 0.01;          % 10 ms but for phase3 for varying demand analysis it need to change to 10, 20, 50 to build 3 acados s_fun

% Default plant period
simulation.plant_step_s = 0.01; 
simulation.initial_x_m = scenario.X_ref_m(1);
simulation.initial_y_m = scenario.Y_ref_m(1);
simulation.initial_yaw_rad = scenario.psi_ref_rad(1);
simulation.initial_speed_mps = scenario.initial_speed_mps;

simulation.stop_time_s = scenario.simulation_stop_time_s;
% simulation.stop_time_s = 1;
% simulation.road_friction_mu = scenario.road_friction_mu; %% used using
% environment var
simulation.slope_rad = scenario.slope_rad;

%% sampling jitter phase 1.3
simulation.simulationStep_s = 0.0005;
simulation.jitterBound_ms = 5;
simulation.randomSeed = 1;

end
