function results = runFAWADSDiversitySweep(N, dataLength, simTime, positions, params, diversityList)
% Run FAWADS for multiple diversity orders

    if nargin < 6 || isempty(diversityList)
        diversityList = 1:min(3, params.numChannel);
    end

    results = struct();
    results.diversityList = diversityList;
    results.parTimeList   = params.parTimeList;
    results.byDiversity   = repmat(struct('D',[],'stats',[]), 1, numel(diversityList));

    baseSeed = [];
    if isfield(params,'seed') && ~isempty(params.seed)
        baseSeed = params.seed;
    end

    for dIdx = 1:numel(diversityList)
        paramsD = params;
        paramsD.numDiversity = diversityList(dIdx);

        % Reproducible runs
        if ~isempty(baseSeed)
            paramsD.seed = baseSeed + 100*dIdx;
        end

        results.byDiversity(dIdx).D = diversityList(dIdx);
        results.byDiversity(dIdx).stats = simulateFAWADSIC(N, dataLength, simTime, positions, paramsD);
    end
end