function figureHandle = jitterSeedScatter( ...
    jitterData, jitterBound_ms, failingSeed, options)
%JITTERSEEDSCATTER Compare applied jitter across random seeds.

arguments
    jitterData table
    jitterBound_ms (1,1) double {mustBeNonnegative}
    failingSeed (1,1) double
    options.TimeWindow_s (1,:) double = []
    options.FigureTitle (1,1) string = "Sampling-jitter seed comparison"
    options.Visible (1,1) string ...
        {mustBeMember(options.Visible, ["on", "off"])} = "on"
end

requiredVariables = ["time_s", "actual_jitter_ms", "seed"];
missingVariables = setdiff( ...
    requiredVariables, string(jitterData.Properties.VariableNames));
assert(isempty(missingVariables), ...
    "Jitter data is missing: %s", strjoin(missingVariables, ", "));

if ~isempty(options.TimeWindow_s)
    assert(numel(options.TimeWindow_s) == 2 && ...
        options.TimeWindow_s(2) > options.TimeWindow_s(1), ...
        "TimeWindow_s must be [startTime endTime].");
    selected = jitterData.time_s >= options.TimeWindow_s(1) & ...
        jitterData.time_s <= options.TimeWindow_s(2);
    jitterData = jitterData(selected,:);
end

assert(~isempty(jitterData), ...
    "No jitter samples exist in the selected time window.");

failing = jitterData.seed == failingSeed;
assert(any(failing), ...
    "No saved jitter data was found for failing seed %d.", failingSeed);

figureHandle = figure( ...
    Name=options.FigureTitle, Color="white", Visible=options.Visible);
axesHandle = axes(figureHandle);
hold(axesHandle, "on");

seedValues = unique(jitterData.seed, "sorted");
for seed = seedValues.'
    seedRows = jitterData.seed == seed;
    seedData = sortrows(jitterData(seedRows,:), "time_s");

    if seed == failingSeed
        traceColor = [0.85, 0.15, 0.12];
        traceWidth = 1.5;
    else
        traceColor = [0.78, 0.80, 0.83];
        traceWidth = 0.6;
    end

    plot( ...
        axesHandle, ...
        seedData.time_s, ...
        seedData.actual_jitter_ms, ...
        Color=traceColor, ...
        LineWidth=traceWidth, ...
        HandleVisibility="off");
end

scatter( ...
    axesHandle, ...
    jitterData.time_s(~failing), ...
    jitterData.actual_jitter_ms(~failing), ...
    10, [0.65, 0.68, 0.72], "filled", ...
    MarkerFaceAlpha=0.35, ...
    DisplayName="Other seeds");

scatter( ...
    axesHandle, ...
    jitterData.time_s(failing), ...
    jitterData.actual_jitter_ms(failing), ...
    22, [0.85, 0.15, 0.12], "filled", ...
    DisplayName="Failing seed " + failingSeed);

yline(axesHandle, 0, "k-", HandleVisibility="off");
yline(axesHandle, jitterBound_ms, "r--", "+J bound", ...
    HandleVisibility="off");
yline(axesHandle, -jitterBound_ms, "r--", "-J bound", ...
    HandleVisibility="off");

if ~isempty(options.TimeWindow_s)
    xlim(axesHandle, options.TimeWindow_s);
end

grid(axesHandle, "on");
box(axesHandle, "on");
xlabel(axesHandle, "Controller execution time (s)");
ylabel(axesHandle, "Actual jitter (ms)");
title(axesHandle, options.FigureTitle, Interpreter="none");
legend(axesHandle, Location="best", Interpreter="none");
hold(axesHandle, "off");

end
