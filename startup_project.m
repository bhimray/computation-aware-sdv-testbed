function startup_project
%STARTUP_PROJECT Configure paths for the vehicle testbed.

projectRoot = fileparts(mfilename("fullpath"));

addpath(fullfile(projectRoot, "common"));
addpath(genpath(fullfile(projectRoot, "common")));
addpath(genpath(fullfile(projectRoot, "phase0")));

fprintf("Project initialized from:\n%s\n", projectRoot);
%% we are using this since all of the simullink parameter of the plant
%% is using UT variables: Don't change this file and vehicle parameter files
%% since both are not dependent by variable but values is intended to be same
%% for correct simulation.
run(fullfile(projectRoot, ...
    "common", "plant", "source", ...
    "Ego_car_speed_control_script_Student.m"))

assignin("base", "UT", UT);
end