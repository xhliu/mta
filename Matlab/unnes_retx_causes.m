%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Xiaohui Liu (whulxh@gmail.com)
%   Date:   6/24/2010
%   Function: analyze the causes for unnecessary retx, namely, timeout too
%   short and/or ACK loss
%   [Type; NodeID; SourceID/isACK; SeqNum; FC1; FC2; FC3; FC4; FC5;
%   Last_Hop_Sender; Last_Hop_Ntw_Seq; Last_Hop_MAC_Seq; Local_Ntw_Seq; Local_MAC_Seq; Timestamp]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear
clc

DirDelimiter='/';
srcDir = '~/Downloads/Jobs';
srcDir2 = '262'; % Defined by users
srcDir3 = '';
dest = [srcDir DirDelimiter srcDir2 srcDir3 DirDelimiter];
files = dir([dest '*.mat']);

BASESTATION_ID = 15;

TX_FLAG = 9;
RX_FLAG = 10;

IS_ACK_POS = 3;
NODE_ID_POS = 2;
%unicast or not
CAST_POS = 10;

FCS_POS = 5;
FCS_SIZE = 5;

LAST_HOP_POS = 10;
% forwarding #
LAST_HOP_SEQ_POS = 12;
LOCAL_SEQ_POS = 14;
TIMESTAMP_POS = 15;
RETX_TIME_POS = 16;

INVALID_ADDR = 255;

txCounts = 0;
ackTimelyCounts = 0;
ackTimelySucCounts = 0;
validCounts = 0;
unsyncCounts = 0;
ackLateCounts = 0;
ackLossCounts = 0;
noAckCounts = 0;
%receiption prior to tx
errs = [];
lateness = [];

% for each node
for fileIndex = 1:length(files)
    indexedFile = files(fileIndex).name;
    if strcmp(indexedFile, 'delaySamples.mat') || strcmp(indexedFile, 'TxRx.mat') || ...
            strcmp(indexedFile, 'unnecessaryReTx.mat')
        disp (['Skip file ' indexedFile]);
        continue;
    end
    load ([dest indexedFile]);
    disp (['Loading file ' indexedFile]);
    
%     txrxLogs = Packet_Log(find(Packet_Log(:, 1) == TX_FLAG |
    % only broadcast packets require explicit ACK
    sender_txLogs = Packet_Log(find(Packet_Log(:, 1) == TX_FLAG  & Packet_Log(:, CAST_POS) == 0), :);
    sender_rxLogs = Packet_Log(find(Packet_Log(:, 1) == RX_FLAG), :);
    if isempty(sender_txLogs)
        disp (['node not sending ' indexedFile]);
        continue;
    end
    nodeId = sender_txLogs(1, NODE_ID_POS);
    
    %base station receives no ACK
    if nodeId == BASESTATION_ID
        continue;
    end
    
    txCounts = txCounts + size(sender_txLogs, 1);
    
    % each tx
    for i = 1 : size(sender_txLogs, 1)
        seqno = sender_txLogs(i, LOCAL_SEQ_POS);
        txTime = sender_txLogs(i, TIMESTAMP_POS);
        retxTime = sender_txLogs(i, RETX_TIME_POS);
        
        any_ack = false;
        any_ack_timely_suc = false;
        any_ack_timely = false;
        % any FC receives
        rcv = false;
        
        %each FC
        for j = 1 : FCS_SIZE
            fc = sender_txLogs(i, FCS_POS + j - 1);
        	if INVALID_ADDR == fc
                break;
            end
            % no record for this FC
            if ~exist([dest num2str(fc) '.mat'], 'file')
                fprintf('node %d does not exist \n', fc);
                continue;
            end
            load ([dest num2str(fc) '.mat']);
            % used to find next ACK index
            totalRcvEntries = size(Packet_Log, 1);
            % see if it receives
            %rcvIX = find(Packet_Log(:, 1) == RX_FLAG & Packet_Log(:, LAST_HOP_POS) == nodeId & Packet_Log(:, LAST_HOP_SEQ_POS) == seqno);
            % not duplicate
            rcvIX = find(Packet_Log(:, 1) == RX_FLAG & Packet_Log(:, LAST_HOP_POS) == nodeId &...
                Packet_Log(:, LAST_HOP_SEQ_POS) == seqno & Packet_Log(:, 16) == 0);
            % not received
            if isempty(rcvIX)
                fprintf('packet not received \n');
                continue;
            else
                rcv = true;
                rxTime = Packet_Log(rcvIX, TIMESTAMP_POS);
                if rxTime <= txTime
                    errs = [errs; txTime - rxTime];
                end
            end
            % find the next ACK after this reception
            later_Packet_Log = Packet_Log(rcvIX(1) : totalRcvEntries, :);
            nextACKIX = find(later_Packet_Log(:, 1) == TX_FLAG & later_Packet_Log(:, IS_ACK_POS) ~= 0);
            % reach the end; no ACK later
            if isempty(nextACKIX)
                fprintf('no ACK found later \n');
                continue;
            else
                any_ack = true;
            end
            
            % next ACK
            ack_seqno = later_Packet_Log(nextACKIX(1), LOCAL_SEQ_POS);
            nextACKTime = later_Packet_Log(nextACKIX(1), TIMESTAMP_POS);
            if (nextACKTime > txTime) && (nextACKTime < retxTime)
                %timely
                any_ack_timely = true;
                %all_ack_late = false;
                % see if the ACK is lost
                if isempty(sender_rxLogs)
                    senderRxIX = [];
                else
                    % packet id <node id, local seq#>
                    senderRxIX = find(sender_rxLogs(:, LAST_HOP_POS) == fc & sender_rxLogs(:, LAST_HOP_SEQ_POS) == ack_seqno);
                end
                if isempty(senderRxIX)
                    ackLossCounts = ackLossCounts + 1;
                    fprintf('ACK Loss \n');
                else
                    any_ack_timely_suc = true;
                    fprintf('timely ACK received \n');
                end
            else
                if (nextACKTime >= retxTime)
                    %ack too late
                    lateness = [lateness; txTime, retxTime, rxTime, nextACKTime,...
                        retxTime - txTime, nextACKTime - rxTime, nextACKTime - retxTime];
                    if (nextACKTime - retxTime) > 3000
                        disp('');
                    end
                    ackLateCounts = ackLateCounts + 1;
                    fprintf('ACK late \n');
                else
                    unsyncCounts = unsyncCounts + 1;
                    fprintf('sync err \n');
                end
            end
        end %end of FCS
        
        if rcv
            if ~any_ack
                noAckCounts = noAckCounts + 1;
            end
            validCounts = validCounts + 1;
            if any_ack_timely
                ackTimelyCounts = ackTimelyCounts + 1;
                if any_ack_timely_suc
                    ackTimelySucCounts = ackTimelySucCounts + 1;
                end
            end
        end
    end
end
if txCounts ~= 0
    fprintf('total tx is %d, %d are valid(%f), timely ACK %d (%f), of which ACK success is %d (%f) \n',...
        txCounts, validCounts, validCounts / txCounts, ackTimelyCounts, ackTimelyCounts / validCounts, ackTimelySucCounts, ackTimelySucCounts / ackTimelyCounts); 
end
save([dest 'unnecessaryReTx.mat'], 'txCounts', 'validCounts', 'ackTimelyCounts', ...
    'ackTimelySucCounts', 'ackLateCounts', 'noAckCounts', 'ackLossCounts', 'unsyncCounts', 'lateness', 'errs'); 
clear;