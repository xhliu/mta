%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Qiao Xiang @ Wayne State University, May 27th, 2010
%   Contact: du4641@wayne.edu
%
%   This program is designed to calculate of each link'r reliability in
%   tOR.
%
%   To use this program, users need to change the value of srcDir and srcDir2.
%
%   In the output mat file, matrix ReliabilityMatrix recorded a 5-element
%   tuple for each link, (Sender, Receiver, # of Transmissions, # of
%   Receptions, Reliability). If the Receiver attribute is 88888, it
%   implies that there is no link from the corresponsing Sender.
%
%   Revised on June 2nd, 2010: Whenk sink is transmitting, the Forward
%   Candidate set will contain only node 65536, which is a virtual one. The
%   program added a check on this scenario.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


clear
clc


DirDelimiter='/';  %'/'; %\: windows    /: unix
srcDir = '~/Downloads/Jobs';
srcDir2 = '3536';
srcDir3 = '';



SensorIPTable = {'10.0.0.1-5', '10.0.0.1-7', '10.0.0.1-11', '10.0.0.4-6', '10.0.0.4-5', '10.0.0.7-0', '10.0.0.7-10', '10.0.0.7-9', '10.0.0.10-4', '10.0.0.10-5', '10.0.0.13-4', '10.0.0.13-5', '10.0.0.13-0'...
                '10.0.0.1-9', '10.0.0.1-10', '10.0.0.1-6', '10.0.0.4-4', '10.0.0.4-2', '10.0.0.7-2', '10.0.0.7-1', '10.0.0.7-7', '10.0.0.10-0', '10.0.0.10-2', '10.0.0.13-3', '10.0.0.13-2', '10.0.0.13-1'...
                '10.0.0.1-8', '10.0.0.1-2', '10.0.0.1-3', '10.0.0.4-0', '10.0.0.4-3', '10.0.0.7-3', '10.0.0.7-5', '10.0.0.7-8', '10.0.0.10-3', '10.0.0.10-6', '10.0.0.13-10', '10.0.0.13-11', '10.0.0.13-8'...
                '10.0.0.1-0', '10.0.0.1-1', '10.0.0.1-4', '10.0.0.4-1', '10.0.0.5-6', '10.0.0.7-6', '10.0.0.7-4', '10.0.0.7-11', '10.0.0.11-5', '10.0.0.10-1', '10.0.0.13-7', '10.0.0.13-6', '10.0.0.13-9'...
                '10.0.0.2-5', '10.0.0.2-4', '10.0.0.2-2', '10.0.0.5-2', '10.0.0.5-5', '10.0.0.8-3', '10.0.0.8-4', '10.0.0.8-2', '10.0.0.11-1', '10.0.0.11-2', '10.0.0.14-5', '10.0.0.14-3', '10.0.0.14-4'...
                '10.0.0.2-0', '10.0.0.2-3', '10.0.0.2-1', '10.0.0.5-0', '10.0.0.5-4', '10.0.0.8-1', '10.0.0.8-5', '10.0.0.8-0', '10.0.0.11-4', '10.0.0.11-6', '10.0.0.14-2', '10.0.0.14-1', '10.0.0.14-0'...
                '10.0.0.3-6', '10.0.0.3-11', '10.0.0.3-8', '10.0.0.5-3', '10.0.0.5-1', '10.0.0.9-1', '10.0.0.9-0', '10.0.0.9-6', '10.0.0.11-3', '10.0.0.11-0', '10.0.0.15-5', '10.0.0.15-0', '10.0.0.15-2'...
                '10.0.0.3-7', '10.0.0.3-9', '10.0.0.3-10', '10.0.0.6-4', '10.0.0.6-5', '10.0.0.9-2', '10.0.0.9-7', '10.0.0.9-10', '10.0.0.12-5', '10.0.0.12-2', '10.0.0.15-1', '10.0.0.15-3', '10.0.0.15-4'...
                '10.0.0.3-3', '10.0.0.3-2', '10.0.0.3-0', '10.0.0.6-2', '10.0.0.6-3', '10.0.0.9-4', '10.0.0.9-8', '10.0.0.9-9', '10.0.0.12-3', '10.0.0.12-1', '10.0.0.15-10', '10.0.0.15-9', '10.0.0.15-7'...
                '10.0.0.3-1', '10.0.0.3-5', '10.0.0.3-4', '10.0.0.6-0', '10.0.0.6-1', '10.0.0.9-3', '10.0.0.9-5', '10.0.0.9-11', '10.0.0.12-4', '10.0.0.12-0', '10.0.0.15-11', '10.0.0.15-6', '10.0.0.15-8'};


