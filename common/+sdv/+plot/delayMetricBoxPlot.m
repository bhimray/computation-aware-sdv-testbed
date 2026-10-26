function statisticsTable = delayMetricBoxPlot( ...
    axesHandle, sampleGroups, delayValues_ms, groupNames, options)
%DELAYMETRICBOXPLOT Plot paired distributions at each delay value.

arguments
    axesHandle (1,1) matlab.graphics.axis.Axes
    sampleGroups cell
    delayValues_ms (:,1) double
    groupNames (:,1) string
    options.Title (1,1) string = ""
    options.YLabel (1,1) string = "Metric"
    options.Colors (:,3) double = zeros(0,3)
    options.ShowMean (1,1) logical = true
    options.ShowP95 (1,1) logical = true
end

sampleGroups = sampleGroups(:);
assert(numel(sampleGroups) == numel(delayValues_ms) && ...
    numel(sampleGroups) == numel(groupNames), ...
    "Samples, delays, and group names must have equal lengths.");

delayLevels_ms = unique(delayValues_ms, "sorted");
uniqueGroups = unique(groupNames, "stable");
numberOfGroups = numel(uniqueGroups);

colors = options.Colors;
if isempty(colors)
    colors = lines(numberOfGroups);
end
assert(size(colors,1) == numberOfGroups, ...
    "Colors must contain one row per group.");

offsets = linspace(-0.18, 0.18, numberOfGroups);
boxHandles = gobjects(numberOfGroups,1);

sampleCount = zeros(numel(sampleGroups),1);
sampleMean = zeros(numel(sampleGroups),1);
sampleMedian = zeros(numel(sampleGroups),1);
sampleP95 = zeros(numel(sampleGroups),1);
sampleP99 = zeros(numel(sampleGroups),1);

hold(axesHandle, "on");

for groupIndex = 1:numberOfGroups
    groupName = uniqueGroups(groupIndex);
    xSamples = zeros(0,1);
    ySamples = zeros(0,1);
    markerX = zeros(0,1);
    meanValues = zeros(0,1);
    p95Values = zeros(0,1);

    selectedRows = find(groupNames == groupName);
    for rowIndex = selectedRows.'
        [statistics, samples] = ...
            sdv.metrics.computeSampleStatistics(sampleGroups{rowIndex});

        delayIndex = find( ...
            delayLevels_ms == delayValues_ms(rowIndex), 1);
        xPosition = delayIndex + offsets(groupIndex);

        xSamples = [xSamples; repmat(xPosition, numel(samples), 1)]; %#ok<AGROW>
        ySamples = [ySamples; samples]; %#ok<AGROW>
        markerX(end+1,1) = xPosition; %#ok<AGROW>
        meanValues(end+1,1) = statistics.Mean; %#ok<AGROW>
        p95Values(end+1,1) = statistics.P95; %#ok<AGROW>

        sampleCount(rowIndex) = statistics.SampleCount;
        sampleMean(rowIndex) = statistics.Mean;
        sampleMedian(rowIndex) = statistics.Median;
        sampleP95(rowIndex) = statistics.P95;
        sampleP99(rowIndex) = statistics.P99;
    end

    boxHandles(groupIndex) = boxchart( ...
        axesHandle, xSamples, ySamples, ...
        BoxFaceColor=colors(groupIndex,:), ...
        BoxWidth=0.30, ...
        MarkerStyle=".", ...
        DisplayName=replace(groupName, "_", " "));

    if options.ShowMean
        plot(axesHandle, markerX, meanValues, "d", ...
            Color=colors(groupIndex,:), ...
            MarkerFaceColor="white", HandleVisibility="off");
    end
    if options.ShowP95
        plot(axesHandle, markerX, p95Values, "^", ...
            Color=colors(groupIndex,:), ...
            MarkerFaceColor=colors(groupIndex,:), ...
            HandleVisibility="off");
    end
end

hold(axesHandle, "off");
grid(axesHandle, "on");
xticks(axesHandle, 1:numel(delayLevels_ms));
xticklabels(axesHandle, string(delayLevels_ms));
xlabel(axesHandle, "Equivalent delay (ms)");
ylabel(axesHandle, options.YLabel);
title(axesHandle, options.Title);
legend(axesHandle, boxHandles, replace(uniqueGroups, "_", " "), ...
    Interpreter="none", Location="best");

statisticsTable = table( ...
    delayValues_ms, groupNames, sampleCount, sampleMean, sampleMedian, ...
    sampleP95, sampleP99, ...
    VariableNames=["delay_ms", "group", "sample_count", "mean", ...
    "median", "p95", "p99"]);

end
