function startup_project
%STARTUP_PROJECT Configure paths for the vehicle testbed.

projectRoot = fileparts(mfilename("fullpath"));

addpath(fullfile(projectRoot, "common"));
addpath(genpath(fullfile(projectRoot, "common")));
addpath(genpath(fullfile(projectRoot, "phase0")));

fprintf("Project initialized from:\n%s\n", projectRoot);
end