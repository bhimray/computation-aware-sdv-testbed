function [stateReference,kappaReference,XReference,YReference, ...
    yawReference,stationReference,trackIndex,stopStatus] = ...
    scenario_reference_manager(X_m,Y_m,vx_mps,time_s, ...
    trackReferenceTable,stopEventTable)
%SCENARIO_REFERENCE_MANAGER Monotonic local lookup with stop/dwell state.
%
% stopEventTable columns:
% [active, station_m, dwell_s, capture_distance_m, capture_speed_mps]

persistent previousTime_s previousIndex currentStopNumber
persistent dwellActive dwellStartTime_s stopCompleted

numberOfPoints = size(trackReferenceTable,1);
resetRequested = isempty(previousTime_s) || time_s < previousTime_s || ...
    (time_s == 0 && (~isempty(previousTime_s) && previousTime_s > 0));

if resetRequested
    previousTime_s = time_s;
    previousIndex = 1;
    currentStopNumber = 1;
    dwellActive = false;
    dwellStartTime_s = 0;
    stopCompleted = false(size(stopEventTable,1),1);
end

searchBehind = 5;
searchAhead = 200;
firstIndex = max(1,previousIndex-searchBehind);
lastIndex = min(numberOfPoints,previousIndex+searchAhead);
candidateIndices = (firstIndex:lastIndex)';
distanceSquared = ...
    (trackReferenceTable(candidateIndices,2)-X_m).^2 + ...
    (trackReferenceTable(candidateIndices,3)-Y_m).^2;
[~,localIndex] = min(distanceSquared);
trackIndex = candidateIndices(localIndex);
trackIndex = max(trackIndex,previousIndex);

stopStatus = zeros(1,4);
numberOfStops = size(stopEventTable,1);

while currentStopNumber <= numberOfStops && ...
        stopEventTable(currentStopNumber,1) < 0.5
    stopCompleted(currentStopNumber) = true;
    currentStopNumber = currentStopNumber+1;
end

if currentStopNumber <= numberOfStops
    stopStation_m = stopEventTable(currentStopNumber,2);
    dwellDuration_s = stopEventTable(currentStopNumber,3);
    captureDistance_m = stopEventTable(currentStopNumber,4);
    captureSpeed_mps = stopEventTable(currentStopNumber,5);
    [~,stopIndex] = min(abs(trackReferenceTable(:,1)-stopStation_m));

    reachedStop = abs(trackReferenceTable(trackIndex,1)-stopStation_m) <= ...
        captureDistance_m && vx_mps <= captureSpeed_mps;

    if reachedStop && ~dwellActive
        dwellActive = true;
        dwellStartTime_s = time_s;
        trackIndex = stopIndex;
    end

    if dwellActive
        trackIndex = stopIndex;
        if time_s-dwellStartTime_s >= dwellDuration_s
            dwellActive = false;
            stopCompleted(currentStopNumber) = true;
            currentStopNumber = currentStopNumber+1;
            trackIndex = min(stopIndex+1,numberOfPoints);
        end
    elseif trackReferenceTable(trackIndex,1) >= stopStation_m-captureDistance_m
        % Do not let nearest-point selection skip a pending stop.
        trackIndex = min(trackIndex,stopIndex);
    end
end

stationReference = trackReferenceTable(trackIndex,1);
XReference = trackReferenceTable(trackIndex,2);
YReference = trackReferenceTable(trackIndex,3);
yawReference = trackReferenceTable(trackIndex,4);
kappaReference = trackReferenceTable(trackIndex,5);
speedReference = trackReferenceTable(trackIndex,6);
yawRateReference = trackReferenceTable(trackIndex,7);

if dwellActive
    speedReference = 0;
    yawRateReference = 0;
end

stateReference = [speedReference,0,yawRateReference,0,0];
stopStatus(1) = currentStopNumber;
stopStatus(2) = double(dwellActive);
stopStatus(3) = sum(stopCompleted);
if dwellActive
    stopStatus(4) = time_s-dwellStartTime_s;
end

previousIndex = trackIndex;
previousTime_s = time_s;
end
