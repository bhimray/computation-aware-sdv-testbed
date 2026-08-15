function durationData = load_control_task_durations( ...
    scenarioName, ...
    environmentName)

arguments
    scenarioName (1,1) string
    environmentName (1,1) string
end

project = matlab.project.currentProject;
projectRoot = string(project.RootFolder);

% Modify only this layout to match your existing Phase 1 folders.
resultFile = fullfile( ...
    projectRoot, ...
    "phase2", ...
    "DataSolveTime", ...
    scenarioName, ...
    environmentName, ...
    "results.mat");

assert(isfile(resultFile), ...
    "Phase 1 result file was not found:\n%s", ...
    resultFile);

savedData = load(resultFile);

% Support either results.solve_time_s or solve_time_s.
if isfield(savedData, "results") && ...
        isfield(savedData.results, "solve_time_s")

    solveTime_s = savedData.results.solve_time_s;

else
    error( ...
        "SDV:MissingSolveTime", ...
        "No solve_time_s variable was found in:\n%s", ...
        resultFile);
end

solveTime_s = double(solveTime_s(:));

valid = ...
    isfinite(solveTime_s) & ...
    solveTime_s > 0;

solveTime_s = solveTime_s(valid);

assert(~isempty(solveTime_s), ...
    "No positive finite solve-time samples exist in:\n%s", ...
    resultFile);

durationData = struct();

durationData.samples_s = solveTime_s;
durationData.stop_time_s = savedData.results.time_s(end);
durationData.source_file = string(resultFile);
durationData.scenario = scenarioName;
durationData.environment = environmentName;
durationData.mean_s = mean(solveTime_s);
durationData.maximum_s = max(solveTime_s);
durationData.deadline_miss_fraction = ...
    mean(solveTime_s > 0.010);

end