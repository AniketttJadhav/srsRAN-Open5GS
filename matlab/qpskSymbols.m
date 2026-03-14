function x = qpskSymbols(N)
% Unit-power QPSK
b = randi([0 1], N, 2);
x = ((2*b(:,1)-1) + 1j*(2*b(:,2)-1)) / sqrt(2);
end