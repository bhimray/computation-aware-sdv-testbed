function delta = steering_conversion(delta_sw)
% Convert steering wheel angle to vehicle steering angle
conversionFactor = pi/(180 * controller_parameters.is);
delta = delta_sw * conversionFactor;
end
