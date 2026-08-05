function folders = createOutputFolders( ...
    projectRoot, runConfig, controllerName)
%CREATEOUTPUTFOLDERS Create deterministic result and figure directories.

arguments
    projectRoot (1,1) string
    runConfig (1,1) struct
    controllerName (1,1) string
end

pathParts = [ ...
    runConfig.phase_name
    controllerName
    ];

if runConfig.phase_name == "phase1"
    delayMilliseconds = 1e3 * runConfig.actuation_delay_s;
    delayText = string(sprintf("%g", delayMilliseconds));
    delayText = replace(delayText, ".", "p");
    pathParts(end + 1) = ...
        "actuation_delay_" + delayText + "_ms";
end

pathParts(end + 1) = runConfig.scenario_name;
pathParts(end + 1) = runConfig.environment_name;

folders = struct();
tailParts = pathParts(2:end);
folders.results = fullfile( ...
    projectRoot, runConfig.phase_name, "results", tailParts{:});
folders.figures = fullfile( ...
    projectRoot, runConfig.phase_name, "figures", tailParts{:});

if ~isfolder(folders.results)
    mkdir(folders.results);
end

if ~isfolder(folders.figures)
    mkdir(folders.figures);
end

end
