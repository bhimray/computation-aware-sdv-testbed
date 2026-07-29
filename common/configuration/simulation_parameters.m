function simulation = simulation_parameters(scenario)
%SIMULATION_PARAMETERS Run-specific settings and initial conditions.

simulation.Ts_s = 0.01;

simulation.initial_x_m = scenario.X_ref_m(1);
simulation.initial_y_m = scenario.Y_ref_m(1);
simulation.initial_yaw_rad = scenario.psi_ref_rad(1);
simulation.initial_speed_mps = scenario.initial_speed_mps;

simulation.stop_time_s = scenario.simulation_stop_time_s;
simulation.road_friction_mu = scenario.road_friction_mu;
simulation.slope_rad = scenario.slope_rad;
end
