%% Three reference-path panels for the research paper (no simulation).
% Run this file directly. It reads the saved track variables in scenarios/data.
% Copy the exported scenario_paths.pdf to the paper's figures/ directory.

projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
scenarioFolder = fullfile(projectRoot, 'phase0', 'scenarios', 'data');
outputFolder = fullfile(projectRoot, 'phase0', 'results', 'paper_figures');

%% Editable plot settings
scenarioNames = ["highway_cruise", "urban_profile", "aggressive_maneuver"];
panelTitles = ["(a) Highway cruise", "(b) Urban profile", "(c) Aggressive maneuver"];
saveFigure = true;
equalAxisScale = false; % true preserves geometric aspect ratio; long paths look flat.
figureSize_cm = [18, 6.5]; % Two-column paper width.
fontSize = 12;
pathColor = [0.10, 0.35, 0.65];

%% Load all paths before creating the figure
tracks = cell(1, numel(scenarioNames));
for k = 1:numel(scenarioNames)
    sourceFile = fullfile(scenarioFolder, scenarioNames(k) + ".mat");
    assert(isfile(sourceFile), 'Missing scenario file: %s', sourceFile);
    saved = load(sourceFile, 'track');
    assert(isfield(saved, 'track') && ...
        all(isfield(saved.track, {'X_ref_m', 'Y_ref_m'})), ...
        'Expected track.X_ref_m and track.Y_ref_m in %s.', sourceFile);
    x = saved.track.X_ref_m(:);
    y = saved.track.Y_ref_m(:);
    assert(numel(x) == numel(y) && numel(x) >= 2 && ...
        all(isfinite(x)) && all(isfinite(y)), ...
        'Invalid reference-path coordinates in %s.', sourceFile);
    tracks{k} = [x, y];
end

%% Plot: independent distance axes, one shared legend
figureHandle = figure('Color', 'white', 'Name', 'Reference paths', ...
    'Units', 'centimeters', 'Position', [2, 2, figureSize_cm]);
layout = tiledlayout(figureHandle, 1, 3, ...
    'TileSpacing', 'compact', 'Padding', 'compact');

for k = 1:numel(tracks)
    ax = nexttile(layout);
    xy = tracks{k};
    pathHandle = plot(ax, xy(:,1), xy(:,2), '-', ...
        'Color', pathColor, 'LineWidth', 1.4);
    hold(ax, 'on');
    startHandle = plot(ax, xy(1,1), xy(1,2), 'o', ...
        'Color', pathColor, 'MarkerFaceColor', 'white', 'MarkerSize', 5);
    endHandle = plot(ax, xy(end,1), xy(end,2), 's', ...
        'Color', pathColor, 'MarkerFaceColor', pathColor, 'MarkerSize', 5);
    set(ax, 'FontName', 'Times New Roman', 'FontSize', fontSize, ...
        'Color', 'white', 'XColor', 'black', 'YColor', 'black', ...
        'GridColor', [0.7, 0.7, 0.7], 'GridAlpha', 0.25, 'Box', 'on');
    grid(ax, 'on');
    axis(ax, 'padded');
    if equalAxisScale
        axis(ax, 'equal');
    end
    xlabel(ax, 'X (m)');
    ylabel(ax, 'Y (m)');
    title(ax, panelTitles(k), 'FontWeight', 'normal', 'Color', 'black');
    if k == 1
        legendHandles = [pathHandle, startHandle, endHandle];
    end
end
sharedLegend = legend(legendHandles, {'Reference path', 'Start', 'End'}, ...
    'Orientation', 'horizontal', 'Box', 'off', ...
    'TextColor', 'black', 'FontSize', fontSize);
sharedLegend.Layout.Tile = 'south';

%% Export vector PDF and editable MATLAB figure
if saveFigure
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end
    drawnow;
    exportgraphics(figureHandle, fullfile(outputFolder, 'scenario_paths.pdf'), ...
        'ContentType', 'vector', 'BackgroundColor', 'white');
    savefig(figureHandle, fullfile(outputFolder, 'scenario_paths.fig'));
    fprintf('Saved reference-path figures to:\n%s\n', outputFolder);
end
