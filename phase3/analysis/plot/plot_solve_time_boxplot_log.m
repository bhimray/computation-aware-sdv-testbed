function [figureHandle, summaryTable] = ...
    plot_solve_time_boxplot_log( ...
        solveTimeGroups_ms, ...
        groupLabels, ...
        samplingTimes_ms, ...
        options)
%PLOT_SOLVE_TIME_BOXPLOT_LOG Plot grouped solve times on a logarithmic y-axis.
%
% solveTimeGroups_ms is an N-by-M cell array. N is the number of x-axis
% groups and M is the number of controller sampling periods. Each cell
% contains the raw solve-time samples in milliseconds.

arguments
    solveTimeGroups_ms (:,:) cell
    groupLabels (:,1) string
    samplingTimes_ms (1,:) double {mustBePositive}
    options.SeriesLabels (1,:) string = strings(1,0)
    options.Colors (:,3) double = zeros(0,3)
    options.ShowDeadlineLines (1,1) logical = true
    options.Deadlines_ms (1,:) double = double.empty(1,0)
    options.FontSize_pt (1,1) double {mustBePositive} = 12
    options.FigureSize_in (1,2) double {mustBePositive} = [7.16, 3.6]
    options.YLimits_ms (1,2) double = [NaN, NaN]
    options.BoxFaceAlpha (1,1) double = 0.70
    options.MarkerStyle (1,1) string = "."
    options.Title (1,1) string = ""
    options.YLabel (1,1) string = "Solve time (ms)"
    options.LegendLocation (1,1) string = "northoutside"
    options.ExportPDF (1,1) string = ""
    options.ExportPNG (1,1) string = ""
    options.PNGResolution_dpi (1,1) double {mustBePositive} = 600
    options.ShowFigure (1,1) logical = true
end

[numberOfGroups, numberOfSeries] = size(solveTimeGroups_ms);

assert(numel(groupLabels) == numberOfGroups, ...
    "Provide one label for every solve-time group.");
assert(numel(samplingTimes_ms) == numberOfSeries, ...
    "Provide one sampling time for every series.");

if isempty(options.SeriesLabels)
    seriesLabels = compose("%g ms", samplingTimes_ms);
else
    assert(numel(options.SeriesLabels) == numberOfSeries, ...
        "Provide one series label for every sampling time.");
    seriesLabels = options.SeriesLabels;
end

if isempty(options.Colors)
    colors = lines(numberOfSeries);
else
    assert(size(options.Colors,1) >= numberOfSeries, ...
        "Colors must contain at least one row per series.");
    colors = options.Colors(1:numberOfSeries,:);
end

if isempty(options.Deadlines_ms)
    deadlines_ms = samplingTimes_ms;
else
    assert(numel(options.Deadlines_ms) == numberOfSeries, ...
        "Provide one deadline for every series.");
    deadlines_ms = options.Deadlines_ms;
end

visibility = "off";
if options.ShowFigure
    visibility = "on";
end

figureHandle = figure( ...
    Color="white", ...
    Visible=visibility, ...
    Units="inches", ...
    Position=[1, 1, options.FigureSize_in]);

axesHandle = axes( ...
    figureHandle, ...
    Color="white", ...
    FontSize=options.FontSize_pt, ...
    YScale="log");

hold(axesHandle, "on");
grid(axesHandle, "on");
box(axesHandle, "on");

offsets = linspace(-0.25, 0.25, numberOfSeries);
boxWidth = min(0.20, 0.65/numberOfSeries);
legendHandles = gobjects(numberOfSeries,1);

recordCount = numberOfGroups*numberOfSeries;
groupColumn = strings(recordCount,1);
samplingColumn_ms = NaN(recordCount,1);
sampleCount = zeros(recordCount,1);
meanColumn_ms = NaN(recordCount,1);
medianColumn_ms = NaN(recordCount,1);
p95Column_ms = NaN(recordCount,1);
p99Column_ms = NaN(recordCount,1);
maximumColumn_ms = NaN(recordCount,1);

recordIndex = 0;

