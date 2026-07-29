function gate = check_highway_speed_feasibility(requestedSpeed_mps)
%CHECK_HIGHWAY_SPEED_FEASIBILITY Open-loop plant gate for highway speed.

arguments
    requestedSpeed_mps (1,1) double {mustBePositive} = 27
end

vehicleParams = vehicle_parameters();
actuatorParams = actuator_parameters();

rollingResistance_N = ...
    vehicleParams.rolling_resistance_coefficient ...
    * vehicleParams.mass_kg ...
    * vehicleParams.gravity_mps2;

aerodynamicDrag_N = ...
    0.5 ...
    * vehicleParams.air_density_kgpm3 ...
    * vehicleParams.drag_coefficient ...
    * vehicleParams.frontal_area_m2 ...
    * requestedSpeed_mps^2;

steadyTorque_Nm = ...
    vehicleParams.wheel_radius_m ...
    * (rollingResistance_N+aerodynamicDrag_N) ...
    / vehicleParams.drivetrain_efficiency;

gate = struct();
gate.requested_speed_mps = requestedSpeed_mps;
gate.steady_torque_Nm = steadyTorque_Nm;
gate.actuator_feasible = steadyTorque_Nm <= ...
    actuatorParams.maximum_signed_front_axle_torque_Nm;
gate.passed = false;
gate.reason = "";

if ~gate.actuator_feasible % if constraint met, then okay.
    gate.reason = "Estimated steady torque exceeds actuator bound.";
    return
end

simulationInput = Simulink.SimulationInput("plant_open_loop_test");

simulationParams.Ts_s = 0.01;
simulationParams.initial_x_m = 0;
simulationParams.initial_y_m = 0;
simulationParams.initial_yaw_rad = 0;
simulationParams.initial_speed_mps = requestedSpeed_mps;
simulationParams.stop_time_s = 20;
simulationParams.road_friction_mu = ...
    vehicleParams.default_road_friction_mu;
simulationParams.slope_rad = 0;

controllerParams = controller_parameters( ...
    vehicleParams,simulationParams);

simulationInput = simulationInput.setVariable( ...
    "vehicleParams",vehicleParams);
simulationInput = simulationInput.setVariable( ...
    "simulationParams",simulationParams);
simulationInput = simulationInput.setVariable( ...
    "controllerParams",controllerParams);
simulationInput = simulationInput.setVariable("v_ini",requestedSpeed_mps);
simulationInput = simulationInput.setVariable( ...
    "test_drive_torque_Nm",steadyTorque_Nm);
simulationInput = simulationInput.setVariable("test_steering_wheel_deg",0);
simulationInput = simulationInput.setVariable("test_road_friction_mu",0.8);
simulationInput = simulationInput.setModelParameter(StopTime="20");


simulationOutput = sim(simulationInput);
logs = simulationOutput.logsout;
vx = squeeze(double(logs.get("vx_mps").Values.Data));
ax = squeeze(double(logs.get("ax_mps2").Values.Data));
drag = squeeze(double(logs.get("Fax").Values.Data));

tailStart = max(1,floor(0.8*numel(vx)));
disp("tail_start");
disp(tailStart);
gate.all_finite = all(isfinite([vx(:);ax(:);drag(:)]));
gate.final_speed_mps = mean(vx(tailStart:end));
gate.final_acceleration_mps2 = mean(ax(tailStart:end));
gate.mean_drag_N = mean(drag(tailStart:end));
gate.drag_balance_relative_error = abs( ...
        steadyTorque_Nm/vehicleParams.wheel_radius_m - ...
        (rollingResistance_N+gate.mean_drag_N)) / ...
        max(steadyTorque_Nm/vehicleParams.wheel_radius_m,1);

gate.passed = gate.all_finite && ...
    abs(gate.final_speed_mps-requestedSpeed_mps) <= 2 && ...
    abs(gate.final_acceleration_mps2) <= 0.30 && ...
    gate.drag_balance_relative_error <= 0.25;
if ~gate.passed
    gate.reason = "Finite-state, speed, acceleration, or drag-balance gate failed.";
end

end
