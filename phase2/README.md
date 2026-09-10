# Phase 2

Run all commands from the project root in MATLAB.

## Main files

Run the Phase 2.3 scheduler experiment with:

```matlab
startup_project;
run("phase2/main.m");
```

Before running, edit `scenarioNames`, `environmentNames`, and `loadCases` to select the required cases. The script runs every active combination and saves each run independently.

Run the Phase 2.4 processor-utilization sweep with:

```matlab
run("phase2/main_phase2_4.m");
```

Edit its scenario, environment, load-duration, random-seed, and resume options before starting a long sweep. Phase 2 currently has no separate `runFile` folder; its reusable runners are in `phase2/scripts`.

## Models

Phase 2 models are in `phase2/models`. The main scheduler testbed is `phase2_scheduler_testbed.slx`; the other models support the scheduler application and SoC tool-spike experiments.

## Results

Phase 2.3 results are saved under `phase2/results/phase2_3`. Phase 2.4 summaries and checkpoints are saved under `phase2/results/phase2_4`. Offline plotting functions are under `phase2/plots`.

## Compiling

Phase 2 uses the common fixed-rate acados solver. If it is missing or the controller model changed, run:

```matlab
startup_project;
recompile_acados;
```

On Windows, keep the project in a short path such as `C:\SDV` and regenerate the `build` folder after moving the project.
