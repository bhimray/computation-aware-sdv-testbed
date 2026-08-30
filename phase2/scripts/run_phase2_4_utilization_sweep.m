function [summaryTable, figures] = ...
    run_phase2_4_utilization_sweep(options)
%RUN_PHASE2_4_UTILIZATION_SWEEP Sweep load-task execution time.
%
% table contains tracking, ControlTask, and LoadTask metrics

arguments
    options.ScenarioNames (1,:) string = [ ...
        "urban_profile", "highway_cruise", "aggressive_maneuver"]
    options.EnvironmentNames (1,:) string = [ ...
        "dry_road", "low_friction_road"]
    options.LoadExecutionTime_ms (1,:) double {mustBeNonnegative} = 0:5:40
    options.RandomSeed (1,1) double = 1001
    options.Resume (1,1) logical = true
    options.ShowFigure (1,1) logical = true
end

startup_project;

projectRoot = string(matlab.project.currentProject().RootFolder);
resultsFolder = fullfile(projectRoot, "phase2", "results", "phase2_4");
if ~isfolder(resultsFolder)
    mkdir(resultsFolder);
end

summaryFile = fullfile(resultsFolder, "phase2_4_summary.mat");
summaryCsv = fullfile(resultsFolder, "phase2_4_summary.csv");
summaryTable = emptySummaryTable();

if options.Resume && isfile(summaryFile)
    savedData = load(summaryFile, "summaryTable");
    if isfield(savedData, "summaryTable")
        summaryTable = savedData.summaryTable;
    end
end

numberOfCases = ...
    numel(options.ScenarioNames) ...
    * numel(options.EnvironmentNames) ...
    * numel(options.LoadExecutionTime_ms);
caseNumber = 0;

for scenarioName = options.ScenarioNames
    for environmentName = options.EnvironmentNames
        for loadExecutionTime_ms = options.LoadExecutionTime_ms
            caseNumber = caseNumber + 1;

            if options.Resume && isCompleted( ...
                    summaryTable, ...
                    scenarioName, ...
                    environmentName, ...
                    loadExecutionTime_ms)
                fprintf( ...
                    "[%d/%d] Skipping completed case: %s | %s | %.3f ms\n", ...
                    caseNumber, numberOfCases, scenarioName, ...
                    environmentName, loadExecutionTime_ms);
                continue;
            end

            fprintf( ...
                "\n[%d/%d] %s | %s | load %.3f ms\n", ...
                caseNumber, numberOfCases, scenarioName, ...
                environmentName, loadExecutionTime_ms);

            try
                [~, newRow] = run_phase2_4_case( ...
                    scenarioName, ...
                    environmentName, ...
                    loadExecutionTime_ms, ...
                    RandomSeed=options.RandomSeed, ...
                    SaveResults=true);
            catch exception
                errorReport = getReport( ...
                    exception, ...
                    "extended", ...
                    Hyperlinks="off");
                warning( ...
                    "SDV:Phase2_4CaseFailed", ...
                    "Phase 2.4 case failed:\n%s", ...
                    errorReport);
                newRow = failureRow( ...
                    scenarioName, ...
                    environmentName, ...
                    loadExecutionTime_ms, ...
                    options.RandomSeed, ...
                    exception);
            end

            summaryTable = removeExistingCase( ...
                summaryTable, ...
                scenarioName, ...
                environmentName, ...
                loadExecutionTime_ms);
            summaryTable = [summaryTable; newRow]; %#ok<AGROW>
            summaryTable = sortrows( ...
                summaryTable, ...
                ["Scenario", "Environment", "LoadExecution_ms"]);

            save(summaryFile, "summaryTable");
            writetable(summaryTable, summaryCsv);
            fprintf("Checkpoint saved: %s\n", summaryFile);
        end
    end
end

if options.ShowFigure
    figures = plot_phase2_4_utilization_sweep(summaryTable);
    figures.LoadTask = plot_phase2_4_load_task_sweep(summaryTable);
else
    figures = struct();
end

end


function tableData = emptySummaryTable()

record = emptySummaryRecord();
tableData = struct2table(record);
tableData(1,:) = [];

end


function record = emptySummaryRecord()

record = struct();
record.Scenario = "";
record.Environment = "";
record.LoadExecution_ms = NaN;
record.NominalUtilization = NaN;
record.SpeedRMS_mps = NaN;
record.LateralRMS_m = NaN;
record.HeadingRMS_deg = NaN;
record.ControlMeanResponse_ms = NaN;
record.ControlP95Response_ms = NaN;
record.ControlMaximumResponse_ms = NaN;
record.ControlDeadlineMissCount = NaN;
record.ControlDeadlineMissPercent = NaN;
record.ControlOverrunCount = NaN;
record.ControlDroppedJobs = NaN;
record.LoadMeanResponse_ms = NaN;
record.LoadP95Response_ms = NaN;
record.LoadMaximumResponse_ms = NaN;
record.LoadDeadlineMissCount = NaN;
record.LoadDeadlineMissPercent = NaN;
record.LoadOverrunCount = NaN;
record.LoadDroppedJobs = NaN;
record.RandomSeed = NaN;
record.Status = "";
record.ErrorIdentifier = "";
record.ErrorMessage = "";
record.RunFile = "";

end


function tf = isCompleted(tableData, scenario, environment, load_ms)

if isempty(tableData)
    tf = false;
    return;
end

tf = any( ...
    tableData.Scenario == scenario ...
    & tableData.Environment == environment ...
    & abs(tableData.LoadExecution_ms - load_ms) < 1e-9 ...
    & tableData.Status == "completed");

end


function tableData = removeExistingCase( ...
    tableData, scenario, environment, load_ms)

if isempty(tableData)
    return;
end

matching = ...
    tableData.Scenario == scenario ...
    & tableData.Environment == environment ...
    & abs(tableData.LoadExecution_ms - load_ms) < 1e-9;
tableData(matching,:) = [];

end


function row = failureRow( ...
    scenario, environment, load_ms, randomSeed, exception)

record = emptySummaryRecord();
record.Scenario = scenario;
record.Environment = environment;
record.LoadExecution_ms = load_ms;
record.RandomSeed = randomSeed;
record.Status = "failed";
record.ErrorIdentifier = string(exception.identifier);
record.ErrorMessage = replace(string(exception.message), newline, " ");
row = struct2table(record);

end
