function validation = validate_sampling_jitter_case( ...
    results, controller, jitterBound_ms, simulationStep_s)
%VALIDATE_SAMPLING_JITTER_CASE Validate one Phase 1.3 simulation.
%
% Raw acados solver-status convention:
%   0        = success
%   nonzero  = failure

arguments
    results (1,1) struct
    controller (1,1) struct
    jitterBound_ms (1,1) double {mustBeNonnegative}
    simulationStep_s (1,1) double {mustBePositive}
end

%% Get controller execution telemetry

executionLog = results.controller_execution_log;

assert( ...
    height(executionLog) == ...
    results.execution_validation.actual_count, ...
    "Controller execution count is inconsistent.");

%% Check plant telemetry

plantData = [ ...
    results.time_s(:)
    results.vx_mps(:)
    results.ey_m(:)
    results.epsi_rad(:)
    ];

assert(all(isfinite(plantData)), ...
    "Plant telemetry contains NaN or Inf.");

%% Check solve-time telemetry

solveTime_s = executionLog.SolveTime_s(:);

assert(all(isfinite(solveTime_s)), ...
    "Solve-time telemetry contains NaN or Inf.");

assert(all(solveTime_s >= 0), ...
    "Solve-time telemetry contains negative values.");

%% Check solver status

solverStatus = executionLog.SolverStatus(:);

failedSolve = solverStatus ~= 0;

%% Check realized sampling jitter

actualJitter_s = ...
    executionLog.ActualJitter_s(2:end);

allowedJitter_s = ...
    jitterBound_ms*1e-3 ...
    + 2*simulationStep_s;

jitterExceeded = ...
    abs(actualJitter_s) > allowedJitter_s;

assert(~any(jitterExceeded), ...
    "Realized sampling jitter exceeded its allowed bound.");

%% Build validation result

validation = struct();

validation.execution_count = height(executionLog);
validation.failed_solve_count = nnz(failedSolve);
validation.raw_status_0_count = nnz(solverStatus == 0);
validation.raw_status_2_count = nnz(solverStatus == 2);
validation.raw_status_4_count = nnz(solverStatus == 4);
validation.other_raw_status_count = ...
    nnz(~ismember(solverStatus, [0 2 4]));

validation.deadline_miss_count = ...
    nnz(solveTime_s > controller.Ts_s);

validation.maximum_abs_actual_jitter_s = ...
    max(abs(actualJitter_s), [], "omitnan");

validation.maximum_scheduling_error_s = ...
    max(abs(executionLog.SchedulingError_s), [], "omitnan");

validation.passed = ...
    validation.failed_solve_count == 0;

%% Report any failed or invalid statuses

% if validation.failed_solve_count > 2
% 
%     failedRows = find(failedSolve);
% 
%     fprintf("\nNon-successful controller executions:\n");
% 
%     disp(executionLog( ...
%         failedRows, ...
%         ["EventIndex", ...
%          "ActualTime_s", ...
%          "SolverStatus", ...
%          "SolveTime_s"]));
% 
%     error( ...
%         "%d controller solves did not report success.", ...
%         validation.failed_solve_count);
% end

fprintf( ...
    "Phase 1.3 validation completed: " + ...
    "%d executions, %d nonzero statuses, %d deadline misses.\n", ...
    validation.execution_count, ...
    validation.failed_solve_count, ...
    validation.deadline_miss_count);

end
