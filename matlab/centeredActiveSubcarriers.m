function actIdx = centeredActiveSubcarriers(nFFT, nSC)
% Returns indices of nSC active bins centered in [1..nFFT]
startIdx = floor(nFFT/2) - floor(nSC/2) + 1;
actIdx = startIdx:(startIdx+nSC-1);
end