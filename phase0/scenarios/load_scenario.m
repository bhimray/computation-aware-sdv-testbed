function scenario = load_scenario(name, scenarioFolder)
%LOAD_SCENARIO Load and validate a named Phase 0 runtime scenario.

arguments
    name (1,1) string
    scenarioFolder (1,1) string = string(fileparts(mfilename("fullpath")))
end

validNames = [ ...
    "highway_cruise", ...
    "urban_profile", ...
    "aggressive_maneuver"];
assert(any(name == validNames), ...
    "Unknown scenario '%s'. Valid names: %s.", ...
    name,strjoin(validNames,", "));

scenarioFile = fullfile(scenarioFolder, 'data', name+".mat");
assert(isfile(scenarioFile), ...
    "Scenario file does not exist: %s. Run generate_phase0_scenarios first.", ...
    scenarioFile);

loaded = load(scenarioFile,"track");
assert(isfield(loaded,"track"), ...
    "Scenario file '%s' does not contain variable 'track'.",scenarioFile);
track = loaded.track;
validate_phase0_scenario(track);
assert(string(track.name) == name, ...
    "Scenario filename and embedded name do not match.");

scenario = generate_ref(scenarioFile);
scenario.file = scenarioFile;
scenario.track = track;
scenario.schema_version = string(track.schema_version);
scenario.name = string(track.name);
scenario.description = string(track.description);
scenario.source = string(track.source);
scenario.initial_speed_mps = track.initial_speed_mps;
scenario.traversal_time_s = track.traversal_time_s;
scenario.simulation_stop_time_s = track.simulation_stop_time_s;
scenario.road_friction_mu = track.road_friction_mu;
scenario.slope_rad = track.slope_rad;
scenario.stop_event_table = track.stop_event_table;
end
