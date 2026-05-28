function [nodeQueue, pktLog, pktLogCount] = dropExpiredQueuedPackets(nodeQueue, pktLog, pktLogCount, t)
% dropExpiredQueuedPackets
% Drops packets that are still waiting in a node queue after their deadline.
% This file must be a function, not a script.

    N = numel(nodeQueue);

    for i = 1:N

        if isempty(nodeQueue{i})
            continue;
        end

        keepIdx = true(1, numel(nodeQueue{i}));

        for q = 1:numel(nodeQueue{i})

            pkt = nodeQueue{i}(q);

            if t > pkt.deadlineTime

                pktLogCount = pktLogCount + 1;
                pktLog(pktLogCount).packetId = pkt.id;
                pktLog(pktLogCount).nodeId = i;
                pktLog(pktLogCount).type = pkt.type;
                pktLog(pktLogCount).genTime = pkt.genTime;
                pktLog(pktLogCount).deadlineTime = pkt.deadlineTime;
                pktLog(pktLogCount).success = 0;
                pktLog(pktLogCount).successTime = NaN;
                pktLog(pktLogCount).delay = NaN;
                pktLog(pktLogCount).deadlineMet = 0;
                pktLog(pktLogCount).attempts = 0;
                pktLog(pktLogCount).failureReason = "deadline_expired_queued";

                keepIdx(q) = false;
            end
        end

        nodeQueue{i} = nodeQueue{i}(keepIdx);
    end
end
