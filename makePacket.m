function pkt = makePacket(id, nodeId, type, genTime, deadlineTime, sizeBytes, priority)

    pkt = struct();
    pkt.id = id;
    pkt.nodeId = nodeId;
    pkt.type = type;
    pkt.genTime = genTime;
    pkt.deadlineTime = deadlineTime;
    pkt.sizeBytes = sizeBytes;
    pkt.priority = priority;
end