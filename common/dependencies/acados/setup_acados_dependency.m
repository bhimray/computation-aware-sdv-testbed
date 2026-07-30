function setup_acados_dependency()
%SETUP_ACADOS_DEPENDENCY Install or verify the pinned acados dependency.

dependency = acados_dependency();
acadosRoot = string(dependency.root);

if ~ispc
    error( ...
        "SDV:UnsupportedPlatform", ...
        "The automated acados setup currently supports Windows only.");
end

% Reuse a valid existing installation.
if isfolder(acadosRoot)
    fprintf("Existing acados installation found.\n");
    verify_acados_installation();
    return;
end

%% Check required tools

[gitStatus, ~] = system("git --version");
[cmakeStatus, ~] = system("cmake --version");

if gitStatus ~= 0
    error("SDV:GitUnavailable", ...
        "Git is required to install acados.");
end

if cmakeStatus ~= 0
    error("SDV:CMakeUnavailable", ...
        "CMake is required to install acados.");
end

compiler = mex.getCompilerConfigurations("C", "Selected");

if isempty(compiler)
    error( ...
        "SDV:CompilerUnavailable", ...
        "No C compiler is selected in MATLAB.");
end

if ~contains(compiler.Name, "MinGW", IgnoreCase=true)
    error( ...
        "SDV:IncorrectCompiler", ...
        "Select the MinGW C compiler before installing acados.");
end

%% Create the dependency parent directory

dependencyParent = fileparts(acadosRoot);

if ~isfolder(dependencyParent)
    mkdir(dependencyParent);
end

%% Clone the pinned acados release

fprintf("Cloning acados %s to:\n%s\n", ...
    dependency.version, acadosRoot);

cloneCommand = sprintf( ...
    ['git -c core.longpaths=true clone ' ...
     '--branch "%s" --recurse-submodules "%s" "%s"'], ...
    dependency.version, ...
    dependency.repository, ...
    acadosRoot);

run_checked_command(cloneCommand, "acados clone");

%% Enforce the exact pinned commit

checkoutCommand = sprintf( ...
    'git -C "%s" checkout --detach "%s"', ...
    acadosRoot, ...
    dependency.commit);

run_checked_command(checkoutCommand, "acados commit checkout");

submoduleCommand = sprintf( ...
    'git -C "%s" submodule update --init --recursive', ...
    acadosRoot);

run_checked_command(submoduleCommand, "acados submodule setup");

%% Build the MATLAB interface

interfaceDirectory = fullfile( ...
    acadosRoot, ...
    "interfaces", ...
    "acados_matlab_octave");

addpath(interfaceDirectory);

originalDirectory = pwd;
directoryCleanup = onCleanup(@() cd(originalDirectory)); %#ok<NASGU>

acados_install_windows();

%% Verify the completed installation

rehash;
clear functions;

startup_project;
verify_acados_installation();

fprintf("acados dependency setup completed successfully.\n");

end


function run_checked_command(command, operationName)
%RUN_CHECKED_COMMAND Execute a system command and check its status.

fprintf("Running: %s\n", operationName);

[status, output] = system(command);

if status ~= 0
    error( ...
        "SDV:ExternalCommandFailed", ...
        "%s failed:\n%s", ...
        operationName, ...
        output);
end

end