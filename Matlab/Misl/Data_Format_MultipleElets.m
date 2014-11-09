%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Qiao Xiang @ Wayne State University, May 3rd, 2010
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




clear
clc

DirDelimiter='/';  %'/'; %\: windows    /: unix
srcDir = '~/Downloads/Jobs';
srcDir2 = '3770'; % Defined by users
srcDir3 = '';
dest = [srcDir DirDelimiter srcDir2 DirDelimiter srcDir3];
files = dir([dest '*.txt']);
EletPerLog = 7; % Defined by users


NUM_COLUMNS = 8 + 15 * EletPerLog;  % Number of Columns in Log
SENDER_DATA_FORMAT = repmat('%x ', 1, NUM_COLUMNS); % '%x' means HEX
Control_Data = 8; %Columns that are useless

%       XL
kickout1 = 0;
kickout2 = 0;
packet5Count = 0;
packet6Count = 0;
packet8Count = 0;

fcs_sizes = cell(130, 1);
pkt_times = cell(130, 1);
linkDelays = cell(130, 1);
% timeouts = [];
% queueDelays = [];
% engHacks1 = [];
% engHacks2 = [];
% all_pkt_time = [];
% nb_sizes = cell(129, 1);
% seqs = cell(129, 1);
totalPktsSent = 0;
% process_delays = [];
srcPkts = [];

for fileIndex = 1:length(files)
    indexedFile = files(fileIndex).name;
    fid = fopen([srcDir DirDelimiter srcDir2 DirDelimiter srcDir3 indexedFile]);
    Raw_Data = fscanf(fid, SENDER_DATA_FORMAT,[NUM_COLUMNS inf]);
    Raw_Data = Raw_Data';
%     disp (indexedFile);
    
    Entry_Num = size(Raw_Data, 1) * EletPerLog;
    
    if ~isempty(Raw_Data)
        Packet_Log = zeros(Entry_Num, 9);
        CurrentIndex = 0;
        for temp_Entry = 1:size(Raw_Data, 1)
            for temp_Ele = 1:EletPerLog
                Packet_Log((CurrentIndex + 1), 1) = Raw_Data(temp_Entry, 9 + (temp_Ele - 1) * 17);
                for index = 2:9
                    Packet_Log((CurrentIndex + 1), index) = Raw_Data(temp_Entry, (index - 1) * 2 + 8 + (temp_Ele - 1) * 17) * power(16, 2)...
                                                        + Raw_Data(temp_Entry, (index - 1) * 2 + 9 + (temp_Ele - 1) * 17) * power(16, 0);
                end
                CurrentIndex = CurrentIndex + 1;
            end
        end
        
        Unique_Packet_Log = unique(Packet_Log, 'rows', 'first');
%       XL
%         if ~isempty(find(Packet_Log(:, 1) ~= 1 & Packet_Log(:, 1) ~= 2 & Packet_Log(:, 1) ~= 3 ...
%                     & Packet_Log(:, 1) ~= 9 & Packet_Log(:, 1) ~= 10))
        nodeId = Packet_Log(1, 2);
              
        if ~isempty(find(Packet_Log(:, 1) == 4))
                falseFCs{nodeId + 1} = Packet_Log(find(Packet_Log(:, 1) == 4), :);
                disp (['False FC in ' indexedFile]);
        end        
        
        if ~isempty(find(Packet_Log(:, 1) == 5))
                SWFs{nodeId + 1} = Packet_Log(find(Packet_Log(:, 1) == 5), :);
                disp (['Sliding windown full in  ' indexedFile]);
        end
        
        if ~isempty(find(Packet_Log(:, 1) == 6))
                emptyFCSs{nodeId + 1} = Packet_Log(find(Packet_Log(:, 1) == 6), :);
                disp (['Empty FCS in  ' indexedFile]);
        end
        
        if ~isempty(find(Packet_Log(:, 1) == 15 | Packet_Log(:, 1) == 16))
                linkDelays{nodeId + 1} = Packet_Log(find(Packet_Log(:, 1) == 15 | Packet_Log(:, 1) == 16), :);
                disp (['link delays in  ' indexedFile]);
        end
%         if size(find(Packet_Log(:, 1) == 19 | Packet_Log(:, 1) == 20), 1) > 0
%             disp(['ACK suppressing dup']);
%         end
%         if size(find(Packet_Log(:, 1) == 17), 1) > 0
%             kickout2 = kickout2 + size(find(Packet_Log(:, 1) == 17), 1);
%             disp(['Contain' num2str(size(find(Packet_Log(:, 1) == 17), 1)) 'neighbor kick out 2']);
%         end

        % FCS size for packets
        fcs_size = [];
        if ~strcmp(indexedFile, ['Job' srcDir2 '-10.0.0.3-1.txt'])
            sentPkts = Packet_Log(find(Packet_Log(:, 1) == 9), :);
%             temp = unique(sentPkts(:, 4:9), 'rows');
            temp = sentPkts(:, 5:9);
            for i = 1 : size(temp, 1)
                fcs_size = [fcs_size; length(find(temp(i, :) ~= 255))];
            end
            
%             nb_size = Packet_Log(find(Packet_Log(:, 1) == 15 | Packet_Log(:, 1) == 16 | Packet_Log(:, 1) == 18), 1:4);
            
%             seq = Packet_Log(find(Packet_Log(:, 1) == 30), 3:4);
        end
        
        if ~isempty(find(fcs_size == 0))
            disp (['Empty FCS at node' num2str(Packet_Log(1, 2)) ' in file:' indexedFile]);
        end