MaxNodeID = 129;

ReliabilityMatrix = zeros(1, 5);
RMIndex = 0;
for Sender = 1:130
    if exist ([srcDir DirDelimiter srcDir2 DirDelimiter srcDir3 'Job' srcDir2 '-' cell2mat(SensorIPTable(1, Sender)) '.mat']) == 0
        disp ([srcDir2 '-' cell2mat(SensorIPTable(1, Sender)) '.mat does not exist']);
    else
        load ([srcDir DirDelimiter srcDir2 DirDelimiter srcDir3 'Job' srcDir2 '-' cell2mat(SensorIPTable(1, Sender)) '.mat']);
        disp (['Loading ' srcDir2 '-' cell2mat(SensorIPTable(1, Sender)) '.mat']);
        MReceivers = Packet_Log(find(Packet_Log(:,1) == 9), 5:9);   %9 Transmission   10 Reception
        Receivers = 88888;  %Default, meaning no link
        for i = 1:size(MReceivers, 1)
            if i == 1
                Receivers = MReceivers(i,find(MReceivers(i, :) ~= 65535));
            else
                Receivers = horzcat(Receivers, MReceivers(i,find(MReceivers(i, :) ~= 65535)));
            end
        end
        Receivers = unique(Receivers);
        NumTrans = size(find(Packet_Log(:,1) == 9), 1);
        if size(Receivers, 1) ~=0
            for i = 1:size(Receivers, 2)
                ReliabilityMatrix(RMIndex+i, 1:3) = [Sender-1 Receivers(1, i) NumTrans];
            end
        else
            disp (['The node ' num2str(Sender) ' is transmitting to 65535'])
        end
        RMIndex = size(ReliabilityMatrix, 1);
    end
end

disp 'Done with the transmission calculation';

for i = 1:RMIndex
    if ReliabilityMatrix(i, 2) <= MaxNodeID   
        if exist ([srcDir DirDelimiter srcDir2 DirDelimiter srcDir3 'Job' srcDir2 '-' cell2mat(SensorIPTable(1, ReliabilityMatrix(i, 2) + 1)) '.mat']) == 0
            disp ([srcDir2 '-' cell2mat(SensorIPTable(1, ReliabilityMatrix(i, 2) + 1)) '.mat does not exist']);
        else
            load ([srcDir DirDelimiter srcDir2 DirDelimiter srcDir3 'Job' srcDir2 '-' cell2mat(SensorIPTable(1, ReliabilityMatrix(i, 2) + 1)) '.mat']);
            disp (['Loading ' srcDir2 '-' cell2mat(SensorIPTable(1, ReliabilityMatrix(i, 2) + 1)) '.mat']);
            ReliabilityMatrix(i, 4) = size(find(Packet_Log(:,1) == 10 & Packet_Log(:,5) == ReliabilityMatrix(i, 1)), 1);
            ReliabilityMatrix(i, 5) = ReliabilityMatrix(i, 4) / ReliabilityMatrix(i, 3);
        end
    end
end

save([srcDir DirDelimiter srcDir2 DirDelimiter srcDir2 '-AllLinkReliability.mat'], 'ReliabilityMatrix');






