%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Qiao Xiang @ Wayne State University, July 9th, 2010
%   Contact: du4641@wayne.edu
%
%   This program is designed to format data from raw txt files into mat
%   files when each entry contains multiple packet logs.
%
%   To use this program, users need to change the value of srcDir2 and EletPerLog.
%
%   For details about the log format, please refer to the excel file named
%   Data Format.xlsx which is stored in the same folder with this program.
%
%   Note that to ease the use of other existing matlab files, the formatted
%   log in matlab is different from the one showed in excel file.
%   Currently, from 1st column to the rightmost one, the log in m file is
%   as follows:
%   [TX/RX; NodeID; SourceID; SeqNum; FC1; FC2; FC3; FC4; FC5;
%   Last_Hop_Sender; Last_Hop_Sender_Seq; Local_Seq]
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




clear
clc

% DirDelimiter='\';  %'/'; %\: windows    /: unix
% srcDir = 'C:\Documents and Settings\Qiao Xiang\My Documents\MATLAB\RTSS 2010';
% srcDir2 = '3771'; % Defined by users
% srcDir3 = 'raw data\';
% files = dir([srcDir DirDelimiter srcDir2 DirDelimiter srcDir3 '*.txt']);
% EletPerLog = 7; % Defined by users
DirDelimiter='/';  %'/'; %\: windows    /: unix
srcDir = '~/Downloads/Jobs';
srcDir2 = '3826'; % Defined by users
srcDir3 = '';
dest = [srcDir DirDelimiter srcDir2 srcDir3 DirDelimiter];
files = dir([dest '*.txt']);
EletPerLog = 7;

SW_FULL_FLAG = 5;
FLOW_REJECT_FLAG = 6;
RT_OUT_RANGE_FLAG = 7;
EXPIRATION_FLAG = 8;
MIN_DELAY_FLAG = 13;
CO_DELAY_FLAG = 14;
LINK_DELAY_FLAG = 16;
RETURN_FLAG = 17;

BEACON_LOWER_FLAG = 18;
BEACON_UPPER_FLAG = 26;

Num_Tx = 1;
Num_NodeID = 1;
Num_SourceID = 1;
Num_SeqNum = 2;
Num_FC_each = 1;
Num_FC = 5;
% Num_TimeStamp = 4;
Num_LastSender = 1;
Num_LastSenderSeq = 2;
Num_LocalSeq = 2;


Num_PerElet = Num_Tx + Num_NodeID + Num_SourceID + Num_SeqNum + Num_FC_each * Num_FC + Num_LastSender + Num_LastSenderSeq + Num_LocalSeq;

Control_Data = 8; %Columns that are useless
NUM_COLUMNS = Control_Data + Num_PerElet * EletPerLog;  % Number of Columns in Log
SENDER_DATA_FORMAT = repmat('%x ', 1, NUM_COLUMNS); % '%x' means HEX

totalPktsSent = 0;
% process_delays = [];
srcPkts = [];
flowRejs = cell(130, 1);
SWFs = cell(130, 1);
expiredPkts = cell(130, 1);
minDelays = cell(130, 1);
sampleDelays = cell(130, 1);
coorDelays = cell(130, 1);
returnOPFs = cell(130, 1);
beacons = cell(130, 1);

