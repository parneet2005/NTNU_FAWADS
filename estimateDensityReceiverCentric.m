function dens = estimateDensityReceiverCentric(positions, params, t)
% Estimate current contention density as the number of *transmitting* nodes
% that are in-range of the receiver (excludes receiver itself).
% Uses your existing computeInRange() for fixed-range detection.

inRange = computeInRange(positions, params.recvId, params.rangeThreshold, t);
inRange(params.recvId) = false;
dens = sum(inRange);     % number of contenders heard by receiver right now
end

