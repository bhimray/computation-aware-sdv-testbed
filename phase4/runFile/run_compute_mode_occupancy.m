%% Extract Phase 4 online-supervisor mode occupancy

projectRoot = "C:\Users\rayyu\OneDrive\Desktop\UTD\SDV";

scenarioNames = [
    "highway_cruise"
    "urban_profile"
    "aggressive_maneuver"
    ];

environmentNames = [
    "dry_road"
    "low_friction_road"
    ];

rows = cell(0,7);

for scenarioIndex = 1:numel(scenarioNames)
    for environmentIndex = 1:numel(environmentNames)

        scenario = scenarioNames(scenarioIndex);
        environment = environmentNames(environmentIndex);

        sourceFile = fullfile( ...
            projectRoot, ...
            "phase4", "results", "lookup_supervisor", ...
            scenario, environment, ...
            "simulation_output.mat");

        assert(isfile(sourceFile), ...
            "Missing simulation output:\n%s", sourceFile);

        saved = load(sourceFile, "runArtifact");
        artifact = saved.runArtifact;

        time_s = double(artifact.mode.Time_s(:));
        mode = round(double(artifact.mode.Data(:)));

        valid = isfinite(time_s) & isfinite(mode) & ismember(mode, 1:3);
        time_s = time_s(valid);
        mode = mode(valid);

        % Sort samples and retain the last mode at duplicate timestamps.
        [time_s, order] = sort(time_s);
        mode = mode(order);
        [time_s, uniqueIndices] = unique(time_s, "last");
        mode = mode(uniqueIndices);

        % Include the final interval up to the simulation stop time.
        stopTime_s = double(artifact.stopTime_s);
        assert(stopTime_s >= time_s(end), ...
            "Stop time precedes the final mode timestamp in:\n%s", sourceFile);

        intervalDuration_s = diff([time_s; stopTime_s]);
        observationDuration_s = sum(intervalDuration_s);

        occupancy_pct = zeros(1,3);
        for modeIndex = 1:3
            occupancy_pct(modeIndex) = 100 * ...
                sum(intervalDuration_s(mode == modeIndex)) / ...
                observationDuration_s;
        end

        switchCount = sum(diff(mode) ~= 0);

        rows(end+1,:) = { ... %#ok<SAGROW>
                scenario, ...
                environment, ...
                occupancy_pct(3), ... % 10 ms
                occupancy_pct(2), ... % 20 ms
                occupancy_pct(1), ... % 50 ms
                switchCount, ...
                sourceFile};
    end
end

modeOccupancyTable = cell2table(rows, ...
    VariableNames=[ ...
    "Scenario", ...
    "Environment", ...
    "Occupancy10ms_pct", ...
    "Occupancy20ms_pct", ...
    "Occupancy50ms_pct", ...
    "SwitchCount", ...
    "SourceFile"]);

disp(modeOccupancyTable(:,1:6));

outputFolder = fullfile(projectRoot, "phase4", "results", "analysis");
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

writetable(modeOccupancyTable, ...
    fullfile(outputFolder, "lookup_supervisor_mode_occupancy.csv"));

save(fullfile(outputFolder, "lookup_supervisor_mode_occupancy.mat"), ...
    "modeOccupancyTable");