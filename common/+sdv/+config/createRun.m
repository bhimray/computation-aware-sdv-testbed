function runConfig = createRun( ...
    phaseName, ...
    scenarioName, ...
    environmentName, ...
    options)
%CREATERUN Create phase-independent experiment-run configuration.

% This structure is used only by MATLAB code automation or coordination. Simulink continues
% to receive plain numeric parameter structures and arrays.

arguments
    phaseName (1,1) string
    scenarioName (1,1) string
    environmentName (1,1) string = "dry_road"
    options.ActuationDelay_s (1,1) double ...
        {mustBeNonnegative} = 0
    options.SaveResults (1,1) logical = true
    options.SaveFigures (1,1) logical = true
    options.ShowFigures (1,1) logical = true
end

phaseName = lower(strtrim(phaseName));
scenarioName = lower(strtrim(scenarioName));
environmentName = lower(strtrim(environmentName));

switch phaseName
    case "phase0"
        modelName = "phase0_baseline";

        assert(options.ActuationDelay_s == 0, ...
            "Phase 0 does not inject actuation delay.");

    case "phase1"
        modelName = "phase1_baseline";

    otherwise
        error( ...
            "SDV:UnsupportedPhase", ...
            "Unsupported experiment phase: %s", ...
            phaseName);
end

runConfig = struct();
runConfig.schema_version = 1;
runConfig.phase_name = phaseName;
runConfig.model_name = modelName;
runConfig.scenario_name = scenarioName;
runConfig.environment_name = environmentName;
runConfig.actuation_delay_s = options.ActuationDelay_s;

runConfig.output = struct();
runConfig.output.save_results = options.SaveResults;
runConfig.output.save_figures = options.SaveFigures;
runConfig.output.show_figures = options.ShowFigures;

end
