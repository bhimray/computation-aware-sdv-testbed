function [results, config, resultsFile] = run_phase3_baseline( ...
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
[results, config, resultsFile] = runner.run();

fprintf("Relevant plot file:\n%s\n", fullfile( ...
    matlab.project.currentProject().RootFolder, ...
    "phase3", "plot", "plot_phase3_baseline.m"));

if strlength(resultsFile) > 0
    fprintf("Plot input artifact:\n%s\n", resultsFile);
end

end
