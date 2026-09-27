function figures = plot_phase4_tracking_error_grid(runs, options)
%PLOT_PHASE4_TRACKING_ERROR_GRID Plot fixed-rate errors by scenario and road.

arguments
    runs (1,:) struct
    options.Visible (1,1) string {mustBeMember(options.Visible,["on","off"])} = "on"
    options.FigureSize_cm (1,2) double {mustBePositive} = [17.8 9.0]
    options.FontSize (1,1) double {mustBePositive} = 8
    options.LineWidth (1,1) double {mustBePositive} = 1.2
end

scenarioOrder = ["highway_cruise", "urban_profile", "aggressive_maneuver"];
environmentOrder = ["dry_road", "low_friction_road"];
periodOrder_ms = [10, 20, 50];
colors = [0.00 0.45 0.74; 0.85 0.33 0.10; 0.93 0.69 0.13];

figures.Lateral = createGrid(runs, scenarioOrder, environmentOrder, ...
    periodOrder_ms, colors, "Ey_m", "$e_y$ (m)", ...
    "Fixed-rate lateral tracking error", options);
figures.Heading = createGrid(runs, scenarioOrder, environmentOrder, ...
    periodOrder_ms, colors, "Epsi_deg", "$e_\psi$ (deg)", ...
    "Fixed-rate heading tracking error", options);
end

function figureHandle = createGrid(runs, scenarios, environments, ...
        periods_ms, colors, valueField, yLabelText, figureName, options)

figureHandle = figure(Name=figureName, Color="white", ...
    Visible=options.Visible, Units="centimeters", ...
    Position=[2 2 options.FigureSize_cm]);
layout = tiledlayout(figureHandle, 2, 3, ...
    TileSpacing="compact", Padding="compact");
legendHandles = gobjects(numel(periods_ms),1);

for environmentIndex = 1:numel(environments)
    for scenarioIndex = 1:numel(scenarios)
        tileIndex = (environmentIndex-1)*numel(scenarios) + scenarioIndex;
        axesHandle = nexttile(layout, tileIndex);
        hold(axesHandle,"on");

        for periodIndex = 1:numel(periods_ms)
            selected = string({runs.Scenario}) == scenarios(scenarioIndex) & ...
                string({runs.Environment}) == environments(environmentIndex) & ...
                [runs.SampleTime_ms] == periods_ms(periodIndex);
            assert(nnz(selected)==1, ...
                "Expected one run for %s / %s / %g ms.", ...
                scenarios(scenarioIndex), environments(environmentIndex), ...
                periods_ms(periodIndex));
            run = runs(selected);
            lineHandle = plot(axesHandle, run.Time_s, run.(valueField), ...
                Color=colors(periodIndex,:), LineWidth=options.LineWidth);
            if tileIndex==1
                legendHandles(periodIndex)=lineHandle;
            end
        end

        styleAxes(axesHandle,options.FontSize);
        if environmentIndex==1
            title(axesHandle,replace(scenarios(scenarioIndex),"_"," "), ...
                Interpreter="none",FontWeight="normal");
        end
        if scenarioIndex==1
            ylabel(axesHandle,replace(environments(environmentIndex),"_"," ") + ...
                newline + yLabelText,Interpreter="latex");
        end
        if environmentIndex==numel(environments)
            xlabel(axesHandle,"Time (s)");
        end
    end
end

legendHandle = legend(legendHandles,compose("%g ms",periods_ms), ...
    Orientation="horizontal",Box="off",FontSize=options.FontSize);
legendHandle.Layout.Tile="south";
end

function styleAxes(axesHandle,fontSize)
grid(axesHandle,"on");
set(axesHandle,FontName="Times New Roman",FontSize=fontSize, ...
    LineWidth=0.75,Box="on",GridAlpha=0.15,TickDir="out");
end
