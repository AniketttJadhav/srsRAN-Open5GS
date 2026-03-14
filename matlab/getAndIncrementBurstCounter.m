function k = getAndIncrementBurstCounter()
persistent burstCounter
if isempty(burstCounter)
    burstCounter = 1;
else
    burstCounter = burstCounter + 1;
end
k = burstCounter;
end