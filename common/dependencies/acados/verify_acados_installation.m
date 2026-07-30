function report = verify_acados_installation()
%VERIFY_ACADOS_INSTALLATION Verify the pinned acados dependency.

dependency = acados_dependency();

[available, acadosRoot] = activate_acados(true);

interfaceFile = fullfile( ...
    acadosRoot, ...
    "interfaces", ...
    "acados_matlab_octave", ...
    "AcadosOcp.m");

casadiFile = fullfile( ...
    acadosRoot, ...
    "external", ...
    "casadi-matlab", ...
    "+casadi", ...
    "MX.m");

if ispc
    acadosLibrary = fullfile(acadosRoot, "lib", "acados.lib");
    teraExecutable = fullfile(acadosRoot, "bin", "t_renderer.exe");
else
    acadosLibrary = fullfile(acadosRoot, "lib", "libacados.so");
    teraExecutable = fullfile(acadosRoot, "bin", "t_renderer");
end

% Determine the installed Git commit.
gitCommand = sprintf( ...
    'git -C "%s" rev-parse HEAD', ...
    char(acadosRoot));

[gitStatus, gitOutput] = system(gitCommand);
actualCommit = string(strtrim(gitOutput));

commitMatches = ...
    gitStatus == 0 && ...
    strcmpi(actualCommit, dependency.commit);

checkName = [
    "Installation activated"
    "AcadosOcp interface"
    "CasADi interface"
    "acados library"
    "Tera renderer"
    "Pinned Git commit"
    ];

passed = [
    available
    isfile(interfaceFile)
    isfile(casadiFile)
    isfile(acadosLibrary)
    isfile(teraExecutable)
    commitMatches
    ];

report = table(checkName, passed);

disp(report);

fprintf("Required version: %s\n", dependency.version);
fprintf("Required commit:  %s\n", dependency.commit);
fprintf("Installed commit: %s\n", actualCommit);

if ~all(passed)
    failedChecks = checkName(~passed);

    error( ...
        "SDV:AcadosVerificationFailed", ...
        "acados verification failed: %s", ...
        strjoin(failedChecks, ", "));
end

fprintf("Pinned acados installation verified successfully.\n");

end