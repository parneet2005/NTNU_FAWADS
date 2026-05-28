% Example diversity sweep
% Assumes you already prepared:
%   N, dataLength, simTime, positions, params

Dlist = 1:min(5, params.numChannel);

results = runFAWADSDiversityAnalysis( ...
    N, dataLength, simTime, positions, params, Dlist);