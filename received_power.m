function P_rx_dB = rxPower(P_tx_dB, PL_dB, h)
% Received power in dB
    P_rx_dB = P_tx_dB - PL_dB + 20*log10(abs(h));
end