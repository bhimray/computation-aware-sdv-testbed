function [X_m, Y_m, yaw_rad] = integrate_spatial_curvature( ...
    station_m, curvature_1pm)
%INTEGRATE_SPATIAL_CURVATURE Integrate a planar path from kappa(s).

numberOfPoints = numel(station_m);
X_m = zeros(numberOfPoints,1);
Y_m = zeros(numberOfPoints,1);
yaw_rad = zeros(numberOfPoints,1);

for index = 2:numberOfPoints
    ds_m = station_m(index) - station_m(index-1);
    averageCurvature_1pm = 0.5 * ( ...
        curvature_1pm(index) + curvature_1pm(index-1));
    yaw_rad(index) = yaw_rad(index-1) + ...
        averageCurvature_1pm * ds_m;
    averageYaw_rad = 0.5 * (yaw_rad(index) + yaw_rad(index-1));
    X_m(index) = X_m(index-1) + cos(averageYaw_rad) * ds_m;
    Y_m(index) = Y_m(index-1) + sin(averageYaw_rad) * ds_m;
end
end
