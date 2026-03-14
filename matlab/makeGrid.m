% 02_makeGrid.m
run("params.m");

[T, C, B, S] = ndgrid(sweep.periodicity_ms, sweep.comb, sweep.bandwidth_RB, sweep.nSymbols);

grid = table(T(:), C(:), B(:), S(:), ...
    'VariableNames', {'periodicity_ms','comb','bandwidth_RB','nSymbols'});

disp("Grid preview:");
disp(grid(1:min(10,height(grid)), :));
fprintf("Total parameter points = %d\n", height(grid));