function install_scenario_reference_manager
%INSTALL_SCENARIO_REFERENCE_MANAGER Update ControllerWrapper automatically.
%
% The external ControllerWrapper interface is unchanged. The existing vx
% input and an internal Clock feed the reference manager. Extra diagnostic
% outputs remain internal and are logged for validation.

modelName = "ControllerWrapper";
managerPath = modelName + "/MATLAB Function";
load_system(modelName);

root = sfroot;
charts = find(root,"-isa","Stateflow.EMChart");
managerChart = [];
for chartIndex = 1:numel(charts)
    if string(charts(chartIndex).Path) == managerPath
        managerChart = charts(chartIndex);
        break
    end
end
assert(~isempty(managerChart), ...
    "Could not find MATLAB Function block '%s'.",managerPath);

managerChart.Script = sprintf([ ...
    "function [state_ref,kappa_ref,X_ref,Y_ref,yaw_ref," ...
    "station_ref,track_index,stop_status] = path_ref(" ...
    "X_m,Y_m,vx_mps,time_s,track_ref_table,scenario_stop_table)\n" ...
    "[state_ref,kappa_ref,X_ref,Y_ref,yaw_ref,station_ref," ...
    "track_index,stop_status] = scenario_reference_manager(" ...
    "X_m,Y_m,vx_mps,time_s,track_ref_table,scenario_stop_table);\n" ...
    "end\n"]);

set_param(modelName,SimulationCommand="update");

clockPath = modelName + "/scenario_clock";
if getSimulinkBlockHandle(clockPath) < 0
    add_block("simulink/Sources/Clock",clockPath, ...
        Position=[-780 260 -750 280]);
end

managerPorts = get_param(managerPath,"PortHandles");
vxPorts = get_param(modelName+"/vx_mps","PortHandles");
clockPorts = get_param(clockPath,"PortHandles");

if numel(managerPorts.Inport) < 4
    set_param(modelName,SimulationCommand="update");
    managerPorts = get_param(managerPath,"PortHandles");
end
assert(numel(managerPorts.Inport) == 4, ...
    "Reference manager must expose X, Y, vx, and time inputs.");

connectIfNeeded(modelName,vxPorts.Outport,managerPorts.Inport(3));
connectIfNeeded(modelName,clockPorts.Outport,managerPorts.Inport(4));

set_param(modelName,SimulationCommand="update");
managerPorts = get_param(managerPath,"PortHandles");

diagnosticNames = [ ...
    "station_reference_m", ...
    "track_index", ...
    "stop_status"];
for outputIndex = 6:8
    set_param(managerPorts.Outport(outputIndex), ...
        DataLogging="on", ...
        DataLoggingNameMode="Custom", ...
        DataLoggingName=diagnosticNames(outputIndex-5));
end

save_system(modelName);
end

function connectIfNeeded(modelName,sourcePort,destinationPort)
existingLine = get_param(destinationPort,"Line");
if existingLine == -1
    add_line(modelName,sourcePort,destinationPort,autorouting="on");
end
end
