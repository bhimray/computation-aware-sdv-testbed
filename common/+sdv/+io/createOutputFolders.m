function folders = createOutputFolders( ...
    projectRoot, runConfig, controllerName)
%CREATEOUTPUTFOLDERS Create deterministic result and figure directories.

arguments
    projectRoot (1,1) string
    runConfig (1,1) struct
    controllerName (1,1) string
end

phaseFolderName = runConfig.phase_name;

if runConfig.phase_name == "phase1_trigger"
    phaseFolderName = "phase1";
end

pathParts = [phaseFolderName; controllerName];

if runConfig.phase_name == "phase1"
    delayMilliseconds = 1e3 * runConfig.actuation_delay_s;
    delayText = string(sprintf("%g", delayMilliseconds));
    delayText = replace(delayText, ".", "p");
    pathParts(end + 1) = ...
        "actuation_delay_" + delayText + "_ms";
elseif runConfig.phase_name == "phase1_trigger"
    jitterText = string(sprintf( ...
        "%g", runConfig.jitter.bound_ms));
    jitterText = replace(jitterText, ".", "p");

    pathParts(end + 1) = "sampling_jitter";
    pathParts(end + 1) = ...
        "jitter_bound_" + jitterText + "_ms";
    pathParts(end + 1) = ...
        "seed_" + string(runConfig.jitter.random_seed);
end

pathParts(end + 1) = runConfig.scenario_name;
pathParts(end + 1) = runConfig.environment_name;

folders = struct();
tailParts = pathParts(2:end);
folders.results = fullfile( ...
    projectRoot, phaseFolderName, "results", tailParts{:});
folders.figures = fullfile( ...
    projectRoot, phaseFolderName, "figures", tailParts{:});

if ~isfolder(folders.results)
    mkdir(folders.results);
end

if ~isfolder(folders.figures)
    mkdir(folders.figures);
end

end
