function options = acados_simulink_options(controller)
%ACADOS_SIMULINK_OPTIONS Configure the generated S-function interface.

options = get_acados_simulink_opts();

% Disable every default input.
inputNames = fieldnames(options.inputs);

for index = 1:numel(inputNames)
    options.inputs.(inputNames{index}) = 0;
end

options.inputs.x_init = 1;
options.inputs.u_init = 1;

% Enable only the required runtime inputs.
options.inputs.lbx_0 = 1;
options.inputs.ubx_0 = 1;
options.inputs.parameter_traj = 1;
options.inputs.y_ref = 1;
options.inputs.y_ref_e = 1;
options.inputs.pi_init = 1;
options.inputs.ignore_inits = 1;

% Disable every default output.
outputNames = fieldnames(options.outputs);

for index = 1:numel(outputNames)
    options.outputs.(outputNames{index}) = 0; %false
end

% Enable the standardized backend outputs.
options.outputs.u0 = 1; % true
options.outputs.solver_status = 1;
options.outputs.CPU_time = 1;
options.outputs.CPU_time_sim = 1;
options.outputs.CPU_time_qp = 1;
options.outputs.CPU_time_lin = 1;
hasSoftStateConstraints = ...
    controller.enableIntermediateStateConstraints || ...
    controller.enableTerminalStateConstraints;

% A zero-dimensional slack output is invalid in Simulink.
options.outputs.slack_values = ...
    double(hasSoftStateConstraints);

options.generate_simulink_block = 1;
options.show_port_info = 1;

% Controller and plant use the same sampling interval.
% options.samplingtime = 't0'; %% 't0' is the fixed sampling interval like 10ms
options.samplingtime = '-1'; %% '-1' is inherited for triggered system, phase 1.3

end