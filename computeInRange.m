% computeInRange, initBirthTimes, computeMetrics as before.

%% Helper: Compute which nodes are within range of the receiver
function inRange = computeInRange(positions, params, t)
    posAll = squeeze(positions(t, :, :));   % N×3

    if isfield(params,'rsuPos') && ~isempty(params.rsuPos)
        posRecv = params.rsuPos(:)';        % 1×3 fixed RSU
        dists   = sqrt(sum((posAll - posRecv).^2, 2));
        inRange = (dists <= params.rangeThreshold);
        % no recvId to exclude (RSU is not a vehicle)
    else
        recvId  = params.recvId;
        posRecv = squeeze(positions(t, recvId, :))';
        dists   = sqrt(sum((posAll - posRecv).^2, 2));
        inRange = (dists <= params.rangeThreshold);
        inRange(recvId) = false;           % receiver vehicle doesn't tx
    end
end
