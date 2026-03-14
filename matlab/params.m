% params.m
clear; clc;

sweep.periodicity_ms = [2 5 10 20];
sweep.comb           = [2 4];
sweep.bandwidth_RB   = [24 48 96];
sweep.nSymbols       = [1 2 4];

cfg.nRepeats   = 30;
cfg.snr_dB     = 20;
cfg.fs         = 15.36e6;
cfg.nFFT       = 2048;
cfg.cpLen      = 72;
cfg.nTaps      = 8;
cfg.maxDelay_s = 1.2e-6;
cfg.doppler_Hz = 30;

cfg.cirWindow  = 256;
cfg.topK       = 5;

disp("Loaded sweep + cfg.");