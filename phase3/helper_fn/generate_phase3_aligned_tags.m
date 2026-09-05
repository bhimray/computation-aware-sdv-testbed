function alignedTags = generate_phase3_aligned_tags( ...
    taggedScenario, baseTick_s)

arguments
    taggedScenario (1,1) struct
    baseTick_s (1,1) double ...
        {mustBePositive, mustBeFinite} = 0.010
end

%% Read existing demand tags and saved periods

tags = taggedScenario.demand_table;

sourceTime_s = double(tags.time_s(:));
sourceMode = double(tags.dwellMode(:));

periods_s = double( ...
    taggedScenario.parameters.sample_time_s(:));

assert(numel(sourceTime_s) >= 2 && ...
       all(isfinite(sourceTime_s)) && ...
       sourceTime_s(1) == 0 && ...
       all(diff(sourceTime_s) > 0), ...
    "Tag times must start at zero and increase strictly.");

assert(numel(sourceMode) == numel(sourceTime_s) && ...
       all(ismember(sourceMode, [1 2 3])), ...
    "Demand modes must be LOW=1, MEDIUM=2, HIGH=3.");

assert(numel(periods_s) == 3 && ...
       all(isfinite(periods_s)) && all(periods_s > 0), ...
    "Three positive sampling periods are required.");

% Perform scheduling calculations using integer tick counts.
periodTicks = round(periods_s / baseTick_s);

assert(all(periodTicks >= 1) && ...
       all(abs(periods_s/baseTick_s - periodTicks) < 1e-9), ...
    "Sampling periods must be integer multiples of the base tick.");

%% Sample demand requests on the base-tick timeline

lastTick = floor(sourceTime_s(end) / baseTick_s);
tickNumber = (0:lastTick).';
time_s = tickNumber * baseTick_s;

% Previous-value interpolation keeps tags discrete.
requestedMode = interp1( ...
    sourceTime_s, sourceMode, time_s, "previous");

numberOfTicks = numel(time_s);

activeMode = zeros(numberOfTicks, 1);
switchAccepted = false(numberOfTicks, 1);
controllerReleased = false(numberOfTicks, 1);

% Initial mode is selected at t = 0.
currentMode = requestedMode(1);

%% Apply common-boundary switching

for index = 1:numberOfTicks

    requested = requestedMode(index);

    if requested ~= currentMode

        commonBoundaryTicks = lcm( ...
            periodTicks(currentMode), ...
            periodTicks(requested));

        atCommonBoundary = ...
            mod(tickNumber(index), commonBoundaryTicks) == 0;

        if atCommonBoundary
            currentMode = requested;
            switchAccepted(index) = true;
        end
    end

    activeMode(index) = currentMode;

    % At an accepted switch, release the new mode once.
    controllerReleased(index) = ...
        mod(tickNumber(index), periodTicks(currentMode)) == 0;
end

%% Collect the aligned timeline

activePeriod_s = periods_s(activeMode);
switchPending = requestedMode ~= activeMode;

requestedMode = uint8(requestedMode);
activeMode = uint8(activeMode);

timingTable = table( ...
    time_s, ...
    requestedMode, ...
    activeMode, ...
    activePeriod_s, ...
    switchPending, ...
    switchAccepted, ...
    controllerReleased);

%% Store metadata with the generated data

alignedTags.schema_version = "phase3-aligned-demand-v1";
alignedTags.scenario_name = taggedScenario.scenario_name;
alignedTags.parameters = taggedScenario.parameters;
alignedTags.base_tick_s = baseTick_s;
alignedTags.schedule_origin_s = 0;
alignedTags.switching_policy = ...
    "Common release boundary; latest demand request";
alignedTags.timing_table = timingTable;

end