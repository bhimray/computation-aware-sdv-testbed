function [requestedMode, candidateCost, admissible] = ...
    selectModeFromCost( ...
        predictedOutcomes, ...
        insideMapCoverage, ...
        candidateSampleTimes_s, ...
        modeMeanCpuUtilization, ...
        modeCpuAdmissible, ...
        maximumLateralError_m, ...
        maximumHeadingError_rad, ...
        maximumCpuUtilization, ...
        costWeights)
%SELECTMODEFROMCOST Select the lowest-cost admissible controller mode.
%
% predictedOutcomes columns:
%   1 lateral RMS, m
%   2 heading RMS, rad
%   3 peak lateral error, m
%   4 peak heading error, rad
%   5 P95 response time, s
%   6 solver-failure flag
%
% costWeights = [lateral; heading; CPU; response]

numberOfCandidates = numel(candidateSampleTimes_s);

candidateCost = inf(numberOfCandidates, 1);
admissible = false(numberOfCandidates, 1);

for candidateIndex = 1:numberOfCandidates

    eyRms_m = predictedOutcomes(candidateIndex, 1);
    epsiRms_rad = predictedOutcomes(candidateIndex, 2);
    eyPeak_m = predictedOutcomes(candidateIndex, 3);
    epsiPeak_rad = predictedOutcomes(candidateIndex, 4);
    responseP95_s = predictedOutcomes(candidateIndex, 5);
    solverFailure = predictedOutcomes(candidateIndex, 6);
    sampleTime_s = candidateSampleTimes_s(candidateIndex);

    predictionFinite = all(isfinite( ...
        predictedOutcomes(candidateIndex, :)));
    
   % && modeCpuAdmissible(candidateIndex) ...
   % && insideMapCoverage(candidateIndex) ...
    admissible(candidateIndex) = ...
        predictionFinite ...
        && eyPeak_m <= maximumLateralError_m ...
        && epsiPeak_rad <= maximumHeadingError_rad ...
        && responseP95_s <= sampleTime_s ...
        && solverFailure < 0.5;

    if ~admissible(candidateIndex)
        disp("sample_time");
        disp(sampleTime_s);
        disp(insideMapCoverage(candidateIndex));
        disp(modeCpuAdmissible(candidateIndex));
        disp(predictedOutcomes(candidateIndex, :));
        continue;
    end

    lateralCost = 0.5 * ...
        (eyRms_m / maximumLateralError_m)^2;

    headingCost = 0.5 * ...
        (epsiRms_rad / maximumHeadingError_rad)^2;

    cpuCost = ...
        modeMeanCpuUtilization(candidateIndex) ...
        / maximumCpuUtilization;

    responseCost = ...
        (responseP95_s / sampleTime_s)^2;

    candidateCost(candidateIndex) = ...
        costWeights(1) * lateralCost ...
        + costWeights(2) * headingCost ...
        + costWeights(3) * cpuCost ...
        + costWeights(4) * responseCost;
end

[minimumCost, requestedModeIndex] = min(candidateCost);

if isfinite(minimumCost)
    requestedMode = uint8(requestedModeIndex);
else
    % Candidate order is [50; 20; 10] ms, so the minimum period is the
    % tracking-safe fallback when the map cannot admit any candidate.
    [~, fallbackIndex] = min(candidateSampleTimes_s);
    requestedMode = uint8(fallbackIndex);
end

end
