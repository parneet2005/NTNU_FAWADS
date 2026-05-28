function [ueObj, genStats] = generatePacketsForUE_PoissonDENMBG(ueObj, t, params, ueID)
% generatePacketsForUE_PoissonDENMBG
%
% Traffic generator using:
%   DENM : Poisson arrival
%   CAM  : Bernoulli arrival, same as original
%   BG   : Poisson arrival
%
% lambda_DENM, lambda_CAM, lambda_BG are per-node per-slot arrival rates.
%
% Poisson means each UE can generate 0, 1, 2, ... packets per slot.

genStats.DENM = 0;
genStats.CAM  = 0;
genStats.BG   = 0;

%% ==========================
%  DENM: Poisson arrival
%  ==========================

numDENM = poissrnd(params.qos.lambda_DENM);

for k = 1:numDENM
    pkt = createPacket("DENM", t, params, ueID);
    ueObj.Q_DENM = appendPacket(ueObj.Q_DENM, pkt);
end

genStats.DENM = numDENM;


%% ==========================
%  CAM: keep original Bernoulli
%  ==========================
% CAM is often periodic/semi-periodic, so for now we keep your original
% Bernoulli CAM model.

if rand < params.qos.lambda_CAM
    pkt = createPacket("CAM", t, params, ueID);
    ueObj.Q_CAM = appendPacket(ueObj.Q_CAM, pkt);
    genStats.CAM = 1;
end


%% ==========================
%  BG: Poisson arrival
%  ==========================

numBG = poissrnd(params.qos.lambda_BG);

for k = 1:numBG
    pkt = createPacket("BG", t, params, ueID);
    ueObj.Q_BG = appendPacket(ueObj.Q_BG, pkt);
end

genStats.BG = numBG;

end