# Computation-Aware SDV Testbed

This repository contains a modular MATLAB/Simulink testbed for longitudinal
speed tracking and lateral path tracking. A mid-fidelity vehicle model is used
as the plant, while a lower-order dynamic bicycle model is used for MPC
prediction.

Phase 0 currently supports two controller backends:

- acados nonlinear MPC
- MATLAB Adaptive MPC

The fixed linear MATLAB MPC backend is reserved but is not yet implemented.

## Requirements

The project was developed with MATLAB R2026a on Windows. The following MATLAB
products are required:

- MATLAB
- Simulink
- Control System Toolbox
- Model Predictive Control Toolbox

The acados backend additionally requires:

- Git
- CMake
- MATLAB MinGW-w64 C compiler support

The automated acados installation currently supports Windows only.

## Clone and open the project

Clone the repository and open MATLAB in the repository root:

```matlab
openProject("computation-aware-sdv.prj");
```

The project paths can also be initialized manually:

```matlab
startup_project;
```

## Select the controller backend

Open:

```text
common/configuration/controller_parameters.m
```

Select one backend:

```matlab
controller.controller_backend = controller.BACKEND_ACADOS;
```

or:

```matlab
controller.controller_backend = controller.BACKEND_ADAPTIVE;
```

The backend identifiers are:

```text
BACKEND_ACADOS  = 1
BACKEND_MATLAB  = 2   (not implemented)
BACKEND_ADAPTIVE = 3
```

## Run all Phase 0 scenarios

From the repository root, run:

```matlab
run("phase0/main.m");
```

The script checks the required MATLAB products and then runs:

1. Urban profile
2. Aggressive maneuver
3. Highway cruise

If Adaptive MPC is selected, no acados installation is required.

If acados is selected and either acados or the generated S-function is
missing, MATLAB asks:

```text
Install acados and generate the S-function now? [y/N]:
```

Enter `y` to continue. The first installation may take longer than an
ordinary simulation run.

## Manual acados setup

The same setup can be performed explicitly:

```matlab
startup_project;
setup_acados_dependency;
s_fun_generation_acados;
```

The project installs the pinned acados v0.5.4 dependency outside the
repository:

```text
%LOCALAPPDATA%/SDV/dependencies/acados/v0.5.4
```

The generated solver is placed under:

```text
build/acados/sdv_dynamic_bicycle/
```

Regenerate the S-function after changing the prediction dynamics, horizon,
cost structure, constraints, solver options, or generated interface ports.
Changing only the scenario reference or road profile does not require
regeneration.

## Run one scenario

After running `startup_project`, use one of:

```matlab
run_urban_profile;
run_aggressive_maneuver;
run_highway_cruise;
```

## Generated outputs

Scenario results and figures are saved by controller backend:

```text
phase0/results/<controller>/<scenario>/
phase0/figures/<controller>/<scenario>/
```

Each run stores simulation results, tracking-error metrics, and figures.
acados runs additionally store solve-time statistics and telemetry.

## Troubleshooting

### Missing MATLAB product

Install or activate the product reported by
`check_runtime_requirements`.

### No compatible C compiler

Install the MATLAB MinGW-w64 support package, then select it:

```matlab
mex -setup C
```

### acados is missing

```matlab
setup_acados_dependency;
```

### Generated acados S-function is missing

```matlab
s_fun_generation_acados;
```

### MATLAB is using stale generated code

Close the Simulink models and unload generated MEX files before rebuilding:

```matlab
bdclose("all");
clear mex;
s_fun_generation_acados;
```

## Reproducibility note

The Phase 0 regeneration time assumes MATLAB and the required MathWorks
products are already installed. First-time acados installation and S-function
compilation are dependency-provisioning steps and are not included in the
ordinary baseline simulation time.
