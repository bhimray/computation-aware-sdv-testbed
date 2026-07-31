function UT = legacy_plant_parameters(vehicle, simulation)
% Parameters required by the read-only legacy vehicle plant.

UT = struct();

UT.Ts_Veh = simulation.Ts_s;

UT.lf = vehicle.lf_m;
UT.lr = vehicle.lr_m;
UT.Ls = vehicle.half_track_m;
UT.Rw = vehicle.wheel_radius_m;
UT.h  = vehicle.cg_height_m;
UT.ha = vehicle.aero_height_m;

UT.Mv = vehicle.mass_kg;
UT.Ms = vehicle.sprung_mass_kg;
UT.Ix = vehicle.roll_inertia_kgm2;
UT.Iy = vehicle.pitch_inertia_kgm2;
UT.Iz = vehicle.yaw_inertia_kgm2;
UT.Jw = vehicle.wheel_inertia_kgm2;

UT.Kss = vehicle.suspension_stiffness_Npm;
UT.Cs  = vehicle.suspension_damping_Nspm;

UT.g     = vehicle.gravity_mps2;
UT.rho   = vehicle.air_density_kgpm3;
UT.Cd    = vehicle.drag_coefficient;
UT.Awind = vehicle.frontal_area_m2;
UT.Vw    = vehicle.wind_speed_mps;
UT.CRF   = vehicle.rolling_resistance_coefficient;
UT.mu    = vehicle.default_road_friction_mu;

UT.VSlipMin = ...
    vehicle.minimum_tire_slip_speed_mps; %% for tire slip at v= 0
end