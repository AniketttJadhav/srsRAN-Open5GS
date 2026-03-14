function [h, tau_s] = randomMultipath(nTaps, maxDelay_s, fs)
% Random delays within maxDelay_s, exponential PDP
tau_s = sort(rand(nTaps,1) * maxDelay_s);
tapSamp = max(1, round(tau_s*fs) + 1);

pdp = exp(-tau_s / (maxDelay_s/3));
pdp = pdp / sum(pdp);

taps = (randn(nTaps,1) + 1j*randn(nTaps,1)) .* sqrt(pdp/2);

L = tapSamp(end);
h = complex(zeros(L,1));
for k = 1:nTaps
    h(tapSamp(k)) = h(tapSamp(k)) + taps(k);
end
end