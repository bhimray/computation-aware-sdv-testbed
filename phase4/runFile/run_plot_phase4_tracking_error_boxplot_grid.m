%% Box plots of fixed-rate errors used by the performance maps.
projectRoot = string(fileparts(fileparts(fileparts(mfilename("fullpath")))));
addpath(fullfile(projectRoot,"phase4","plots"));
resultsRoot = fullfile(projectRoot,"phase4","results","performance_map_runs");

scenarios = ["highway_cruise","urban_profile","aggressive_maneuver"];
environments = ["dry_road","low_friction_road"];
periods_ms = [10 20 50];
runs = struct("Scenario",{},"Environment",{},"SampleTime_ms",{}, ...
    "Ey_m",{},"Epsi_deg",{});

for scenario = scenarios
    for environment = environments
        for period_ms = periods_ms
            sourceFile = fullfile(resultsRoot,scenario,environment, ...
                sprintf("sample_time_%03d_ms",period_ms),"fixed_mode_run.mat");
            assert(isfile(sourceFile),"Missing result:\n%s",sourceFile);
            saved = load(sourceFile,"runArtifact");
            result = saved.runArtifact.results;
            valid = isfinite(result.ey_m) & isfinite(result.epsi_rad);
            runs(end+1) = struct( ... %#ok<SAGROW>
                "Scenario",scenario,"Environment",environment, ...
                "SampleTime_ms",period_ms, ...
                "Ey_m",double(result.ey_m(valid)), ...
                "Epsi_deg",rad2deg(double(result.epsi_rad(valid))));
        end
    end
end

figureHandle = plot_phase4_tracking_error_boxplot_grid(runs);
outputFolder = fullfile(projectRoot,"phase4","figures","paper");
if ~isfolder(outputFolder), mkdir(outputFolder); end
exportFigure(figureHandle,outputFolder,"fixed_rate_tracking_error_boxplots");
fprintf("Saved box plots to:\n%s\n",outputFolder);

function exportFigure(figureHandle,outputFolder,fileName)
basePath=fullfile(outputFolder,fileName);
exportgraphics(figureHandle,basePath+".pdf",ContentType="vector",BackgroundColor="white");
exportgraphics(figureHandle,basePath+".png",Resolution=300,BackgroundColor="white");
savefig(figureHandle,basePath+".fig");
end
