function scenarios = generate_all_scenario()
%GENERATE_ALL_SCENARIO Generate and validate all Phase 0 scenario files.

startup_project;
scenarios = generate_phase0_scenarios();

scenarioNames = fieldnames(scenarios);
for index = 1:numel(scenarioNames)
    scenario = scenarios.(scenarioNames{index});
    fprintf( ...
        "Generated %-22s %7.2f m, %7.2f s, %5d points\n", ...
        scenario.name,scenario.total_length_m, ...
        scenario.traversal_time_s,numel(scenario.station_m));
end
end
