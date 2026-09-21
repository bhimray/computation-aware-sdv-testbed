%% Phase 4 lookup-map supervisor

clearvars;
clc;

startup_project;

% Change only these values for one experiment.
scenarioName = "aggressive_maneuver";
environmentName = "dry_road";
loadTaskDuration_s = 0.020;
randomSeed = 4001;

% Replace with measured supervisor execution-time samples when available.
% Empty keeps the configured constant supervisor duration.
supervisorExecutionTimeSamples_s = zeros(0,1);

[simulationOutput, resultsFile] = ...
    run_phase4_lookup_supervisor( ...
        scenarioName, ...
        environmentName, ...
        LoadTaskDuration_s=loadTaskDuration_s, ...
        RandomSeed=randomSeed, ...
        SupervisorExecutionTimeSamples_s= ...
            supervisorExecutionTimeSamples_s);

fprintf("\nPhase 4 simulation completed.\n%s\n", resultsFile);
