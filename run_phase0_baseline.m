%% Phase 0 baseline regeneration entry point
clearvars;
% bdclose("all");
% clear functions;
% rehash;

startup_project;

disp("Phase 0 baseline runner initialized.");

% %% steady-state test
% run_open_loop_drive_test;
% %% step-steer test
% run_open_loop_steep_steer_test;


%% road profile: highway_cruise/urban_profile/aggressive_maneuver
projectRoot = fileparts(mfilename('fullpath'));
trackFile = fullfile( ...
    projectRoot, ...
    "phase0", ...
    "scenarios", ...
    "test_track.mat");
% Load the track data for further processing
reference = generate_ref(trackFile);

track_ref_table = ...
    reference.lookup_table;
%% controller parameter
controllerParams = controller_parameters(UT);
controllerParams.pose_x0_m = reference.X_ref_m(1); % initial state x0 for integrator
controllerParams.pose_y0_m = reference.Y_ref_m(1); % initial state y0 for integrator

adaptiveModelParams = ...
    adaptive_model_parameters(controllerParams);

[Ad0,Bmv0,Emd0] = ...
    linearize_prediction_model(controllerParams);

mpc_baseline = configure_baseline_mpc( ...
    Ad0,Bmv0,Emd0,controllerParams);
plant0 = mpc_baseline.Model.Plant;

[A0,B0,C0,D0] = ssdata(plant0);

fprintf("States:  %d\n",size(A0,1));
fprintf("Inputs:  %d\n",size(B0,2));
fprintf("Outputs: %d\n",size(C0,1));
fprintf("Ts:      %.3f s\n",plant0.Ts);

disp("Input groups:");
disp(plant0.InputGroup)

assert(isequal(size(A0),[5 5]), ...
    "A must be 5-by-5");

assert(isequal(size(B0),[5 3]), ...
    "B must contain two MVs and one measured disturbance");

assert(isequal(size(C0),[5 5]), ...
    "C must be 5-by-5");

assert(isequal(size(D0),[5 3]), ...
    "D must be 5-by-3");

assert(abs(plant0.Ts-controllerParams.Ts_s) < 1e-12, ...
    "Prediction model sample time is incorrect");

assert(all(isfinite(A0(:))) && all(isfinite(B0(:))), ...
    "Prediction model contains NaN or Inf");

disp("Nominal prediction model passed.");



mpc_adaptive = configure_baseline_mpc( ...
    Ad0,Bmv0,Emd0,controllerParams);
assert(isa(mpc_adaptive,"mpc"), ...
    "mpc_adaptive was not created");

adaptivePlant0 = mpc_adaptive.Model.Plant;

[Aa,Ba,Ca,Da] = ssdata(adaptivePlant0);

assert(isequal(size(Aa),[5 5]));
assert(isequal(size(Ba),[5 3]));
assert(isequal(size(Ca),[5 5]));
assert(isequal(size(Da),[5 3]));

assert(abs(adaptivePlant0.Ts-controllerParams.Ts_s) < 1e-12);

disp("Adaptive MPC nominal object passed.");

xNominal = controllerParams.nominal_state;

uNominal = [
    controllerParams.nominal_signed_front_axle_torque_Nm
    controllerParams.nominal_road_wheel_angle_rad
    ];

xdotNominal = dynamic_model( ...
    xNominal, ...
    uNominal, ...
    controllerParams.nominal_curvature_1pm, ...
    controllerParams);

disp(xdotNominal);

assert(norm(xdotNominal,Inf) < 1e-9, ...
    "Nominal operating point is not an equilibrium");

disp("Nonlinear-model equilibrium test passed.");

xNominal = controllerParams.nominal_state;

uNominal = [
    controllerParams.nominal_signed_front_axle_torque_Nm
    controllerParams.nominal_road_wheel_angle_rad
    ];

xNext = propagate_prediction_model( ...
    xNominal, ...
    uNominal, ...
    controllerParams.nominal_curvature_1pm, ...
    controllerParams);

disp(xNext-xNominal);

assert(all(isfinite(xNext)), ...
    "Discrete model produced NaN or Inf");

assert(norm(xNext-xNominal,Inf) < 1e-9, ...
    "Nominal equilibrium changed during propagation");

disp("Discrete nonlinear propagation test passed.");

xNominal = controllerParams.nominal_state;

uNominal = [
    controllerParams.nominal_signed_front_axle_torque_Nm
    controllerParams.nominal_road_wheel_angle_rad
    ];

kappaNominal = ...
    controllerParams.nominal_curvature_1pm;

