% This is a script for Merging Control of ACM
clc
clear all
%close all
set(0,'DefaultAxesFontName', 'Times');
set(0,'DefaultAxesFontSize', 12);
set(0,'DefaultTextFontname', 'Times');
set(0,'DefaultTextFontSize', 12);

%% Vehicle Dynamics
global UT
UT.Ts_Veh = 0.01;    % Basic Simulink period = Veh Dyn Simulation period = SUMO period = MFC;
                      
% Values based of CarSim D-Class Sedan
UT.lf  =  1.11;        %m        length from c.g to front
UT.lr  =  1.66622;     %m        length from c.g to rear
UT.Ls  =  0.775;       %m        half of the track width, w=2*Ls
UT.Rw  =  0.330;       %m        Wheel Radius (Effective rolling radius)
UT.ha  =  0.72;        %m        height that the aerodynamic resistance force acts
UT.Mv  =  1530;        %kg       total mass of the vehicle
UT.Ms  =  1370;        %kg       sprung mass of the vehicle
UT.g   =  9.81;        %m/s^2    gravitational constant
UT.h   =  0.54;        %m        height from ground to c.g
UT.Kss =  153*10^3;    %N/m      suspension stiffness
UT.Cs  =  2.9447*10^3; %N*s/m    suspension damping
UT.rho =  1.206;       %kg/m^3   air mass density
UT.Cd  =  0.28;        %         aerodynamic drag coeff (at zero slip angle)
UT.Awind = 2.51;       %m^2      projected area of the vehicle in direction of travel
UT.Vw  = 0;            %m/s      wind speed
UT.CRF = 0.03;    
UT.Iz  = 4192;         %kg*m^2   Moment of inertia around the z-axis for Z-torque
UT.Ix  = 606.1;        %kg*m^2   Moment of inertia around the x-axis for X-torque
UT.Iy  = 4192;         %kg*m^2   Moment of inertia around the y-axis for Y-torque
UT.Jw  = 0.9;          %kg*m^2   Polar Moment of inertia around the wheel center

% T_ADE = UT.Ts_Veh;
UT.v_ini = 5;

% Load Leader Speed 
% load('Front_car_speed.mat')

% Desired Int-Veh Dist
% time_headway  = 1;
% safety_margin = 2.5; 

% Initial_dist = 12;

% %% Sim
% sim('car_speed_control_Student')
