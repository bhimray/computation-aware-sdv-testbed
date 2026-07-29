function scenarios = generate_phase0_scenarios(outputFolder, highwaySpeed_mps)
%GENERATE_PHASE0_SCENARIOS Reproducibly generate all Phase 0 scenarios.

arguments
    outputFolder (1,1) string = fullfile( ...
        string(fileparts(mfilename("fullpath"))),"data")
    highwaySpeed_mps (1,1) double {mustBePositive} = 27
end

vehicle = vehicle_parameters();

scenarios = struct();
scenarios.highway_cruise = ...
    highway_cruise(outputFolder,highwaySpeed_mps,vehicle);
scenarios.urban_profile = urban_profile(outputFolder,vehicle);
scenarios.aggressive_maneuver = ...
    aggressive_maneuver(outputFolder,vehicle);

end
