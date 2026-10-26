function [ ...
    lbx0, ...
    ubx0, ...
    parameterTrajectory, ...
    pathReference, ...
    terminalReference, ...
    xInit, ...
    uInit, ...
    piInit] = ...
    format_acados_simulink_inputs( ...
        measuredState, ...
        previousCommand, ...
        track_i, ...
        track_ref_table)
%FORMAT_ACADOS_SIMULINK_INPUTS Format the N=100 acados S-function inputs.
%
% measuredState   = [vx; vy; yawRate; lateralError; headingError]
% previousCommand = [frontAxleTorque; roadWheelAngle]

numberOfIntervals = 100;
predictionStep_s = 0.01;

%% Fixed-size S-function outputs

lbx0 = zeros(7,1);
ubx0 = zeros(7,1);
parameterTrajectory = zeros(101,1);
pathReference = zeros(891,1);  % 9*(N-1)
terminalReference = zeros(5,1); %#ok<PREALL>
xInit = zeros(707,1);          % 7*(N+1)
uInit = zeros(200,1);          % 2*N
piInit = zeros(700,1);         % 7*N

%% Preview indices for nodes 0 through N

numberOfTrackPoints = size(track_ref_table, 1);
previewIndices = ones(numberOfIntervals + 1, 1);

currentIndex = round(track_i);
currentIndex = max(1, min(currentIndex, numberOfTrackPoints));

previewIndices(1) = currentIndex;
predictedStation_m = track_ref_table(currentIndex, 1);

for node = 2:(numberOfIntervals + 1)

    currentIndex = previewIndices(node - 1);
    predictedSpeed_mps = ...
        max(track_ref_table(currentIndex, 6), 0);

    predictedStation_m = ...
        predictedStation_m ...
        + predictedSpeed_mps*predictionStep_s;

    nextIndex = currentIndex;

    while nextIndex < numberOfTrackPoints && ...
            track_ref_table(nextIndex, 1) < predictedStation_m

        nextIndex = nextIndex + 1;
    end

    previewIndices(node) = nextIndex;
end

%% Curvature preview for nodes 0 through N

for node = 1:(numberOfIntervals + 1)
    parameterTrajectory(node) = ...
        track_ref_table(previewIndices(node), 5);
end

%% Nine-element references for stages 1 through N-1

for stage = 1:(numberOfIntervals - 1)

    referenceIndex = previewIndices(stage + 1);

    stageReference = [
        track_ref_table(referenceIndex, 6)  % vx reference
        0                                   % vy reference
        track_ref_table(referenceIndex, 7)  % yaw-rate reference
        0                                   % lateral-error reference
        0                                   % heading-error reference
        0                                   % torque-effort reference
        0                                   % steering-effort reference
        0                                   % torque-rate reference
        0                                   % steering-rate reference
        ];

    outputStartIndex = (stage - 1)*9 + 1;

    for element = 1:9
        pathReference(outputStartIndex + element - 1) = ...
            stageReference(element);
    end
end

%% Initial augmented state

for stateIndex = 1:5
    lbx0(stateIndex) = measuredState(stateIndex);
    ubx0(stateIndex) = measuredState(stateIndex);
end

for commandIndex = 1:2
    lbx0(5 + commandIndex) = previousCommand(commandIndex);
    ubx0(5 + commandIndex) = previousCommand(commandIndex);
end

%% Terminal reference contains only the five vehicle states

terminalIndex = previewIndices(numberOfIntervals + 1);

terminalReference = [
    track_ref_table(terminalIndex, 6)
    0
    track_ref_table(terminalIndex, 7)
    0
    0
    ];

%% External state-trajectory initialization

for stage = 0:numberOfIntervals

    startIndex = stage*7 + 1;

    for stateIndex = 1:5
        xInit(startIndex + stateIndex - 1) = ...
            measuredState(stateIndex);
    end

    xInit(startIndex + 5) = previousCommand(1);
    xInit(startIndex + 6) = previousCommand(2);
end

% uInit and piInit intentionally remain zero. The optimizer inputs are
% command rates, so zero is the neutral cold-start guess.

end
