function [figureHandle, timingTable] = ...
    plot_scheduler_cycle( ...
        time_s, ...
        dwellMode, ...
        options)

arguments
    time_s (:,1) double
    dwellMode (:,1) double

    % Mode IDs: 1=LOW, 2=MEDIUM, 3=HIGH
    options.ModePeriods_ms (1,3) double = [50, 20, 10]
    options.BaseTick_ms (1,1) double = 10

    % Displayed interval only
    options.PlotStart_s (1,1) double = 0
    options.PlotDuration_s (1,1) double = 1

    options.ExportFile (1,1) string = ""
    options.Visible (1,1) string = "on"
end

assert(numel(time_s) == numel(dwellMode), ...
    "time_s and dwellMode must have equal lengths.");

assert(all(isfinite(time_s)) && ...
       all(isfinite(dwellMode)), ...
    "Inputs must contain finite values.");

assert(all(ismember(dwellMode, [1, 2, 3])), ...
    "Mode identifiers must be 1, 2, or 3.");

%% Prepare dwell-mode signal

[time_s, order] = sort(time_s);
dwellMode = dwellMode(order);

[time_s, uniqueIndices] = unique(time_s, "last");
dwellMode = dwellMode(uniqueIndices);

time_ms = 1000 * time_s;
baseTick_ms = options.BaseTick_ms;

periodTicks = ...
    options.ModePeriods_ms / baseTick_ms;

assert(all(abs(periodTicks - round(periodTicks)) < 1e-12), ...
    "Controller periods must be integer multiples of BaseTick_ms.");

periodTicks = round(periodTicks);

firstTick = ceil(time_ms(1) / baseTick_ms);
lastTick = floor(time_ms(end) / baseTick_ms);

tickNumber = (firstTick:lastTick).';
tickTime_ms = tickNumber * baseTick_ms;

assert(~isempty(tickTime_ms), ...
    "The input does not contain a complete scheduler tick.");

if isscalar(time_ms)
    dwellModeAtTick = repmat( ...
        dwellMode(1), ...
        size(tickTime_ms));
else
    dwellModeAtTick = interp1( ...
        time_ms, ...
        dwellMode, ...
        tickTime_ms, ...
        "previous", ...
        "extrap");
end

dwellModeAtTick = round(dwellModeAtTick);

%% Generate ERCOSek-aligned active mode

osekMode = zeros(size(dwellModeAtTick));
osekMode(1) = dwellModeAtTick(1);

for sampleIndex = 2:numel(tickNumber)

    previousMode = osekMode(sampleIndex - 1);
    requestedMode = dwellModeAtTick(sampleIndex);

    osekMode(sampleIndex) = previousMode;

    if requestedMode ~= previousMode

        switchingIntervalTicks = lcm( ...
            periodTicks(previousMode), ...
            periodTicks(requestedMode));

        legalSwitch = ...
            mod( ...
                tickNumber(sampleIndex), ...
                switchingIntervalTicks) == 0;

        if legalSwitch
            osekMode(sampleIndex) = requestedMode;
        end
    end
end

%% Store complete timing result

timingTable = table( ...
    tickTime_ms / 1000, ...
    dwellModeAtTick, ...
    osekMode, ...
    dwellModeAtTick ~= osekMode, ...
    VariableNames=[ ...
        "Time_s", ...
        "DwellMode", ...
        "OsekMode", ...
        "SwitchPending"]);
    
%% Select the displayed window

assert(options.PlotDuration_s > 0, ...
    "PlotDuration_s must be positive.");

windowStart_ms = 1000 * options.PlotStart_s;
windowEnd_ms = windowStart_ms + ...
    1000 * options.PlotDuration_s;

assert(windowStart_ms >= time_ms(1) && ...
       windowEnd_ms <= time_ms(end), ...
    "The requested window must be inside the saved tag data.");

%% Draw the two timelines

figureHandle = figure( ...
    Color="white", ...
    Visible=options.Visible, ...
    Position=[100 100 1400 450]);

ax = axes(figureHandle);
hold(ax, "on");

modeColors = [
    0.10 0.60 0.35
    0.95 0.55 0.05
    0.65 0.20 0.75
    ];

