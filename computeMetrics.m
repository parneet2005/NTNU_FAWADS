%% Helper: Compute send rate and average delay
function metrics = computeMetrics(successCount, dataSendCount, delayAccum, simTime, dataLength)
    sendCount = successCount / dataLength;
    metrics.sendRate = sendCount / simTime;
    totalPackets    = sum(dataSendCount);
    if totalPackets > 0
        metrics.delayAve = sum(delayAccum) / totalPackets;
    else
        metrics.delayAve = NaN;
    end
end
