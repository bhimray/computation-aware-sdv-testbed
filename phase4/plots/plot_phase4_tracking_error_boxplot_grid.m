function figureHandle = plot_phase4_tracking_error_boxplot_grid(runs, options)
%PLOT_PHASE4_TRACKING_ERROR_BOXPLOT_GRID Compare fixed-rate error distributions.

arguments
    runs (1,:) struct
    options.Visible (1,1) string {mustBeMember(options.Visible,["on","off"])} = "on"
    options.FigureSize_cm (1,2) double {mustBePositive} = [17.8 16]
    options.FontSize (1,1) double {mustBePositive} = 8
    options.UseAbsoluteError (1,1) logical = true
end

scenarios = ["highway_cruise","urban_profile","aggressive_maneuver"];
environments = ["dry_road","low_friction_road"];
periods_ms = [10 20 50];
colors = [0.00 0.45 0.74; 0.85 0.33 0.10; 0.93 0.69 0.13];

figureHandle = figure(Color="white",Visible=options.Visible, ...
    Units="centimeters",Position=[2 2 options.FigureSize_cm]);
layout = tiledlayout(figureHandle,4,3, ...
    TileSpacing="compact",Padding="compact");

for environmentIndex = 1:numel(environments)
    valueFields = ["Ey_m","Epsi_deg"];
    metricLabels = ["$|e_y|$ (m)","$|e_\psi|$ (deg)"];
    for metricIndex = 1:numel(valueFields)
        rowIndex = (environmentIndex-1)*2+metricIndex;
        for scenarioIndex = 1:numel(scenarios)
            tileIndex = (rowIndex-1)*numel(scenarios)+scenarioIndex;
            axesHandle = nexttile(layout,tileIndex);
            hold(axesHandle,"on");

            for periodIndex = 1:numel(periods_ms)
                selected = string({runs.Scenario})==scenarios(scenarioIndex) & ...
                    string({runs.Environment})==environments(environmentIndex) & ...
                    [runs.SampleTime_ms]==periods_ms(periodIndex);
                assert(nnz(selected)==1,"Missing or duplicate fixed-rate run.");
                values = runs(selected).(valueFields(metricIndex));
                if options.UseAbsoluteError, values=abs(values); end
                boxchart(axesHandle,repmat(periodIndex,size(values)),values, ...
                    BoxFaceColor=colors(periodIndex,:),BoxWidth=0.55, ...
                    MarkerStyle=".");
            end

            styleAxes(axesHandle,options.FontSize);
            xticks(axesHandle,1:3);
            xticklabels(axesHandle,compose("%g ms",periods_ms));
            if rowIndex==1
                title(axesHandle,replace(scenarios(scenarioIndex),"_"," "), ...
                    Interpreter="none",FontWeight="normal");
            end
            if scenarioIndex==1
                ylabel(axesHandle,replace(environments(environmentIndex),"_"," ") + ...
                    newline + metricLabels(metricIndex),Interpreter="latex");
            end
            if rowIndex==4
                xlabel(axesHandle,"Controller period");
            end
        end
    end
end
end

function styleAxes(axesHandle,fontSize)
grid(axesHandle,"on");
set(axesHandle,FontName="Times New Roman",FontSize=fontSize, ...
    LineWidth=0.75,Box="on",GridAlpha=0.15,TickDir="out");
end
