function [CWmin_i, D_i] = getTrafficAwareFAWADSParams(packetType, params)

    TYPE_CAM  = 1;
    TYPE_DENM = 2;
    TYPE_BG   = 3;

    if isfield(params,'v2x') && isstruct(params.v2x)
        traffic = params.v2x;
    elseif isfield(params,'traffic') && isstruct(params.traffic)
        traffic = params.traffic;
    else
        traffic = struct();
    end

    switch packetType

        case TYPE_DENM
            CWmin_i = traffic.DENM.CWmin;
            D_i = traffic.DENM.diversity;

        case TYPE_CAM
            CWmin_i = traffic.CAM.CWmin;
            D_i = traffic.CAM.diversity;

        case TYPE_BG
            CWmin_i = traffic.BG.CWmin;
            D_i = traffic.BG.diversity;

        otherwise
            CWmin_i = params.fa.CWmin;
            D_i = params.numDiversity;
    end

    CWmin_i = max(1, CWmin_i);
    D_i = max(1, D_i);
end
