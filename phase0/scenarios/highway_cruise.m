function track = highway_cruise(outputFolder,requestedSpeed_mps,vehicle)
%HIGHWAY_CRUISE Generate the Phase 0 smooth S-shaped highway scenario.

arguments
    outputFolder (1,1) string = fullfile( ...
        string(fileparts(mfilename("fullpath"))),"data")
    requestedSpeed_mps (1,1) double {mustBePositive} = 27
    vehicle (1,1) struct = vehicle_parameters()
end

ds_m = 0.25;
station_m = (0:ds_m:1400)';
curvature_1pm = zeros(size(station_m));
maximumCurvature_1pm = 2/requestedSpeed_mps^2;

curvature_1pm = addCurve(curvature_1pm, station_m, ...
    200, 100, 150, 100, maximumCurvature_1pm);
curvature_1pm = addCurve(curvature_1pm, station_m, ...
    700, 100, 150, 100, -maximumCurvature_1pm);

[X_ref_m,Y_ref_m,psi_ref_rad] = ...
    integrate_spatial_curvature(station_m,curvature_1pm);

localSpeedLimit_mps = requestedSpeed_mps*ones(size(station_m));
profile = phase0_profile_parameters(vehicle,requestedSpeed_mps,2.0);
[vx_ref_mps,curvatureLimit_mps,forwardSpeed_mps,traversalTime_s] = ...
    three_pass_speed_profile(station_m,curvature_1pm, ...
    localSpeedLimit_mps,profile);

track = struct();
track.name = "highway_cruise";
track.description = ...
    "Smooth S-shaped highway cruise with gentle mirrored curvature.";
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
track.initial_speed_mps = requestedSpeed_mps;
track.requested_speed_mps = requestedSpeed_mps;
track.maximum_lateral_acceleration_mps2 = 2.0;
track.total_length_m = station_m(end);
track.traversal_time_s = traversalTime_s;
track.simulation_stop_time_s = ceil(traversalTime_s + 10);
track.road_friction_mu = vehicle.default_road_friction_mu;
track.slope_rad = 0;
track.stop_event_table = zeros(2,5);
track.profile_parameters = profile;

track = save_phase0_scenario(track,outputFolder,true);
end

function curvature = addCurve(curvature,station,startStation, ...
    rampLength,constantLength,exitRampLength,maximumCurvature)

mask = station >= startStation & station < startStation+rampLength;
xi = (station(mask)-startStation)/rampLength;
curvature(mask) = 0.5*maximumCurvature.*(1-cos(pi*xi));

constantStart = startStation+rampLength;
mask = station >= constantStart & ...
    station < constantStart+constantLength;
curvature(mask) = maximumCurvature;

exitStart = constantStart+constantLength;
mask = station >= exitStart & ...
    station <= exitStart+exitRampLength;
xi = (station(mask)-exitStart)/exitRampLength;
curvature(mask) = 0.5*maximumCurvature.*(1+cos(pi*xi));
end
