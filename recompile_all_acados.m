function recompile_all_acados()
%REBUILD_ACADOS_BACKEND Recompile the fixed-interface acados backend.

bdclose("all");
clear mex; % also necessary to clear c++ building cache
clear functions; % necessary to ensure proper building and clearing cache
rehash toolboxcache;

s_fun_gen_acados_var_sample_time();


%% uncomment if you want to copy the s-function block ------ IMPORTANT ----------
% open_system( ...
% 'sdv_dynamic_bicycle_ocp_solver_simulink_block');

end