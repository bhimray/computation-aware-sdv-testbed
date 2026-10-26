%% Fixed-rate tracking errors used to construct the performance maps.
projectRoot = string(fileparts(fileparts(fileparts(mfilename("fullpath")))));
addpath(fullfile(projectRoot,"phase4","plots"));

resultsRoot = fullfile(projectRoot,"phase4","results","performance_map_runs");
scenarioNames = ["highway_cruise","urban_profile","aggressive_maneuver"];
environmentNames = ["dry_road","low_friction_road"];
sampleTimes_ms = [10,20,50];
runs = struct("Scenario",{},"Environment",{},"SampleTime_ms",{}, ...
    "Time_s",{},"Ey_m",{},"Epsi_deg",{});

for scenario = scenarioNames
    for environment = environmentNames
        for sampleTime_ms = sampleTimes_ms
            sourceFile = fullfile(resultsRoot,scenario,environment, ...
                sprintf("sample_time_%03d_ms",sampleTime_ms),"fixed_mode_run.mat");
            assert(isfile(sourceFile),"Missing fixed-rate result:\n%s",sourceFile);
            saved = load(sourceFile,"runArtifact");
            result = saved.runArtifact.results;
            valid = isfinite(result.time_s) & isfinite(result.ey_m) & ...
                isfinite(result.epsi_rad);
            runs(end+1) = struct( ... %#ok<SAGROW>
                "Scenario",scenario,"Environment",environment, ...
                "SampleTime_ms",sampleTime_ms, ...
                "Time_s",double(result.time_s(valid)), ...
                "Ey_m",double(result.ey_m(valid)), ...
                "Epsi_deg",rad2deg(double(result.epsi_rad(valid))));
        end
    end
end

figures = plot_phase4_tracking_error_grid(runs, ...
    FigureSize_cm=[17.8 9.0],FontSize=8,LineWidth=1.2);

outputFolder = fullfile(projectRoot,"phase4","figures","paper");
if ~isfolder(outputFolder), mkdir(outputFolder); end
exportPaperFigure(figures.Lateral,outputFolder,"fixed_rate_lateral_error_grid");
exportPaperFigure(figures.Heading,outputFolder,"fixed_rate_heading_error_grid");
fprintf("Saved tracking-error grids to:\n%s\n",outputFolder);

function exportPaperFigure(figureHandle,outputFolder,fileName)
basePath = fullfile(outputFolder,fileName);
exportgraphics(figureHandle,basePath+".pdf",ContentType="vector", ...
    BackgroundColor="white");
exportgraphics(figureHandle,basePath+".png",Resolution=300, ...
    BackgroundColor="white");
savefig(figureHandle,basePath+".fig");
end
