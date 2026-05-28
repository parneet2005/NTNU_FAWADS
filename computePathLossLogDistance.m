function [PLdB] = computePathLossLogDistance(d, phyParams)
% computePathLossLogDistance  Log‑distance + shadowing path‑loss
%   d         : Tx–Rx distance in meters
%   phyParams : struct with fields {d0, PL0, n, sigma}

    % avoid log10(0)
    if d < phyParams.d0
        d = phyParams.d0;
    end

    PLdB = phyParams.PL0 ...
         + 10*phyParams.n * log10(d/phyParams.d0) ...
         + phyParams.sigma * randn();
end
