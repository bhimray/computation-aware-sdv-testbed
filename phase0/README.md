# Phase 0

Run all commands from the project root in MATLAB.

## Main file

Run the Phase 0 entry point with:

```matlab
startup_project;
run("phase0/main.m");
```

In `phase0/main.m`, uncomment the required environments and scenario calls before running. The file prepares the selected controller backend and then runs the active scenario/environment combinations.

## Individual run files

Use the scripts in `phase0/runFile` to run one test or scenario directly:

```matlab
run("phase0/runFile/run_highway_main.m");
run("phase0/runFile/run_urban_profile_main.m");
run("phase0/runFile/run_agg_man_main.m");
run("phase0/runFile/run_open_loop_drive_test_main.m");
run("phase0/runFile/run_open_loop_steep_steer_main.m");
```

For the three closed-loop scenario files, select the required road environments by commenting or uncommenting entries in `environmentNames`.

## Models

Phase 0 Simulink models are in `phase0/models`. The closed-loop model is `phase0_baseline.slx`; the other two models are used for the open-loop drive and step-steer tests.

## Results

Closed-loop results are saved under `phase0/results/ACADOS_MPC`. Open-loop test results are saved under `phase0/results/open_loop`.

## Recompiling acados

After changing the acados controller or prediction model, rebuild the generated S-function with:

```matlab
startup_project;
recompile_acados;
```

The generated solver is placed under `build/acados/sdv_dynamic_bicycle`.

### Windows path-length recommendation

Keep the project in a short directory such as `C:\SDV`. Deeply nested project paths can exceed the Windows/MinGW path limit and cause acados compilation to fail while creating `.obj.d` files.

When moving or extracting the project to a shorter path, do not reuse a partially generated `build` folder. Generate the solver again with `recompile_acados`.
