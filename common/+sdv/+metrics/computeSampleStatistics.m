function [statistics, samples, sampleTime] = ...
    computeSampleStatistics(inputData, sampleTime)
%COMPUTESAMPLESTATISTICS Summarize one numeric or time-series signal.
%
% statistics = sdv.metrics.computeSampleStatistics(data)
% statistics = sdv.metrics.computeSampleStatistics(data, time)
% statistics = sdv.metrics.computeSampleStatistics(timeSeries)
% statistics = sdv.metrics.computeSampleStatistics(loggedSignal)
%
% Supported inputs:
%   - Numeric vector
%   - MATLAB timeseries
%   - Simulink.SimulationData.Signal whose Values contain a timeseries
%   - Struct with a Data field and optional Time_s or Time field
%
% P95 and P99 use the empirical nearest-rank definition. NaN and Inf
% samples are excluded and reported in RemovedSampleCount.

arguments
    inputData
    sampleTime = []
end

[samples, sampleTime] = extractSamples(inputData, sampleTime);

assert(isvector(samples) || isempty(samples), ...
    "SDV:InvalidStatisticsData", ...
    "Statistics input must contain exactly one signal.");

samples = double(samples(:));

if ~isempty(sampleTime)
    sampleTime = normalizeTime(sampleTime);
    assert(numel(sampleTime) == numel(samples), ...
        "SDV:InvalidStatisticsTime", ...
        "The time and data vectors must have the same number of samples.");
end

originalSampleCount = numel(samples);
valid = isfinite(samples);

if ~isempty(sampleTime)
    valid = valid & isfinite(sampleTime);
    sampleTime = sampleTime(valid);
end

samples = samples(valid);

statistics = struct( ...
    SampleCount=numel(samples), ...
    RemovedSampleCount=originalSampleCount - numel(samples), ...
    Mean=NaN, ...
    Median=NaN, ...
    P95=NaN, ...
    P99=NaN);

if isempty(samples)
    return;
end

sortedSamples = sort(samples);

statistics.Mean = mean(samples);
statistics.Median = median(samples);
statistics.P95 = nearestRank(sortedSamples, 95);
statistics.P99 = nearestRank(sortedSamples, 99);

end


function [samples, sampleTime] = extractSamples(inputData, sampleTime)

if isnumeric(inputData) || islogical(inputData)
    samples = inputData;
    return;
end

assert(isempty(sampleTime), ...
    "SDV:InvalidStatisticsTime", ...
    "Do not supply a separate time vector with a time-series input.");

if isa(inputData, "timeseries")
    samples = inputData.Data;
    sampleTime = inputData.Time;
    return;
end

if isa(inputData, "Simulink.SimulationData.Signal")
    [samples, sampleTime] = extractSamples(inputData.Values, []);
    return;
end

if isstruct(inputData) && isfield(inputData, "Data")
    samples = inputData.Data;

    if isfield(inputData, "Time_s")
        sampleTime = inputData.Time_s;
    elseif isfield(inputData, "Time")
        sampleTime = inputData.Time;
    else
        sampleTime = [];
    end
    return;
end

error( ...
    "SDV:UnsupportedStatisticsInput", ...
    "Unsupported input. Supply a numeric vector, timeseries, " + ...
    "logged Simulink signal, or struct containing Data.");

end


function time = normalizeTime(time)

if isduration(time)
    time = seconds(time);
elseif isdatetime(time)
    time = seconds(time - time(1));
else
    time = double(time);
end

time = time(:);

end


function value = nearestRank(sortedSamples, percentile)

sampleIndex = max( ...
    1, ...
    ceil((percentile/100)*numel(sortedSamples)));

value = sortedSamples(sampleIndex);

end
