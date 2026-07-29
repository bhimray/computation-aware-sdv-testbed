% Open loop simulation
% steady-state test

scenario = 'highway_cruise';
config = build_phase0_configuration(scenario);
simulationParams = config.simulation;

run_open_loop_drive_test;
disp("steady-state drive test done.")

% step-steer test
run_open_loop_steep_steer_test;
disp("constant velocity steep steer test done.")
