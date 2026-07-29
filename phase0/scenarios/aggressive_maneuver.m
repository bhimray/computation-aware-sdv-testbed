function track = aggressive_maneuver(outputFolder,vehicle)
%AGGRESSIVE_MANEUVER Generate a smooth, non-ISO double lane change.

arguments
    outputFolder (1,1) string = fullfile( ...
        string(fileparts(mfilename("fullpath"))),"data")
    vehicle (1,1) struct = vehicle_parameters()
end

denseX_m = (0:0.025:300)';
denseY_m = zeros(size(denseX_m));
laneOffset_m = 3.5;

mask = denseX_m >= 50 & denseX_m < 90;
xi = (denseX_m(mask)-50)/40;
denseY_m(mask) = laneOffset_m*smoothstep5(xi);

mask = denseX_m >= 90 & denseX_m < 105;
denseY_m(mask) = laneOffset_m;

mask = denseX_m >= 105 & denseX_m < 145;
xi = (denseX_m(mask)-105)/40;
denseY_m(mask) = laneOffset_m*(1-smoothstep5(xi));

denseStation_m = [0;cumsum(hypot(diff(denseX_m),diff(denseY_m)))];
station_m = (0:0.25:floor(denseStation_m(end)/0.25)*0.25)';
X_ref_m = interp1(denseStation_m,denseX_m,station_m,"pchip");
Y_ref_m = interp1(denseStation_m,denseY_m,station_m,"pchip");

dXds = gradient(X_ref_m,station_m);
dYds = gradient(Y_ref_m,station_m);
psi_ref_rad = unwrap(atan2(dYds,dXds));
curvature_1pm = gradient(psi_ref_rad,station_m);

referenceSpeed_mps = 15;
localSpeedLimit_mps = referenceSpeed_mps*ones(size(station_m));
maximumLateralAcceleration_mps2 = ...
    max(referenceSpeed_mps^2*abs(curvature_1pm))*1.01;
profile = phase0_profile_parameters(vehicle,referenceSpeed_mps, ...
    maximumLateralAcceleration_mps2);

% This maneuver intentionally uses constant speed; the generated curvature
% is checked explicitly against its selected aggressive envelope.
vx_ref_mps = localSpeedLimit_mps;
curvatureLimit_mps = sqrt(maximumLateralAcceleration_mps2 ./ ...
    max(abs(curvature_1pm),1e-8));
forwardSpeed_mps = vx_ref_mps;
traversalTime_s = station_m(end)/referenceSpeed_mps;

track = struct();
track.name = "aggressive_maneuver";
track.description = ...
    "Project-generated smooth double-lane-change; not ISO 3888-2 compliant.";
track.source = ...
    "Analytical quintic lateral transitions using h(xi)=10xi^3-15xi^4+6xi^5.";
track.station_m = station_m;
track.X_ref_m = X_ref_m;
track.Y_ref_m = Y_ref_m;
track.psi_ref_rad = psi_ref_rad;
track.curvature_1pm = curvature_1pm;
track.local_speed_limit_mps = localSpeedLimit_mps;
track.vx_ref_mps = vx_ref_mps;
track.curvature_speed_limit_mps = curvatureLimit_mps;
track.forward_pass_speed_mps = forwardSpeed_mps;
track.initial_speed_mps = referenceSpeed_mps;
track.maximum_lateral_acceleration_mps2 = ...
    maximumLateralAcceleration_mps2;
track.total_length_m = station_m(end);
track.traversal_time_s = traversalTime_s;
track.simulation_stop_time_s = ceil(traversalTime_s+8);
track.road_friction_mu = vehicle.default_road_friction_mu;
track.slope_rad = 0;
track.stop_event_table = zeros(2,5);
track.profile_parameters = profile;

track = save_phase0_scenario(track,outputFolder,true);
end

function value = smoothstep5(xi)
value = 10*xi.^3-15*xi.^4+6*xi.^5;
end
