function [ ...
    predictedOutcomes, ...
    insideMapCoverage, ...
    nearestDistance] = ...
    predictFromLookupMap( ...
        featureVector, ...
        candidateSampleTimes_s, ...
        mapX, ...
        mapY, ...
        mapSampleTimes_s, ...
        normalizationMean, ...
        normalizationScale, ...
        rawMinimum, ...
        rawMaximum, ...
        safetyMargins, ...
        maximumNearestDistance)
%PREDICTLOOKUPMAPCORE Runtime K-nearest-neighbor lookup.
%
% featureVector order:
%   1  abs(ey), m
%   2  abs(epsi), rad
%   3  vx, m/s
%   4  abs(vy), m/s
%   5  abs(yaw rate), rad/s
%   6  RMS preview curvature, 1/m
%   7  maximum absolute preview curvature, 1/m
%
% predictedOutcomes columns:
%   1  lateral RMS, m
%   2  heading RMS, rad
%   3  peak lateral error, m
%   4  peak heading error, rad
%   5  predicted P95 response time, s
%   6  predicted solver failures
%
% predictedOutcomes rows correspond to candidateSampleTimes_s

numberOfCandidates = 3; %modes
numberOfResponses = 6;
neighborCount = 15;

predictedOutcomes = inf( ...
    numberOfCandidates, numberOfResponses); % modes (3) x outputs (6)

% Mark solver outcome as failed until a prediction is available.
predictedOutcomes(:, 6) = 1;

insideMapCoverage = false(numberOfCandidates, 1);
nearestDistance = inf(numberOfCandidates, 1);

% Only the seven vehicle/path features participate in the lookup.
% This also tolerates the former eight-element input while the caller is
% being updated; any former background-utilization element is ignored.
lookupFeature = featureVector(1:7).';

normalizedFeature = ...
    (lookupFeature - normalizationMean) ...
    ./ normalizationScale;

numberOfMapRows = size(mapX, 1);

for candidateIndex = 1:numberOfCandidates

    candidateSampleTime_s = ...
        candidateSampleTimes_s(candidateIndex);

    bestDistanceSquared = inf(neighborCount, 1);
    bestIndices = zeros(neighborCount, 1);

    %% Locate nearest entries for this candidate mode

    for mapRow = 1:numberOfMapRows

        if mapSampleTimes_s(mapRow) ...
                ~= candidateSampleTime_s
            continue;
        end

        difference = ...
            mapX(mapRow, :) - normalizedFeature;

        distanceSquared = max( ...
                sum(difference .* difference), ...
                0.0);

        if distanceSquared < bestDistanceSquared(end)

            insertPosition = neighborCount;

            while insertPosition > 1 ...
                    && distanceSquared ...
                    < bestDistanceSquared(insertPosition - 1)

                bestDistanceSquared(insertPosition) = ...
                    bestDistanceSquared(insertPosition - 1);

                bestIndices(insertPosition) = ...
                    bestIndices(insertPosition - 1);

                insertPosition = insertPosition - 1;
            end

            bestDistanceSquared(insertPosition) = ...
                distanceSquared;

            bestIndices(insertPosition) = mapRow;
        end
    end

    validNeighborCount = sum(isfinite(bestDistanceSquared));

    if validNeighborCount == 0
        continue;
    end

    nearestDistance(candidateIndex) = sqrt(max( ...
        bestDistanceSquared(1), 0.0));

    %% Interpolate neighbor outcomes

    estimate = zeros(1, numberOfResponses);

    if bestDistanceSquared(1) <= eps

        estimate = mapY(bestIndices(1), :);

    else

        totalWeight = 0;
        maximumSolverFailures = 0;

        for neighborIndex = 1:validNeighborCount

            mapRow = bestIndices(neighborIndex);

            weight = 1 / sqrt(max( ...
                bestDistanceSquared(neighborIndex), ...
                eps));

            estimate(1:5) = estimate(1:5) ...
                + weight * mapY(mapRow, 1:5);

            totalWeight = totalWeight + weight;

            maximumSolverFailures = max( ...
                maximumSolverFailures, ...
                mapY(mapRow, 6));
        end

        estimate(1:5) = ...
            estimate(1:5) / totalWeight;

        % Conservative discrete risk estimate.
        estimate(6) = maximumSolverFailures;
    end

    % Calibration margins are normally nonzero only for
    % peak errors and response time.
    estimate(1:5) = ...
        estimate(1:5) + safetyMargins(1:5);

    predictedOutcomes(candidateIndex, :) = estimate;

    %% Coverage test

    insideRange = all( ...
        lookupFeature ...
            >= rawMinimum(candidateIndex, :) ...
        & lookupFeature ...
            <= rawMaximum(candidateIndex, :));

    closeEnough = ...
        nearestDistance(candidateIndex) ...
        <= maximumNearestDistance(candidateIndex);

    insideMapCoverage(candidateIndex) = ...
        insideRange && closeEnough;
end
end
