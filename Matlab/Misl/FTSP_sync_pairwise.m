%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Qiao Xiang @ Wayne State University, June 18th, 2010
%   Contact: du4641@wayne.edu
%
%   This program is designed to check how FTSP is synced and converged.
%
%   To use this program, users need to change the value of srcDir and
%   srcDir2. This program also calls a external function called maximize,
%   which means users should also put maximize.m together with this file in
%   the same folder.
%
%   The output of this program contains a mat file and several figures.
%   The mat file records information about average sync difference, max
%   sync difference and sync ratio for each round(counter). More details can be
%   found in figures.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


clear
clc


DirDelimiter='/';  %'/'; %\: windows    /: unix
srcDir = '~/Downloads/Jobs';
srcDir2 = '106';   %Defined by users
srcDir3 = '';

files = dir([srcDir DirDelimiter srcDir2 DirDelimiter srcDir3 '*.mat']);

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
Nodes_Prtd = 129;

Num_Counter = 0;
for fileIndex = 1:length(files)
    indexedFile = files(fileIndex).name;
    load ([srcDir DirDelimiter srcDir2 DirDelimiter srcDir3 indexedFile]);
    if Num_Counter < max(Packet_Log(:, 4));
        Num_Counter = max(Packet_Log(:, 4));
    end
end
disp (['The number of counter is ' num2str(Num_Counter)]);


Pairwise_Dif = zeros(Num_Counter, (MaxNodeID + 1) * MaxNodeID / 2);
Pairwise_Sttt = zeros(Num_Counter, 4);  %# of pairs, Ave dif, Max dif, Sync ratio
Sync_Cnt = zeros(Num_Counter, 1);

for Current_Cntr = 1:Num_Counter
    Current_Pair = 1;
    for NodeID = 0:129
        if exist ([srcDir DirDelimiter srcDir2 DirDelimiter srcDir3 'Job' srcDir2 '-' cell2mat(SensorIPTable(1, NodeID + 1)) '.mat']) == 0
            disp ([srcDir2 '-' cell2mat(SensorIPTable(1, NodeID + 1)) '.mat does not exist']);
        else
            load ([srcDir DirDelimiter srcDir2 DirDelimiter srcDir3 'Job' srcDir2 '-' cell2mat(SensorIPTable(1, NodeID + 1)) '.mat']);
            Std_Time = Packet_Log(find(Packet_Log(:, 4) == Current_Cntr), 1);
            
            if ~isempty(Std_Time)
                if Packet_Log(find(Packet_Log(:, 4) == Current_Cntr), 2) == 0
                    Sync_Cnt(Current_Cntr, 1) = Sync_Cnt(Current_Cntr, 1) + 1;  %Count Synced Nodes
                end


                if NodeID < 129
                    for SndNodeID = (NodeID + 1):129
                        if exist ([srcDir DirDelimiter srcDir2 DirDelimiter srcDir3 'Job' srcDir2 '-' cell2mat(SensorIPTable(1, SndNodeID + 1)) '.mat']) == 0
                            disp ([srcDir2 '-' cell2mat(SensorIPTable(1, SndNodeID + 1)) '.mat does not exist']);
                        else
                            load ([srcDir DirDelimiter srcDir2 DirDelimiter srcDir3 'Job' srcDir2 '-' cell2mat(SensorIPTable(1, SndNodeID + 1)) '.mat']);
                            Tgt_Time = Packet_Log(find(Packet_Log(:, 4) == Current_Cntr), 1);
                            if ~isempty(Tgt_Time)
                                Pairwise_Dif(Current_Cntr, Current_Pair) = abs(Std_Time - Tgt_Time);
                                Current_Pair = Current_Pair + 1;
                            end
                        end
                    end
                end
            end
        end
    end
    Pairwise_Sttt(Current_Cntr, 1) = Current_Pair - 1;
    Pairwise_Sttt(Current_Cntr, 2) = mean(Pairwise_Dif(Current_Cntr, 1:(Current_Pair - 1)));
    Pairwise_Sttt(Current_Cntr, 3) = max(Pairwise_Dif(Current_Cntr, 1:(Current_Pair - 1)));
    Pairwise_Sttt(Current_Cntr, 4) = Sync_Cnt(Current_Cntr, 1) / Nodes_Prtd;
    disp (['Doen with the round ' num2str(Current_Cntr)]);
end

save([srcDir DirDelimiter srcDir2 DirDelimiter 'FTSP_Pairwise_', srcDir2 '.mat'], 'Num_Counter', 'Pairwise_Sttt', 'Pairwise_Dif')

bar(Pairwise_Sttt(:,2));
set(gca, 'XTick', [1:10:Num_Counter]);
grid on;
colormap summer;
legend ('Mean Pairwise Diff');
maximize(gcf);
saveas(gcf, [srcDir DirDelimiter srcDir2 DirDelimiter 'FTSP_Pairwise_', srcDir2 'Ave_Dif.fig']);
% saveas(gcf, [srcDir DirDelimiter srcDir2 DirDelimiter 'FTSP_Pairwise_', srcDir2 'Ave_Dif.emf']);
close;

bar(Pairwise_Sttt(:,3));
set(gca, 'XTick', [1:10:Num_Counter]);
grid on;
colormap spring;
legend ('Max Pairwise Diff');
maximize(gcf);
saveas(gcf, [srcDir DirDelimiter srcDir2 DirDelimiter 'FTSP_Pairwise_', srcDir2 'Max_Dif.fig']);
% saveas(gcf, [srcDir DirDelimiter srcDir2 DirDelimiter 'FTSP_Pairwise_', srcDir2 'Max_Dif.emf']);
close;

bar(Pairwise_Sttt(:,4));
set(gca, 'XTick', [1:10:Num_Counter]);
grid on;
colormap autumn;
legend ('Sync Ratio');
maximize(gcf);
saveas(gcf, [srcDir DirDelimiter srcDir2 DirDelimiter 'FTSP_Pairwise_', srcDir2 'Sync_Ratio.fig']);
% saveas(gcf, [srcDir DirDelimiter srcDir2 DirDelimiter 'FTSP_Pairwise_', srcDir2 'Sync_Ratio.emf']);
close;













