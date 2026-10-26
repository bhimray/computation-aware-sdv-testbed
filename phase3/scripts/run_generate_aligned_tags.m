%% Generate and save aligned tags for all scenarios

startup_project;

projectRoot = string( ...
    matlab.project.currentProject().RootFolder);

sourceFolder = fullfile( ...
    projectRoot, "phase3", "results", "demand_tags");

outputFolder = fullfile( ...
    projectRoot, "phase3", "results", "aligned_demand_tags");

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

scenarioNames = [
    "urban_profile"
    "highway_cruise"
    "aggressive_maneuver"
    ];

for scenarioName = scenarioNames.'

    sourceFile = fullfile( ...
        sourceFolder, scenarioName + "_tags.mat");

    savedData = load(sourceFile, "taggedScenario");

    alignedTags = generate_phase3_aligned_tags( ...
        savedData.taggedScenario, 0.010);

    alignedTags.source_file = sourceFile;

    outputBase = fullfile( ...
        outputFolder, scenarioName + "_aligned_tags");

    save(outputBase + ".mat", "alignedTags");

    writetable( ...
        alignedTags.timing_table, ...
        outputBase + ".csv");

    fprintf( ...
        "%s: %d accepted switches, %d nominal releases.\n", ...
        scenarioName, ...
        nnz(alignedTags.timing_table.switchAccepted), ...
        nnz(alignedTags.timing_table.controllerReleased));
end