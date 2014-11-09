%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This program is designed to format data from raw txt files into mat
%   files when each entry contains multiple packet logs.
%   Note that to ease the use of other existing matlab files, the formatted
%   log in matlab is different from the one showed in excel file.
%   Currently, from 1st column to the rightmost one, the log in m file is
%   as follows:
%   [TX/RX; NodeID; SourceID; SeqNum; FC1; FC2; FC3; FC4; FC5;
%   Last_Hop_Sender; Last_Hop_Ntw_Seq; Last_Hop_MAC_Seq; Local_Ntw_Seq; Local_MAC_Seq; Timestamp, rtTimeout]
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear
clc

DirDelimiter='/';
srcDir = '~/Projects/tOR/RawData';
% srcDir = '~/Downloads/Jobs';
job_id = 3265;
srcDir2 = num2str(job_id); % Defined by users
SRC_ID = 76;

MAX_FCS_SIZE = 0; %0, 5; 3;5
Colmn_Packet = 11; %11, 16; 14;
srcDir3 = '';
dest = [srcDir DirDelimiter srcDir2 srcDir3 DirDelimiter];
files = dir([dest '*.txt']);

cd(dest);
output = fopen('output.txt', 'w');

QUEUE_SIZE = 38;

% preallocation
MAX_ENTRIES = 1000000;

sendCounts = 0;
rcvCounts = 0;
destPkts = [];
ROOT_ID = 15;

Control_Data = 8; %NetEye 8, Kansei 10: 2 Columns that are useless

IsOR = 1;

% UNICAST_IDX = 15;
FCS_IDX = 5;
INVALID_ADDR = 255;
SERIAL_NUM_IDX = 16;

SEND_FLAG = 1;
SEND_FAIL_FLAG = 0;
RCV_FLAG = 3;
INTERCEPT_FLAG = 2;
SNOOP_FLAG = 8;
TX_FLAG = 9;
RX_FLAG = 10;

BEACON_SEND_FLAG = 18;

ETX_FLAG = 23;
ETXs = [];

% packet loss
SW_FULL_FLAG = 5;
REJECT_FLAG = 6;
% RT_OUT_RANGE_FLAG = 7;
% SUPPRESS_FLAG = 8;
%EXPIRATION_FORWARD_FLAG = 8,
EXPIRE_FLAG = 11;
% DBG_FAIL_PKT_LINK_DELAY = 25;
% REJ_FLAG = 112;
% rejs = [];

DEBUG_FLAG = 255;
DBG_LOSS_IN_AIR_FLAG = 5;
% PROCESS_DELAY_FLAG = 12;
% QUEUE_DELAY_FLAG = PROCESS_DELAY_FLAG + 1;
% NT_FLAG = QUEUE_DELAY_FLAG + 1;
TIMEOUT_FLAG = 20;
nodeForwards = [];

LINK_QUALITY_FLAG = 24;
link_pdrs = [];
% PKT_TIME_FLAG = TIMEOUT_FLAG + 1;
% 
% process_delays = [];
% 
% % QUEUE_DELAY_FLAG = 19;
% queue_delays = [];
% 
% NTs = [];
% 
% %TIMEOUT_FLAG = 20;
% timeouts = [];
% 
% PKT_TIME = PKT_TIME_FLAG;
% packet_times = [];
% 
% LINK_DELAY = PKT_TIME_FLAG + 1;
% link_delays = [];
% 
% COOR_DELAY_FLAG = 18;
% coor_delays = [];

% UART reliability
% uarts = [];
uart_relis = [];

%liveness check
beacons = [];

% ranks = [];

Num_Tx = 1;
Num_NodeID = 1;
Num_SourceID = 1;
Num_SeqNum = 2;
Num_FC_each = 1;

if IsOR == 1
%     MAX_FCS_SIZE = 3; %5;
%     Colmn_Packet = 14; %16
    EletPerLog = 5; 
else
%     MAX_FCS_SIZE = 1;
%     Colmn_Packet = 11;  %11
    EletPerLog = 6; %6
end

