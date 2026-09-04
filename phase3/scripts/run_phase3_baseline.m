function [results, config] = run_phase3_baseline( ...
    scenarioName, environmentName, modelName)
%RUN_PHASE0_BASELINE Run one Phase 0 experiment through the shared runner.

arguments
    scenarioName (1,1) string
    environmentName (1,1) string = "dry_road"
    modelName (1,1) string = "phase3_20ms"
end

startup_project;

runConfig = sdv.config.createRun( ...
    modelName, scenarioName, environmentName);

runner = sdv.ExperimentRunner(runConfig);
[results, config] = runner.run();

end