for fileIndex = 1:length(files)
    indexedFile = files(fileIndex).name;
    fid = fopen([srcDir DirDelimiter srcDir2 DirDelimiter srcDir3 indexedFile]);
    Raw_Data = fscanf(fid, SENDER_DATA_FORMAT,[NUM_COLUMNS inf]);
    Raw_Data = Raw_Data';
    disp (['Loading file ' indexedFile]);
    
    Entry_Num = size(Raw_Data, 1) * EletPerLog;
    
    if ~isempty(Raw_Data)
        Packet_Log = zeros(Entry_Num, 12);
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
                Current_R_Index = Current_R_Index + Num_SeqNum + Num_LastSender + Num_LastSenderSeq + Num_LocalSeq;   %Jump New Columns
                PL_Index = PL_Index + 1;
                
                for j = 1:1:Num_FC        %FC Set
                    for i = 1:1:Num_FC_each
                        Packet_Log((CurrentIndex + 1), PL_Index) = Packet_Log((CurrentIndex + 1), PL_Index) +...
                                                            Raw_Data(temp_Entry, (temp_Ele - 1) * Num_PerElet + Control_Data + Current_R_Index + i) * power(16, (Num_FC_each - i) * 2);
                    end
                    Current_R_Index = Current_R_Index + Num_FC_each;
                    PL_Index = PL_Index + 1;
                end
                
                %%Adding New Columns
                Current_R_Index = Current_R_Index - Num_FC * Num_FC_each - (Num_LastSender + Num_LastSenderSeq + Num_LocalSeq);
                for i = 1:1:Num_LastSender    %Last Hop Sender
                    Packet_Log((CurrentIndex + 1), PL_Index) = Packet_Log((CurrentIndex + 1), PL_Index) +...
                                                        Raw_Data(temp_Entry, (temp_Ele - 1) * Num_PerElet + Control_Data + Current_R_Index + i) * power(16, (Num_LastSender - i) * 2);
                end
                Current_R_Index = Current_R_Index + Num_LastSender;
                PL_Index = PL_Index + 1;
                
                for i = 1:1:Num_LastSenderSeq    %Last Hop Sender Sequence Number
                    Packet_Log((CurrentIndex + 1), PL_Index) = Packet_Log((CurrentIndex + 1), PL_Index) +...
                                                        Raw_Data(temp_Entry, (temp_Ele - 1) * Num_PerElet + Control_Data + Current_R_Index + i) * power(16, (Num_LastSenderSeq - i) * 2);
                end
                Current_R_Index = Current_R_Index + Num_LastSenderSeq;
                PL_Index = PL_Index + 1;
                
                for i = 1:1:Num_LocalSeq    %Local Sequence Number
                    Packet_Log((CurrentIndex + 1), PL_Index) = Packet_Log((CurrentIndex + 1), PL_Index) +...
                                                        Raw_Data(temp_Entry, (temp_Ele - 1) * Num_PerElet + Control_Data + Current_R_Index + i) * power(16, (Num_LocalSeq - i) * 2);
                end
                Current_R_Index = Current_R_Index + Num_LocalSeq;
                PL_Index = PL_Index + 1;
                
                CurrentIndex = CurrentIndex + 1;
                Current_R_Index = Current_R_Index + Num_FC * Num_FC_each;   %Add back to the latest index
                Current_R_Index = 0;
            end
        end
        
        Unique_Packet_Log = unique(Packet_Log, 'rows', 'first');
        [pathstr, prename, ext, versn] = fileparts(indexedFile);
        save([srcDir DirDelimiter srcDir2 DirDelimiter srcDir3 prename '.mat'], 'Packet_Log', 'Unique_Packet_Log');
        
        nodeId = Packet_Log(1, 2);
        valid_log = [Packet_Log(:, 1), Packet_Log(:, 4), Packet_Log(:, 12)];
        if nodeId == 69 %|| nodeId == 8 || nodeId == 22
%             disp('Source:');
%             unique(Packet_Log(:, 1), 'rows')
            sentPackets = unique(valid_log(find(valid_log(:, 1) == 1), 2:3), 'rows');
            sendCounts = size(sentPackets, 1);
%             sendCounts = size(unique(Packet_Log(find(Packet_Log(:, 1) == 1), 3:4), 'rows'), 1);
            srcPkts = [srcPkts; sentPackets];
            disp(['Total packets sent:' num2str(sendCounts)]);
            
            totalPktsSent = totalPktsSent + sendCounts;
        end

