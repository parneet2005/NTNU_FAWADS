function [Pr_dBm] = computeRxPower(PLdB, phyParams)
% computeRxPower  Received power (dBm) = Pt_dBm – PL (dB)
    Pr_dBm = phyParams.Pt_dBm - PLdB;
end
