function config = build_phase0_configuration(scenarioName)

vehicle = vehicle_parameters();
actuator = actuator_parameters();
scenario = load_scenario(scenarioName);
simulation = simulation_parameters(scenario);
controller = controller_parameters(vehicle, simulation);

adaptiveModel = adaptive_model_parameters( ...
    vehicle, controller);

config.vehicle = vehicle;
config.actuator = actuator;
config.scenario = scenario;
config.simulation = simulation;
config.controller = controller;
config.adaptiveModel = adaptiveModel;
end