Num_LastSender = 1;
Num_LastSenderSeq = 2;
Num_LocalSeq = 2;

Num_LastNtwSeq = 2;
Num_LocalNtwSeq = 2;

Num_TimeStamp = 4;
Num_RetxTime = 4;

Num_PerElet = Num_Tx + Num_NodeID + Num_SourceID + Num_SeqNum + Num_FC_each * MAX_FCS_SIZE + Num_LastSender + ...
    Num_LastSenderSeq + Num_LocalSeq + Num_LastNtwSeq + Num_LocalNtwSeq + Num_TimeStamp + Num_RetxTime;

% Control_Data = 10; %8 -> Kansei Columns that are useless
NUM_COLUMNS = Control_Data + Num_PerElet * EletPerLog;  % Number of Columns in Log
SENDER_DATA_FORMAT = repmat('%x ', 1, NUM_COLUMNS); % '%x' means HEX


debugs = zeros(MAX_ENTRIES, Colmn_Packet);
debugs_cnts = 1;
% all participating nodes, including those do not tx/forward data
nodes = [];
% nodes = zeros(MAX_ENTRIES, Colmn_Packet);
rejs = zeros(MAX_ENTRIES, Colmn_Packet);
rejs_cnts = 1;

expires = zeros(MAX_ENTRIES, Colmn_Packet);
expires_cnts = 1;

overflows = zeros(MAX_ENTRIES, Colmn_Packet);
overflows_cnts = 1;

txs = zeros(MAX_ENTRIES, Colmn_Packet);
txs_cnts = 1;

unicasts = zeros(MAX_ENTRIES, 3);
unicasts_cnts = 1;

rxs = zeros(MAX_ENTRIES, Colmn_Packet);
rxs_cnts = 1;

intercepts = zeros(MAX_ENTRIES, Colmn_Packet);
intercepts_cnts = 1;

srcPkts = [];
% srcPkts = zeros(MAX_ENTRIES, Colmn_Packet);

%%
for fileIndex = 1:length(files)
    indexedFile = files(fileIndex).name;
    fid = fopen([srcDir DirDelimiter srcDir2 DirDelimiter srcDir3 indexedFile]);
    Raw_Data = fscanf(fid, SENDER_DATA_FORMAT,[NUM_COLUMNS inf]);
    Raw_Data = Raw_Data';
    disp (['Loading file ' indexedFile]);
    
    Entry_Num = size(Raw_Data, 1) * EletPerLog;
    
    if ~isempty(Raw_Data)
        Packet_Log = zeros(Entry_Num, Colmn_Packet);
        CurrentIndex = 0;
        for temp_Entry = 1:size(Raw_Data, 1)
            Current_R_Index = 0;
            for temp_Ele = 1:EletPerLog
                PL_Index = 1;
                for i = 1:1:Num_Tx        %TX/RX
                    Packet_Log((CurrentIndex + 1), PL_Index) = Packet_Log((CurrentIndex + 1), PL_Index) +...
                                                        Raw_Data(temp_Entry, (temp_Ele - 1) * Num_PerElet + Control_Data + Current_R_Index + i) * power(16, (Num_Tx - i) * 2);
                end
                Current_R_Index = Current_R_Index + Num_Tx;
                PL_Index = PL_Index + 1;
