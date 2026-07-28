function p = adaptive_model_parameters(controller)
%ADAPTIVE_MODEL_PARAMETERS
% Extract only numeric parameters required by the nonlinear model.

p.Ts_s = controller.Ts_s;
p.integration_substeps = controller.integration_substeps;

p.mass_kg = controller.mass_kg;
p.yaw_inertia_kgm2 = controller.yaw_inertia_kgm2;

p.lf_m = controller.lf_m;
p.lr_m = controller.lr_m;

p.wheel_radius_m = controller.wheel_radius_m;
p.drivetrain_efficiency = controller.drivetrain_efficiency;

p.gravity_mps2 = controller.gravity_mps2;
p.air_density_kgpm3 = controller.air_density_kgpm3;
p.drag_coefficient = controller.drag_coefficient;
p.frontal_area_m2 = controller.frontal_area_m2;
p.rolling_resistance_coefficient = ...
    controller.rolling_resistance_coefficient;

p.Cf_Nprad = controller.Cf_Nprad;
p.Cr_Nprad = controller.Cr_Nprad;

p.minimum_speed_mps = controller.minimum_speed_mps;
end