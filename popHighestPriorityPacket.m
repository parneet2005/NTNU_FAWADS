function [pkt, q] = popHighestPriorityPacket(q)

    priorities = [q.priority];
    genTimes = [q.genTime];

    % Highest priority first; if tie, oldest packet first
    score = priorities * 1e9 - genTimes;

    [~, idx] = max(score);

    pkt = q(idx);
    q(idx) = [];
end