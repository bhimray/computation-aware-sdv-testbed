%% Table VII: fixed 10/20/50 ms, offline supervisor, online supervisor.
% Reads saved results only. Does not modify simulation or sweep summaries.
projectRoot = string(fileparts(fileparts(fileparts(mfilename('fullpath')))));
addpath(fullfile(projectRoot, 'common'));

%% Select one comparison (edit these settings or the five paths below).
scenarioName = "aggressive_maneuver";
environmentName = "low_friction_road";
loadExecutionTime_ms = 20;
saveTable = true;

fixedRoot = fullfile(projectRoot, 'phase4', 'results', ...
    'performance_map_runs', scenarioName, environmentName);
sourceFiles = [
    fullfile(fixedRoot, 'sample_time_010_ms', 'fixed_mode_run.mat')
    fullfile(fixedRoot, 'sample_time_020_ms', 'fixed_mode_run.mat')
    fullfile(fixedRoot, 'sample_time_050_ms', 'fixed_mode_run.mat')
    fullfile(projectRoot, 'phase3', 'results', 'aligned_scheduler_runs', ...
        scenarioName, environmentName, ...
        "load_" + string(loadExecutionTime_ms/1000), 'simulation_output.mat')
    fullfile(projectRoot, 'phase4', 'results', 'lookup_supervisor', ...
        scenarioName, environmentName, 'simulation_output.mat')
    ];
controllerNames = ["Fixed 10 ms"; "Fixed 20 ms"; "Fixed 50 ms"; ...
    "Offline supervisor"; "Online supervisor"];

%% Compute full-run metrics using the existing saved-result convention.
rows = cell(5,1);
for k = 1:5
    assert(isfile(sourceFiles(k)), 'Missing result file: %s', sourceFiles(k));
    saved = load(sourceFiles(k), 'runArtifact');
    assert(isfield(saved, 'runArtifact'), 'Missing runArtifact: %s', sourceFiles(k));
    a = saved.runArtifact;
    assert(string(a.scenarioName) == scenarioName && ...
        string(a.environmentName) == environmentName, ...
        'Scenario/environment mismatch: %s', sourceFiles(k));
    assert(abs(a.loadExecutionTime_ms-loadExecutionTime_ms) < 1e-6, ...
        'Load mismatch in %s: saved %.3f ms, requested %.3f ms.', ...
        sourceFiles(k), a.loadExecutionTime_ms, loadExecutionTime_ms);
    rows{k} = comparisonRow(a, controllerNames(k));
end
comparisonData = vertcat(rows{:});
comparisonData.SourceFile = sourceFiles;

%% Display the compact columns used in the paper.
paperTable = table(comparisonData.Controller, comparisonData.LateralRMS_m, ...
    comparisonData.HeadingRMS_deg, ...
    compose('%.4g / %.4g', comparisonData.LateralPeak_m, comparisonData.HeadingPeak_deg), ...
    comparisonData.MeanCPU_pct, comparisonData.ResponseP95_ms, ...
    compose('%d / %d', comparisonData.DeadlineMisses, comparisonData.DroppedJobs), ...
    comparisonData.SolverFailureSamples, ...
    compose('%.1f / %.1f / %.1f', comparisonData.Mode10_pct, ...
        comparisonData.Mode20_pct, comparisonData.Mode50_pct), ...
    'VariableNames', {'Controller','LateralRMS_m','HeadingRMS_deg', ...
    'PeakErrors_m_deg','MeanCPU_pct','ResponseP95_ms','Misses_Drops', ...
    'SolverFailureSamples','Mode10_20_50_pct'});
disp(paperTable);
fprintf('Misses include late completed jobs plus dropped jobs (existing collector convention).\n');
fprintf('Solver failures count nonzero logged status samples, not inferred failed jobs.\n');
fprintf('Mode occupancy is time-weighted; CPU uses the saved observed C/T estimate.\n');

if saveTable
    outputFolder = fullfile(projectRoot, 'phase4', 'results', 'paper_tables', ...
        scenarioName, environmentName, "load_" + string(loadExecutionTime_ms) + "_ms");
    if ~isfolder(outputFolder), mkdir(outputFolder); end
    writetable(paperTable, fullfile(outputFolder, 'tracking_scheduling_comparison.csv'));
    save(fullfile(outputFolder, 'tracking_scheduling_comparison.mat'), ...
        'paperTable', 'comparisonData', 'scenarioName', 'environmentName', ...
        'loadExecutionTime_ms');
    fprintf('Saved comparison tables:\n%s\n', outputFolder);
end

function row = comparisonRow(a, name)
    r = a.results;
    ey = double(r.ey_m(:));
    ep = rad2deg(double(r.epsi_rad(:)));
    assert(~isempty(ey) && all(isfinite(ey)) && all(isfinite(ep)), ...
        'Invalid tracking samples in %s.', name);
    jobs = a.controlJobs;
    stats = sdv.metrics.computeSampleStatistics(1000*jobs.ResponseTime_s);
    task = a.taskData(strcmp(string({a.taskData.Name}), "ControlTask"));
    assert(isscalar(task), 'Expected one ControlTask record for %s.', name);
    drops = double(task.NumDropped);
    assert(isscalar(drops) && isfinite(drops), 'Invalid drop count for %s.', name);
    late = sum(jobs.DeadlineMiss);
    status = double(r.solve_status(:));
    failures = sum(isfinite(status) & status ~= 0);
    occupancy = modeOccupancy(a.mode, r.time_s);
    row = table(name, sqrt(mean(ey.^2)), sqrt(mean(ep.^2)), ...
        max(abs(ey)), max(abs(ep)), double(a.observedCpuUtilization.Total_pct), ...
        stats.P95, late+drops, drops, failures, occupancy(1), occupancy(2), ...
        occupancy(3), double(r.time_s(end)-r.time_s(1)), ...
        'VariableNames', {'Controller','LateralRMS_m','HeadingRMS_deg', ...
        'LateralPeak_m','HeadingPeak_deg','MeanCPU_pct','ResponseP95_ms', ...
        'DeadlineMisses','DroppedJobs','SolverFailureSamples', ...
        'Mode10_pct','Mode20_pct','Mode50_pct','RunDuration_s'});
end

function pct = modeOccupancy(mode, runTime)
    t = double(mode.Time_s(:));
    m = double(mode.Data(:));
    [t, idx] = unique(t, 'last'); m = m(idx);
    first = double(runTime(1)); last = double(runTime(end));
    assert(~isempty(t) && t(1) <= first && last > first, ...
        'Mode log must cover the observation start.');
    edges = unique([first; t(t>first & t<last); last]);
    if isscalar(t)
        active = repmat(m, numel(edges)-1, 1);
    else
        active = interp1(t, m, edges(1:end-1), 'previous', 'extrap');
    end
    assert(all(ismember(active, [1 2 3])), 'Invalid active mode in saved run.');
    dt = diff(edges);
    pct = zeros(1,3);
    modes = [3 2 1]; % Saved mode IDs: HIGH=3, MEDIUM=2, LOW=1.
    for j = 1:3
        pct(j) = 100*sum(dt(active==modes(j)))/(last-first);
    end
end