%                 for index = 2:9
%                     Packet_Log((CurrentIndex + 1), index) = Raw_Data(temp_Entry, (index - 1) * 2 + 8 + (temp_Ele - 1) * 17) * power(16, 2)...
%                                                         + Raw_Data(temp_Entry, (index - 1) * 2 + 9 + (temp_Ele - 1) * 17) * power(16, 0);
%                 end

                for i = 1:1:Num_NodeID    %NodeID
                    Packet_Log((CurrentIndex + 1), PL_Index) = Packet_Log((CurrentIndex + 1), PL_Index) +...
                                                        Raw_Data(temp_Entry, (temp_Ele - 1) * Num_PerElet + Control_Data + Current_R_Index + i) * power(16, (Num_NodeID - i) * 2);
                end
                Current_R_Index = Current_R_Index + Num_NodeID;
                PL_Index = PL_Index + 1;
                
                for i = 1:1:Num_SourceID  %SourceID
                    Packet_Log((CurrentIndex + 1), PL_Index) = Packet_Log((CurrentIndex + 1), PL_Index) +...
                                                        Raw_Data(temp_Entry, (temp_Ele - 1) * Num_PerElet + Control_Data + Current_R_Index + i) * power(16, (Num_SourceID - i) * 2);
                end
                Current_R_Index = Current_R_Index + Num_SourceID;
                PL_Index = PL_Index + 1;
                
                for i = 1:1:Num_SeqNum    %Sequence Number
                    Packet_Log((CurrentIndex + 1), PL_Index) = Packet_Log((CurrentIndex + 1), PL_Index) +...
                                                        Raw_Data(temp_Entry, (temp_Ele - 1) * Num_PerElet + Control_Data + Current_R_Index + i) * power(16, (Num_SeqNum - i) * 2);
                end
                Current_R_Index = Current_R_Index + Num_SeqNum + Num_LastSender + Num_LastSenderSeq + Num_LocalSeq + Num_LastNtwSeq + Num_LocalNtwSeq;   %Jump New Columns
                PL_Index = PL_Index + 1;
                
                for j = 1:1:MAX_FCS_SIZE        %FC Set
                    for i = 1:1:Num_FC_each
                        Packet_Log((CurrentIndex + 1), PL_Index) = Packet_Log((CurrentIndex + 1), PL_Index) +...
                                                            Raw_Data(temp_Entry, (temp_Ele - 1) * Num_PerElet + Control_Data + Current_R_Index + i) * power(16, (Num_FC_each - i) * 2);
                    end
                    Current_R_Index = Current_R_Index + Num_FC_each;
                    PL_Index = PL_Index + 1;
                end
                
                %%Adding New Columns
                Current_R_Index = Current_R_Index - MAX_FCS_SIZE * Num_FC_each - (Num_LastSender + Num_LastSenderSeq + Num_LocalSeq + Num_LastNtwSeq + Num_LocalNtwSeq);
                for i = 1:1:Num_LastSender    %Last Hop Sender
                    Packet_Log((CurrentIndex + 1), PL_Index) = Packet_Log((CurrentIndex + 1), PL_Index) +...
                                                        Raw_Data(temp_Entry, (temp_Ele - 1) * Num_PerElet + Control_Data + Current_R_Index + i) * power(16, (Num_LastSender - i) * 2);
                end
                Current_R_Index = Current_R_Index + Num_LastSender;
                PL_Index = PL_Index + 1;
                
                for i = 1:1:Num_LastNtwSeq    %Last Hop Network Sequence Number
                    Packet_Log((CurrentIndex + 1), PL_Index) = Packet_Log((CurrentIndex + 1), PL_Index) +...
                                                        Raw_Data(temp_Entry, (temp_Ele - 1) * Num_PerElet + Control_Data + Current_R_Index + i) * power(16, (Num_LastNtwSeq - i) * 2);
                end
                Current_R_Index = Current_R_Index + Num_LastNtwSeq;
                PL_Index = PL_Index + 1;
                
                for i = 1:1:Num_LastSenderSeq    %Last Hop MAC Sequence Number
                    Packet_Log((CurrentIndex + 1), PL_Index) = Packet_Log((CurrentIndex + 1), PL_Index) +...
                                                        Raw_Data(temp_Entry, (temp_Ele - 1) * Num_PerElet + Control_Data + Current_R_Index + i) * power(16, (Num_LastSenderSeq - i) * 2);
                end
                Current_R_Index = Current_R_Index + Num_LastSenderSeq;
                PL_Index = PL_Index + 1;
                
                for i = 1:1:Num_LocalNtwSeq    %Local Network Sequence Number
                    Packet_Log((CurrentIndex + 1), PL_Index) = Packet_Log((CurrentIndex + 1), PL_Index) +...
                                                        Raw_Data(temp_Entry, (temp_Ele - 1) * Num_PerElet + Control_Data + Current_R_Index + i) * power(16, (Num_LocalNtwSeq - i) * 2);
                end
                Current_R_Index = Current_R_Index + Num_LocalNtwSeq;
                PL_Index = PL_Index + 1;
                
                for i = 1:1:Num_LocalSeq    %Local MAC Sequence Number
                    Packet_Log((CurrentIndex + 1), PL_Index) = Packet_Log((CurrentIndex + 1), PL_Index) +...
                                                        Raw_Data(temp_Entry, (temp_Ele - 1) * Num_PerElet + Control_Data + Current_R_Index + i) * power(16, (Num_LocalSeq - i) * 2);
                end
                Current_R_Index = Current_R_Index + Num_LocalSeq;
                PL_Index = PL_Index + 1;
                
                Current_R_Index = Current_R_Index + MAX_FCS_SIZE * Num_FC_each;   %Add back to the latest index
                
                for i = 1:1:Num_TimeStamp    %Time Stamp
                    Packet_Log((CurrentIndex + 1), PL_Index) = Packet_Log((CurrentIndex + 1), PL_Index) +...
                                                        Raw_Data(temp_Entry, (temp_Ele - 1) * Num_PerElet + Control_Data + Current_R_Index + i) * power(16, (Num_TimeStamp - i) * 2);
                end
                Current_R_Index = Current_R_Index + Num_TimeStamp;
                PL_Index = PL_Index + 1;                
                
                % time for next retx
                for i = 1:1:Num_RetxTime
                    Packet_Log((CurrentIndex + 1), PL_Index) = Packet_Log((CurrentIndex + 1), PL_Index) +...
                                                        Raw_Data(temp_Entry, (temp_Ele - 1) * Num_PerElet + Control_Data + Current_R_Index + i) * power(16, (Num_RetxTime - i) * 2);
                end
                Current_R_Index = Current_R_Index + Num_RetxTime;
                PL_Index = PL_Index + 1;
                
                CurrentIndex = CurrentIndex + 1;
                
                Current_R_Index = 0;
            end
        end
        
