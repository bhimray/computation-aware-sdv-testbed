%% Phase 1 single-case entry point

startup_project;

% Select one mode:
%   "constant_delay", "random_delay", or "sampling_jitter"
timingMode = "sampling_jitter";

scenarioName = "highway_cruise";
environmentName = "dry_road";

prepare_phase1_runtime(scenarioName);

% [results, config, timingData] = run_phase1_case( ...
%     timingMode, ...
%     scenarioName, ...
%     environmentName, ...
%     Delay_ms=50, ...              % constant/random delay magnitude
%     JitterBound_ms=8, ...         % sampling-jitter bound
%     RandomSeed=1, ...
%     SimulationStep_s=0.0005, ...
%     SaveResults=true, ...
%     SaveFigures=true, ...
%     ShowFigures=true);

% Batch studies remain separate:
  run_constant_delay_sweep()
%   run_random_delay_sweep(...)
%   run_sampling_jitter_monte_carlo()
