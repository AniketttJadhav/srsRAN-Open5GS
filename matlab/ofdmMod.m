function tx = ofdmMod(grid, cpLen)
% grid: [nFFT x nSym] already in "FFT bin order"
[nFFT, nSym] = size(grid);
tx = complex([]);

for s = 1:nSym
    x = ifft(grid(:,s), nFFT);
    xcp = [x(end-cpLen+1:end); x];
    tx = [tx; xcp]; %#ok<AGROW>
end
end