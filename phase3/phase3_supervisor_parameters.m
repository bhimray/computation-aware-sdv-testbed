function parameters = phase3_supervisor_parameters()

parameters.preview_s = 1.0;
parameters.minimum_dwell_s = 0.5; %% need to be adjusted based on the specific requirements

%% Find optimal for simulation
parameters.kappa_low_1pm = 0.003;
parameters.kappa_high_1pm = 0.010;

parameters.delta_speed_low_mps = 0.25;
parameters.delta_speed_high_mps = 0.75;

% Demand codes: LOW = 1, MEDIUM = 2, HIGH = 3
parameters.sample_time_s = [
    0.050
    0.020
    0.010
    ];

end