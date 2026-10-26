function [figureHandle, probe, runArtifact] = ...
    probeSavedRun(resultLocation, options)
%PROBESAVEDRUN Inspect a saved Phase 2 or Phase 3 scheduler run.
%
% [fig, probe, runArtifact] = sdv.analysis.probeSavedRun( ...
%     resultLocation, TimeWindow_s=[39 40]);
%
% resultLocation may be a MAT file containing runArtifact or its folder.

arguments
    resultLocation (1,1) string
    options.TimeWindow_s (1,2) double = [NaN NaN]
    options.ControlPeriod_s (1,1) double = NaN
    options.ComputedTorqueScale (1,1) double = 0.5
    options.AppliedTorqueScale (1,1) double = 1.0
    options.ComputedSteeringScale (1,1) double = 180/pi
    options.AppliedSteeringScale (1,1) double = 1/24
    options.Title (1,1) string = ""
    options.Visible (1,1) logical = true
    options.SaveFile (1,1) string = ""
end

runFile = resolveRunFile(resultLocation);
savedRun = load(runFile, "runArtifact");

assert(isfield(savedRun, "runArtifact"), ...
    "Saved file does not contain runArtifact: %s", runFile);

runArtifact = savedRun.runArtifact;

assert(isfield(runArtifact, "results"), ...
    "runArtifact does not contain results: %s", runFile);

availableWindow_s = [ ...
    min(double(runArtifact.results.time_s(:))), ...
    max(double(runArtifact.results.time_s(:)))];

if all(isnan(options.TimeWindow_s))
    window_s = availableWindow_s;
else
    assert(all(isfinite(options.TimeWindow_s)) ...
        && options.TimeWindow_s(1) < options.TimeWindow_s(2), ...
        "TimeWindow_s must be [startTime endTime] or [NaN NaN].");
    window_s = options.TimeWindow_s;
end

assert(window_s(1) >= availableWindow_s(1) ...
    && window_s(2) <= availableWindow_s(2), ...
    "Requested window [%.6f, %.6f] s is outside the saved " + ...
    "interval [%.6f, %.6f] s.", ...
    window_s(1), window_s(2), ...
    availableWindow_s(1), availableWindow_s(2));

probe = sdv.analysis.extractProbeWindow( ...
    runArtifact, window_s, ...
    ControlPeriod_s=options.ControlPeriod_s);

figureHandle = sdv.plot.schedulerProbe( ...
    probe, ...
    ComputedTorqueScale=options.ComputedTorqueScale, ...
    AppliedTorqueScale=options.AppliedTorqueScale, ...
    ComputedSteeringScale=options.ComputedSteeringScale, ...
    AppliedSteeringScale=options.AppliedSteeringScale, ...
    Title=options.Title, ...
    Visible=options.Visible);

if strlength(options.SaveFile) > 0
    outputFolder = string(fileparts(options.SaveFile));
    if strlength(outputFolder) > 0 && ~isfolder(outputFolder)
        mkdir(outputFolder);
    end
    exportgraphics(figureHandle, options.SaveFile, Resolution=300);
end

fprintf("Probed %s from %.6f to %.6f s.\n", ...
    runFile, window_s(1), window_s(2));

end


function runFile = resolveRunFile(resultLocation)

if isfile(resultLocation)
    runFile = resultLocation;
    return;
end

assert(isfolder(resultLocation), ...
    "Result location does not exist: %s", resultLocation);

preferredNames = ["simulation_output.mat", "run_data.mat"];
existing = strings(0,1);

for fileName = preferredNames
    candidate = fullfile(resultLocation, fileName);
    if isfile(candidate)
        existing(end+1,1) = candidate; %#ok<AGROW>
    end
end

assert(~isempty(existing), ...
    "Folder does not contain simulation_output.mat or run_data.mat: %s", ...
    resultLocation);

runFile = existing(1);

end
