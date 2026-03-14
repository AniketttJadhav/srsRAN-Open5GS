% plotAndSave.m
run("runSweep.m");

figure;
scatter(results.nmseMean, results.featureStabilityCV, 40, 'filled');
xlabel("NMSE (lower is better)");
ylabel("Feature Stability CV (lower is better)");
title("Accuracy vs Feature Stability across SRS settings");
grid on;

writetable(results, "srs_param_sweep_results.csv");
save("srs_param_sweep_results.mat", "results");  

disp("Saved: srs_param_sweep_results.csv and .mat");