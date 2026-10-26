function parameters = phase4_performance_map_parameters()
%PHASE4_PERFORMANCE_MAP_PARAMETERS Central Phase 4 experiment settings.

parameters.candidate_sample_times_s = [
    0.050
    0.020
    0.010
    ];

parameters.mode_ids = uint8([1; 2; 3]);
parameters.supervisor_sample_time_s = 0.010;

parameters.prediction_horizon_s = 1.0;
parameters.map_row_stride_s = 0.050;

parameters.load_task_period_s = 0.050;
parameters.load_task_duration_s = 0.020;

parameters.communication_execution_time_s = 0.0005;
parameters.communication_period_s = 0.005;
parameters.supervisor_execution_time_s = 0.00005;
parameters.supervisor_period_s = 0.010;

parameters.maximum_cpu_utilization = 0.95;

% cost weights
parameters.cost_weights = [
    50  % lateral tracking
    50  % heading tracking
    0.1  % CPU utilization
    0.1  % response-time margin
    ];

end
