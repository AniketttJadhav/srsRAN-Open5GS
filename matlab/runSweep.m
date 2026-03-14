% runSweep.m
run("makeGrid.m");   

nPoints = height(grid);

% Preallocate
periodicity_ms = zeros(nPoints,1);
comb           = zeros(nPoints,1);
bandwidth_RB   = zeros(nPoints,1);
nSymbols       = zeros(nPoints,1);

nmseMean = zeros(nPoints,1);
nmseStd  = zeros(nPoints,1);
featureStabilityCV = zeros(nPoints,1);

for i = 1:nPoints
    p = grid(i,:);

    resetStage1();   

    nmseVec = nan(cfg.nRepeats,1);
    featMat = [];  % [nRepeats x nFeat]

    for r = 1:cfg.nRepeats
        out = simulateOneShot_REAL(p, cfg);  
        nmseVec(r) = out.nmse;
        featMat(r,:) = out.features(:).'; %#ok<AGROW>
    end

    % Metrics
    nmseMean(i) = mean(nmseVec, "omitnan");
    nmseStd(i)  = std(nmseVec,  "omitnan");

    featMean = mean(featMat, 1, "omitnan");
    featStd  = std(featMat,  0, 1, "omitnan");
    featCV   = featStd ./ max(abs(featMean), 1e-12);
    featureStabilityCV(i) = mean(featCV, "omitnan");

    % Params
    periodicity_ms(i) = p.periodicity_ms;
    comb(i)           = p.comb;
    bandwidth_RB(i)   = p.bandwidth_RB;
    nSymbols(i)       = p.nSymbols;

    fprintf("(%3d/%3d) T=%2d comb=%d RB=%3d sym=%d | NMSE=%.5f | stabCV=%.5f\n", ...
        i, nPoints, periodicity_ms(i), comb(i), bandwidth_RB(i), nSymbols(i), ...
        nmseMean(i), featureStabilityCV(i));
end

% Build table ONCE
results = table(periodicity_ms, comb, bandwidth_RB, nSymbols, nmseMean, nmseStd, featureStabilityCV);

disp("Done. First 10 rows:");
disp(results(1:min(10,height(results)), :));