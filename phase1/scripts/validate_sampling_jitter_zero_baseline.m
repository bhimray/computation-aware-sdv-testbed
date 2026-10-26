function comparison = validate_sampling_jitter_zero_baseline( ...
    scenarioName, environmentName, simulationStep_s)
%VALIDATE_SAMPLING_JITTER_ZERO_BASELINE Compare periodic and J=0 runs.

arguments
    scenarioName (1,1) string = "highway_cruise"
    environmentName (1,1) string = "dry_road"
    simulationStep_s (1,1) double {mustBePositive} = 0.0005
end

startup_project;

[periodicResults, ~] = run_phase1_baseline( ...
    scenarioName, environmentName, 0, ...
    SaveResults=false);

[triggeredResults, ~] = run_sampling_jitter_case( ...
    scenarioName, environmentName, 0, 1, simulationStep_s, ...
    SaveResults=false);

comparison = compare_sampling_jitter_baseline( ...
    periodicResults, triggeredResults);

fprintf("Step 9 passed: J = 0 matches the periodic baseline.\n");

end
