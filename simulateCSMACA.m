function statsCSMA = simulateCSMACA(N, simTime, positions, params)
%SIMULATECSMACA  Run slotted CSMA/CA with a single receiver over mobility trace
%   Each node except params.recvId transmits to the receiver.
%   Outputs statsCSMA(p).sendRate and statsCSMA(p).delayAve for each parTime.

    % ACK duration in slots (could also use params.ackSlots)
    phy       = params.phy;
    ackSlots = 1;
    recvId   = params.recvId;
    dataSlots = 3;          % e.g., payload duration in slots
    statsCSMA = struct();
    
    for parTime = params.parTimeList
        % Initialize per‐parTime state
        packetBirthTime = initBirthTimes(N, parTime, recvId);
        packetSendTime  = packetBirthTime;
        collisionCount  = zeros(N,1);
        dataSendCount   = zeros(N,1);
        delayAccum      = zeros(N,1);
        successCount    = 0;
        
        % Channel state
        channelBusy    = false(params.numChannel,1);
        channelRelease = zeros(params.numChannel,1);

        % Main time‐slot loop
        for t = 1:simTime
            % Release finished ACKs
            done = channelRelease <= t;
            channelBusy(done) = false;

            % Determine in‐range transmitters
            inRange = computeInRange(positions, recvId, params.rangeThreshold, t);
            inRange(recvId) = false;  % ensure receiver is never a transmitter

            % Transmission attempts
            for i = 1:N
                if i == recvId || ~inRange(i) || packetSendTime(i) > t
                    continue;
                end

                                %% —— INSERT PATH‑LOSS CHECK HERE ——
                % 1) distance
                pos_tx = squeeze(positions(t, i, :));
                pos_rx = squeeze(positions(t, recvId, :));
                d      = norm(pos_tx - pos_rx);

                % 2) path‑loss dB
                PLdB   = computePathLossLogDistance(d, phy);

                % 3) received power dBm
                Pr_dBm = phy.Pt_dBm - PLdB;

                % 4) if too weak, treat as failure & schedule backoff
                if Pr_dBm < phy.RxSens_dBm
                    collisionCount(i) = min(collisionCount(i)+1, 10);
                    CWmin = 8; CWmax = 512;
                    cw = min(CWmin * 2^collisionCount(i), CWmax);
                    packetSendTime(i) = t + randi(cw);
                    continue;
                end
                
                % Sense a random channel
                ch = randi(params.numChannel);
                if ~channelBusy(ch)
                    % --- Success ---
                    txFinish           = t + dataSlots + ackSlots;   % DATA + ACK
                    successCount = successCount + 1;
                    dataSendCount(i) = dataSendCount(i) + 1;
                    delayAccum(i) = delayAccum(i) + (txFinish - packetBirthTime(i));
                    % Occupy channel for ACK
                    channelBusy(ch)    = true;
                    channelRelease(ch) = txFinish;
                    % Schedule next birth
                    packetBirthTime(i) = txFinish + randi(parTime);
                    packetSendTime(i)  = packetBirthTime(i);
                    collisionCount(i)  = 0;
                else
                    % --- Collision/Backoff ---
                    collisionCount(i) = min(collisionCount(i)+1, 5);
                    backoff = randi(2^collisionCount(i)) + 1;
                    packetSendTime(i) = t + backoff;
                end
                % Try to find an IDLE channel (CSMA), otherwise back off
                perm = randperm(params.numChannel);
                ch = 0;
                for k = perm
                    if ~channelBusy(k)
                        ch = k; break;
                    end
                end
                if ch == 0
                    collisionCount(i) = min(collisionCount(i)+1, 10);
                    CWmin = 8; CWmax = 512;
                    cw = min(CWmin * 2^collisionCount(i), CWmax);
                    packetSendTime(i) = t + randi(cw);
                    continue;
                end
            end
        end
        
        % Compute & store metrics
        metrics = computeMetrics(successCount, dataSendCount, delayAccum, simTime, 1);
        statsCSMA(parTime).sendRate = metrics.sendRate;
        statsCSMA(parTime).delayAve = metrics.delayAve;
    end
end