function recompile_acados()
%REBUILD_ACADOS_BACKEND Recompile the fixed-interface acados backend.

bdclose("all");
clear mex; % also necessary to clear c++ building cache
clear functions; % necessary to ensure proper building and clearing cache
rehash toolboxcache;

solverFile = s_fun_generation_acados();

solverFolder = fileparts(solverFile);
addpath(solverFolder);
rehash;

%% uncomment if you want to copy the s-function block ------ IMPORTANT ----------

% open_system( ...
% 'sdv_dynamic_bicycle_ocp_solver_simulink_block');

end