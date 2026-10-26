# Phase 3

Run all commands from the project root in MATLAB.

## Main files

Run the standard Phase 3 scheduler experiment with:

```matlab
startup_project;
run("phase3/main.m");
```

Run the experiment using aligned demand tags with:

```matlab
run("phase3/main_aligned_tag.m");
```

Before running either file, edit the active entries in `scenarioNames`, `environmentNames`, and `loadCases`. Commented selections are intentional and allow cases to be run individually.

Phase 3 currently has no separate `runFile` folder. Tag-generation and offline plotting entry points are available under `phase3/scripts`.

## Models

Phase 3 models are in `phase3/models`. `phase3_scheduler_testbed.slx` is the main scheduler-in-the-loop model. The 20 ms and 50 ms models provide the additional controller rates used by the supervisor.

## Results

Scheduler results are saved under `phase3/results/scheduler_runs` or `phase3/results/aligned_scheduler_runs`. Demand tags are stored under `phase3/results/demand_tags` and `phase3/results/aligned_demand_tags`. Offline plotting functions are under `phase3/plot`.

## Compiling

Phase 3 requires generated acados solvers for the supported 10 ms, 20 ms, and 50 ms controller periods. Rebuild all of them with:

```matlab
startup_project;
recompile_all_acados;
```

On Windows, keep the project in a short path such as `C:\SDV` and do not reuse a generated `build` folder after moving the project.
