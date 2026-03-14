function out = simulateOneShot_REAL(p, cfg)
% simulateOneShot_REAL
% Inputs:
%   p: one row from grid table (periodicity_ms, comb, bandwidth_RB, nSymbols)
%   cfg: config struct from params.m (SNR, FFT, CP, fs, doppler, etc.)
% Output:
%   out.nmse     : channel estimation NMSE (lower better)
%   out.features : sensing features vector (you sweep stability on these)

% ---------- 1) Build an "SRS-like" pilot grid ----------
% Bandwidth proxy: RB -> subcarriers (12 per RB)
nSC = p.bandwidth_RB * 12;

% Guard: must fit inside FFT
if nSC > cfg.nFFT
    error("bandwidth_RB too large: nSC (%d) > nFFT (%d)", nSC, cfg.nFFT);
end

% Active subcarriers centered in the FFT bins (DC-centered mapping)
actIdx = centeredActiveSubcarriers(cfg.nFFT, nSC);

% Comb: pilots every 'comb' subcarriers
pilotBins = actIdx(1:p.comb:end);

% Pilot grid: [nFFT x nSymbols] (only pilots, no data)
txGrid = zeros(cfg.nFFT, p.nSymbols);
pilotSym = qpskSymbols(numel(pilotBins) * p.nSymbols);
txGrid(pilotBins, :) = reshape(pilotSym, numel(pilotBins), p.nSymbols);

% ---------- 2) OFDM Modulate ----------
tx = ofdmMod(txGrid, cfg.cpLen);

% ---------- 3) Time-evolving multipath channel ----------
% We simulate one "burst" at a time; periodicity_ms changes how much the channel phase evolves.
% Here we apply Doppler as a bulk phase rotation over time (simple but makes periodicity matter).
dt = (p.periodicity_ms * 1e-3);           % time between SRS bursts in seconds
phi = 2*pi*cfg.doppler_Hz * dt;           % phase advance per burst

% Keep channel taps stable across bursts but rotate them by phi each call
% so longer periodicity => more phase evolution => harder tracking => worse stability.
[h0, tapDelays_s] = randomMultipath(cfg.nTaps, cfg.maxDelay_s, cfg.fs);

% Use a persistent burst counter so repeated calls represent different "times"
% Reset it when user calls resetStage1() (helper below).
burstIdx = getAndIncrementBurstCounter();
h = h0 .* exp(1j * (burstIdx-1) * phi);   % rotate taps with time

% Pass signal through channel
rx = filter(h, 1, tx);

% Add AWGN
rx = awgn(rx, cfg.snr_dB, 'measured');

% ---------- 4) OFDM Demodulate ----------
rxGrid = ofdmDemod(rx, cfg.nFFT, cfg.cpLen, p.nSymbols);

% ---------- 5) True channel (freq domain) for NMSE ----------
Htrue = fft([h; zeros(cfg.nFFT - numel(h), 1)], cfg.nFFT);

% ---------- 6) Channel estimation on pilots (LS + interpolation) ----------
Hhat = zeros(cfg.nFFT, p.nSymbols);

for s = 1:p.nSymbols
    yPil = rxGrid(pilotBins, s);
    xPil = txGrid(pilotBins, s);
    Hpil = yPil ./ max(xPil, 1e-12);

    % Interpolate pilots across active subcarriers
    Hact = interp1(pilotBins, Hpil, actIdx, 'linear', 'extrap');

    Hhat(:,s) = 0;
    Hhat(actIdx,s) = Hact;
end

% Average across symbols for sensing
Havg = mean(Hhat, 2);

% ---------- 7) NMSE (only on active subcarriers) ----------
err = Havg(actIdx) - Htrue(actIdx);
nmse = sum(abs(err).^2) / max(sum(abs(Htrue(actIdx)).^2), 1e-12);

% ---------- 8) Sensing features (from estimated CIR) ----------
% CIR = IFFT of estimated channel
cir = ifft(Havg, cfg.nFFT);
cir = cir(1:cfg.cirWindow);
mag = abs(cir);
pow = mag.^2 + 1e-12;

% Feature A: Peak-to-sidelobe ratio (bigger better)
[pMax, kMax] = max(mag);
guard = 3;
mask = true(size(mag));
mask(max(1,kMax-guard):min(numel(mag),kMax+guard)) = false;
side = max(mag(mask));
p2s = pMax / max(side, 1e-12);

% Feature B: RMS delay spread (seconds) from power-weighted taps
n = (0:numel(pow)-1).';
powSum = sum(pow);
meanDelay = sum(n.*pow) / powSum;
rmsDelay = sqrt(sum(((n-meanDelay).^2).*pow)/powSum) / cfg.fs;

% Feature C: Peak delay (seconds)
peakDelay = (kMax-1) / cfg.fs;

% Feature D: "Concentration" of energy: top-K energy fraction (bigger better)
K = min(cfg.topK, numel(pow));
sortedPow = sort(pow, 'descend');
topKFrac = sum(sortedPow(1:K)) / powSum;

% Feature E: RSSI proxy
rssi = 10*log10(mean(abs(rx).^2) + 1e-12);

features = [p2s, rmsDelay, peakDelay, topKFrac, rssi];

out.nmse = nmse;
out.features = features;

% optional debug outputs (keep if you want)
out.Htrue = Htrue;
out.Hhat  = Havg;
out.cir   = cir;
out.tapDelays_s = tapDelays_s;
end