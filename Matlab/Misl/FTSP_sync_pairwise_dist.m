%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Qiao Xiang @ Wayne State University, June 23rd, 2010
%   Contact: du4641@wayne.edu
%
%   This program is designed to calculate the global time differences between synced 
%   nodes, and between unsynced nodes in FTSP after the first time FTSP converged.
%
%   To define convergence, users can change the value of Threshold to
%   define FTSP converged when Threshold * 100% nodes are synced.
%
%   To use this program, users need to change the value of Threshold, srcDir and
%   srcDir2 respectively. 
%
%   The output of this program contains a mat file including the
%   information about in which counter FTSP first converged and {the time
%   differences between synced nodes, and between unsynced nodes in each
%   counter from the first convergence.}
%   
%   For a 3-hour experiment, this program may take about one hour to get all
%   data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear
clc


DirDelimiter='\';  %'/'; %\: windows    /: unix
srcDir = 'C:\Documents and Settings\Qiao Xiang\My Documents\MATLAB\RTSS 2010';
srcDir2 = '3585';   %Defined by users
srcDir3 = 'raw data\';
Threshold = 0.92;


load ([srcDir DirDelimiter srcDir2 DirDelimiter 'FTSP_Pairwise_', srcDir2 '.mat']);

Counter_Synced = find(Pairwise_Sttt(:,4) >= Threshold, 1, 'first');

Synced_Diff = cell(1, Num_Counter- Counter_Synced + 1);
Unsynced_Diff = cell(1, Num_Counter- Counter_Synced + 1);

disp (['First Sycned Counter is ' num2str(Counter_Synced)]);

for i = Counter_Synced:Num_Counter
    Synced_Mtrx = zeros(1, 1);
    Synced_Index = 1;
    Unsynced_Mtrx = zeros(1, 1);
    Unsynced_Index = 1;
    
    for NodeID = 0:129
        if NodeID < 129
            if isempty(cell2mat(Cell_PacketLog(1, NodeID + 1))) == 0
                temp_1 = cell2mat(Cell_PacketLog(1, NodeID + 1));
                for SndNodeID = (NodeID+1):129
                    if isempty(cell2mat(Cell_PacketLog(1, SndNodeID + 1))) == 0
                        temp_2 = cell2mat(Cell_PacketLog(1, SndNodeID + 1));
                        if isempty(find(temp_1(:, 4) == i & temp_1(:, 2) == 0)) == 0  && isempty(find(temp_2(:, 4) == i & temp_2(:, 2) == 0)) == 0
                            Sync_Std_Time = temp_1(find(temp_1(:, 4) == i & temp_1(:, 2) == 0), 1);
                            Sync_Tgt_Time = temp_2(find(temp_2(:, 4) == i & temp_2(:, 2) == 0), 1);
                            Synced_Mtrx(1, Synced_Index) = abs(Sync_Std_Time - Sync_Tgt_Time);
                            Synced_Index = Synced_Index + 1;
                        else
                            if isempty(find(temp_1(:, 4) == i & temp_1(:, 2) == 1)) == 0 && isempty(find(temp_2(:, 4) == i & temp_2(:, 2) == 1)) == 0
                                Unsync_Std_Time = temp_1(find(temp_1(:, 4) == i & temp_1(:, 2) == 1), 1);
                                Unsync_Tgt_Time = temp_2(find(temp_2(:, 4) == i & temp_2(:, 2) == 1), 1);
                                Unsynced_Mtrx(1, Unsynced_Index) = abs(Unsync_Std_Time - Unsync_Tgt_Time);
                                Unsynced_Index = Unsynced_Index + 1;
                            end
                        end
                    end
                end
            end
        end
    end
    Synced_Diff(1, i + 1 -Counter_Synced) = mat2cell(Synced_Mtrx);
    Unsynced_Diff(1, i + 1 -Counter_Synced) = mat2cell(Unsynced_Mtrx);
    disp (['Done with the counter ' num2str(i)]);
end

save([srcDir DirDelimiter srcDir2 DirDelimiter 'FTSP_Pairwise_diff_dist', srcDir2 '.mat'], 'Counter_Synced', 'Synced_Diff', 'Unsynced_Diff')

