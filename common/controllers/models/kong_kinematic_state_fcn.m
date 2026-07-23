function xdot = kong_kinematic_state_fcn(x,u)
% Kong nonlinear kinematic bicycle model.
%
% Reference:
% Kong et al., IEEE IV 2015, Equations (1a)-(1e).
%
% States:
% x(1) = X position                    [m]
% x(2) = Y position                    [m]
% x(3) = yaw angle, psi               [rad]
% x(4) = vehicle speed, v             [m/s]
%
% Inputs:
% u(1) = front road-wheel angle       [rad]
% u(2) = longitudinal acceleration    [m/s^2]

lf_m = UT.lf;
lr_m = UT.lr;

psi_rad = x(3);
speed_mps = x(4);

delta_front_rad = u(1);
acceleration_mps2 = u(2);

beta_rad = atan( ...
    (lr_m/(lf_m + lr_m)) * tan(delta_front_rad));

xdot = zeros(4,1);

xdot(1) = speed_mps*cos(psi_rad + beta_rad);
xdot(2) = speed_mps*sin(psi_rad + beta_rad);
xdot(3) = (speed_mps/lr_m)*sin(beta_rad);
xdot(4) = acceleration_mps2;
end