%         if ~isempty(find(fcs_size ~= 1))
%             disp (['FCS size not 1 for L-ETX at node' num2str(Packet_Log(1, 2)) ' in file:' indexedFile]);
%         end
        fcs_sizes{nodeId + 1} = fcs_size;
        
        % process delay
%         process_delay = Packet_Log(find(Packet_Log(:, 1) == 12), 3);
%         process_delays = [process_delays; process_delay];
        % packet time
%         pkt_time = Packet_Log(find(Packet_Log(:, 1) == 11), 3:4);
%         pkt_times{nodeId} = pkt_time;
%         all_pkt_time = [all_pkt_time; pkt_time];
%         if ~isempty(nb_size)
%             disp (['Node' num2str(Packet_Log(1, 2)) 'contains nb size info in file:' indexedFile]);
%         end
%         nb_sizes{nodeId} = nb_size;
%         
%         seqs{nodeId} = seq;
        
        %  retx timeout
        %[retxtime - 2; current turn round time estimation]
%         timeout = Packet_Log(find(Packet_Log(:, 1) == 15), 3:4);
%         timeouts = [timeouts; timeout];

        %  queueing delay
        % [current queue delay estimation; delay sample]
%         queueDelay = Packet_Log(find(Packet_Log(:, 1) == 12), 3:4);
%         queueDelays = [queueDelays; queueDelay];
        
        %   hacks
%         engHack1 = Packet_Log(find(Packet_Log(:, 1) == 19), 3:4);
%         engHacks1 = [engHacks1; engHack1];
%         engHack2 = Packet_Log(find(Packet_Log(:, 1) == 20), 3:4);
%         engHacks2 = [engHacks2; engHack2];
%         POIs = [16, 17, 18];
%         if size(find(Packet_Log(:, 1) == POIs(1)), 1) > 0
%             packet5Count = packet5Count + size(find(Packet_Log(:, 1) == POIs(1)), 1);
%             disp (['Contains ' num2str(size(find(Packet_Log(:, 1) == POIs(1)), 1)) ' not in nb table, in total: ' num2str(packet5Count)]);
% %             disp (['Contains ' num2str(size(find(Packet_Log(:, 1) == 5),
% %             1)) ' SWF packets, in total: ' num2str(packet5Count)]);
%         end
% 
%         if size(find(Packet_Log(:, 1) == POIs(2)), 1) > 0
%             packet6Count = packet6Count + size(find(Packet_Log(:, 1) == POIs(2)), 1);
%             disp (['Contains ' num2str(size(find(Packet_Log(:, 1) == POIs(2)), 1)) ' not in rcver window, in total: ' num2str(packet6Count)]);
%         end
% 
%         if size(find(Packet_Log(:, 1) == POIs(3)), 1) > 0
%             packet8Count = packet8Count + size(find(Packet_Log(:, 1) == POIs(3)), 1);
%             disp (['Contains ' num2str(size(find(Packet_Log(:, 1) == POIs(3)), 1)) ' capacity dec, in total: ' num2str(packet8Count)]);
%         end
%         end
%       ~XL
        
        [pathstr, prename, ext, versn] = fileparts(indexedFile);
        save([srcDir DirDelimiter srcDir2 DirDelimiter srcDir3 prename '.mat'], 'Packet_Log', 'Unique_Packet_Log');

%         if strcmp(indexedFile, ['Job' srcDir2 '-10.0.0.5-4.txt'])
        if nodeId == 69 %|| nodeId == 8 || nodeId == 22
            disp('Source:');
%             unique(Packet_Log(:, 1), 'rows')
            sendCounts = size(unique(Packet_Log(find(Packet_Log(:, 1) == 1), 3:4), 'rows'), 1);
            srcPkts = [srcPkts; unique(Packet_Log(find(Packet_Log(:, 1) == 1), 3:4), 'rows')];
            disp(['Total packets sent:' num2str(sendCounts)]);
            
            totalPktsSent = totalPktsSent + sendCounts;
        end

%         if strcmp(indexedFile, ['Job' srcDir2 '-10.0.0.3-1.txt'])
        if nodeId == 117  
            disp('Base Station:');
            unique(Packet_Log(:, 1), 'rows')
            rcvCounts = size(unique(Packet_Log(find(Packet_Log(:, 1) == 3), 3:4), 'rows'), 1);
            destPkts = unique(Packet_Log(find(Packet_Log(:, 1) == 3), 3:4), 'rows');
            disp(['Total packets received:' num2str(rcvCounts)]);
        end

        disp (['Done with ' indexedFile ', go to next']);
    else
        disp (['File ' indexedFile ' is empty, go to next']);
    end
end
% disp(['Total kickout1 = ' num2str(kickout1)]);
% disp(['Total kickout2 = ' num2str(kickout2)]);
% if sendCounts ~= 0
%     disp(['Reliability for job' srcDir2 ':' num2str(rcvCounts / sendCounts)]);
% end
disp(['total packets received: ' num2str(rcvCounts) ', total packets sent: ' num2str(totalPktsSent)]);
if totalPktsSent ~= 0
    disp(['Reliability for job' srcDir2 ':' num2str(rcvCounts / totalPktsSent)]);
end

save([dest 'linkDelays.mat'], 'linkDelays'); 
% save([dest 'timeouts.mat'], 'timeouts');
% save([dest 'queueDelays.mat'], 'queueDelays');
% save([dest 'pkt_time.mat'], 'all_pkt_time', 'pkt_times');
save([dest 'TxRx.mat'], 'rcvCounts', 'totalPktsSent', 'srcPkts', 'destPkts'); 
clear;