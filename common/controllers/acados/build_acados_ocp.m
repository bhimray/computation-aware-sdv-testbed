function [ocp, metadata] = ...
    build_acados_ocp( ...
        modelParameters, controller, generateSimulinkBlock)
%BUILD_ACADOS_OCP

settings = acados_ocp_parameters(controller);

[model, ~] = ...
    build_acados_prediction_model(modelParameters);

nx = 5;
nu = 2;
N = settings.number_of_intervals;

%% OCP object

ocp = AcadosOcp();
ocp.model = model;

%% Initial-stage cost
% The state is fixed by the initial-condition constraint, so only penalize
% input effort at stage zero.

ocp.cost.cost_type_0 = 'NONLINEAR_LS';
ocp.model.cost_y_expr_0 = model.u;
ocp.cost.W_0 = settings.R;
ocp.cost.yref_0 = settings.nominal_input;

%% Intermediate-stage cost

ocp.cost.cost_type = 'NONLINEAR_LS';

ocp.model.cost_y_expr = vertcat( ...
    model.x, ...
    model.u);

ocp.cost.W = blkdiag( ...
    settings.Q, ...
    settings.R);

ocp.cost.yref = [
    controller.nominal_state
    settings.nominal_input
    ];

%% Terminal cost

ocp.cost.cost_type_e = 'NONLINEAR_LS';
ocp.model.cost_y_expr_e = model.x;
ocp.cost.W_e = settings.Q_terminal;
ocp.cost.yref_e = controller.nominal_state;

%% Input magnitude constraints

% ocp.model.con_h_expr_0 = model.u;
% ocp.constraints.lh_0 = settings.minimum_input;
% ocp.constraints.uh_0 = settings.maximum_input;

% ocp.model.con_h_expr = model.u;
% ocp.constraints.lh = settings.minimum_input;
% ocp.constraints.uh = settings.maximum_input;

%% Native input bounds

ocp.constraints.idxbu = (0:(nu - 1))';
ocp.constraints.lbu = settings.minimum_input;
ocp.constraints.ubu = settings.maximum_input;

%% Soft state constraints: intermediate nodes

constrainedStateIndices = [3; 4];

pathStateMinimum = [
    settings.minimum_state(4)   % e_y minimum, m
    settings.minimum_state(5)   % e_psi minimum, rad
    ];
pathStateMaximum = [
    settings.maximum_state(4)   % e_y maximum, m
    settings.maximum_state(5)   % e_psi maximum, rad
    ];

%% Intermediate stages

ocp.constraints.idxbx = constrainedStateIndices;
ocp.constraints.lbx = pathStateMinimum;
ocp.constraints.ubx = pathStateMaximum;
ocp.constraints.idxsbx = [0; 1];
slackPenalty = ...
    settings.slack_penalty * ones(2, 1);
ocp.cost.Zl = slackPenalty;
ocp.cost.Zu = slackPenalty;
ocp.cost.zl = zeros(2, 1);
ocp.cost.zu = zeros(2, 1);

% % Terminal stage
% % commenting terminal constraint because it solver throws status 4 (infeasible solution)
% ocp.constraints.idxbx_e = constrainedStateIndices;
% ocp.constraints.lbx_e = pathStateMinimum;
% ocp.constraints.ubx_e = pathStateMaximum;
% 
% ocp.constraints.idxsbx_e = [0; 1];
% 
% ocp.cost.Zl_e = slackPenalty;
% ocp.cost.Zu_e = slackPenalty;
% ocp.cost.zl_e = zeros(2, 1);
% ocp.cost.zu_e = zeros(2, 1);

% stateBoundIndices = (0:(nx - 1))';
% ocp.constraints.lbx = ...
%     settings.minimum_state;
% 
% ocp.constraints.ubx = ...
%     settings.maximum_state;

% % idxsbx indexes the entries in idxbx that are softened.
% ocp.constraints.idxsbx = ...
%     stateBoundIndices;
% 
% stateSlackPenalty = ...
%     settings.slack_penalty * ones(nx,1);

% % Quadratic slack penalties.
% ocp.cost.Zl = stateSlackPenalty;
% ocp.cost.Zu = stateSlackPenalty;
% 
% % No additional linear slack penalty.
% ocp.cost.zl = zeros(nx,1);
% ocp.cost.zu = zeros(nx,1);

% %% Soft state constraints: terminal node
% 
% ocp.constraints.idxbx_e = ...
%     stateBoundIndices;
% 
% ocp.constraints.lbx_e = ...
%     settings.minimum_state;
% 
% ocp.constraints.ubx_e = ...
%     settings.maximum_state;
% 
% ocp.constraints.idxsbx_e = ...
%     stateBoundIndices;
% 
% ocp.cost.Zl_e = stateSlackPenalty;
% ocp.cost.Zu_e = stateSlackPenalty;
% 
% ocp.cost.zl_e = zeros(nx,1);
% ocp.cost.zu_e = zeros(nx,1);

%% Initial condition

ocp.constraints.x0 = controller.initial_state;

%% Online curvature parameter

ocp.parameter_values = 0;

%% Solver configuration

ocp.solver_options.N_horizon = N;
ocp.solver_options.tf = settings.prediction_horizon_s;

ocp.solver_options.nlp_solver_type = ...
    settings.nlp_solver_type;

ocp.solver_options.qp_solver = ...
    settings.qp_solver;

ocp.solver_options.integrator_type = ...
    settings.integrator_type;

ocp.solver_options.hessian_approx = ...
    settings.hessian_approximation;

ocp.solver_options.globalization = ...
    settings.globalization;

ocp.solver_options.nlp_solver_max_iter = ...
    settings.maximum_nlp_iterations;

ocp.solver_options.nlp_solver_tol_stat = ...
    settings.nlp_solver_tol_stat;

ocp.solver_options.nlp_solver_tol_eq = ...
    settings.nlp_solver_tol_eq;

ocp.solver_options.nlp_solver_tol_ineq = ...
    settings.nlp_solver_tol_ineq;

ocp.solver_options.nlp_solver_tol_comp = ...
    settings.nlp_solver_tol_comp;

ocp.solver_options.sim_method_num_stages = ...
    settings.integration_stages;

ocp.solver_options.sim_method_num_steps = ...
    settings.integration_steps;

ocp.solver_options.qp_solver_cond_N = ...
    settings.condensing_intervals;

ocp.solver_options.ext_fun_compile_flags = '-O2';

%% Generated-code location

acadosFolder = fileparts(mfilename('fullpath'));
controllersFolder = fileparts(acadosFolder);
commonFolder = fileparts(controllersFolder);
projectRoot = fileparts(commonFolder);

generatedDirectory = fullfile( ...
    projectRoot, ...
    'build', ...
    'acados', ...
    model.name);

ocp.code_gen_opts.code_export_directory = ...
    generatedDirectory;

ocp.code_gen_opts.json_file = fullfile( ...
    generatedDirectory, ...
    [model.name, '.json']);

if generateSimulinkBlock
    ocp.simulink_opts = ...
        acados_simulink_options(controller);
else
    ocp.simulink_opts = [];
end

%% Metadata

metadata.nx = nx;
metadata.nu = nu;
metadata.N = N;
metadata.settings = settings;
metadata.generated_directory = generatedDirectory;

end