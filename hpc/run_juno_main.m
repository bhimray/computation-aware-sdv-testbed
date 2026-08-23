function run_juno_main()
%RUN_JUNO_MAIN Execute one existing SDV main script on Juno.
%
% SLURM_ARRAY_TASK_ID:
%   0 -> phase0/main.m
%   1 -> phase1/main.m
%   2 -> phase2/main.m

projectRoot = string(fileparts( ...
    fileparts(mfilename("fullpath"))));

taskText = string(getenv("SLURM_ARRAY_TASK_ID"));

assert(strlength(taskText) > 0, ...
    "SLURM_ARRAY_TASK_ID is not defined.");

taskIndex = str2double(taskText);

assert( ...
    isfinite(taskIndex) && ...
    ismember(taskIndex, 0:2), ...
    "SLURM_ARRAY_TASK_ID must be 0, 1, or 2.");

entryNames = [
    "phase0"
    "phase1"
    "phase2"
    ];

mainFiles = [
    fullfile(projectRoot, "phase0", "main.m")
    fullfile(projectRoot, "phase1", "main.m")
    fullfile(projectRoot, "phase2", "main.m")
    ];

entryName = entryNames(taskIndex + 1);
mainFile = mainFiles(taskIndex + 1);

assert(isfile(mainFile), ...
    "Main file does not exist: %s", mainFile);

%% Isolated Simulink cache for this SLURM task

scratchRoot = string(getenv("SDV_TASK_SCRATCH"));

if strlength(scratchRoot) == 0
    scratchRoot = fullfile( ...
        string(tempdir), ...
        "sdv_task_" + taskText);
end

cacheFolder = fullfile(scratchRoot, "simulink_cache");
codeGenerationFolder = fullfile(scratchRoot, "code_generation");

Simulink.fileGenControl( ...
    "set", ...
    "CacheFolder", cacheFolder, ...
    "CodeGenFolder", codeGenerationFolder, ...
    "createDir", true);

%% Headless and deterministic execution

set(groot, "defaultFigureVisible", "off");
rng(1001, "twister");

cd(projectRoot);
startup_project;

%% Fail before the long run if dependencies are unavailable

configuration = ...
    build_phase0_configuration("highway_cruise");

controller = configuration.controller;

check_runtime_requirements(controller);

if controller.controller_backend == ...
        controller.BACKEND_ACADOS

    [acadosAvailable, acadosRoot] = ...
        activate_acados(false);

    assert(acadosAvailable, ...
        "Linux acados installation is unavailable.");

    solverFile = fullfile( ...
        projectRoot, ...
        "build", ...
        "acados", ...
        "sdv_dynamic_bicycle", ...
        "acados_solver_sfunction_sdv_dynamic_bicycle." ...
        + string(mexext));

    assert(isfile(solverFile), ...
        [ ...
        "Linux acados S-function is missing:\n%s\n" ...
        "Generate the .mexa64 file before submitting jobs." ...
        ], ...
        solverFile);
else
    acadosRoot = "";
end

%% Save reproducibility metadata

jobId = string(getenv("SLURM_ARRAY_JOB_ID"));

if strlength(jobId) == 0
    jobId = "local";
end

runFolder = fullfile( ...
    projectRoot, ...
    "hpc", ...
    "runs", ...
    "job_" + jobId, ...
    "task_" + taskText + "_" + entryName);

if ~isfolder(runFolder)
    mkdir(runFolder);
end

manifest = struct();

manifest.entry_name = entryName;
manifest.main_file = mainFile;
manifest.job_id = jobId;
manifest.array_task_id = taskIndex;
manifest.started_utc = datetime( ...
    "now", TimeZone="UTC");

manifest.matlab_release = string(version("-release"));
manifest.matlab_version = string(version);
manifest.mex_extension = string(mexext);
manifest.hostname = string(getenv("HOSTNAME"));
manifest.allocated_cpus = string( ...
    getenv("SLURM_CPUS_PER_TASK"));
manifest.allocated_memory = string( ...
    getenv("SLURM_MEM_PER_NODE"));
manifest.acados_root = acadosRoot;
manifest.random_seed = 1001;
manifest.completed = false;
manifest.error_report = "";

manifestFile = fullfile(runFolder, "manifest.mat");
save(manifestFile, "manifest");

fprintf("\n========================================\n");
fprintf("Juno SDV run\n");
fprintf("Entry:   %s\n", entryName);
fprintf("Script:  %s\n", mainFile);
fprintf("Scratch: %s\n", scratchRoot);
fprintf("========================================\n\n");

%% Run the script in the base workspace
%
% phase1/main.m and phase2/main.m contain clearvars. Running them in the
% base workspace prevents clearvars from deleting this dispatcher's data.

escapedMainFile = strrep( ...
    char(mainFile), ...
    "'", ...
    "''");

runCommand = sprintf( ...
    "run('%s');", ...
    escapedMainFile);

try
    evalin("base", runCommand);

    manifest.completed = true;
    manifest.finished_utc = datetime( ...
        "now", TimeZone="UTC");

    save(manifestFile, "manifest");

    fprintf("\nJuno entry completed: %s\n", entryName);

catch simulationError
    manifest.completed = false;
    manifest.finished_utc = datetime( ...
        "now", TimeZone="UTC");

    manifest.error_report = string(getReport( ...
        simulationError, ...
        "extended", ...
        "hyperlinks", ...
        "off"));

    save(manifestFile, "manifest");

    fprintf(2, "%s\n", manifest.error_report);
    rethrow(simulationError);
end

end