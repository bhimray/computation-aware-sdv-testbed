%% Vehicle parameters for mid-fidelity plant

set(0,'DefaultAxesFontName', 'Times');
set(0,'DefaultAxesFontSize', 12);
set(0,'DefaultTextFontname', 'Times');
set(0,'DefaultTextFontSize', 12);

global UT

UT = struct();

% Simulation
UT.Ts_Veh = 0.01;       % s, vehicle-dynamics simulation period

% Geometry
UT.lf = 1.11;           % m, CG to front axle
UT.lr = 1.66622;        % m, CG to rear axle
UT.Ls = 0.775;          % m, half-track width
UT.Rw = 0.330;          % m, effective wheel radius
UT.h  = 0.54;           % m, CG height
UT.ha = 0.72;           % m, aerodynamic-force application height

% Mass and inertia
UT.Mv = 1530;           % kg, total vehicle mass
UT.Ms = 1370;           % kg, sprung mass
UT.Ix = 606.1;          % kg*m^2, roll-axis inertia
UT.Iy = 4192;           % kg*m^2, pitch-axis inertia
UT.Iz = 4192;           % kg*m^2, yaw-axis inertia
UT.Jw = 0.9;            % kg*m^2, wheel rotational inertia

% Suspension
UT.Kss = 153e3;         % N/m, suspension stiffness
UT.Cs  = 2.9447e3;      % N*s/m, suspension damping

% Environment and resistance
UT.g     = 9.81;        % m/s^2, gravitational acceleration
UT.rho   = 1.206;       % kg/m^3, air density
UT.Cd    = 0.28;        % aerodynamic drag coefficient
UT.Awind = 2.51;        % m^2, frontal area
UT.Vw    = 0;           % m/s, wind speed
UT.CRF   = 0.03;        % rolling-resistance coefficient

% Default initial condition
v_ini = 5;              % m/s

%sim
simOut = sim("PlantWrapper");
% Extract simulation results
ts_FxFL = simOut.PSG1_FxFL;             % timeseries object
time = ts_FxFL.Time;
data = ts_FxFL.Data;
