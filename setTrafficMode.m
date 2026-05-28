function params = setTrafficMode(params, mode)

% First disable all traffic
params.v2x.CAM.enable  = false;
params.v2x.DENM.enable = false;
params.v2x.BG.enable   = false;

switch mode

    case "CAM_ONLY"
        params.v2x.CAM.enable = true;

    case "DENM_ONLY"
        params.v2x.DENM.enable = true;

    case "BG_ONLY"
        params.v2x.BG.enable = true;

    case "CAM_DENM"
        params.v2x.CAM.enable  = true;
        params.v2x.DENM.enable = true;

    case "CAM_DENM_BG"
        params.v2x.CAM.enable  = true;
        params.v2x.DENM.enable = true;
        params.v2x.BG.enable   = true;

    otherwise
        error("Unknown traffic mode");
end

end