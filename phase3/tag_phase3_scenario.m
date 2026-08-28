function taggedScenario = tag_phase3_scenario( ...
    scenarioName, ...
    lookupTable, ...
    parameters)

arguments
    scenarioName (1,1) string
    lookupTable (:,7) double
    parameters (1,1) struct
end

station_m = lookupTable(:,1);
xReference_m = lookupTable(:,2);
yReference_m = lookupTable(:,3);
headingReference_rad = lookupTable(:,4);
curvatureReference_1pm = lookupTable(:,5);
speedReference_mps = lookupTable(:,6);

% Convert the spatial reference to reference time.
safeSpeed_mps = max(speedReference_mps, 0.1);

segmentTime_s = ...
    2 .* diff(station_m) ./ ...
    (safeSpeed_mps(1:end-1) + safeSpeed_mps(2:end));

time_s = [0; cumsum(segmentTime_s)];
numberOfSamples = numel(time_s);

previewKappa_1pm = zeros(numberOfSamples,1);
previewDeltaKappa_1pm = zeros(numberOfSamples,1);
previewDeltaSpeed_mps = zeros(numberOfSamples,1);
rawMode = ones(numberOfSamples,1,"uint8");

for sampleIndex = 1:numberOfSamples

    previewEndIndex = find( ...
        time_s <= time_s(sampleIndex) + parameters.preview_s, ...
        1, ...
        "last");

    previewIndices = sampleIndex:previewEndIndex;

    previewCurvature = ...
        curvatureReference_1pm(previewIndices);

    previewSpeed = ...
        speedReference_mps(previewIndices);

    previewKappa_1pm(sampleIndex) = ...
        max(abs(previewCurvature));

    previewDeltaKappa_1pm(sampleIndex) = ...
        max(previewCurvature) - min(previewCurvature);

    previewDeltaSpeed_mps(sampleIndex) = ...
        max(previewSpeed) - min(previewSpeed);

    highDemand = ...
        previewKappa_1pm(sampleIndex) >= ...
            parameters.kappa_high_1pm || ...
        previewDeltaSpeed_mps(sampleIndex) >= ...
            parameters.delta_speed_high_mps;

    mediumDemand = ...
        previewKappa_1pm(sampleIndex) >= ...
            parameters.kappa_low_1pm || ...
        previewDeltaSpeed_mps(sampleIndex) >= ...
            parameters.delta_speed_low_mps;

    if highDemand
        rawMode(sampleIndex) = uint8(3);
    elseif mediumDemand
        rawMode(sampleIndex) = uint8(2);
    else
        rawMode(sampleIndex) = uint8(1);
    end
end

% Minimum dwell between mode transitions.
dwellMode = rawMode;
activeMode = rawMode(1);
lastSwitchTime_s = time_s(1);

for sampleIndex = 2:numberOfSamples

    dwellSatisfied = ...
        time_s(sampleIndex) - lastSwitchTime_s >= ...
        parameters.minimum_dwell_s;

    if rawMode(sampleIndex) ~= activeMode && dwellSatisfied
        activeMode = rawMode(sampleIndex);
        lastSwitchTime_s = time_s(sampleIndex);
    end

    dwellMode(sampleIndex) = activeMode;
end

sampleTime_s = ...
    parameters.sample_time_s(double(dwellMode));

modeLabel = strings(numberOfSamples,1);
modeLabel(dwellMode == 1) = "low";
modeLabel(dwellMode == 2) = "medium";
modeLabel(dwellMode == 3) = "high";

demandTable = table( ...
    time_s, ...
    station_m, ...
    xReference_m, ...
    yReference_m, ...
    headingReference_rad, ...
    curvatureReference_1pm, ...
    speedReference_mps, ...
    previewKappa_1pm, ...
    previewDeltaKappa_1pm, ...
    previewDeltaSpeed_mps, ...
    rawMode, ...
    dwellMode, ...
    modeLabel, ...
    sampleTime_s);

taggedScenario.schema_version = "phase3-demand-v1";
taggedScenario.scenario_name = scenarioName;
taggedScenario.parameters = parameters;
taggedScenario.demand_table = demandTable;

end