function [snr_dB, ber] = phyLayer(posTx, posRx, params)
%PHY LAYER ABSTRACTION
%  posTx, posRx: 1×2 [x y] positions [m]
%  params: struct with fields
%     .fc, .txPower, .noiseFloor,
%     .shadowStd, .enableShadowing, .enableFading,
%     .snrGrid, .berGrid

    % 1) Distance
    d = norm(posTx - posRx);

    % 2) Free-space path loss
    PL_dB = fspl(d, params.fc);

    % 3) Shadowing
    if params.enableShadowing
        PL_dB = PL_dB + randn*params.shadowStd;
    end

    % 4) Received power before fading
    rxP_dB = params.txPower - PL_dB;

    % 5) Small-scale fading
    if params.enableFading
        h = raylrnd(1);                % Rayleigh amplitude
        rxP_dB = rxP_dB + 20*log10(h);
    end

    % 6) SNR
    snr_dB = rxP_dB - params.noiseFloor;

    % 7) BER lookup (BPSK AWGN baseline)
    ber = interp1(params.snrGrid, params.berGrid, snr_dB, ...
                  "linear", "extrap");
end
