bdclose("all");
clear mex;
clear classes;

startup_project;

config = build_phase0_configuration("highway_cruise");

[ocp, metadata] = build_acados_ocp( ...
    config.adaptiveModel, ...
    config.controller, ...
    true);

solver = AcadosOcpSolver(ocp);

generatedDirectory = metadata.generated_directory;
cd(generatedDirectory);

make_sfun;