%         Unique_Packet_Log = unique(Packet_Log, 'rows', 'first');
%         if size(Packet_Log, 1) == size(Unique_Packet_Log, 1)
%             disp xx;
%         end
        nodeId = Packet_Log(1, 2);
        nodes = [nodes; nodeId];
        %% detect packet loss
        valid_log = [Packet_Log(:, 1), Packet_Log(:, 3), Packet_Log(:, 4), Packet_Log(:, 10)];
        if ~isempty(find(valid_log(:, 1) == REJECT_FLAG, 1))
%                 flowRejs = valid_log(valid_log(:, 1) == FLOW_REJECT_FLAG, :);
                disp (['Flow rejected in ' num2str(nodeId)]);
        end
        
        if ~isempty(find(valid_log(:, 1) == SW_FULL_FLAG, 1))
%                 SWFs = valid_log(valid_log(:, 1) == SW_FULL_FLAG, :);
                disp (['Sliding window full in  ' num2str(nodeId)]);
        end
        
%         if ~isempty(find(valid_log(:, 1) == RT_OUT_RANGE_FLAG, 1))
%                 emptyFCSs{nodeId + 1} = valid_log(valid_log(:, 1) == RT_OUT_RANGE_FLAG, :);
%                 disp (['RT out of range in ' num2str(nodeId)]);
%         end
%         
%         if ~isempty(find(valid_log(:, 1) == EXPIRATION_DROP_FLAG, 1))
%                 expiredPkts{nodeId + 1} = valid_log(valid_log(:, 1) == EXPIRATION_DROP_FLAG, :);
%                 disp (['packets expire in  ' num2str(nodeId)]);
%         end
        