%         if strcmp(indexedFile, ['Job' srcDir2 '-10.0.0.3-1.txt'])
        if nodeId == 117  
%             disp('Base Station:');
%             unique(Packet_Log(:, 1), 'rows')
            destPkts = unique(valid_log(find(valid_log(:, 1) == 3), 2:3), 'rows');
            rcvCounts = size(destPkts, 1);
            disp(['Total packets received:' num2str(rcvCounts)]);
        end
        
        if ~isempty(find(valid_log(:, 1) == FLOW_REJECT_FLAG))
                flowRejs{nodeId + 1} = valid_log(find(valid_log(:, 1) == FLOW_REJECT_FLAG), :);
                disp (['Flow rejcted in ' indexedFile]);
        end        
        
        if ~isempty(find(valid_log(:, 1) == SW_FULL_FLAG))
                SWFs{nodeId + 1} = valid_log(find(valid_log(:, 1) == SW_FULL_FLAG), :);
                disp (['Sliding windown full in  ' indexedFile]);
        end
        
        if ~isempty(find(valid_log(:, 1) == RT_OUT_RANGE_FLAG))
%                 emptyFCSs{nodeId + 1} = valid_log(find(valid_log(:, 1) == RT_OUT_RANGE_FLAG), :);
                disp (['RT out of range in ' indexedFile]);
        end
        
        if ~isempty(find(valid_log(:, 1) == EXPIRATION_FLAG))
                expiredPkts{nodeId + 1} = valid_log(find(valid_log(:, 1) == EXPIRATION_FLAG), :);
                disp (['packets expire in  ' indexedFile]);
        end

        if ~isempty(find(valid_log(:, 1) == MIN_DELAY_FLAG))
                minDelays{nodeId + 1} = valid_log(find(valid_log(:, 1) == MIN_DELAY_FLAG), :);
%                 disp (['packets expire in  ' indexedFile]);
        end
        
        if ~isempty(find(valid_log(:, 1) == LINK_DELAY_FLAG))
                sampleDelays{nodeId + 1} = valid_log(find(valid_log(:, 1) == LINK_DELAY_FLAG), :);
%                 disp (['packets expire in  ' indexedFile]);
        end
        
        if ~isempty(find(valid_log(:, 1) == CO_DELAY_FLAG))
                coorDelays{nodeId + 1} = valid_log(find(valid_log(:, 1) == CO_DELAY_FLAG), :);
%                 disp (['packets expire in  ' indexedFile]);
        end
        
        if ~isempty(find(valid_log(:, 1) == RETURN_FLAG))
                returnOPFs{nodeId + 1} = valid_log(find(valid_log(:, 1) == RETURN_FLAG), :);
%                 disp (['packets expire in  ' indexedFile]);
        end
        
        beaconIX = find(valid_log(:, 1) >= BEACON_LOWER_FLAG & valid_log(:, 1) <= BEACON_UPPER_FLAG);
        if ~isempty(beaconIX)
                beacons{nodeId + 1} = valid_log(beaconIX, :);
%                 disp (['packets expire in  ' indexedFile]);
        end
        disp (['Done with ' indexedFile ', go to next']);
    else
        disp (['File ' indexedFile ' is empty, go to next']);
    end
end

% disp(['total packets received: ' num2str(rcvCounts) ', total packets sent: ' num2str(totalPktsSent)]);
% if totalPktsSent ~= 0
%     disp(['Reliability for job' srcDir2 ':' num2str(rcvCounts / totalPktsSent)]);
% end

save([dest 'packetsDrop.mat'], 'flowRejs', 'SWFs', 'expiredPkts'); 
save([dest 'delays.mat'], 'minDelays', 'sampleDelays', 'coorDelays', 'returnOPFs', 'beacons'); 
save([dest 'TxRx.mat'], 'rcvCounts', 'totalPktsSent', 'srcPkts', 'destPkts');
clear;