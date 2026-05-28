function statsFAWADS = simulateFAWAD(N, dataLength, simTime, positions, params)
%IMPLEMENTFAWADFUNCT  Run FAWADS protocol and return raw results (no plotting)

    recvId   = params.recvId;
    % Fixed protocol parameters
    numDiversity   = 3;
    % ---- constants / helpers ----
    % Optionally make results deterministic (if you expose params.seed)
    if isfield(params,'seed') && ~isempty(params.seed)
        rng(params.seed,'twister');
    end
    % Initialize outputs
    statsFAWADS    = struct();

    % Loop over packet‐generation intervals
    for parTime = params.parTimeList
        % Determine contention window sweep based on N
        minDelay = inf;
        maxSend  = 0;

        if N < 50
            window = 1:N-1;
        elseif N < 100
            window = 2:2:N-2;
        else
            window = 5:5:N-5;
        end

        % Preallocate per‐window metrics
        sendRate = zeros(size(window));
        delayAve = zeros(size(window));

        % Loop over window sizes
        for idx = 1:length(window)
            W = window(idx);

            % Initialize per‐window state
            firstBirthTime  = zeros(N,1);
            packetBirthTime = initBirthTimes(N, parTime, params.recvId);
            packetSendTime  = zeros(N,numDiversity);
            packetHold      = zeros(N,numDiversity);
            collisionCount  = zeros(N,1);
            packetSendCount = zeros(N,1);
            dataSendCount   = zeros(N,1);
            delayAccum      = zeros(N,1);
            successCount    = 0;
            channelSelection = zeros(N, numDiversity);   % NEW: avoid size growth each slot

            % Time‐slot loop
            for t = 1:simTime
                % Determine which nodes are in‐range
                inRange = computeInRange(positions, params.recvId, params.rangeThreshold, t);
                inRange(params.recvId) = false;             % NEW: receiver never transmits
                % Schedule new transmissions
                for i = 1:N
                    if ~inRange(i) || packetBirthTime(i) > t || any(packetHold(i,:)) || any(packetSendTime(i,:) >= t)
                        continue;
                    end
                    % Record first birth time
                    if packetSendCount(i) == 0
                        firstBirthTime(i) = packetBirthTime(i);
                    end
                    
                    % Random multi‐channel, multi‐branch scheduling
                    k = min(numDiversity, params.numChannel);
                    channels = randperm(params.numChannel, k); 
                    
                    % initialize all branches as inactive first
                    packetSendTime(i,:)  = 0;
                    packetHold(i,:)      = 0;
                    channelSelection(i,:)= 0;
                    
                    
                    for j = 1:k
                        tempDelay = randi(numDiversity*10);
                        if mod(i - mod(t + tempDelay, N), N) <= W
                            packetSendTime(i,j) = t + mod(i - mod(t + tempDelay, N), N);
                            packetHold(i,j)     = 1;
                        else
                            packetSendTime(i,j) = t + tempDelay;
                        end
                        channelSelection(i,j) = channels(j);
                    end
                end

                % Count transmissions for collision detection
                chanCount = zeros(params.numChannel, 1);
                for i = setdiff(1:N, params.recvId)
                    for j = 1:numDiversity
                        if packetSendTime(i,j) == t
                            c = channelSelection(i,j);
                            chanCount(c) = chanCount(c) + 1;
                        end
                    end
                end

                % Resolve successes and collisions
                % ===== Resolve successes and collisions (increment once per node per slot) =====
                % Build a list of transmitting nodes this slot (faster than setdiff each time)
                txNodes = 1:N; 
                txNodes(params.recvId) = [];   % receiver never transmits
                
                for ii = 1:numel(txNodes)
                    i = txNodes(ii);
                
                    % Active branches for node i at time t
                    activeJ = find(packetSendTime(i,:) == t & channelSelection(i,:) ~= 0);
                    if isempty(activeJ), continue; end
                
                    % ---------- PASS 1: Check if any branch succeeds ----------
                    successThisSlot = false;
                    for jj = 1:numel(activeJ)
                        j = activeJ(jj);
                        c = channelSelection(i,j);
                
                        % Link budget (same as your code)
                        d    = norm(squeeze(positions(t,i,:)) - squeeze(positions(t,recvId,:)));
                        PLdB = computePathLossLogDistance(d, params.phy);
                        Pr   = params.phy.Pt_dBm - PLdB;
                
                        if (Pr >= params.phy.RxSens_dBm) && (chanCount(c) == 1)
                            % ---- SUCCESS ----
                            successCount        = successCount + 1;
                            packetSendCount(i)  = packetSendCount(i) + 1;
                            collisionCount(i)   = 0;
                
                            % Cancel all sibling branches of this fragment
                            packetHold(i,:)       = 0;
                            packetSendTime(i,:)   = 0;
                            channelSelection(i,:) = 0;
                
                            % If a full packet (all fragments) is done, finalize delay and schedule next
                            if packetSendCount(i) == dataLength
                                packetSendCount(i) = 0;
                                dataSendCount(i)   = dataSendCount(i) + 1;
                                delayAccum(i)      = delayAccum(i) + (t - firstBirthTime(i) + 1);
                                packetBirthTime(i) = t + randi(parTime) + 1;
                            end
                
                            successThisSlot = true;
                            break;  % no backoff bump; we’re done with node i at slot t
                        end
                    end
                
                    if successThisSlot
                        continue;  % move to next node
                    end
                
                    % ---------- PASS 2: All active branches failed → schedule backoff for each ----------
                    anyFailThisSlot = true;                   % since activeJ is nonempty and none succeeded
                    ccTmp = min(collisionCount(i) + 1, 5);    % temporary count used for backoff range
                
                    for jj = 1:numel(activeJ)
                        j = activeJ(jj);
                
                        backoff = randi(2^ccTmp - 1) + 1;     % use the same bumped k for all branches
                        temp_t  = t + backoff;
                
                        if mod(i - mod(temp_t, N), N) <= W
                            packetSendTime(i,j) = temp_t + mod(i - mod(temp_t, N), N);
                            packetHold(i,j)     = 1;
                        else
                            packetSendTime(i,j) = temp_t;
                            packetHold(i,j)     = 0;
                        end
                    end
                
                    % ---------- Commit the bump ONCE for this node ----------
                    if anyFailThisSlot
                        collisionCount(i) = ccTmp;            % bump once, cap already applied
                    end
                end
                % ===== end Resolve successes and collisions =====
            end

            % Compute metrics
            metrics    = computeMetrics(successCount, dataSendCount, delayAccum, simTime, dataLength);
            sendRate(idx) = metrics.sendRate;
            delayAve(idx) = metrics.delayAve;

            % Update global best
            if isfinite(metrics.delayAve) && metrics.delayAve < minDelay
                minDelay = metrics.delayAve;
                maxSend  = metrics.sendRate * simTime * dataLength;
            end
        end

        % Store raw results (no plotting)
        statsFAWADS(parTime).windowList = window;
        statsFAWADS(parTime).sendRate   = sendRate;
        statsFAWADS(parTime).delayAve   = delayAve;
        statsFAWADS(parTime).minDelay   = minDelay;
        statsFAWADS(parTime).maxSend    = maxSend;
    end
end






