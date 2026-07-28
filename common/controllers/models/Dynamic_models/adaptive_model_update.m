function [A,B,C,D,X,Y,U,DX] = ...
    adaptive_model_update(x,u,kappa,p)
%ADAPTIVE_MODEL_UPDATE
% Numerically linearizes the discrete nonlinear prediction model.
%
% States:
%   [vx; vy; yaw_rate; lateral_error; heading_error]
%
% Inputs:
%   [front_axle_torque; road_wheel_angle; curvature]

x = x(:);
u = u(:);

numberOfStates = 5;
numberOfMV = 2;

stateStep = [
    1e-4
    1e-5
    1e-6
    1e-5
    1e-6
    ];

inputStep = [
    0.1      % N*m
    1e-5     % rad
    ];

curvatureStep = 1e-6;

xNextNominal = propagate_prediction_model( ...
    x,u,kappa,p);

%% State Jacobian

A = zeros(numberOfStates,numberOfStates);

for stateIndex = 1:numberOfStates

    xPositive = x;
    xNegative = x;

    xPositive(stateIndex) = ...
        xPositive(stateIndex) + stateStep(stateIndex);

    xNegative(stateIndex) = ...
        xNegative(stateIndex) - stateStep(stateIndex);

    nextPositive = propagate_prediction_model( ...
        xPositive,u,kappa,p);

    nextNegative = propagate_prediction_model( ...
        xNegative,u,kappa,p);

    A(:,stateIndex) = ...
        (nextPositive-nextNegative) ...
        /(2*stateStep(stateIndex));
end

%% Manipulated-input Jacobian

Bmv = zeros(numberOfStates,numberOfMV);

for inputIndex = 1:numberOfMV

    uPositive = u;
    uNegative = u;

    uPositive(inputIndex) = ...
        uPositive(inputIndex) + inputStep(inputIndex);

    uNegative(inputIndex) = ...
        uNegative(inputIndex) - inputStep(inputIndex);

    nextPositive = propagate_prediction_model( ...
        x,uPositive,kappa,p);

    nextNegative = propagate_prediction_model( ...
        x,uNegative,kappa,p);

    Bmv(:,inputIndex) = ...
        (nextPositive-nextNegative) ...
        /(2*inputStep(inputIndex));
end

%% Curvature Jacobian

nextPositive = propagate_prediction_model( ...
    x,u,kappa+curvatureStep,p);

nextNegative = propagate_prediction_model( ...
    x,u,kappa-curvatureStep,p);

Bmd = ...
    (nextPositive-nextNegative) ...
    /(2*curvatureStep);

%% Adaptive MPC model data

B = [Bmv Bmd];

C = eye(numberOfStates);
D = zeros(numberOfStates,numberOfMV+1);

X = reshape(x,[5 1]);
Y = reshape(x,[5 1]);

U = reshape([u;kappa],[3 1]);

DX = reshape(xNextNominal-X,[5 1]);
end