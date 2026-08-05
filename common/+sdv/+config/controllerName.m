function name = controllerName(controllerParams)
%CONTROLLERNAME Return the stable output name for a controller backend.

switch controllerParams.controller_backend
    case controllerParams.BACKEND_ACADOS
        name = "ACADOS_MPC";
    case controllerParams.BACKEND_MATLAB
        name = "MATLAB_MPC";
    case controllerParams.BACKEND_ADAPTIVE
        name = "ADAPTIVE_MPC";
    otherwise
        error( ...
            "SDV:UnknownControllerBackend", ...
            "Unknown controller backend ID: %d", ...
            controllerParams.controller_backend);
end

end