%         if ~isempty(find(valid_log(:, 1) == SUPPRESS_FLAG))
%                 suppressedPkts{nodeId + 1} = valid_log(find(valid_log(:, 1) == SUPPRESS_FLAG), :);
%                 disp (['packets suppressed in  ' num2str(nodeId)]);
%         end
%         nodeForwards = [nodeForwards; nodeId, length(find(valid_log(:, 1) == SW_FULL_FLAG)), length(find(valid_log(:, 1) == RT_OUT_RANGE_FLAG)), ...
%                 length(find(valid_log(:, 1) == EXPIRATION_DROP_FLAG)), length(find(valid_log(:, 1) == SUPPRESS_FLAG)),... 
%                 length(find(valid_log(:, 1) == INTERCEPT_FLAG)), length(unique(valid_log(find(valid_log(:, 1) == TX_FLAG), 3:4), 'rows'))]; 
        % # of successful logs
        log_count = size(Packet_Log, 1);
        % # of log requests
        req_count = Packet_Log(end, end) + 1;
        reli = log_count / req_count;
        uart_relis = [uart_relis; nodeId, log_count, req_count, reli];
%         uarts = [uarts; repmat(nodeId, log_count, 1) (Packet_Log(:, 11) - Packet_Log(:, 12))];
        
%         if reli ~= 1
%             disp('UART log err');
%         end
        
%         if ~isempty(find(Packet_Log(:, 1) == 255, 1))
%             disp('Err: ETX ordering');
%         end
%         
%         if nodeId == SRC_ID %|| nodeId == 8 || nodeId == 22
            disp(['Source:' num2str(nodeId)]);
%             unique(Packet_Log(:, 1), 'rows')
            node_tx = size(unique(Packet_Log(Packet_Log(:, 1) == SEND_FLAG, 3:4), 'rows'), 1);
            sendCounts = sendCounts + node_tx;
            srcPkts = [srcPkts; unique(Packet_Log(Packet_Log(:, 1) == SEND_FLAG, :), 'rows')];
            disp(['Total packets sent:' num2str(node_tx)]);
%         end

% %         if strcmp(indexedFile, ['Job' srcDir2 '-10.0.0.3-1.txt'])
        if nodeId == ROOT_ID  
            disp('Base Station:');
%             unique(Packet_Log(:, 1), 'rows');
            rcvCounts = size(unique(Packet_Log(Packet_Log(:, 1) == RCV_FLAG, 3:4), 'rows'), 1);
%             destPkts = unique(Packet_Log(Packet_Log(:, 1) == RCV_FLAG, :), 'rows');
            destPkts = Packet_Log(Packet_Log(:, 1) == RCV_FLAG, :);
%             disp(['Total packets received:' num2str(rcvCounts)]);
        end
%         len = length(find(Packet_Log(:, 1) == UNICAST_FLAG));
%         unicasts(unicasts_cnts : unicasts_cnts + len - 1, :) = Packet_Log(Packet_Log(:, 1) == UNICAST_FLAG, 2:4);
%         unicasts_cnts = unicasts_cnts + len;
        len = length(find(Packet_Log(:, 1) == SW_FULL_FLAG));
        overflows(overflows_cnts : overflows_cnts + len - 1, :) = Packet_Log(Packet_Log(:, 1) == SW_FULL_FLAG, :);
        overflows_cnts = overflows_cnts + len;

        len = length(find(Packet_Log(:, 1) == REJECT_FLAG));
        rejs(rejs_cnts : rejs_cnts + len - 1, :) = Packet_Log(Packet_Log(:, 1) == REJECT_FLAG, :);
        rejs_cnts = rejs_cnts + len;
        
        len = length(find(Packet_Log(:, 1) == EXPIRE_FLAG));
        expires(expires_cnts : expires_cnts + len - 1, :) = Packet_Log(Packet_Log(:, 1) == EXPIRE_FLAG, :);
        expires_cnts = expires_cnts + len;
        
        len = length(find(Packet_Log(:, 1) == TX_FLAG));
        txs(txs_cnts : txs_cnts + len - 1, :) = Packet_Log(Packet_Log(:, 1) == TX_FLAG, :);
        txs_cnts = txs_cnts + len;
%         rejs = [rejs; Packet_Log(Packet_Log(:, 1) == REJ_FLAG, 2:4)];
%         ETXs = [ETXs; Packet_Log(Packet_Log(:, 1) == ETX_FLAG, [2:4, 15])];
%         
        len = length(find(Packet_Log(:, 1) == DEBUG_FLAG));
        debugs(debugs_cnts : debugs_cnts + len - 1, :) = Packet_Log(Packet_Log(:, 1) == DEBUG_FLAG, :);
        debugs_cnts = debugs_cnts + len;        
