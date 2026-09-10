function [configuration, controller] = prepare_phase1_runtime(scenarioName)
%PREPARE_PHASE1_RUNTIME Compatibility wrapper for runtime preparation.

arguments
    scenarioName (1,1) string = "highway_cruise"
end

startup_project;
[configuration, controller] = ...
    prepare_controller_runtime(scenarioName);

end
