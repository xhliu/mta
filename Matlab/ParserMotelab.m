%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Xiaohui Liu (whulxh@gmail.com)
%   Date:   2/12/2011
%   Function: parse raw data from Motelab / Indriya
%   Attention: MUST remove the table header at first line
%   [TX/RX; NodeID; SourceID; SeqNum; Last_Hop_Sender; Last_Hop_Ntw_Seq; Last_Hop_MAC_Seq; Local_Ntw_Seq;
%   Local_MAC_Seq; Timestamp, serial_seqno]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
clear;
clc;

SEND_FLAG = 1;
RCV_FLAG = 3;
INTERCEPT_FLAG = 2;
TX_FLAG = 9;
RX_FLAG = 10;
% UNICAST_IDX = 15;
DEBUG_FLAG = 255;
ROOT_ID = 58;
srcDirs = '';
SW_FULL_FLAG = 5;

DirDelimiter = '/';
job = 16434;
% remove first line!!!!!
% srcDir = ['~/Downloads/' num2str(job)];
% srcDir = ['~/Downloads/Motelab/data-' num2str(job)];
srcDir = ['~/Projects/tOR/RawData/data-' num2str(job)];

dest = [srcDir DirDelimiter];
fid = fopen([dest '7857.dat']);

COLUMNS_PER_PKT = 11;   %16
PKT_CNTS = 5;   %4
NUM_COLUMNS = COLUMNS_PER_PKT * PKT_CNTS;
SENDER_DATA_FORMAT = repmat('%u ', 1, NUM_COLUMNS); % '%x' means HEX
% 2011-02-12 22:10:36
% CONTROL_FORMAT = repmat('%s ', 1, 4);
CONTROL_FORMAT = '%u-%u-%u %u:%u:%u %u %u';
SENDER_DATA_FORMAT = [SENDER_DATA_FORMAT CONTROL_FORMAT];
% for fileIndex = 1:length(files)
%     fileIndex = 1;
%     indexedFile = files(fileIndex).name;
% preallocation
MAX_ENTRIES = 1000000;
Colmn_Packet = COLUMNS_PER_PKT;
debugs = zeros(MAX_ENTRIES, COLUMNS_PER_PKT);
debugs_cnts = 1;
txs = zeros(MAX_ENTRIES, Colmn_Packet);
txs_cnts = 1;

rxs = zeros(MAX_ENTRIES, Colmn_Packet);
rxs_cnts = 1;

intercepts = zeros(MAX_ENTRIES, Colmn_Packet);
intercepts_cnts = 1;

srcPkts = [];


    Raw_Data = fscanf(fid, SENDER_DATA_FORMAT, [NUM_COLUMNS + 8, inf]);
    fclose(fid);
    Raw_Data = Raw_Data';
%     disp (['Loading file ' indexedFile]);
    
    len = size(Raw_Data, 1);
    Packet_Log = zeros(len * PKT_CNTS, COLUMNS_PER_PKT);
    for i = 1 : PKT_CNTS
        lo = (i - 1) * len + 1;
        high = i * len;
        left = (i - 1) * COLUMNS_PER_PKT + 1;
        right = i * COLUMNS_PER_PKT;
        Packet_Log(lo : high, :) = Raw_Data(:, left : right);
    end
    len = length(find(Packet_Log(:, 1) == DEBUG_FLAG));
    debugs(debugs_cnts : debugs_cnts + len - 1, :) = Packet_Log(Packet_Log(:, 1) == DEBUG_FLAG, :);
    debugs_cnts = debugs_cnts + len;  
% end

if ~isempty(find(Packet_Log(:, 1) == SW_FULL_FLAG, 1))
    disp('sliding window full')
end
txs = Packet_Log(Packet_Log(:, 1) == TX_FLAG, :);
rxs = Packet_Log(Packet_Log(:, 1) == RX_FLAG, :);

cd(dest);

srcPkts = unique(Packet_Log(Packet_Log(:, 1) == SEND_FLAG, :), 'rows');
destPkts = unique(Packet_Log(Packet_Log(:, 1) == RCV_FLAG, :), 'rows');

% ignore base station 
nonroot_txs = txs(txs(:, 2) ~= ROOT_ID, :);
unique_txs = unique(nonroot_txs(:, 3:4), 'rows');
sendCounts = size(unique_txs, 1);

unique_rxs = unique(rxs(rxs(:, 2) == ROOT_ID, 3:4), 'rows');
rcvCounts = size(unique_rxs, 1);
disp(['total packets received: ' num2str(rcvCounts) ', total packets sent: ' num2str(sendCounts)]);
if sendCounts ~= 0
    disp(['Reliability : ' num2str(rcvCounts / sendCounts)]);
%     disp(['OR percentage: ' num2str(length(find(nonroot_txs(:, UNICAST_IDX) == 0)) / size(nonroot_txs, 1))]);
end
if rcvCounts ~= 0
    disp(['tx cost for job' num2str(job) ': ' num2str(size(nonroot_txs, 1) / rcvCounts) ', ' num2str(size(nonroot_txs, 1)) ' out of ' num2str(rcvCounts)]);
end
debugs(debugs_cnts : end, :) = [];
save('TxRx.mat', 'txs', 'rxs', 'debugs', 'srcPkts', 'destPkts');
% save('debugs.mat', 'debugs');
clear;