% %         link_pdrs = [link_pdrs; Packet_Log(Packet_Log(:, 1) == LINK_QUALITY_FLAG, :)];
%         %link_pdrs = [link_pdrs(:, 1:4) link_pdrs(:, 15)];

        len = length(find(Packet_Log(:, 1) == RX_FLAG | Packet_Log(:, 1) == SNOOP_FLAG));
        rxs(rxs_cnts : rxs_cnts + len - 1, :) = Packet_Log(Packet_Log(:, 1) == RX_FLAG  | Packet_Log(:, 1) == SNOOP_FLAG, :);
        rxs_cnts = rxs_cnts + len;        
        
        len = length(find(Packet_Log(:, 1) == INTERCEPT_FLAG));
        intercepts(intercepts_cnts : intercepts_cnts + len - 1, :) = Packet_Log(Packet_Log(:, 1) == INTERCEPT_FLAG, :);
        intercepts_cnts = intercepts_cnts + len;
%         intercepts = [intercepts; Packet_Log(Packet_Log(:, 1) == INTERCEPT_FLAG, :)];
        %heartbeat
        IX = find(Packet_Log(:, 1) == BEACON_SEND_FLAG);
        if isempty(IX)
            disp('no beacon');
%         else
%             beacons = [beacons; nodeId, length(IX), Packet_Log(IX(end, 1), 4)];
             %beacons = [beacons; Packet_Log(IX, [2:4 15])];
        end
        
        [pathstr, prename, ext, versn] = fileparts(indexedFile);
        save([srcDir DirDelimiter srcDir2 DirDelimiter srcDir3 num2str(nodeId) '.mat'], 'Packet_Log'); %, 'Unique_Packet_Log');
        disp (['Done with ' indexedFile ', go to next']);
    else
        disp (['File ' indexedFile ' is empty, go to next']);
    end
    fclose(fid);
end
% remove unused entries
rejs(rejs_cnts : end, :) = [];
expires(expires_cnts : end, :) = [];
overflows(overflows_cnts : end, :) = [];
txs(txs_cnts : end, :) = [];
rxs(rxs_cnts : end, :) = [];
debugs(debugs_cnts : end, :) = [];
unicasts(unicasts_cnts : end, :) = [];
intercepts(intercepts_cnts : end, :) = [];
%% Transmission_Cost(dest, SRC_ID, ROOT_ID); 
% % ignore base station 
% nonroot_txs = txs(txs(:, 2) ~= ROOT_ID, :);
% unique_txs = unique(nonroot_txs(:, 3:4), 'rows');
% sendCounts = size(unique_txs, 1);
% 
% % application reception: root is recipient and not duplicate
% % unique_rxs = unique(rxs(rxs(:, 2) == ROOT_ID, 3:4), 'rows');
% unique_rxs = unique(rxs(rxs(:, 2) == ROOT_ID & rxs(:, end - 2) == 1 & rxs(:, end) == 0, 3:4), 'rows');
% rcvCounts = size(unique_rxs, 1);
% disp(['total packets received: ' num2str(rcvCounts) ', total packets sent: ' num2str(sendCounts)]);
% if sendCounts ~= 0
%     disp(['Reliability for job' srcDir2 ': ' num2str(rcvCounts / sendCounts)]);
% %     disp(['OR percentage: ' num2str(length(find(nonroot_txs(:, UNICAST_IDX) == 0)) / size(nonroot_txs, 1))]);
%     disp(['OR percentage: ' num2str(length(find(nonroot_txs(:, end) == INVALID_ADDR)) / size(nonroot_txs, 1))]);
% end
% if rcvCounts ~= 0
%     disp(['tx cost for job' srcDir2 ': ' num2str(size(nonroot_txs, 1) / rcvCounts) ', ' num2str(size(nonroot_txs, 1)) ' out of ' num2str(rcvCounts)]);
% end
% save([dest 'TxRx.mat'], 'rcvCounts', 'sendCounts', 'unique_txs', 'unique_rxs', 'txs', ...
%     'rxs', 'uart_relis', 'intercepts', 'uarts', 'beacons', 'nodeForwards', 'ETXs', ...
%         'link_pdrs', 'unicasts', 'rejs', 'nodes'); 
% %save([dest 'delaySamples.mat'], 'link_delays', 'process_delays', 'queue_delays', 'NTs', 'timeouts', 'packet_times');
% save([dest 'debugs.mat'], 'debugs');
% 
% % [node, samples, P2 estimated qtls]
% node_sample_ests = debugs(:, [2, end - 1, 4]);
% save([dest 'node_sample-ests.mat'], 'node_sample_ests');
%%
fprintf(output, '\n');
fprintf(output, 'min uart log reliability: %f\n', min(uart_relis(:, end)));
% if sendCounts ~= 0
    reliability = rcvCounts / sendCounts;
    fprintf(output, ['Reliability for job' srcDir2 ': ' num2str(reliability)]);
    fprintf(output, '\n');
