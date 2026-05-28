function PL_dB = pathLoss(d, d0, PL0_dB, n)
% Log-distance path loss
%   d    = Tx–Rx distance (m)
%   d0   = reference distance (m)
%   PL0_dB = path loss at d0 (dB)
%   n    = path-loss exponent
    PL_dB = PL0_dB + 10*n*log10(d./d0);
end