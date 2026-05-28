function statsFAWADS = simulateFAWADSIC_V2XTraffic(N, dataLength, simTime, positions, params)
% simulateFAWADSIC_V2XTraffic
% Main FAWADS + V2X traffic simulation framework.
%
% This split version keeps the original framework intact:
%   1) in-range computation
%   2) V2X traffic generation
%   3) FQ-CoDel queue control
%   4) queued/active deadline drops
%   5) FAWADS scheduling
%   6) channel counting
%   7) SIC eligibility
%   8) TX success/collision resolution
%   9) retransmission backoff
%
% Helper functions are stored as separate .m files in the same folder.

    if nargin < 5
        error(['simulateFAWADSIC_V2XTraffic requires 5 inputs: ' ...
               'N, dataLength, simTime, positions, params. ' ...
               'Call it as: statsFAWADS = simulateFAWADSIC_V2XTraffic(N, dataLength, simTime, positions, params);']);
    end

    %#ok<NASGU>
    unusedDataLength = dataLength;

    [params, opts] = setupFAWADSV2XOptions(params, N);

    if isfield(params,'seed') && ~isempty(params.seed)
        rng(params.seed,'twister');
    end

    recvId = params.recvId;

    %% Window list
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

    %% V2X traffic generation is controlled by each traffic type config.
    numTrafficConfigs = 1;

    statsFAWADS = repmat(struct( ...
        'trafficConfig', [], ...
        'windowList', [], ...
        'sendRate', [], ...
        'delayAve', [], ...
        'minDelay', [], ...
        'maxSend', [], ...
        'v2x', []), 1, numTrafficConfigs);

    %% Run configured V2X traffic scenario
    for cfgIdx = 1:numTrafficConfigs

        window = windowListMaster;

        sendRate = zeros(1,numel(window));
        delayAve = nan(1,numel(window));

        minDelay = inf;
        maxSend = 0;
        v2xByWindow = [];

        %% Sweep W
        for idx = 1:numel(window)

            W = window(idx);
            fprintf('\n==================== START W = %d ====================\n', W);

            st = initFAWADSWindowState(N, simTime, params, opts);

            %% Slot loop
            for t = 1:simTime

                %% 1) Determine in-range nodes
                inRange = computeInRange(positions, params, t);

                if ~isfield(params,'rsuPos') || isempty(params.rsuPos)
                    inRange(recvId) = false;
                end

                debugSlotStart(t, W, inRange, opts);

                %% 2) Generate V2X packets
                totalGeneratedBefore = st.totalGenerated;

                [st.nodeQueue, st.pktLog, st.pktLogCount, st.nextPacketId, st.totalGenerated] = ...
                    generateV2XTrafficForSlot(st.nodeQueue, st.pktLog, st.pktLogCount, ...
                    st.nextPacketId, st.totalGenerated, N, t, params, inRange);

                debugQueueAfterGeneration(st, totalGeneratedBefore, t, W, opts, N);

                %% 2.5) FQ-CoDel queue management
                pktLogCountBeforeFQCoDel = st.pktLogCount;

                if params.fqCoDel.enable
                    [st.nodeQueue, st.pktLog, st.pktLogCount] = applyFQCoDelQueueControl( ...
                        st.nodeQueue, st.pktLog, st.pktLogCount, t, params, opts);
                end

                debugLogNewDrops(st, pktLogCountBeforeFQCoDel, t, W, opts, 'FQ-CODEL DROP');

                %% 3) Drop expired queued packets
                pktLogCountBeforeQueuedDrop = st.pktLogCount;

                [st.nodeQueue, st.pktLog, st.pktLogCount] = ...
                    dropExpiredQueuedPackets(st.nodeQueue, st.pktLog, st.pktLogCount, t);

                debugLogNewDrops(st, pktLogCountBeforeQueuedDrop, t, W, opts, 'DROP-QUEUED');

                %% 4) Drop expired active packets
                st = dropExpiredActivePackets(st, t, W, opts);

                %% 5) Schedule new transmissions
                st = scheduleNewTransmissions(st, t, W, N, params, inRange, opts);

                %% 6) Count channel transmissions
                txNodes = 1:N;
                if ~isfield(params,'rsuPos') || isempty(params.rsuPos)
                    txNodes(recvId) = [];
                end

                [chanCount, HP_lists, LP_lists] = countChannelTransmissions(st, t, params, txNodes);

                debugChannelOccupancy(chanCount, t, W, opts);

                %% 7) SIC eligibility
                branchEligible = computeSICEligibility(HP_lists, LP_lists, params, N, params.numDiversity);

                debugSICEligibility(st, branchEligible, t, W, opts);

                %% 8 and 9) Resolve success/collision and retransmissions
                st = resolveFAWADSTransmissions(st, t, W, positions, params, txNodes, chanCount, branchEligible, opts);
            end

            %% Trim logs
            st.pktLog = st.pktLog(1:st.pktLogCount);
            st.txLog  = st.txLog(1:st.txLogCount);

            %% Compute normal and V2X metrics
            v2xMetrics = computeV2XMetrics(st.pktLog, st.txLog, simTime, params);

            sendRate(idx) = st.successCount / simTime;
            delayAve(idx) = v2xMetrics.delay_all_avg;

            if isfinite(delayAve(idx)) && delayAve(idx) < minDelay
                minDelay = delayAve(idx);
                maxSend = sendRate(idx) * simTime;
            end

            v2xByWindow(idx) = v2xMetrics;

            fprintf('==================== END W = %d | successCount=%d sendRate=%.4f delayAve=%.4f ====================\n', ...
                W, st.successCount, sendRate(idx), delayAve(idx));
        end

        statsFAWADS(cfgIdx).trafficConfig = params.v2x;
        statsFAWADS(cfgIdx).windowList = window;
        statsFAWADS(cfgIdx).sendRate = sendRate;
        statsFAWADS(cfgIdx).delayAve = delayAve;
        statsFAWADS(cfgIdx).minDelay = minDelay;
        statsFAWADS(cfgIdx).maxSend = maxSend;
        statsFAWADS(cfgIdx).v2x = v2xByWindow;
    end
end
