function delayProfile = generate_random_delay_profile( ...
    stopTime_s, ...
    controllerSampleTime_s, ...
    maximumDelay_s, ...
    randomSeed)
%GENERATERANDOMDELAYPROFILE Generate reproducible per-step delay.

arguments
    stopTime_s (1,1) double {mustBePositive}
    controllerSampleTime_s (1,1) double {mustBePositive}
    maximumDelay_s (1,1) double {mustBeNonnegative}
    randomSeed (1,1) double ...
        {mustBeInteger, mustBeNonnegative}
end

numberOfSamples = ...
    floor(stopTime_s/controllerSampleTime_s) + 1;

time_s = ...
    (0:numberOfSamples-1).' * controllerSampleTime_s;

randomStream = RandStream( ...
    "mt19937ar", ...
    Seed=randomSeed);

normalizedDelay = ...
    rand(randomStream, numberOfSamples, 1);

delay_s = ...
    maximumDelay_s * normalizedDelay;

delayProfile = struct();

delayProfile.seed = randomSeed;
delayProfile.maximum_delay_s = maximumDelay_s;
delayProfile.time_s = time_s;
delayProfile.delay_s = delay_s;

delayProfile.timeseries = ...
    timeseries(delay_s, time_s);

delayProfile.timeseries = ...
    setinterpmethod( ...
    delayProfile.timeseries, ...
    "zoh");

delayProfile.sample_mean_s = mean(delay_s);
delayProfile.sample_std_s = std(delay_s);
delayProfile.sample_min_s = min(delay_s);
delayProfile.sample_max_s = max(delay_s);

end