# Mid-Fidelity Vehicle Plant Wrapper

## 1. Purpose

`PlantWrapper.slx` provides a stable and documented interface to the mid-fidelity Simulink vehicle model.

Controllers, scenarios, and test harnesses must interact with the vehicle through `PlantWrapper.slx`. The vehicle model is treated as read-only and must not be modified.

The wrapper:

- exposes controller commands as named input ports;
- exposes measured vehicle states as named output ports;
- provides ports for future road disturbances (TODO);
- preserves the internal behavior of the supplied vehicle model;
- standardizes signal names, units, and sign conventions.

## 2. Model files

| File | Purpose | Modification policy |
|---|---|---|
| `PlantWrapper.slx` | Stable controller-facing vehicle interface | May be modified when the interface needs to be extended |
| `EgoCarModel.slx` | Extracted vehicle plant used by the wrapper | Do not modify unless an integration correction is required |
| `source/car_speed_control_Student.slx` | Original course vehicle model | Read-only |
| `source/Ego_car_speed_control_script_Student.m` | Original model initialization and parameter script | Read-only |

## 3. Input interface

| Port | Signal name | Unit | Nominal value | Positive convention | Description |
|---:|---|---|---:|---|---|
| 1 | `front_drive_torque_Nm` | N·m | Test-dependent | Positive torque propels the vehicle forward | Front-drive torque command supplied to the vehicle model |
| 2 | `braking_cmd` | Source-model command unit; verification pending | 0 | Increasing positive command increases braking | Brake command supplied to the original brake subsystem |
| 3 | `steering_wheel_deg` | deg | 0 | Positive sign follows the source-model steering convention | Steering-wheel angle before conversion to left and right road-wheel angles |
| 4 | `slope` | rad | 0 | Positive | Road-grade disturbance |
| 5 | `road_friction_mu` | dimensionless | 0.95 | Positive coefficient of friction | Tire-road friction coefficient supplied to the tire model |

## 4. Output interface

| Port | Signal name | Unit | Positive convention | Description |
|---:|---|---|---|---|
| 1 | `vx_mps` | m/s | Positive in the forward body-axis direction | Longitudinal vehicle velocity |
| 2 | `ax_mps2` | m/s² | Positive forward acceleration | Longitudinal vehicle acceleration |
| 3 | `yaw_rate_radps` | rad/s | Source-model yaw convention; verify using a positive steering test | Yaw angular velocity |
| 4 | `yaw_angle_rad` | rad | Same rotational convention as yaw rate | Vehicle yaw or heading angle |
| 5 | `ay_mps2` | m/s² | Source-model lateral-axis convention | Lateral vehicle acceleration |
| 6 | `vy_mps` | m/s | Source-model lateral-axis convention | Lateral vehicle velocity |
| 7 | `sideslip_rad` | rad | Source-model sideslip convention | Vehicle body sideslip angle |
| 8 | `x_position_m` | m | Estimated global X position obtained by integrating body velocities |
| 9 | `y_position_m` | m | Estimated global Y position obtained by integrating body velocities |
| 10 | `speed_mps` | m/s | Scalar vehicle speed, \(\sqrt{V_x^2+V_y^2}\) |

These outputs are available for controller feedback, validation, and diagnostic plotting. A controller should only consume signals that are assumed to be measurable or estimated in the intended implementation.

Global position is calculated in the editable plant wrapper using body-fixed longitudinal and lateral velocities and vehicle yaw angle. The original course vehicle model is not modified. In simulation, this subsystem represents an ideal dead-reckoning/localization measurement. A real implementation would normally obtain global pose from a localization system such as GPS/INS.

## 5. Wrapper-to-source-model mapping

