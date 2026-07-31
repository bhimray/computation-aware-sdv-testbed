function track = urban_profile(outputFolder,vehicle)
%URBAN_PROFILE Generate the Phase 0 open-square route with two stops.

arguments
    outputFolder (1,1) string = fullfile( ...
        string(fileparts(mfilename("fullpath"))),"data")
    vehicle (1,1) struct = vehicle_parameters()
end

ds_m = 0.25;
straightLength_m = 150;
turnRadius_m = 30;
rampLength_m = 10;
constantTurnLength_m = pi*turnRadius_m/2-rampLength_m;
turnLength_m = 2*rampLength_m+constantTurnLength_m;
totalLength_m = 4*straightLength_m+3*turnLength_m;
station_m = (0:ds_m:floor(totalLength_m/ds_m)*ds_m)';
curvature_1pm = zeros(size(station_m));

turnStarts_m = straightLength_m + ...
    (0:2)*(straightLength_m+turnLength_m);
for turnStart_m = turnStarts_m
    curvature_1pm = addUrbanTurn(curvature_1pm,station_m, ...
        turnStart_m,rampLength_m,constantTurnLength_m,turnRadius_m);
end

[X_ref_m,Y_ref_m,psi_ref_rad] = ...
    integrate_spatial_curvature(station_m,curvature_1pm);

urbanSpeedLimit_mps = 13.4;
localSpeedLimit_mps = urbanSpeedLimit_mps*ones(size(station_m));

stopStations_m = [ ...
    turnStarts_m(1)-20; ...
    turnStarts_m(3)-20];
for stopStation_m = stopStations_m'
    [~,stopIndex] = min(abs(station_m-stopStation_m));
    localSpeedLimit_mps(stopIndex) = 0;
end

profile = phase0_profile_parameters(vehicle,0,8^2/turnRadius_m);
[vx_ref_mps,curvatureLimit_mps,forwardSpeed_mps,traversalTime_s] = ...
    three_pass_speed_profile(station_m,curvature_1pm, ...
    localSpeedLimit_mps,profile);

% Enforce exact zeros at the event samples after numerical profile passes.
for stopStation_m = stopStations_m'
    [~,stopIndex] = min(abs(station_m-stopStation_m));
    vx_ref_mps(stopIndex) = 0;
end

stopEventTable = zeros(2,5);
stopEventTable(:,1) = 1;             % active
stopEventTable(:,2) = stopStations_m;
stopEventTable(:,3) = 3.0;           % dwell duration, s
stopEventTable(:,4) = 1.0;           % capture distance, m
stopEventTable(:,5) = 0.15;          % capture speed, m/s

track = struct();
track.name = "urban_profile";
track.description = ...
    "Open-square urban route with rounded turns, two stops, and dwell.";
track.source = "Project-generated analytical spatial scenario.";
track.station_m = station_m;
track.X_ref_m = X_ref_m;
track.Y_ref_m = Y_ref_m;
track.psi_ref_rad = psi_ref_rad;
track.curvature_1pm = curvature_1pm;
track.local_speed_limit_mps = localSpeedLimit_mps;
track.vx_ref_mps = vx_ref_mps;
track.curvature_speed_limit_mps = curvatureLimit_mps;
track.forward_pass_speed_mps = forwardSpeed_mps;
track.initial_speed_mps = 0;
track.maximum_lateral_acceleration_mps2 = 8^2/turnRadius_m;
track.total_length_m = station_m(end);
track.traversal_time_s = traversalTime_s;
track.simulation_stop_time_s = ceil(traversalTime_s+sum(stopEventTable(:,3)));
track.road_friction_mu = vehicle.default_road_friction_mu;
track.slope_rad = 0;
track.stop_event_table = stopEventTable;
track.profile_parameters = profile;

track = save_phase0_scenario(track,outputFolder,true);
end

function curvature = addUrbanTurn(curvature,station,startStation, ...
    rampLength,constantLength,turnRadius)
maximumCurvature = 1/turnRadius;

mask = station >= startStation & station < startStation+rampLength;
xi = (station(mask)-startStation)/rampLength;
curvature(mask) = 0.5*maximumCurvature.*(1-cos(pi*xi));

constantStart = startStation+rampLength;
mask = station >= constantStart & station < constantStart+constantLength;
curvature(mask) = maximumCurvature;

exitStart = constantStart+constantLength;
mask = station >= exitStart & station <= exitStart+rampLength;
xi = (station(mask)-exitStart)/rampLength;
curvature(mask) = 0.5*maximumCurvature.*(1+cos(pi*xi));
end
