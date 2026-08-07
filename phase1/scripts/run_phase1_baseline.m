function [results, config] = run_phase1_baseline( ...
    scenarioName, ...
    environmentName, ...
    actuationDelay_s, ...
    options)
%RUN_PHASE1_BASELINE Run one Phase 1 experiment.

arguments
    scenarioName (1,1) string
    environmentName (1,1) string = "dry_road"
    actuationDelay_s (1,1) double ...
        {mustBeNonnegative} = 0

    options.SaveResults (1,1) logical = true
    options.SaveFigures (1,1) logical = true
    options.ShowFigures (1,1) logical = true
end

startup_project;

% setup all the requirement for simulation to run
runConfig = sdv.config.createRun( ...
    "phase1", ... %% to run particular SIMULINK model, phase0_baseline, phase1_baseline
    scenarioName, ...
    environmentName, ...
    ActuationDelay_s=actuationDelay_s, ...
    SaveResults=options.SaveResults, ...
    SaveFigures=options.SaveFigures, ...
    ShowFigures=options.ShowFigures);

% pass the requirements or configuration to class to create object to run
% simulation
runner = sdv.ExperimentRunner(runConfig);

[results, config] = runner.run();

end
