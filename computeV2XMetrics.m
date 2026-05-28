function metrics = computeV2XMetrics(pktLog, txLog, simTime, params)

    TYPE_CAM  = 1;
    TYPE_DENM = 2;
    TYPE_BG   = 3;

    if isempty(pktLog)
        metrics = emptyV2XMetrics();
        return;
    end

    success = [pktLog.success] == 1;
    types = [pktLog.type];

    delays = [pktLog.delay];

    metrics.totalPackets = numel(pktLog);
    metrics.successPackets = sum(success);
    metrics.PDR_all = safeDiv(sum(success), numel(pktLog));

    metrics.PDR_CAM  = safeDiv(sum(success & types == TYPE_CAM),  sum(types == TYPE_CAM));
    metrics.PDR_DENM = safeDiv(sum(success & types == TYPE_DENM), sum(types == TYPE_DENM));
    metrics.PDR_BG   = safeDiv(sum(success & types == TYPE_BG),   sum(types == TYPE_BG));

    deadlineMet = [pktLog.deadlineMet] == 1;

    metrics.DSR_all  = safeDiv(sum(deadlineMet), numel(pktLog));
    metrics.DSR_CAM  = safeDiv(sum(deadlineMet & types == TYPE_CAM),  sum(types == TYPE_CAM));
    metrics.DSR_DENM = safeDiv(sum(deadlineMet & types == TYPE_DENM), sum(types == TYPE_DENM));
    metrics.DSR_BG   = safeDiv(sum(deadlineMet & types == TYPE_BG),   sum(types == TYPE_BG));

    metrics.delay_all_avg = mean(delays(success), 'omitnan');
    metrics.delay_CAM_avg = mean(delays(success & types == TYPE_CAM), 'omitnan');
    metrics.delay_DENM_avg = mean(delays(success & types == TYPE_DENM), 'omitnan');
    metrics.delay_BG_avg = mean(delays(success & types == TYPE_BG), 'omitnan');

    if ~isempty(txLog)
        coll = [txLog.collision] == 1;
        metrics.collisionRate = safeDiv(sum(coll), numel(txLog));
        metrics.txAttempts = numel(txLog);
    else
        metrics.collisionRate = NaN;
        metrics.txAttempts = 0;
    end

    metrics.throughput_packets_per_slot = sum(success) / simTime;
end

function out = safeDiv(num, den)
    if den == 0
        out = NaN;
    else
        out = num / den;
    end
end
