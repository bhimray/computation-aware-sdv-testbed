function vehicle = vehicle_parameters()
%VEHICLE_PARAMETERS Physical parameters of the mid-fidelity vehicle.

%% Geometry

vehicle.lf_m = 1.11;
vehicle.lr_m = 1.66622;
vehicle.half_track_m = 0.775;
vehicle.wheel_radius_m = 0.330;
vehicle.cg_height_m = 0.54;
vehicle.aero_height_m = 0.72;

%% Mass and inertia

vehicle.mass_kg = 1530;
vehicle.sprung_mass_kg = 1370;
vehicle.roll_inertia_kgm2 = 606.1;
vehicle.pitch_inertia_kgm2 = 4192;
vehicle.yaw_inertia_kgm2 = 4192;
vehicle.wheel_inertia_kgm2 = 0.9;

%% Suspension

vehicle.suspension_stiffness_Npm = 153e3;
vehicle.suspension_damping_Nspm = 2.9447e3;

%% Environment and resistance

vehicle.gravity_mps2 = 9.81;
vehicle.air_density_kgpm3 = 1.206;
vehicle.drag_coefficient = 0.28;
vehicle.frontal_area_m2 = 2.51;
vehicle.wind_speed_mps = 0;
vehicle.rolling_resistance_coefficient = 0.03;
vehicle.default_road_friction_mu = 0.80;

vehicle.drivetrain_efficiency = 1; %no loss
vehicle.minimum_tire_slip_speed_mps = 0.10; %% Low-speed numerical protection

end