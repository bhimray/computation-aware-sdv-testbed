function environment = load_env_profile( ...
    profileName, ...
    simulationStopTime_s, ...
    options)
%LOAD_ENVIRONMENT_PROFILE Create a traceable road-friction profile.
%
% environment = load_env_profile( ...
%     "dry_road", simulationStopTime_s)
%
% environment = load_env_profile( ...
%     "sudden_friction_drop", ...
%     simulationStopTime_s, ...
%     FrictionDropTime_s=20)

arguments
    profileName (1,1) string
    simulationStopTime_s (1,1) double ...
        {mustBeFinite, mustBePositive}

    options.FrictionDropTime_s (1,1) double ...
        {mustBeFinite, mustBePositive} = 20
end

profileName = lower(profileName);

environment = struct();

environment.schema_version = "1.0";
environment.name = profileName;
environment.units.road_friction_mu = "dimensionless";
environment.interpolation = "zero-order hold";

switch profileName

    case "dry_road"

        environment.description = ...
            "Constant nominal dry-road friction.";

        environment.event_type = "none";
        environment.event_time_s = NaN;

        profileTime_s = [
            0
            simulationStopTime_s
            ];

        frictionMu = [
            0.8
            0.8
            ];

    case "low_friction_road"

        environment.description = ...
            "Constant low-friction road.";

        environment.event_type = "none";
        environment.event_time_s = NaN;

        profileTime_s = [
            0
            simulationStopTime_s
            ];

        frictionMu = [
            0.4
            0.4
            ];

    case "sudden_friction_drop"

        frictionDropTime_s = ...
            options.FrictionDropTime_s;

        assert( ...
            frictionDropTime_s < simulationStopTime_s, ...
            "Friction-drop time must be before simulation stop time.");

        environment.description = ...
            "Unexpected road-friction drop from 0.8 to 0.3.";

        environment.event_type = ...
            "road_friction_drop";

        environment.event_time_s = ...
            frictionDropTime_s;

        profileTime_s = [
            0
            frictionDropTime_s
            simulationStopTime_s
            ];

        frictionMu = [
            0.8
            0.4
            0.4
            ];

    otherwise

        error( ...
            "Unknown environment profile '%s'. " + ...
            "Valid profiles are dry_road, " + ...
            "low_friction_road, and " + ...
            "sudden_friction_drop.", ...
            profileName);
end

%% Validate profile

assert( ...
    all(isfinite(profileTime_s)), ...
    "Environment-profile times must be finite.");

assert( ...
    all(diff(profileTime_s) > 0), ...
    "Environment-profile times must be strictly increasing.");

assert( ...
    all(isfinite(frictionMu)), ...
    "Road-friction values must be finite.");

assert( ...
    all(frictionMu >= 0) && all(frictionMu <= 1), ...
    "Road-friction values must be between zero and one.");

%% Store plain numeric data for traceability

environment.time_s = profileTime_s;
environment.road_friction_mu = frictionMu;

%% Create the Simulink input signal

roadFrictionProfile = timeseries( ...
    frictionMu, ...
    profileTime_s);

roadFrictionProfile.Name = ...
    "road_friction_mu";

roadFrictionProfile = setinterpmethod( ...
    roadFrictionProfile, ...
    "zoh");

environment.road_friction_profile = ...
    roadFrictionProfile;

end