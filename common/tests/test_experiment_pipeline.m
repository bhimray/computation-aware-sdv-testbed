function tests = test_experiment_pipeline
%TEST_EXPERIMENT_PIPELINE Unit tests for phase-independent utilities.

tests = functiontests(localfunctions);

end

function testPhaseZeroConfiguration(testCase)

runConfig = sdv.config.createRun( ...
    "phase0", "highway_cruise", "dry_road");

verifyEqual(testCase, runConfig.model_name, "phase0_baseline");
verifyEqual(testCase, runConfig.actuation_delay_s, 0);

end

function testPhaseOneConfiguration(testCase)

runConfig = sdv.config.createRun( ...
    "phase1", ...
    "urban_profile", ...
    "dry_road", ...
    ActuationDelay_s=0.05);

verifyEqual(testCase, runConfig.model_name, "phase1_baseline");
verifyEqual(testCase, runConfig.actuation_delay_s, 0.05);

end

function testTrackingMetrics(testCase)

results = struct();
results.ev_mps = [3; 4];
results.ey_m = [-1; 1];
results.epsi_rad = [0; pi/2];

metrics = sdv.metrics.computeTracking(results);

verifyEqual(testCase, metrics.speed_rmse_mps, ...
    sqrt(12.5), AbsTol=1e-12);
verifyEqual(testCase, metrics.speed_peak_mps, 4);
verifyEqual(testCase, metrics.lateral_rmse_m, 1);
verifyEqual(testCase, metrics.heading_peak_deg, 90, ...
    AbsTol=1e-12);

end

function testConstraintMetrics(testCase)

results = struct();
results.ey_m = [0; 0.9; 0.7; 1.0; 0];
results.epsi_rad = zeros(5,1);

controller = struct();
controller.maximumLateralError_m = 0.8;
controller.maximumHeadingError_rad = deg2rad(45);

metrics = sdv.metrics.computeConstraintViolations( ...
    results, controller, 0.01);

verifyEqual(testCase, metrics.any_sample_count, 2);
verifyEqual(testCase, metrics.event_count, 2);
verifyEqual(testCase, metrics.duration_s, 0.02, ...
    AbsTol=1e-12);

end

function testIndependentPerformanceMonitor(testCase)

scenario = struct();
scenario.station_m = [0; 10; 20];
scenario.X_ref_m = [0; 10; 20];
scenario.Y_ref_m = [0; 0; 0];
scenario.psi_ref_rad = [0; 0; 0];
scenario.vx_ref_mps = [5; 5; 5];

results = struct();
results.time_s = [0; 1; 2];
results.x_pos_m = [0; 5; 10];
results.y_pos_m = [1; 1; 1];
results.vx_mps = [5; 5; 5];
results.yaw_rate_radps = [0; 0; 0];

monitor = sdv.metrics.computePerformanceMonitor( ...
    results, scenario, 0);

verifyEqual(testCase, monitor.ev_mps, zeros(3,1), ...
    AbsTol=1e-12);
verifyEqual(testCase, monitor.ey_m, ones(3,1), ...
    AbsTol=1e-12);
verifyEqual(testCase, monitor.epsi_rad, zeros(3,1), ...
    AbsTol=1e-12);

end
