clear; clc; close all;

%% Load data
D = load('sensing_data.mat');

time_sec      = double(D.time_sec(:));
snr_db        = double(D.snr_db(:));
jammer_power  = double(D.jammer_power(:));
jammer_on     = double(D.jammer_on(:));

%% Basic sanity check
fprintf('Total samples: %d\n', length(time_sec));
fprintf('Jammer OFF samples: %d\n', sum(jammer_on == 0));
fprintf('Jammer ON samples : %d\n', sum(jammer_on == 1));

%% ---------------- Plot 1: SNR vs Time ----------------
figure;
plot(time_sec, snr_db, 'LineWidth', 1.2);
grid on;
xlabel('Time (s)');
ylabel('SNR (dB)');
title('SNR vs Time');

%% ---------------- Plot 2: Jammer Power vs Time ----------------
figure;
plot(time_sec, jammer_power, 'LineWidth', 1.2);
grid on;
xlabel('Time (s)');
ylabel('Jammer Power');
title('Jammer Power vs Time');

%% ---------------- Plot 3: Jammer ON/OFF over Time ----------------
figure;
stairs(time_sec, jammer_on, 'LineWidth', 1.2);
grid on;
xlabel('Time (s)');
ylabel('Jammer On');
title('Ground Truth Jammer State vs Time');
ylim([-0.1 1.1]);

%% ---------------- Plot 4: SNR colored by jammer state ----------------
figure;
hold on;
plot(time_sec(jammer_on==0), snr_db(jammer_on==0), '.', 'MarkerSize', 8);
plot(time_sec(jammer_on==1), snr_db(jammer_on==1), '.', 'MarkerSize', 8);
grid on;
xlabel('Time (s)');
ylabel('SNR (dB)');
title('SNR vs Time, Split by Jammer State');
legend('Jammer OFF','Jammer ON','Location','best');

%% ---------------- Plot 5: Jammer power colored by jammer state ----------------
figure;
hold on;
plot(time_sec(jammer_on==0), jammer_power(jammer_on==0), '.', 'MarkerSize', 8);
plot(time_sec(jammer_on==1), jammer_power(jammer_on==1), '.', 'MarkerSize', 8);
grid on;
xlabel('Time (s)');
ylabel('Jammer Power');
title('Jammer Power vs Time, Split by Jammer State');
legend('Jammer OFF','Jammer ON','Location','best');

%% ---------------- Plot 6: Boxplots ----------------
figure;
boxplot(snr_db, jammer_on, 'Labels', {'OFF','ON'});
grid on;
ylabel('SNR (dB)');
title('SNR Distribution for Jammer OFF vs ON');

figure;
boxplot(jammer_power, jammer_on, 'Labels', {'OFF','ON'});
grid on;
ylabel('Jammer Power');
title('Jammer Power Distribution for Jammer OFF vs ON');

%% ---------------- Summary Statistics ----------------
snr_off = snr_db(jammer_on==0);
snr_on  = snr_db(jammer_on==1);

jp_off = jammer_power(jammer_on==0);
jp_on  = jammer_power(jammer_on==1);

fprintf('\n===== SUMMARY =====\n');
fprintf('SNR when jammer OFF: mean = %.3f dB, std = %.3f dB\n', mean(snr_off), std(snr_off));
fprintf('SNR when jammer ON : mean = %.3f dB, std = %.3f dB\n', mean(snr_on), std(snr_on));

fprintf('Jammer power when OFF: mean = %.3f, std = %.3f\n', mean(jp_off), std(jp_off));
fprintf('Jammer power when ON : mean = %.3f, std = %.3f\n', mean(jp_on), std(jp_on));

%% ---------------- Simple Threshold Classifier 1: Using SNR ----------------
% Learn threshold halfway between class means
thr_snr = (mean(snr_off) + mean(snr_on)) / 2;

% Predict jammer ON when SNR is below threshold
pred_snr = snr_db < thr_snr;

acc_snr = mean(pred_snr == jammer_on);

TP = sum((pred_snr == 1) & (jammer_on == 1));
TN = sum((pred_snr == 0) & (jammer_on == 0));
FP = sum((pred_snr == 1) & (jammer_on == 0));
FN = sum((pred_snr == 0) & (jammer_on == 1));

fprintf('\n===== SNR Threshold Classifier =====\n');
fprintf('Threshold = %.3f dB\n', thr_snr);
fprintf('Accuracy  = %.4f\n', acc_snr);
fprintf('TP = %d, TN = %d, FP = %d, FN = %d\n', TP, TN, FP, FN);

figure;
histogram(snr_off, 40, 'Normalization', 'pdf'); hold on;
histogram(snr_on, 40, 'Normalization', 'pdf');
xline(thr_snr, 'r', 'LineWidth', 2);
grid on;
xlabel('SNR (dB)');
ylabel('PDF');
title('SNR-Based Jammer Detection');
legend('Jammer OFF','Jammer ON','Threshold','Location','best');

%% ---------------- Simple Threshold Classifier 2: Using Jammer Power ----------------
thr_jp = (mean(jp_off) + mean(jp_on)) / 2;

% Predict jammer ON when jammer power exceeds threshold
pred_jp = jammer_power > thr_jp;

acc_jp = mean(pred_jp == jammer_on);

TP2 = sum((pred_jp == 1) & (jammer_on == 1));
TN2 = sum((pred_jp == 0) & (jammer_on == 0));
FP2 = sum((pred_jp == 1) & (jammer_on == 0));
FN2 = sum((pred_jp == 0) & (jammer_on == 1));

fprintf('\n===== Jammer Power Threshold Classifier =====\n');
fprintf('Threshold = %.3f\n', thr_jp);
fprintf('Accuracy  = %.4f\n', acc_jp);
fprintf('TP = %d, TN = %d, FP = %d, FN = %d\n', TP2, TN2, FP2, FN2);

figure;
histogram(jp_off, 40, 'Normalization', 'pdf'); hold on;
histogram(jp_on, 40, 'Normalization', 'pdf');
xline(thr_jp, 'r', 'LineWidth', 2);
grid on;
xlabel('Jammer Power');
ylabel('PDF');
title('Jammer-Power-Based Detection');
legend('Jammer OFF','Jammer ON','Threshold','Location','best');

%% ---------------- Optional Combined Rule ----------------
% Very simple combined detector:
% predict jammer ON if SNR is low OR jammer power is high
pred_combined = (snr_db < thr_snr) | (jammer_power > thr_jp);
acc_combined = mean(pred_combined == jammer_on);

TP3 = sum((pred_combined == 1) & (jammer_on == 1));
TN3 = sum((pred_combined == 0) & (jammer_on == 0));
FP3 = sum((pred_combined == 1) & (jammer_on == 0));
FN3 = sum((pred_combined == 0) & (jammer_on == 1));

fprintf('\n===== Combined Detector =====\n');
fprintf('Accuracy = %.4f\n', acc_combined);
fprintf('TP = %d, TN = %d, FP = %d, FN = %d\n', TP3, TN3, FP3, FN3);