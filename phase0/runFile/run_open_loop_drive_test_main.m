%% open-loop drive sanity test.

[results, resultsFile] = run_open_loop_drive_test();
disp('Open loop drive test completed. Results saved to:');
disp(resultsFile);

f = plot_open_loop_drive_test(results);