for groupIndex = 1:numberOfGroups
    for seriesIndex = 1:numberOfSeries
        recordIndex = recordIndex + 1;

        samples_ms = double( ...
            solveTimeGroups_ms{groupIndex,seriesIndex}(:));
        samples_ms = samples_ms( ...
            isfinite(samples_ms) & samples_ms > 0);

        assert(~isempty(samples_ms), ...
            "Group '%s', series '%s' contains no positive finite samples.", ...
            groupLabels(groupIndex), seriesLabels(seriesIndex));

        xPosition = groupIndex + offsets(seriesIndex);

        chartHandle = boxchart( ...
            axesHandle, ...
            repmat(xPosition,size(samples_ms)), ...
            samples_ms, ...
            BoxFaceColor=colors(seriesIndex,:), ...
            BoxFaceAlpha=options.BoxFaceAlpha, ...
            BoxWidth=boxWidth, ...
            MarkerStyle=options.MarkerStyle, ...
            JitterOutliers="on", ...
            DisplayName=seriesLabels(seriesIndex));

        if groupIndex == 1
            legendHandles(seriesIndex) = chartHandle;
        else
            chartHandle.HandleVisibility = "off";
        end

        groupColumn(recordIndex) = groupLabels(groupIndex);
        samplingColumn_ms(recordIndex) = samplingTimes_ms(seriesIndex);
        sampleCount(recordIndex) = numel(samples_ms);
        meanColumn_ms(recordIndex) = mean(samples_ms);
        medianColumn_ms(recordIndex) = median(samples_ms);
        p95Column_ms(recordIndex) = empiricalPercentile(samples_ms,95);
        p99Column_ms(recordIndex) = empiricalPercentile(samples_ms,99);
        maximumColumn_ms(recordIndex) = max(samples_ms);
    end
end

if options.ShowDeadlineLines
    for seriesIndex = 1:numberOfSeries
        lineHandle = yline( ...
            axesHandle, ...
            deadlines_ms(seriesIndex), ...
            "--", ...
            seriesLabels(seriesIndex) + " deadline", ...
            Color=colors(seriesIndex,:), ...
            LineWidth=1.0, ...
            FontSize=options.FontSize_pt);
        lineHandle.HandleVisibility = "off";
    end
end

xlim(axesHandle,[0.5,numberOfGroups+0.5]);
xticks(axesHandle,1:numberOfGroups);
xticklabels(axesHandle,groupLabels);
xtickangle(axesHandle,25);
ylabel(axesHandle,options.YLabel,FontSize=options.FontSize_pt);

if all(isfinite(options.YLimits_ms))
    assert(all(options.YLimits_ms > 0) && ...
        options.YLimits_ms(2) > options.YLimits_ms(1), ...
        "Logarithmic y-limits must be positive and increasing.");
    ylim(axesHandle,options.YLimits_ms);
end

if strlength(options.Title) > 0
    title( ...
        axesHandle, ...
        options.Title, ...
        FontSize=max(9,options.FontSize_pt));
end

legend( ...
    axesHandle, ...
    legendHandles, ...
    Location=options.LegendLocation, ...
    Orientation="horizontal", ...
    FontSize=options.FontSize_pt);

fontObjects = findall(figureHandle,"-property","FontSize");
for objectIndex = 1:numel(fontObjects)
    fontObjects(objectIndex).FontSize = max( ...
        options.FontSize_pt, ...
        fontObjects(objectIndex).FontSize);
end

summaryTable = table( ...
    groupColumn, ...
    samplingColumn_ms, ...
    sampleCount, ...
    meanColumn_ms, ...
    medianColumn_ms, ...
    p95Column_ms, ...
    p99Column_ms, ...
    maximumColumn_ms, ...
    VariableNames=[ ...
        "Group", "SamplingTime_ms", "Samples", "Mean_ms", ...
        "Median_ms", "P95_ms", "P99_ms", "Maximum_ms"]);

exportFigure(figureHandle,options.ExportPDF,"vector",NaN);
exportFigure( ...
    figureHandle, ...
    options.ExportPNG, ...
    "image", ...
    options.PNGResolution_dpi);

end


function value = empiricalPercentile(samples,percentile)

samples = sort(samples(:));
sampleIndex = max(1,ceil((percentile/100)*numel(samples)));
value = samples(sampleIndex);

end


function exportFigure(figureHandle,fileName,contentType,resolution)

if strlength(fileName) == 0
    return;
end

parentFolder = fileparts(fileName);
if strlength(parentFolder) > 0 && ~isfolder(parentFolder)
    mkdir(parentFolder);
end

if isfinite(resolution)
    exportgraphics(figureHandle,fileName,Resolution=resolution);
else
    exportgraphics(figureHandle,fileName,ContentType=contentType);
end

end