| Wrapper signal | Source-model signal or subsystem | Conversion |
|---|---|---|
| `front_drive_torque_Nm` | `Torque` / `Tdf` | No conversion currently applied |
| `braking_cmd` | `Brake` | No conversion currently applied |
| `steering_wheel_deg` | `steering wheel angle deg` | Source steering subsystem converts steering-wheel angle into left and right road-wheel angles |
| `slope` | `slope` | No conversion; input is expected in radians |
| `road_friction_mu` | `TRFC` | No conversion |
| `vx_mps` | `Vx` | No conversion |
| `ax_mps2` | `ax` | No conversion |
| `yaw_rate_radps` | `Yaw Rate` | No conversion |
| `yaw_angle_rad` | `Yaw Angle` | No conversion |
| `ay_mps2` | `ay` | No conversion |
| `vy_mps` | `Vy` | No conversion |
| `sideslip_rad` | `Beta` | No conversion |

The wrapper must not silently rescale or reinterpret a signal. Any future scaling or conversion must be documented in this table.

## 6. Disturbance inputs

Road grade and tire-road friction are exposed at the wrapper boundary because they are required for future disturbance scenarios.

The disturbance ports are:

- `slope`
- `road_friction_mu`

These ports are added in the wrapper vehicle model.

For nominal Phase 0 tests:

```matlab
slope = 0;
road_friction_mu = 0.95;
```

Additional disturbances required by later project phases must also be introduced through the wrapper whenever possible.

## 7. Initialization and operating assumptions

The vehicle parameters are initialized using the supplied vehicle configuration script.

Important nominal parameters include:

| Parameter | Value | Unit |
|---|---:|---|
| Vehicle mass, `UT.Mv` | 1530 | kg |
| Wheel radius, `UT.Rw` | 0.330 | m |
| Vehicle model sample time, `UT.Ts_Veh` | 0.01 | s |
| Initial speed, `v_ini` | Test-dependent; commonly 5 | m/s |
| Nominal road friction | 0.95 | dimensionless |
| Nominal road slope | 0 | rad |
| Nominal brake command | 0 | source-model command unit |

Operating assumptions:

- longitudinal velocity is positive in the forward direction;
- the source vehicle model remains unchanged;
- test commands remain within the valid operating range of the original model;
- low-speed tire-slip behavior may require separate numerical validation;
- all test scripts explicitly set their inputs rather than relying on old workspace values.

## 8. Sign-convention verification

The sign conventions must be verified using controlled open-loop tests.

| Verification | Applied condition | Expected observation | Status |
|---|---|---|---|
| Drive-torque sign | Positive drive torque, zero brake | Sufficient torque produces positive longitudinal acceleration | Verified |
| Brake sign | Positive brake command at nonzero speed | Longitudinal speed decreases | Pending confirmation |
| Steering sign | Positive steering-wheel step at constant positive speed | Record the resulting yaw-rate sign | Pending documentation |
| Grade sign | Positive slope at constant propulsion command | Record whether longitudinal resistance increases or decreases | Pending confirmation |
| Friction effect | Reduce `road_friction_mu` under the same maneuver | Tire-force capacity decreases | Pending later disturbance test |

Replace "Pending" entries after each convention has been verified. Record the tested value and observed signal sign.


## 9. Test harness policy

Phase 0 uses separate test harnesses that reference the same wrapper:

```text
phase0/models/plant_open_loop_drive_test.slx
phase0/models/plant_open_loop_step_steer_test.slx
```

The vehicle model must not be copied separately into each test harness.

The intended structure is:

```text
Test harness
    └── PlantWrapper.slx
            └── EgoCarModel.slx
                    └── original vehicle dynamics
```

Each test must have a corresponding MATLAB script that:

- defines all test inputs;
- runs the simulation;
- retrieves the logged signals;
- calculates relevant summary values;
- generates repeatable plots;
- saves the results and figures.

## 10. Interface-change policy

If the wrapper interface changes:

1. do not modify the original source plant;
2. update the ports in `PlantWrapper.slx`;
3. update every affected test harness;
4. update the input/output tables in this README;
5. document all scaling or unit conversions;
6. rerun both Phase 0 sanity checks;
7. commit the interface and documentation changes together.