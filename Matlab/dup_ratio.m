%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Xiaohui Liu (whulxh@gmail.com)
%   Date:   2/7/2011
%   Function: analyze duplicate ratio of received packets, excluding
%   packets not destinated to me (overheard unicast or non-FC in OR)
%   [Type; NodeID; SourceID/isACK; SeqNum; FC1; FC2; FC3; FC4; FC5;
%   Last_Hop_Sender; Last_Hop_Ntw_Seq; Last_Hop_MAC_Seq; Local_Ntw_Seq; Local_MAC_Seq; Timestamp]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ROOT_ID = 15;
%packet destinated to root
root_rxs = rxs(rxs(:, 2) == ROOT_ID & rxs(:, 14) == 1, :);
dup_ratio = size(root_rxs, 1) / size(unique(root_rxs(:, 3:4), 'rows'), 1);