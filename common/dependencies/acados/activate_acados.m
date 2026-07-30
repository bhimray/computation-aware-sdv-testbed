function [available, acadosRoot] = activate_acados(required)
%ACTIVATE_ACADOS Activate the pinned acados MATLAB installation.
%
% [available, acadosRoot] = activate_acados()
% activate_acados(true) throws an error if acados is unavailable.

arguments
    required (1,1) logical = false
end

dependency = acados_dependency();

% Allow an advanced user to override the default installation location.
customRoot = string(getenv("SDV_ACADOS_ROOT"));

if strlength(customRoot) > 0
    acadosRoot = customRoot;
else
    acadosRoot = string(dependency.root);
end

interfaceDirectory = fullfile( ...
    acadosRoot, ...
    "interfaces", ...
    "acados_matlab_octave");

casadiDirectory = fullfile( ...
    acadosRoot, ...
    "external", ...
    "casadi-matlab");

libraryDirectory = fullfile(acadosRoot, "lib");
binaryDirectory = fullfile(acadosRoot, "bin");

requiredLocationsExist = ...
    isfolder(acadosRoot) && ...
    isfolder(interfaceDirectory) && ...
    isfolder(casadiDirectory) && ...
    isfolder(libraryDirectory) && ...
    isfolder(binaryDirectory);

if ~requiredLocationsExist
    available = false;

    message = sprintf( ...
        "Pinned acados %s was not found at:\n%s", ...
        dependency.version, ...
        acadosRoot);

    if required
        error("SDV:AcadosNotFound", "%s", message);
    else
        return;
    end
end

% Add only the necessary acados folders.
% Do not use genpath(acadosRoot).
addpath(interfaceDirectory);
addpath(casadiDirectory);

compatibilityDirectory = fullfile( ...
    fileparts(mfilename('fullpath')), ...
    'compatibility');

if isfolder(compatibilityDirectory)
    addpath(compatibilityDirectory, '-begin');
end

% Set the environment expected by the acados MATLAB interface.
setenv("ACADOS_INSTALL_DIR", acadosRoot);
setenv("ENV_RUN", "true");

% Make the compiled acados libraries available to generated solvers.
currentPath = string(getenv("PATH"));
pathEntries = split(currentPath, pathsep);

if ~any(strcmpi(pathEntries, binaryDirectory))
    updatedPath = binaryDirectory + pathsep + currentPath;
    setenv("PATH", updatedPath);
end

% Confirm that the new MATLAB interface is now visible.
available = ~isempty(which("AcadosOcp"));

if required && ~available
    error( ...
        "SDV:AcadosInterfaceUnavailable", ...
        "The acados installation exists, but AcadosOcp is not visible.");
end

if available
    fprintf( ...
        "Activated acados %s from:\n%s\n", ...
        dependency.version, ...
        acadosRoot);
end

end