% end
nonroot_txs = txs(txs(:, 2) ~= ROOT_ID, :);
% if rcvCounts ~= 0
    tx_cost = size(nonroot_txs, 1) / rcvCounts;
%     disp(['tx cost for job' srcDir2 ': ' num2str(tx_cost) ', ' num2str(size(nonroot_txs, 1)) ' out of ' num2str(rcvCounts)]);
    fprintf(output, 'tx cost for job %d: %f, %d txs out of %d rxs\n', job_id, tx_cost, size(nonroot_txs, 1), rcvCounts);
% end
%% src tx cost
tmp = nonroot_txs;
src_txs = length(find(tmp(:, 3) == SRC_ID));
tmp = destPkts;
src_rxs = length(unique(tmp(tmp(:, 3) == SRC_ID, 3:4), 'rows'));
fprintf(output, 'src tx cost %f\n', src_txs / src_rxs);

t = srcPkts;
t = t(t(:, 2) == SRC_ID, 4);
src_tx_cnts = size(unique(t), 1);
t = destPkts;
dest_rx_src_cnts = length(unique(t(t(:, 3) == SRC_ID, 4)));
src_reliability = dest_rx_src_cnts / src_tx_cnts;
cd(dest);
load([num2str(SRC_ID) '.mat']);
tmp = Packet_Log;
app_send_fail_ratio = length(find(tmp(:, 1) == SEND_FAIL_FLAG)) / (length(find(tmp(:, 1) == SEND_FAIL_FLAG)) + length(find(tmp(:, 1) == SEND_FLAG)));
fprintf(output, 'src app send fail ratio %f, reliability (send success): %f, %d src pkts lost of %d in total\n', ...
            app_send_fail_ratio, src_reliability, src_tx_cnts - dest_rx_src_cnts, src_tx_cnts);
t = debugs;
% exclude root since all its pkts are lost in air
t = t(t(:, 2) ~= ROOT_ID, :);
in_air_loss = t(t(:, 3) == DBG_LOSS_IN_AIR_FLAG, :);
fprintf(output, 'src pkt loss due to overflow: %d, due to lost in air: %d\n', length(unique(overflows(overflows(:, 3) == SRC_ID, 4))), ...
            length(unique(in_air_loss(in_air_loss(:, 4) == SRC_ID, 10))));
% whether received pkts are rejected or expire
rejected_pkts = unique(rejs(:, 3 : 4), 'rows');
expired_pkts = unique(expires(:, 3 : 4), 'rows');
% % if backup route used
% rx_pkts = unique(destPkts(:, 3 : 4), 'rows');
% rx_not_rejected_pkts = setdiff(rx_pkts, rejected_pkts, 'rows');
% rx_not_expired_pkts = setdiff(rx_pkts, expired_pkts, 'rows');
% len = size(rx_pkts, 1);
% fprintf(output, 'of received packets: %f rejected, %f expired\n\n', 1 - size(rx_not_rejected_pkts, 1) / len, 1 - size(rx_not_expired_pkts, 1) / len);
% no backup route
% caution: packets can be rejected and expired and arrived, overflowed or
% lost in the air more than once bcoz of duplicates
len = size(unique(srcPkts(:, 3 : 4), 'rows'), 1);
fprintf(output, 'of packets sent: %f rejected, %f expired\n\n', size(rejected_pkts, 1) / len, size(expired_pkts, 1) / len);

