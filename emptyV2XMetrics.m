function metrics = emptyV2XMetrics()

    metrics = struct();
    metrics.totalPackets = 0;
    metrics.successPackets = 0;
    metrics.PDR_all = NaN;
    metrics.PDR_CAM = NaN;
    metrics.PDR_DENM = NaN;
    metrics.PDR_BG = NaN;
    metrics.DSR_all = NaN;
    metrics.DSR_CAM = NaN;
    metrics.DSR_DENM = NaN;
    metrics.DSR_BG = NaN;
    metrics.delay_all_avg = NaN;
    metrics.delay_CAM_avg = NaN;
    metrics.delay_DENM_avg = NaN;
    metrics.delay_BG_avg = NaN;
    metrics.collisionRate = NaN;
    metrics.txAttempts = 0;
    metrics.throughput_packets_per_slot = 0;
end

function y = safeDiv(a,b)

    if b == 0
        y = NaN;
    else
        y = a / b;
    end
end