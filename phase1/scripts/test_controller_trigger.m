[controllerTrigger, eventTable] = ...
    generate_sampling_jitter_trigger( ...
    20, ...       % simulation duration
    0.010, ...   % nominal controller period
    0.005, ...   % jitter bound
    0.0005, ...  % fixed simulation step
    1);          % random seed

disp(eventTable(1:10,:));

stairs( ...
    controllerTrigger.Time, ...
    controllerTrigger.Data);

grid on;
xlim([0 0.2]);
xlabel("Time (s)");
ylabel("Trigger");
title("Script-generated controller trigger");