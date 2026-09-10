function [results, config, resultsFile] = run_phase0_baseline( ...
    scenarioName, environmentName)
%RUN_PHASE0_BASELINE Run one Phase 0 experiment through the shared runner.

arguments
    scenarioName (1,1) string
    environmentName (1,1) string = "dry_road"
end

startup_project;

runConfig = sdv.config.createRun( ...
    "phase0", scenarioName, environmentName);

runner = sdv.ExperimentRunner(runConfig);
[results, config, resultsFile] = runner.run();

fprintf("Relevant plot file:\n%s\n", fullfile( ...
    matlab.project.currentProject().RootFolder, ...
    "phase0", "plots", "plot_phase0_baseline.m"));

if strlength(resultsFile) > 0
    fprintf("Plot input artifact:\n%s\n", resultsFile);
end

end
