function statsFAWADS = simulateFAWADSIC(N, dataLength, simTime, positions, params)
% Run FAWADS protocol and return raw results (no plotting)

    % ----- defaults -----
    if ~isfield(params,'fa') || ~isstruct(params.fa), params.fa = struct(); end
    if ~isfield(params.fa,'CWmin') || isempty(params.fa.CWmin), params.fa.CWmin = 8;   end
    if ~isfield(params.fa,'CWmax') || isempty(params.fa.CWmax), params.fa.CWmax = 512; end

    if ~isfield(params,'enableSIC') || isempty(params.enableSIC)
        params.enableSIC = false;   % default: SIC enabled
    end

    if ~isfield(params,'numDiversity') || isempty(params.numDiversity)
        params.numDiversity = 3;
    end
    numDiversity = params.numDiversity;
    fprintf('Requested D = %d, effective D = %d, numChannel = %d\n', ...
        params.numDiversity, min(params.numDiversity, params.numChannel), params.numChannel);

    if ~isfield(params,'seed') || isempty(params.seed)
        % leave RNG unchanged
    else
        rng(params.seed,'twister');
    end

    recvId = params.recvId;

    % Use indexed parTime storage, not statsFAWADS(parTime)
    parTimeList = params.parTimeList(:).';
    numPar = numel(parTimeList);

    % Optional fixed window list from caller
    if isfield(params,'windowList') && ~isempty(params.windowList)
        windowListMaster = params.windowList;
    else
        if N < 50
            windowListMaster = 1:N-1;
        elseif N < 100
            windowListMaster = 2:2:N-2;
        else
            windowListMaster = 5:5:N-5;
        end
    end

    statsFAWADS = repmat(struct( ...
        'parTime', [], ...
        'numDiversity', numDiversity, ...
        'windowList', [], ...
        'sendRate', [], ...
        'delayAve', [], ...
        'minDelay', [], ...
        'maxSend', []), 1, numPar);
    


    % Loop over packet‐generation intervals
    for pIdx = 1:numPar
        parTime = parTimeList(pIdx);
        % Determine contention window sweep based on N
        minDelay = inf;
        maxSend  = 0;

        window = windowListMaster;
        sendRate = zeros(1, numel(window));
        delayAve = nan(1, numel(window));

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
                inRange = computeInRange(positions, params, t);
                
                % Only exclude recvId if receiver is a vehicle (no RSU)
                if ~isfield(params,'rsuPos') || isempty(params.rsuPos)
                    inRange(params.recvId) = false;
                end




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
                    
                    CWmin_FA  = params.fa.CWmin;
                    tempDelay = randi([1, CWmin_FA]);
                    for j = 1:k
                        % AFTER: initial defer aligned to CWmin_FA
                                       % 1..CWmin
                    
                    r = mod(i - mod(t + tempDelay, N), N);              % phase distance
                    if (r <= W) && (r < tempDelay)                      % snap only if EARLIER
                        packetSendTime(i,j) = t + r;
                        packetHold(i,j)     = 1;
                    else
                        packetSendTime(i,j) = t + tempDelay;
                        packetHold(i,j)     = 0;
                    end

                        channelSelection(i,j) = channels(j);
                    end
                end
                % --- Count transmissions and (optionally) build HP/LP lists for SIC ---
                sicEnabled = params.enableSIC;

                chanCount = zeros(params.numChannel, 1);

                % For SIC: per-channel lists of (node,branch) for HP / LP
                if sicEnabled
                    HP_lists = cell(params.numChannel,1);
                    LP_lists = cell(params.numChannel,1);
                    for c = 1:params.numChannel
                        HP_lists{c} = [];
                        LP_lists{c} = [];
                    end
                end

                txNodes = 1:N;
                if ~isfield(params,'rsuPos') || isempty(params.rsuPos)
                    txNodes(params.recvId) = [];   % only when receiver is a vehicle
                end


                for ii = 1:numel(txNodes)
                    i = txNodes(ii);
                    for j = 1:numDiversity
                        if packetSendTime(i,j) == t && channelSelection(i,j) ~= 0
                            c = channelSelection(i,j);
                            chanCount(c) = chanCount(c) + 1;

                            if sicEnabled
                                if packetHold(i,j) == 1
                                    % High-power (HP) branch
                                    HP_lists{c}(end+1,:) = [i,j];
                                else
                                    % Low-power (LP) branch
                                    LP_lists{c}(end+1,:) = [i,j];
                                end
                            end
                        end
                    end
                end

                % --- With SIC: decide which branches are "eligible" to be decoded ---
                % At most 1 HP + 1 LP per channel per slot.
                branchEligible = false(N, numDiversity);

                if sicEnabled
                    for c = 1:params.numChannel
                        HP = HP_lists{c};
                        LP = LP_lists{c};
                        nHP = size(HP,1);
                        nLP = size(LP,1);

                        if nHP >= 2
                            % Too many HP contenders: all fail (no eligible branches)
                            continue;

                        elseif nHP == 1
                            % 1 HP always gets a shot
                            ihp = HP(1,1); jhp = HP(1,2);
                            branchEligible(ihp, jhp) = true;

                            % plus at most 1 LP (SIC of LP after HP)
                            if nLP >= 1
                                k = randi(nLP);
                                ilp = LP(k,1); jlp = LP(k,2);
                                branchEligible(ilp, jlp) = true;
                            end

                        else % nHP == 0
                            % Only LP contenders; allow at most one to be eligible
                            if nLP == 1
                                ilp = LP(1,1); jlp = LP(1,2);
                                branchEligible(ilp, jlp) = true;
                            end
                        end
                    end
                end

                % ===== Resolve successes and collisions (increment once per node per slot) =====
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

                        % Link budget (as in your original code)
                        if isfield(params,'rsuPos') && ~isempty(params.rsuPos)
                            pos_rx = params.rsuPos(:);
                        else
                            pos_rx = squeeze(positions(t,recvId,:));
                        end
                        d = norm(squeeze(positions(t,i,:)) - pos_rx);

                        PLdB = computePathLossLogDistance(d, params.phy);

                        % Choose HP vs LP transmit power based on packetHold (1=HP, 0=LP)
                        if packetHold(i,j) == 1
                            Pt = params.phy.PtHP_dBm;
                        else
                            Pt = params.phy.PtLP_dBm;
                        end
                        
                        shadow_dB = params.phy.sigma * randn;
                        Pr = Pt - PLdB - shadow_dB;


                        % --- Success condition differs with/without SIC ---
                        if ~sicEnabled
                            condMAC = (chanCount(c) == 1);      % original rule
                        else
                            condMAC = branchEligible(i,j);       % chosen by SIC per channel
                        end

                        if (Pr >= params.phy.RxSens_dBm) && condMAC
                            % ---- SUCCESS ----
                            successCount        = successCount + 1;
                            packetSendCount(i)  = packetSendCount(i) + 1;
                            collisionCount(i)   = 0;

                            % Cancel all sibling branches for this packet
                            packetHold(i,:)       = 0;
                            packetSendTime(i,:)   = 0;
                            channelSelection(i,:) = 0;

                            % Full packet done?
                            if packetSendCount(i) == dataLength
                                packetSendCount(i) = 0;
                                dataSendCount(i)   = dataSendCount(i) + 1;
                                delayAccum(i)      = delayAccum(i) + (t - firstBirthTime(i));
                                packetBirthTime(i) = t + randi(parTime);
                            end

                            successThisSlot = true;
                            break;   % only one success per node per slot
                        end
                    end

                    if successThisSlot
                        continue;  % next node
                    end

                    % ---------- PASS 2: All active branches failed → backoff ----------
                    % bump collision count ONCE per node per slot
                    if collisionCount(i) < 5
                        ccTmp = collisionCount(i) + 1;
                    else
                        ccTmp = 5;
                    end

                    backoff = randi(2^ccTmp - 1) + 1;
                    temp_t  = t + backoff;
                    snapOffset = mod(i - mod(temp_t, N), N);

                    for jj = 1:numel(activeJ)
                        j = activeJ(jj);

                        if snapOffset <= W
                            packetSendTime(i,j) = temp_t + snapOffset;
                            packetHold(i,j)     = 1;   % HP (in-window)
                        else
                            packetSendTime(i,j) = temp_t;
                            packetHold(i,j)     = 0;   % LP (out-of-window)
                        end
                    end

                    collisionCount(i) = ccTmp;  % commit bump
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
        statsFAWADS(pIdx).parTime       = parTime;
        statsFAWADS(pIdx).numDiversity  = numDiversity;
        statsFAWADS(pIdx).windowList    = window;
        statsFAWADS(pIdx).sendRate      = sendRate;
        statsFAWADS(pIdx).delayAve      = delayAve;
        statsFAWADS(pIdx).minDelay      = minDelay;
        statsFAWADS(pIdx).maxSend       = maxSend;
    end
end
