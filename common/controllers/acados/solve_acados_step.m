function [command, solverStatus, solveTime_s, diagnostics] = ...
    solve_acados_step( ...
    solver, metadata, measuredState, stateReference, curvatureReference)
%SOLVE_ACADOS_STEP Execute one acados MPC control update.

measuredState = measuredState(:);
stateReference = stateReference(:);

assert(numel(measuredState) == metadata.nx);
assert(numel(stateReference) == metadata.nx);

%% Curvature preview

if isscalar(curvatureReference)
    curvaturePreview = repmat( ...
        curvatureReference, ...
        metadata.N + 1, ...
        1);
else
    curvaturePreview = curvatureReference(:);

    assert( ...
        numel(curvaturePreview) == metadata.N + 1, ...
        "Curvature preview must contain N+1 samples.");
end

%% Apply measured initial state

solver.set('constr_x0', measuredState);

%% Apply state and input references

pathReference = [
    stateReference
    metadata.settings.nominal_input
    ];

for stage = 1:(metadata.N - 1)
    solver.set( ...
        'cost_y_ref', ...
        pathReference, ...
        stage);
end

solver.set( ...
    'cost_y_ref_e', ...
    stateReference, ...
    metadata.N);

%% Apply curvature at every prediction stage

for stage = 0:metadata.N
    solver.set( ...
        'p', ...
        curvaturePreview(stage + 1), ...
        stage);
end

%% Solve

solver.solve();

rawStatus = solver.get('status');
solveTime_s = solver.get('time_tot');

predictedInput = solver.get('u');
predictedState = solver.get('x');

%% Standardized backend output

if rawStatus == 0 && ...
        all(isfinite(predictedInput), 'all') && ...
        all(isfinite(predictedState), 'all')

    command = predictedInput(:,1);
    solverStatus = 1;
else
    command = metadata.settings.nominal_input;
    solverStatus = -1;
end

diagnostics.raw_status = rawStatus;
diagnostics.predicted_input = predictedInput;
diagnostics.predicted_state = predictedState;

end