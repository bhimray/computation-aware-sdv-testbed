function recompile_acados()
%REBUILD_ACADOS_BACKEND Recompile the fixed-interface acados backend.

solverFile = s_fun_generation_acados();

solverFolder = fileparts(solverFile);
addpath(solverFolder);
rehash;

open_system( ...
'sdv_dynamic_bicycle_ocp_solver_simulink_block');

end