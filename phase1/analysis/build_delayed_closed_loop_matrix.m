function result = build_delayed_closed_loop_matrix( ...
    Ad, Bd, K, delaySamples)
%BUILD_DELAYED_CLOSED_LOOP_MATRIX Construct delayed state-feedback model.
%
% Controller:
%   deltaU(k) = -K*deltaX(k)
%
% Delayed plant:
%   deltaX(k+1) = Ad*deltaX(k) ...
%                 - Bd*K*deltaX(k-delaySamples)
%
% delaySamples = 0 means no delay.
% delaySamples = 1 means one controller sample of delay.

arguments
    Ad (:,:) double
    Bd (:,:) double
    K  (:,:) double
    delaySamples (1,1) double ...
        {mustBeInteger, mustBeNonnegative}
end

numberOfStates = size(Ad,1);
numberOfInputs = size(Bd,2);

assert(size(Ad,2) == numberOfStates, ...
    "Ad must be square.");

assert(isequal(size(Bd), ...
        [numberOfStates, numberOfInputs]), ...
    "Bd has an invalid size.");

assert(isequal(size(K), ...
        [numberOfInputs, numberOfStates]), ...
    "K has an invalid size.");

%% No-delay case

if delaySamples == 0

    augmentedA = ...
        Ad - Bd*K;

else

    % Augmented state:
    %
    % z(k) = [
    %   x(k)
    %   x(k-1)
    %   ...
    %   x(k-delaySamples)
    % ]

    augmentedStateCount = ...
        numberOfStates*(delaySamples + 1);

    augmentedA = zeros( ...
        augmentedStateCount, ...
        augmentedStateCount);

    %% Plant-state update

    currentStateColumns = ...
        1:numberOfStates;

    delayedStateColumns = ...
        delaySamples*numberOfStates ...
        + (1:numberOfStates);

    augmentedA( ...
        1:numberOfStates, ...
        currentStateColumns) = Ad;

    augmentedA( ...
        1:numberOfStates, ...
        delayedStateColumns) = -Bd*K;

    %% State-history shift

    identityMatrix = eye(numberOfStates);

    for historyIndex = 1:delaySamples

        destinationRows = ...
            historyIndex*numberOfStates ...
            + (1:numberOfStates);

        sourceColumns = ...
            (historyIndex-1)*numberOfStates ...
            + (1:numberOfStates);

        augmentedA( ...
            destinationRows, ...
            sourceColumns) = identityMatrix;
    end
end

%% Eigenvalue analysis

eigenvalues = eig(augmentedA);

spectralRadius = ...
    max(abs(eigenvalues));

result = struct();

result.delay_samples = delaySamples;
result.augmented_A = augmentedA;
result.eigenvalues = eigenvalues;
result.spectral_radius = spectralRadius;
result.is_stable = spectralRadius < 1;

end