function grid = ofdmDemod(rx, nFFT, cpLen, nSym)
symLen = nFFT + cpLen;
if numel(rx) < nSym*symLen
    error("RX too short for requested nSym");
end

grid = zeros(nFFT, nSym);
for s = 1:nSym
    seg = rx((s-1)*symLen + (1:symLen));
    seg = seg(cpLen+1:end);      % drop CP
    grid(:,s) = fft(seg, nFFT);
end
end