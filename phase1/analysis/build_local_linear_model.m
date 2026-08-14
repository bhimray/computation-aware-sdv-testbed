function result = build_local_linear_model( ...
    config, gainResult, curvatureStar)
%BUILD_LOCAL_LINEAR_MODEL Linearize and discretize the acados model.
%
% Continuous prediction model:
%   xDot = f(x,u,kappa)
%
% State order:
%   [vx; vy; yawRate; lateralError; headingError]
%
% Input order:
%   [frontAxleTorque; roadWheelAngle]

arguments
    config (1,1) struct
    gainResult (1,1) struct
    curvatureStar (1,1) double = 0
end

import casadi.*

%% Operating point

xStar = gainResult.x_star(:);
uStar = gainResult.u_star(:);
K = gainResult.K;

Ts = config.controller.Ts_s;

%% Build the same nonlinear prediction model used by acados

[model, dynamicsFunction] = ...
    build_acados_prediction_model( ...
        config.adaptiveModel);

%% Exact symbolic Jacobians

continuousAExpression = ...
    jacobian( ...
        model.f_expl_expr, ...
        model.x);

continuousBExpression = ...
    jacobian( ...
        model.f_expl_expr, ...
        model.u);

jacobianFunction = Function( ...
    'sdv_prediction_model_jacobians', ...
    {model.x, model.u, model.p}, ...
    {continuousAExpression, continuousBExpression});

[continuousARaw, continuousBRaw] = ...
    jacobianFunction( ...
        xStar, ...
        uStar, ...
        curvatureStar);

Ac = full(continuousARaw);
Bc = full(continuousBRaw);

%% Check the selected operating point

stateDerivative = full( ...
    dynamicsFunction( ...
        xStar, ...
        uStar, ...
        curvatureStar));

equilibriumResidual = ...
    norm(stateDerivative, Inf);

%% Exact zero-order-hold discretization

numberOfStates = size(Ac,1);
numberOfInputs = size(Bc,2);

augmentedMatrix = [
    Ac, Bc
    zeros(numberOfInputs, ...
        numberOfStates + numberOfInputs)
    ];

discreteAugmentedMatrix = ...
    expm(augmentedMatrix*Ts);

Ad = discreteAugmentedMatrix( ...
    1:numberOfStates, ...
    1:numberOfStates);

Bd = discreteAugmentedMatrix( ...
    1:numberOfStates, ...
    numberOfStates + (1:numberOfInputs));

%% Zero-delay closed-loop sanity check

closedLoopMatrix = ...
    Ad - Bd*K;

closedLoopEigenvalues = ...
    eig(closedLoopMatrix);

spectralRadius = ...
    max(abs(closedLoopEigenvalues));

%% Validate dimensions and values

assert(isequal(size(Ac), [5,5]), ...
    "Ac must be 5-by-5.");

assert(isequal(size(Bc), [5,2]), ...
    "Bc must be 5-by-2.");

assert(isequal(size(Ad), [5,5]), ...
    "Ad must be 5-by-5.");

assert(isequal(size(Bd), [5,2]), ...
    "Bd must be 5-by-2.");

assert(all(isfinite([ ...
    Ac(:)
    Bc(:)
    Ad(:)
    Bd(:)])), ...
    "Linearized matrices contain NaN or Inf.");

%% Return result

result = struct();

result.Ac = Ac;
result.Bc = Bc;
result.Ad = Ad;
result.Bd = Bd;

result.x_star = xStar;
result.u_star = uStar;
result.curvature_star = curvatureStar;
result.sample_time_s = Ts;

result.state_derivative = stateDerivative;
result.equilibrium_residual = equilibriumResidual;

result.K = K;
result.zero_delay_closed_loop_matrix = ...
    closedLoopMatrix;

result.zero_delay_eigenvalues = ...
    closedLoopEigenvalues;

result.zero_delay_spectral_radius = ...
    spectralRadius;

%% Display results

fprintf("\nContinuous-time A matrix, Ac:\n");
disp(Ac);

fprintf("Continuous-time B matrix, Bc:\n");
disp(Bc);

fprintf("Discrete-time A matrix, Ad:\n");
disp(Ad);

fprintf("Discrete-time B matrix, Bd:\n");
disp(Bd);

fprintf( ...
    "Operating-point residual: %.6e\n", ...
    equilibriumResidual);

fprintf( ...
    "Zero-delay spectral radius: %.6f\n", ...
    spectralRadius);

if equilibriumResidual > 1e-6
    warning( ...
        "The selected operating point is not an exact equilibrium.");
end

if spectralRadius >= 1
    warning( ...
        "The zero-delay local closed loop is not asymptotically stable.");
else
    fprintf( ...
        "Zero-delay local closed loop is stable.\n");
end

end