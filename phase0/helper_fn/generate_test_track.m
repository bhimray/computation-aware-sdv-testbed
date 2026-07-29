function track = generate_test_track(outputFolder)
%GENERATE_PHASE0_TEST_TRACK

if nargin<1
    thisFileFolder = fileparts(mfilename('fullpath')); % location of current folder
    phase0Folder = fileparts(thisFileFolder);
    outputFolder = fullfile( ...
        phase0Folder,"scenarios","data"); % development artifact folder
else
    outputFolder = string(outputFolder);
end

vehicle = vehicle_parameters();

%% Track geometry configuration

ds_m = 0.25;
trackLength_m = 180;

s_m = (0:ds_m:trackLength_m)';
numberOfPoints = numel(s_m);

% Maximum curvature:
% radius = 1/0.04 = 25 m
maximumCurvature_1pm = 0.04;

kappa_1pm = zeros(numberOfPoints, 1);

%% Left curve

% Curvature transition: 0 -> +kappa
mask = s_m >= 40 & s_m < 50;
transitionCoordinate = (s_m(mask) - 40) / 10;

kappa_1pm(mask) = ...
    0.5 * maximumCurvature_1pm .* ...
    (1 - cos(pi * transitionCoordinate));

% Constant left curvature
mask = s_m >= 50 & s_m < 65;

kappa_1pm(mask) = maximumCurvature_1pm;

% Curvature transition: +kappa -> 0
mask = s_m >= 65 & s_m < 75;
transitionCoordinate = (s_m(mask) - 65) / 10;

kappa_1pm(mask) = ...
    0.5 * maximumCurvature_1pm .* ...
    (1 + cos(pi * transitionCoordinate));

%% Right curve

% Curvature transition: 0 -> -kappa
mask = s_m >= 105 & s_m < 115;
transitionCoordinate = (s_m(mask) - 105) / 10;

kappa_1pm(mask) = ...
    -0.5 * maximumCurvature_1pm .* ...
    (1 - cos(pi * transitionCoordinate));

% Constant right curvature
mask = s_m >= 115 & s_m < 130;

kappa_1pm(mask) = -maximumCurvature_1pm;

% Curvature transition: -kappa -> 0
mask = s_m >= 130 & s_m < 140;
transitionCoordinate = (s_m(mask) - 130) / 10;

kappa_1pm(mask) = ...
    -0.5 * maximumCurvature_1pm .* ...
    (1 + cos(pi * transitionCoordinate));

%% Integrate curvature to obtain heading and position

psi_ref_rad = zeros(numberOfPoints, 1);
X_ref_m = zeros(numberOfPoints, 1);
Y_ref_m = zeros(numberOfPoints, 1);

for index = 2:numberOfPoints

    ds = s_m(index) - s_m(index - 1);

    averageCurvature = 0.5 * ( ...
        kappa_1pm(index) + ...
        kappa_1pm(index - 1));

    psi_ref_rad(index) = ...
        psi_ref_rad(index - 1) + ...
        averageCurvature * ds;

    averageHeading = 0.5 * ( ...
        psi_ref_rad(index) + ...
        psi_ref_rad(index - 1));

    X_ref_m(index) = ...
        X_ref_m(index - 1) + ...
        cos(averageHeading) * ds;

    Y_ref_m(index) = ...
        Y_ref_m(index - 1) + ...
        sin(averageHeading) * ds;
end

%% Local speed limits

localSpeedLimit_mps = ...
    12 * ones(numberOfPoints, 1);

% Begin at 5 m/s
localSpeedLimit_mps(s_m <= 20) = 5;

% Require braking to 6 m/s near the end
localSpeedLimit_mps(s_m >= 165) = 6;

%% Vehicle/profile configuration

profile = phase0_profile_parameters( ...
    vehicle,0,0.35*vehicle.gravity_mps2);

%% Generate three-pass speed profile
[vx_ref_mps, ...
 vx_curvature_limit_mps, ...
 vx_forward_mps, ...
 traversalTime_s] = ...
    three_pass_speed_profile( ...
        s_m, ...
        kappa_1pm, ...
        localSpeedLimit_mps, ...
        profile);

%% Derived yaw-rate reference

yaw_rate_ref_radps = ...
    vx_ref_mps .* kappa_1pm;

%% Create track structure

track = struct();

track.station_m = s_m;
track.X_ref_m = X_ref_m;
track.Y_ref_m = Y_ref_m;
track.psi_ref_rad = psi_ref_rad;
track.curvature_1pm = kappa_1pm;
track.vx_ref_mps = vx_ref_mps;
track.yaw_rate_ref_radps = yaw_rate_ref_radps;

track.local_speed_limit_mps = localSpeedLimit_mps;
track.curvature_speed_limit_mps = ...
    vx_curvature_limit_mps;
track.forward_pass_speed_mps = vx_forward_mps;

track.total_length_m = s_m(end);
track.traversal_time_s = traversalTime_s;
track.profile_parameters = profile;

% Full five-state reference:
% [vx_ref, vy_ref, yaw_rate_ref, ey_ref, epsi_ref]
track.mpc_reference = [ ...
    vx_ref_mps, ...
    zeros(numberOfPoints, 1), ...
    yaw_rate_ref_radps, ...
    zeros(numberOfPoints, 1), ...
    zeros(numberOfPoints, 1)];

%% Save MAT file

matFile = fullfile( ...
    outputFolder, ...
    "test_track.mat");

save(matFile, "track");

%% Save documented TXT file

trackTable = table( ...
    s_m, ...
    X_ref_m, ...
    Y_ref_m, ...
    psi_ref_rad, ...
    kappa_1pm, ...
    vx_ref_mps, ...
    'VariableNames', { ...
        's_m', ...
        'X_ref_m', ...
        'Y_ref_m', ...
        'psi_ref_rad', ...
        'kappa_1pm', ...
        'vx_ref_mps'});

txtFile = fullfile( ...
    outputFolder, ...
    "test_track.txt");

writetable( ...
    trackTable, ...
    txtFile, ...
    'Delimiter', '\t');

%% Plot verification figures

figure("Name", "Test Track");

subplot(3,1,1);

plot( ...
    X_ref_m, ...
    Y_ref_m, ...
    "LineWidth", 1.5);

axis equal;
grid on;
xlabel("X (m)");
ylabel("Y (m)");
title("Test Track");

subplot(3,1,2);

plot( ...
    s_m, ...
    kappa_1pm, ...
    "LineWidth", 1.5);

grid on;
xlabel("Path distance, s (m)");
ylabel("Curvature (1/m)");
title("Reference Curvature");

subplot(3,1,3);

plot( ...
    s_m, ...
    localSpeedLimit_mps, ...
    "k--", ...
    "DisplayName", "Local speed limit");

hold on;

plot( ...
    s_m, ...
    vx_curvature_limit_mps, ...
    "r:", ...
    "DisplayName", "Pass 1: curvature limit");

plot( ...
    s_m, ...
    vx_forward_mps, ...
    "g-.", ...
    "DisplayName", "Pass 2: forward");

plot( ...
    s_m, ...
    vx_ref_mps, ...
    "b", ...
    "LineWidth", 1.8, ...
    "DisplayName", "Pass 3: final");

hold off;
grid on;
xlabel("Path distance, s (m)");
ylabel("Speed (m/s)");
title("Three-Pass Speed Profile");
legend("Location", "best");

fprintf("Track length: %.2f m\n", track.total_length_m);
fprintf("Estimated traversal time: %.2f s\n", ...
    track.traversal_time_s);
fprintf("MAT file: %s\n", matFile);
fprintf("TXT file: %s\n", txtFile);

end



