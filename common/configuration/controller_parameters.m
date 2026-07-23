controller.Ts_s = UT.Ts_Veh;

pose_x0_m = 0;
pose_y0_m = 0;
steering = 0;
controller.num_states = 4;
controller.num_outputs = 4;
controller.num_inputs = 2;

controller.state_names = ...
    ["X_m","Y_m","yaw_rad","speed_mps"];

controller.input_names = ...
    ["front_road_wheel_rad","acceleration_mps2"];

controller.lf_m = UT.lf;
controller.lr_m = UT.lr;
controller.wheelbase_m = ...
    controller.lf_m + controller.lr_m;