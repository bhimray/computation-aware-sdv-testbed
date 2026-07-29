function p = adaptive_model_parameters(vehicle, controller)
%ADAPTIVE_MODEL_PARAMETERS Numeric parameters used by generated code.

p.Ts_s = controller.Ts_s;
p.integration_substeps = controller.integration_substeps;

p.mass_kg = vehicle.mass_kg;
p.yaw_inertia_kgm2 = vehicle.yaw_inertia_kgm2;

p.lf_m = vehicle.lf_m;
p.lr_m = vehicle.lr_m;

p.wheel_radius_m = vehicle.wheel_radius_m;
p.drivetrain_efficiency = vehicle.drivetrain_efficiency;

p.gravity_mps2 = vehicle.gravity_mps2;
p.air_density_kgpm3 = vehicle.air_density_kgpm3;
p.drag_coefficient = vehicle.drag_coefficient;
p.frontal_area_m2 = vehicle.frontal_area_m2;
p.rolling_resistance_coefficient = ...
    vehicle.rolling_resistance_coefficient;

p.rolling_resistance_smoothing_speed_mps = ...
    controller.rolling_resistance_smoothing_speed_mps;

p.Cf_Nprad = controller.Cf_Nprad;
p.Cr_Nprad = controller.Cr_Nprad;
p.minimum_speed_mps = controller.minimum_speed_mps;
end