modeLabels = ["LOW", "MEDIUM", "HIGH"] + ...
    " (" + string(options.ModePeriods_ms) + " ms)";

drawTimingLane( ...
    ax, tickTime_ms, tickNumber, dwellModeAtTick, ...
    periodTicks, 2, windowStart_ms, windowEnd_ms, ...
    modeColors, modeLabels);

drawTimingLane( ...
    ax, tickTime_ms, tickNumber, osekMode, ...
    periodTicks, 1, windowStart_ms, windowEnd_ms, ...
    modeColors, modeLabels);

windowWidth_ms = windowEnd_ms - windowStart_ms;

xlim(ax, [0 windowWidth_ms]);
ylim(ax, [0.85 2.85]);

xticks(ax, linspace(0, windowWidth_ms, 11));
yticks(ax, [1 2]);
yticklabels(ax, ["Aligned mode", "Requested demand"]);

ax.Color = "white";
ax.XColor = "black";
ax.YColor = "black";
ax.FontSize = 12;
ax.TickLength = [0 0];
ax.Box = "off";
ax.YGrid = "off";
ax.XGrid = "on";
ax.GridAlpha = 0.12;

xlabel(ax, "Time from window start (ms)");

title(ax, {
    sprintf("Demand timing: %.3f–%.3f s", ...
        windowStart_ms / 1000, windowEnd_ms / 1000)
    "Shading: demand mode | Dots: nominal release instants"
    }, Color="black");

%% Optional export

if strlength(options.ExportFile) > 0
    exportgraphics( ...
        ax, options.ExportFile, ...
        Resolution=300, ...
        BackgroundColor="white");
end

end


function drawTimingLane( ...
    ax, time_ms, tickNumber, mode, periodTicks, ...
    laneY, windowStart_ms, windowEnd_ms, ...
    modeColors, modeLabels)

windowWidth_ms = windowEnd_ms - windowStart_ms;

% Locate mode changes using the full timeline.
changeIndices = [1; find(diff(mode) ~= 0) + 1];
segmentStarts = time_ms(changeIndices);
segmentEnds = [segmentStarts(2:end); windowEnd_ms];

for index = 1:numel(changeIndices)

    % Clip each mode interval to the requested window.
    left = max(segmentStarts(index), windowStart_ms);
    right = min(segmentEnds(index), windowEnd_ms);

    if right <= left
        continue
    end

    left = left - windowStart_ms;
    right = right - windowStart_ms;
    modeIndex = mode(changeIndices(index));

    patch(ax, ...
        [left right right left], ...
        [laneY laneY laneY+0.28 laneY+0.28], ...
        modeColors(modeIndex,:), ...
        FaceAlpha=0.25, ...
        EdgeColor="none");

    % Avoid crowded labels in very short intervals.
    if right - left >= windowWidth_ms / 12
        text(ax, ...
            (left + right)/2, laneY + 0.14, ...
            modeLabels(modeIndex), ...
            HorizontalAlignment="center", ...
            VerticalAlignment="middle", ...
            FontSize=11, ...
            Color="black", ...
            Interpreter="none");
    end
end

% Determine releases from the full tick sequence.
% Opening another plot window does not restart the schedule.
releasePeriodTicks = periodTicks(mode);
releasePeriodTicks = releasePeriodTicks(:);

isRelease = mod(tickNumber, releasePeriodTicks) == 0;

inWindow = ...
    time_ms >= windowStart_ms & ...
    time_ms <= windowEnd_ms;

releaseTime_ms = ...
    time_ms(isRelease & inWindow) - windowStart_ms;

plot(ax, ...
    [0 windowWidth_ms], [laneY laneY], ...
    "k-", LineWidth=1.3);

if ~isempty(releaseTime_ms)
    markers = stem(ax, ...
        releaseTime_ms, ...
        repmat(laneY + 0.62, size(releaseTime_ms)), ...
        "filled", ...
        BaseValue=laneY, ...
        Color="black", ...
        MarkerSize=3, ...
        LineWidth=1);

    markers.BaseLine.Visible = "off";
end

end