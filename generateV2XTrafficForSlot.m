function [nodeQueue, pktLog, pktLogCount, nextPacketId, totalGenerated] = ...
    generateV2XTrafficForSlot(nodeQueue, pktLog, pktLogCount, ...
    nextPacketId, totalGenerated, N, t, params, inRange)

    qTypeCount = zeros(1,3);

    for qi = 1:N
        if isempty(nodeQueue{qi})
            continue;
        end

        for qk = 1:numel(nodeQueue{qi})
            ptype = nodeQueue{qi}(qk).type;
            if ptype >= 1 && ptype <= 3
                qTypeCount(ptype) = qTypeCount(ptype) + 1;
            
        end
    end

    fprintf('[t=%d W=%d] QUEUE after generation: CAM=%d DENM=%d BG=%d totalGenerated=%d nextPacketId=%d\n', ...
        t, W, qTypeCount(TYPE_CAM), qTypeCount(TYPE_DENM), qTypeCount(TYPE_BG), ...
        totalGenerated, nextPacketId);
end
    % ============================================================
% DEBUG SETTINGS
% ============================================================
debugFlow = true;
debugSlots = 1:100;
debugTypes = [TYPE_CAM TYPE_DENM];     % simulate/debug CAM and DENM
debugNodes = 1:min(N,10);

typeName = ["CAM", "DENM", "BG"];
% ============================================================


% ============================================================
% FULL SIC SETTINGS
% packetHold = 1 means HP branch
% packetHold = 0 means LP branch
% ============================================================
if ~isfield(params,'sic') || ~isstruct(params.sic)
    params.sic = struct();
end

params.sic.fullSIC = true;

% Recommended:
% CAM: 1 HP branch + remaining LP branches
% DENM: 2 HP branches + remaining LP branches
% BG: all LP
if ~isfield(params.sic,'numHP_CAM'),  params.sic.numHP_CAM  = 1; end
if ~isfield(params.sic,'numHP_DENM'), params.sic.numHP_DENM = 2; end
if ~isfield(params.sic,'numHP_BG'),   params.sic.numHP_BG   = 0; end
% ============================================================


% ============================================================
% FQ-CoDel SETTINGS
% Slot-based FQ-CoDel style queue control
% ============================================================
if ~isfield(params,'fqCoDel') || ~isstruct(params.fqCoDel)
    params.fqCoDel = struct();
end

params.fqCoDel.enable = true;

% If a queued packet waits longer than this, FQ-CoDel may drop it.
% Use smaller values for stricter queue delay control.
if ~isfield(params.fqCoDel,'targetSlots')
    params.fqCoDel.targetSlots = 3;
end

% Maximum queue length per node per traffic type.
if ~isfield(params.fqCoDel,'maxQueuePerType')
    params.fqCoDel.maxQueuePerType = 20;
end

% Protect DENM more strongly than CAM because DENM is emergency traffic.
if ~isfield(params.fqCoDel,'protectDENM')
    params.fqCoDel.protectDENM = true;
end
% ============================================================

    if isfield(params,'v2x') && isstruct(params.v2x)
        traffic = params.v2x;
    elseif isfield(params,'traffic') && isstruct(params.traffic)
        traffic = params.traffic;
    else
        error('Missing traffic configuration: expected params.v2x or params.traffic.');
    end

    slotTime_s = params.slotTime_s;

    %% Convert CAM period to slots
    camPeriodSlots = max(1, round(traffic.CAM.period_s / slotTime_s));
    camDeadlineSlots = max(1, round(traffic.CAM.deadline_s / slotTime_s));

    denmDeadlineSlots = max(1, round(traffic.DENM.deadline_s / slotTime_s));
    bgDeadlineSlots   = max(1, round(traffic.BG.deadline_s / slotTime_s));

    for i = 1:N

        % For RSU-centric evaluation, generate packets only from nodes
        % that are currently relevant to the receiver.
        if nargin >= 9
            if ~inRange(i)
                continue;
            end
        end

        %% CAM: periodic
        if traffic.CAM.enable
            if mod(t + i, camPeriodSlots) == 0

                nextPacketId = nextPacketId + 1;
                totalGenerated = totalGenerated + 1;

                pkt = makePacket(nextPacketId, i, TYPE_CAM, t, ...
                    t + camDeadlineSlots, ...
                    traffic.CAM.sizeBytes, ...
                    traffic.CAM.priority);

                nodeQueue{i} = appendPacket(nodeQueue{i}, pkt);
            end
        end

        %% DENM: event-triggered
        if traffic.DENM.enable
            if isfield(traffic.DENM,'eventProbPerSlot') && ~isempty(traffic.DENM.eventProbPerSlot)
                denmProb = traffic.DENM.eventProbPerSlot;
            elseif isfield(traffic.DENM,'meanInterArrival_s') && ~isempty(traffic.DENM.meanInterArrival_s)
                denmProb = min(1, slotTime_s / traffic.DENM.meanInterArrival_s);
            else
                error('DENM configuration needs eventProbPerSlot or meanInterArrival_s.');
            end

            if rand < denmProb

                nextPacketId = nextPacketId + 1;
                totalGenerated = totalGenerated + 1;

                sizeBytes = randi([traffic.DENM.minSizeBytes, ...
                                   traffic.DENM.maxSizeBytes]);

                pkt = makePacket(nextPacketId, i, TYPE_DENM, t, ...
                    t + denmDeadlineSlots, ...
                    sizeBytes, ...
                    traffic.DENM.priority);

                nodeQueue{i} = appendPacket(nodeQueue{i}, pkt);
            end
        end

        %% Background traffic
        if traffic.BG.enable
            bgProb = traffic.BG.probPerSlot;

            if rand < bgProb

                nextPacketId = nextPacketId + 1;
                totalGenerated = totalGenerated + 1;

                sizeBytes = randi([traffic.BG.minSizeBytes, ...
                                   traffic.BG.maxSizeBytes]);

                pkt = makePacket(nextPacketId, i, TYPE_BG, t, ...
                    t + bgDeadlineSlots, ...
                    sizeBytes, ...
                    traffic.BG.priority);

                nodeQueue{i} = appendPacket(nodeQueue{i}, pkt);
            end
        end
    end
end
