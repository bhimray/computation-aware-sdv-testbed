function actuator = actuator_parameters()
%ACTUATOR_PARAMETERS physical command limits.
%
% used by both MPC configuration and
% offline speed-profile generation.

actuator.minimum_signed_front_axle_torque_Nm = -300;
actuator.maximum_signed_front_axle_torque_Nm =  300;
actuator.minimum_signed_torque_rate_Nmps = -100;
actuator.maximum_signed_torque_rate_Nmps =  100;

actuator.minimum_road_wheel_angle_rad = -deg2rad(20);
actuator.maximum_road_wheel_angle_rad =  deg2rad(20);
actuator.minimum_road_wheel_rate_radps = -deg2rad(15);
actuator.maximum_road_wheel_rate_radps =  deg2rad(15);
end
