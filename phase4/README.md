# Phase 4: lookup-map supervisor

Phase 4 builds a K-nearest-neighbor performance map from fixed-rate
scheduler simulations and uses that map to request the 50, 20, or 10 ms
controller mode.

## Run order

Run these files from the project root.

### 1. Configure the copied Phase 4 model once

```matlab
startup_project;
configure_phase4_lookup_model;
```

This connects the existing lookup predictor to the cost selector and then
connects `requestedMode` to the existing release logic. It also corrects
the lookup feature size to seven.

### 2. Collect fixed-mode simulation data

```matlab
run("phase4/run_collect_performance_data.m");
```

This runs every selected scenario and environment at fixed 50, 20 and
10 ms controller periods. Each result is saved immediately under:

```text
phase4/results/performance_map_runs/
    <scenario>/<environment>/sample_time_<period>_ms/
```

Existing completed cases are reused unless `Overwrite=true` is selected
in `run_collect_performance_data.m`.

### 3. Build the performance maps

```matlab
run("phase4/run_build_performance_maps.m");
```

Each complete run is divided into one-second future windows, starting
every 50 ms. One map is created for each scenario/environment pair:

```text
phase4/data/performance_maps/
    <scenario>/<environment>/performance_map.mat
```

The raw, readable table is saved beside it as:

```text
performance_map_table.csv
```

### 4. Run the online lookup supervisor

Edit only these values at the top of `phase4/main.m`:

```matlab
scenarioName = "urban_profile";
environmentName = "dry_road";
loadTaskDuration_s = 0.020;
```

Then run:

```matlab
run("phase4/main.m");
```

## Performance-map contents

The seven KNN inputs are:

```text
|lateral error|
|heading error|
longitudinal speed
|lateral speed|
|yaw rate|
one-second preview-curvature RMS
one-second preview-curvature maximum
```

The six predicted outcomes are:

```text
lateral RMS
heading RMS
peak lateral error
peak heading error
P95 task response time
solver-failure flag
```

CPU utilization is not predicted by KNN. Mean and P95 controller
execution times are measured from the fixed-mode runs and converted to
mode utilization using execution time divided by sampling period.

## Current explicit design choices

- Maps are separate for every scenario/environment pair, as requested.
- Prediction horizon is 1 second.
- Map rows are spaced by 50 ms to avoid storing every plant sample.
- Safety margins are zero.
- Initial cost weights are equal and are stored in
  `phase4_performance_map_parameters.m`. They are not final tuned values.
- The map-distance coverage limit is the empirical 95th percentile of
  leave-one-out nearest-neighbor distance for each mode.
- The current feature layout uses curvature RMS and maximum because that
  matches the existing Phase 4 Simulink feature block. Ordered curvature
  samples can replace these later if sequence sensitivity is required.

## Runtime task durations and CPU utilization

`run_phase4_lookup_supervisor` creates three reproducible empirical
controller execution-time streams: LOW (50 ms), MEDIUM (20 ms), and HIGH
(10 ms). The model selects the column matching `phase4_active_mode` when
each controller job is released. It no longer uses one constant P95
duration for the complete online run.

The supervisor duration is supplied separately as
`supervisorTaskDuration`. By default it uses the configured constant
duration. Pass measured samples through
`SupervisorExecutionTimeSamples_s` to create a reproducible time-varying
supervisor profile.

Observed utilization is reconstructed after simulation from SDI job
execution times:

```text
controller job execution time / corresponding active controller period
+ supervisor job execution time / supervisor period
+ constant LoadTask utilization
+ constant CommTask utilization
```

The saved `runArtifact.controlJobs` and `runArtifact.supervisorJobs`
tables contain the underlying per-job execution times and utilization.
