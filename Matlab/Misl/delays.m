%% analyze all kinds of delay estimated
%%  retx timeout
%[retxtime - 2; current turn round time estimation]
timeout = Packet_Log(find(Packet_Log(:, 1) == 15), 3:4);
timeouts = [timeouts; timeout];

%%  queueing delay
% [current queue delay estimation; delay sample]
queueDelay = Packet_Log(find(Packet_Log(:, 1) == 12), 3:4);
queueDelays = [queueDelays; queueDelay];

%%  engineering hack
%   [remaining hack time; remaing time to next retx]
hackDelay1 = Packet_Log(find(Packet_Log(:, 1) == 19), 3:4);
hackDelay1s = [hackDelay1s; hackDelay1];
hackDelay2 = Packet_Log(find(Packet_Log(:, 1) == 20), 3:4);
hackDelay2s = [hackDelay1s; hackDelay2];