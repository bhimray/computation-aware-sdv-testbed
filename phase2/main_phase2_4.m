%% Phase 2.4 processor-utilization sweep
clearvars;
close all;
clc;

startup_project;

projectRoot = string(matlab.project.currentProject().RootFolder);
logFolder = fullfile(projectRoot, "phase2", "results", "phase2_4");

if ~isfolder(logFolder)
    mkdir(logFolder);
end

logFile = fullfile( ...
    logFolder, ...
    "phase2_4_" + string(datetime("now", Format="yyyyMMdd_HHmmss")) + ".log");

diary(logFile);

try
    summaryTable = run_phase2_4_utilization_sweep( ...
            ScenarioNames=[ ...
                "urban_profile", ...
                "highway_cruise", ...
                "aggressive_maneuver"], ...
            EnvironmentNames=[ ...
                "dry_road", ...
                "low_friction_road" ...
                ], ...
            LoadExecutionTime_ms=20:5:40, ...
            RandomSeed=1001, ...
            Resume=false);

    disp(summaryTable);
    fprintf("\nPhase 2.4 sweep completed.\n");
catch exception
    fprintf(2, "\nPhase 2.4 sweep stopped: %s\n", exception.message);
    diary off;
    rethrow(exception);
end

diary off;

