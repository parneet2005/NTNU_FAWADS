function Q = appendPacket(Q, pkt)
%% appendPacket
%  Adds one packet to the end of a queue or log.

if isempty(Q)
    Q = pkt;
else
    Q(end+1) = pkt;
end

end
