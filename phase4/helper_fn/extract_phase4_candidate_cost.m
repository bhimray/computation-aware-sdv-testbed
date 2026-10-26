function candidateCost = extract_phase4_candidate_cost( ...
        logs, signalName, candidateSampleTimes_s)
%EXTRACT_PHASE4_CANDIDATE_COST Preserve one cost column per sampling mode.

arguments
    logs
    signalName (1,1) string = "candidate_cost"
    candidateSampleTimes_s (:,1) double = [0.050; 0.020; 0.010]
end

signalNames = string(logs.getElementNames);

assert(ismember(signalName, signalNames), ...
    "Logged signal '%s' was not found.", signalName);

element = logs.get(signalName);
values = element.Values;

time_s = double(values.Time(:));
rawData = double(values.Data);

numberOfSamples = numel(time_s);
numberOfModes = numel(candidateSampleTimes_s);

assert(numel(rawData) == numberOfSamples*numberOfModes, ...
    ["Logged signal '%s' must contain %d candidate costs " ...
     "for every time sample."], ...
    signalName, numberOfModes);

if size(rawData, 1) == numberOfSamples
    costData = reshape( ...
        rawData, numberOfSamples, numberOfModes);
elseif size(rawData, ndims(rawData)) == numberOfSamples
    costData = reshape( ...
        rawData, numberOfModes, numberOfSamples).';
else
    error( ...
        "Phase4:CandidateCostShape", ...
        "Unable to identify the time dimension of '%s'.", ...
        signalName);
end

candidateCost = struct( ...
    Time_s=time_s, ...
    Data=costData, ...
    CandidateSampleTimes_s=candidateSampleTimes_s(:));

end