[Aonline,Bonline,Conline,Donline, ...
    Xonline,Yonline,Uonline,DXonline] = ...
    adaptive_model_update( ...
    xNominal, ...
    uNominal, ...
    kappaNominal, ...
    controllerParams);

assert(isequal(size(Aonline),[5 5]));
assert(isequal(size(Bonline),[5 3]));
assert(isequal(size(Conline),[5 5]));
assert(isequal(size(Donline),[5 3]));

assert(all(isfinite(Aonline(:))));
assert(all(isfinite(Bonline(:))));
assert(norm(DXonline,Inf) < 1e-9);

% Compare against the existing nominal analytical model.
[AdReference,BmvReference,EmdReference] = ...
    linearize_prediction_model(controllerParams);

BReference = [BmvReference EmdReference];

relativeAError = ...
    norm(Aonline-AdReference,Inf) ...
    / max(norm(AdReference,Inf),eps);

relativeBError = zeros(1,3);

for inputIndex = 1:3
    relativeBError(inputIndex) = ...
        norm(Bonline(:,inputIndex) ...
        - BReference(:,inputIndex),Inf) ...
        / max(norm(BReference(:,inputIndex),Inf),eps);
end

fprintf("Relative A error: %.6g\n",relativeAError);
fprintf("Relative B errors: %.6g %.6g %.6g\n", ...
    relativeBError);

assert(relativeAError < 0.01, ...
    "Online A matrix does not match the nominal model");

assert(all(relativeBError < 0.05), ...
    "Online B matrix does not match the nominal model");

disp("Adaptive model-update test passed.");

load_system("MPC_backend_adaptive");
assert(all(structfun( ...
    @(value) isnumeric(value) ...
    && isreal(value) ...
    && all(isfinite(value(:))), ...
    adaptiveModelParams)), ...
    "Adaptive model parameters must be finite numeric values");

disp("Numeric adaptive-model parameters passed.");
set_param( ...
    "MPC_backend_adaptive", ...
    "SimulationCommand", ...
    "update");

disp("Adaptive model-update path compiled successfully.");

testTs = controllerParams.Ts_s;
testTime = (0:testTs:1).';

numberOfSamples = numel(testTime);

measuredStateData = repmat( ...
    controllerParams.nominal_state.', ...
    numberOfSamples,1);

referenceStateData = measuredStateData;

curvatureData = zeros(numberOfSamples,1);

externalInputs = Simulink.SimulationData.Dataset;

externalInputs = externalInputs.addElement( ...
    timeseries(measuredStateData,testTime), ...
    "measured_state");

externalInputs = externalInputs.addElement( ...
    timeseries(referenceStateData,testTime), ...
    "state_ref");

externalInputs = externalInputs.addElement( ...
    timeseries(curvatureData,testTime), ...
    "k_ref");

simulationInput = ...
    Simulink.SimulationInput("MPC_backend_adaptive");

simulationInput = simulationInput.setExternalInput( ...
    externalInputs);

simulationInput = simulationInput.setModelParameter( ...
    "StopTime",num2str(testTime(end)), ...
    "SaveOutput","on", ...
    "OutputSaveName","yout", ...
    "SaveFormat","Dataset");

simulationOutput = sim(simulationInput);

outputDataset = simulationOutput.get("yout");

torqueSignal = ...
    outputDataset.getElement("torque").Values;

steeringSignal = ...
    outputDataset.getElement("steering_angle").Values;

statusSignal = ...
    outputDataset.getElement("status").Values;

torqueData = torqueSignal.Data(:);
steeringData = steeringSignal.Data(:);
statusData = statusSignal.Data(:);

assert(all(isfinite(torqueData)), ...
    "Torque contains NaN or Inf");

assert(all(isfinite(steeringData)), ...
    "Steering contains NaN or Inf");

assert(all(torqueData >= ...
    controllerParams.minimumSignedTorque_Nm-1e-9));

assert(all(torqueData <= ...
    controllerParams.maximumSignedTorque_Nm+1e-9));

assert(all(steeringData >= ...
    controllerParams.minimumRoadWheelAngle_rad-1e-9));

assert(all(steeringData <= ...
    controllerParams.maximumRoadWheelAngle_rad+1e-9));

assert(statusData(end) > 0, ...
    "Adaptive MPC did not finish with a successful QP status");

fprintf("Final torque: %.3f N*m\n",torqueData(end));
fprintf("Final steering: %.6f rad\n",steeringData(end));
fprintf("Final solver status: %.0f\n",statusData(end));

disp("Nominal adaptive-backend test passed.");
disp("Baseline simulation completed.");