function reference = generate_ref(referenceFile)
%GENERATE_REF Load and prepare spatial MPC reference data.
%
% Expected track data:
%   s_m
%   X_ref_m
%   Y_ref_m
%   psi_ref_rad
%   kappa_1pm
%   vx_ref_mps

track = load(referenceFile);
track = track.track;
numberOfPoints = numel(track.station_m);

%% Calculate yaw-rate reference

yawRateReference_radps = ...
    track.vx_ref_mps .* ...
    track.curvature_1pm;

%% Full five-state MPC reference
%
% x_ref = [vx_ref; vy_ref; yaw_rate_ref; ey_ref; epsi_ref]

stateReference = [ ...
    track.vx_ref_mps, ...
    zeros(numberOfPoints, 1), ...
    yawRateReference_radps, ...
    zeros(numberOfPoints, 1), ...
    zeros(numberOfPoints, 1)];

%% Construct reference structure

reference = struct();

reference.station_m = track.station_m;
reference.X_ref_m = track.X_ref_m;
reference.Y_ref_m = track.Y_ref_m;
reference.psi_ref_rad = track.psi_ref_rad;
reference.kappa_1pm = track.curvature_1pm;
reference.vx_ref_mps = track.vx_ref_mps;
reference.yaw_rate_ref_radps = ...
    yawRateReference_radps;
reference.local_speed_limit_mps = track.local_speed_limit_mps;
reference.stop_event_table = track.stop_event_table;
reference.initial_speed_mps = track.initial_speed_mps;
reference.traversal_time_s = track.traversal_time_s;
reference.simulation_stop_time_s = track.simulation_stop_time_s;

reference.state_reference = stateReference;

% Convenient single matrix for a Simulink parameter:
%
% Columns:
% 1 s
% 2 X
% 3 Y
% 4 psi
% 5 kappa
% 6 vx
% 7 yaw rate

reference.lookup_table = [ ...
    reference.station_m, ...
    reference.X_ref_m, ...
    reference.Y_ref_m, ...
    reference.psi_ref_rad, ...
    reference.kappa_1pm, ...
    reference.vx_ref_mps, ...
    reference.yaw_rate_ref_radps];

end
