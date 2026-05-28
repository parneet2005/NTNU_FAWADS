function statsALOHA = simulateSlottedALOHA(N, simTime, positions, params)
%SIMULATESLOTTEDALOHA  Run slotted ALOHA over mobility trace with log-distance path-loss
%   Single receiver (params.recvId), multi-channel slotted ALOHA.
%   Outputs statsALOHA(p).sendRate and statsALOHA(p).delayAve for each parTime.

    recvId       = params.recvId;
    numChannel   = params.numChannel;
    phy          = params.phy;  % Unpack PHY parameters
    slotLen = 4;
    statsALOHA = struct();
    for parTime = params.parTimeList
        % Initialize per-parTime state
        packetBirthTime  = initBirthTimes(N, parTime, recvId);
        firstBirthTime   = zeros(N,1);
        packetSendCount  = zeros(N,1);
        dataSendCount    = zeros(N,1);
        delayAccum       = zeros(N,1);
        collisionCount   = zeros(N,1);
        successCount     = 0;

        % Time-slot loop
        for t = 1:simTime
            % Determine which nodes are in-range of the receiver
            inRange = computeInRange(positions, recvId, params.rangeThreshold, t);
            inRange(recvId) = false;

            % Reset per-slot collision counters
            chanLoad = zeros(numChannel,1);
            % Pick transmitters: those whose birth time <= t
            tx = find(inRange & packetBirthTime <= t);

            % Random channel selection and preliminary count
            chSelection = zeros(N,1);
            for i = tx(:)'
                % Record first packet birth for delay
                if packetSendCount(i) == 0 && collisionCount(i) == 0
                    firstBirthTime(i) = packetBirthTime(i);
                end
                ch = randi(numChannel);
                chSelection(i) = ch;
                chanLoad(ch) = chanLoad(ch) + 1;
            end

            % Resolve transmissions
            for i = tx(:)'
                ch = chSelection(i);

                %—— Path-loss check ——
                pos_tx = squeeze(positions(t, i, :));
                pos_rx = squeeze(positions(t, recvId, :));
                d = norm(pos_tx - pos_rx);
                PLdB = computePathLossLogDistance(d, phy);
                Pr_dBm = phy.Pt_dBm - PLdB;
                if Pr_dBm < phy.RxSens_dBm
                    % Treat as collision/backoff
                    collisionCount(i) = min(collisionCount(i)+1, 5);
                    backoff = randi(2^collisionCount(i)-1) + 1;
                    packetBirthTime(i) = t + backoff;
                    continue;
                end

                if chanLoad(ch) == 1
                    % Success
                    successCount = successCount + 1;
                    packetSendCount(i) = packetSendCount(i) + 1;
                    collisionCount(i)   = 0;
                    txFinish           = t + slotLen;                   % end of this ALOHA frame
                    if packetSendCount(i) == 1  % dataLength assumed 1
                        packetSendCount(i) = 0;
                        dataSendCount(i)   = dataSendCount(i) + 1;
                        delayAccum(i)      = delayAccum(i) + (txFinish - firstBirthTime(i));
                    end
                    % Schedule next birth
                    packetBirthTime(i) = txFinish + randi(parTime);      % next arrival after finish
                else
                    % Collision
                    collisionCount(i) = min(collisionCount(i)+1, 5);
                    backoff = randi(2^collisionCount(i)-1) + 1;
                    packetBirthTime(i) = t + backoff;
                end
            end
        end

        % Compute metrics
        metrics = computeMetrics(successCount, dataSendCount, delayAccum, simTime, 1);
        statsALOHA(parTime).sendRate = metrics.sendRate;
        statsALOHA(parTime).delayAve = metrics.delayAve;
    end
end
