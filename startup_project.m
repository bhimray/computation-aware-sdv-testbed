function startup_project
%STARTUP_PROJECT Configure paths for the vehicle testbed.

projectRoot = fileparts(mfilename("fullpath"));

addpath(fullfile(projectRoot, "common"));
addpath(genpath(fullfile(projectRoot, "common")));
addpath(genpath(fullfile(projectRoot, "phase0")));
addpath(genpath(fullfile(projectRoot, "phase1")));
addpath(genpath(fullfile(projectRoot, "phase2")));
addpath(genpath(fullfile(projectRoot, "hpc")));

fprintf("Project initialized from:\n%s\n", projectRoot);

% Activate the optional pinned acados backend.
[acadosAvailable, ~] = activate_acados(false); %% if you want to activate acados:true

if ~acadosAvailable
    fprintf( ...
        "%s\n%s\n", ...
        "acados is not installed or configured.", ...
        "The MATLAB MPC backend remains available.");
end


end
