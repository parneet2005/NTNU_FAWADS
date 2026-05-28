%% Helper: Initialize packet birth times
function birthTimes = initBirthTimes(N, parTime, recvId)
    birthTimes = randi(parTime, N, 1);
    birthTimes(recvId) = 0;
end