%% e2e delay from a source
MAX_E2E_DELAY = 20000;
t = destPkts;
t = t(t(:, 3) == SRC_ID, :);
% may have duplicates; consider the first arrived copy
[b m n] = unique(t(:, 4), 'first');
pkt_delays = t(m, 10);
t = pkt_delays;
if ~isempty(t)
    fprintf(output, 'invalid delay %f\n', length(find(t > MAX_E2E_DELAY)) / size(t, 1));
end
t = t(t <= MAX_E2E_DELAY);
if ~isempty(t)
    figure;
    title(num2str(SRC_ID));
    h = plot(t);
    saveas(h, 'e2e delay', 'fig');
    saveas(h, 'e2e delay', 'jpg');
    if (.9 / reliability) <= 1
        tmp = quantile(t, .9 / reliability);
    else
        tmp = inf;
    end
    fprintf(output, 'e2e delay: 90 percentile %f, max %f, 90 percentile considering loss %f\n\n', ...
            quantile(t, .9), max(t), tmp);
end
%% queueing level
% forget root
figure;
title('queueing level');
t = txs;
t = t(t(:, 2) ~= ROOT_ID, :);
[n xout] = hist(t(:, 5), QUEUE_SIZE);
h = bar(xout, n / sum(n));
saveas(h, 'queueing level', 'fig');

%% paths taken by each packet(tracing from source)
ROOT_ID = 15;   % 15 NetEye, 58 Motelab
PARENT_IDX = 10;
% paths taken by each packet
tmp = txs;
% SRC_ID = 76; % 1, 5
SEQ_IDX = 4;
% src_seqs = unique(tmp(tmp(:, 2) == SRC_ID & tmp(:, 3) == SRC_ID, SEQ_IDX));
t = destPkts;
src_seqs = unique(t(t(:, 3) == SRC_ID, SEQ_IDX));
src_txs = tmp(tmp(:, 3) == SRC_ID, :);
len = length(src_seqs);
NTW_SIZE = 10;
pkt_paths = repmat(255, len, NTW_SIZE + 1);
hop_cnts = repmat(0, len, 1);
for i = 1 : len
    node = SRC_ID;
    seq = src_seqs(i);
    hop_cnt = 0;
    path = node;
    while node ~= ROOT_ID
%         fprintf(output, '%d ', node);
        IX = src_txs(:, 2) == node & src_txs(:, SEQ_IDX) == seq;
        node = mode(src_txs(IX, PARENT_IDX));
        hop_cnt = hop_cnt + 1;
        path = [path node];
        if hop_cnt >= NTW_SIZE
            % loop
            break;
        end
    end
    pkt_paths(i, 1 : (hop_cnt + 1)) = path;
%     fprintf(output, '%d......\n', node);
    if (ROOT_ID == node)
        hop_cnts(i) = hop_cnt;
    end
end
% save('pkt_paths.mat', 'pkt_paths', 'hop_cnts');
hop_cnts = hop_cnts(hop_cnts > 0);
[x xout] = hist(hop_cnts);
h = bar(xout, x/sum(x));
title('hop counts hist');
saveas(h, 'hop counts hist', 'fig');
saveas(h, 'hop counts hist', 'jpg');
%%
save([dest 'TxRx.mat'], 'txs', 'rxs', 'debugs', 'intercepts', 'srcPkts', 'destPkts', 'rejs', 'uart_relis', ...
      'reliability', 'tx_cost', 'overflows', 'pkt_delays', 'app_send_fail_ratio', 'expires', 'hop_cnts', 'pkt_paths');
cd(dest);
% close all open files
fclose('all');
clear;
close all;
load('TxRx.mat');
open('output.txt');