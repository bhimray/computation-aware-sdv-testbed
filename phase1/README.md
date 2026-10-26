# Phase 1

Run all commands from the project root in MATLAB.

## Main file

Run the Phase 1 entry point with:

```matlab
startup_project;
run("phase1/main.m");
```

In `phase1/main.m`, set `scenarioName` and `environmentName`, then uncomment only the required experiment: constant delay, random delay, or sampling jitter. The commented single-case and batch calls are intentional experiment selections.

For the dedicated random-delay Monte Carlo setup, run:

```matlab
run("phase1/main_random_delay.m");
```

## Run files

The scripts in `phase1/runFile` are focused analysis or diagnostic runs:

- `run_random_delay_agg_tracking_error_sweep.m`: aggressive-maneuver random-delay runs.
- `run_agg_failed_jitter.m` and `run_highway_failed_jitter.m`: reproduce selected failed-jitter cases.
- Files beginning with `run_plot_` and `compare_`: offline plotting and comparison only.

Run one from the project root, for example:

```matlab
run("phase1/runFile/run_highway_failed_jitter.m");
```

## Models

Phase 1 models are in `phase1/models`. `phase1_baseline.slx` is used for delay experiments and `phase1_baseline_sampling_jitter.slx` is used for sampling-jitter experiments.

## Results

Phase 1 simulation artifacts and sweep summaries are saved under `phase1/results/ACADOS_MPC`. Plotting functions are under `phase1/plots` and `phase1/analysis`.

## Recompiling acados

The fixed-rate Phase 1 controller uses the common generated solver. Rebuild it after changing the prediction model or acados configuration:

```matlab
startup_project;
recompile_acados;
```

On Windows, keep the project in a short path such as `C:\SDV` and do not reuse a generated `build` folder after moving the project.
