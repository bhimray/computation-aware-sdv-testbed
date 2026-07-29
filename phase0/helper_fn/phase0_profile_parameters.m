function profile = phase0_profile_parameters(v, initialSpeed_mps, ...
    maximumLateralAcceleration_mps2)
%PHASE0_PROFILE_PARAMETERS Common physically based speed-profile settings.

actuator = actuator_parameters();

profile.mass_kg = v.mass_kg;
profile.gravity_mps2 = v.gravity_mps2;
profile.road_friction_mu = v.default_road_friction_mu;
profile.air_density_kgpm3 = v.air_density_kgpm3;
profile.drag_coefficient = v.drag_coefficient;
profile.frontal_area_m2 = v.frontal_area_m2;
profile.rolling_resistance_coefficient = v.rolling_resistance_coefficient;
profile.rolling_resistance_smoothing_speed_mps = 0.10;

% The plant command is total signed front-axle torque.
profile.maximum_drive_force_N = ...
    v.drivetrain_efficiency ...
    * actuator.maximum_signed_front_axle_torque_Nm ...
    / v.wheel_radius_m;

profile.maximum_braking_force_N = ...
    v.drivetrain_efficiency ...
    * abs(actuator.minimum_signed_front_axle_torque_Nm) ...
    / v.wheel_radius_m;

profile.maximum_lateral_acceleration_mps2 = ...
    maximumLateralAcceleration_mps2;
profile.initial_speed_mps = initialSpeed_mps;
profile.minimum_speed_for_time_mps = 0.50;
end
