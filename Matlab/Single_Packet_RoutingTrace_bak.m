%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Qiao Xiang @ Wayne State University, May 3rd, 2010
%   Contact: du4641@wayne.edu
%
%   This program is designed to trace back the routes of each element
%   received by the sink. The routes are traced back from ths sink to the
%   source, i.e., this program only looks at the receiving log, not
%   transmission log.
%
%   To use this program, users need to change the value of srcDir2, SinkID,
%   SourceID, and Num_Packets, respectively.
%
%   In the output mat file, cell Complete_Paths records all routes back
%   from the sink to the source. Cell BrokenPaths records all broken
%   routes, which can imply errors in the log file. Cell FirstPath records
%   the very first route that the sink successfully received the packet
%   from the source. Num_Routes records the number of routes to deliver
%   this packet. The output mat file is saved for each single packet.
%
%   Updated on May 27th, 2010:
%   The TX bit is now 9 which in old cases defined as 1.
%   The RX bit is now 10 which in old cases defined as 2.
%
%   Updated on June 29th, 2010:
%   Add a Hop Count matrix to record the Sequence Number, Number of Routes,
%   Maximal Hop Count, Minimal Hop Count, and Mean Hop Count for each
%   packet.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



clear
clc

DirDelimiter='/';  %'/'; %\: windows    /: unix
srcDir = '~/Downloads/Jobs/';
srcDir2 = '177'; % Defined by users
srcDir3 = '';
dest = [srcDir DirDelimiter srcDir2 srcDir3 DirDelimiter];
TX = 9;             %Defined by users
RX = 10;            %Defined by users

% SensorIPTable = {'10.0.0.1-5', '10.0.0.1-7', '10.0.0.1-11', '10.0.0.4-6', '10.0.0.4-5', '10.0.0.7-0', '10.0.0.7-10', '10.0.0.7-9', '10.0.0.10-4', '10.0.0.10-5', '10.0.0.13-4', '10.0.0.13-5', '10.0.0.13-0'...
%                 '10.0.0.1-9', '10.0.0.1-10', '10.0.0.1-6', '10.0.0.4-4', '10.0.0.4-2', '10.0.0.7-2', '10.0.0.7-1', '10.0.0.7-7', '10.0.0.10-0', '10.0.0.10-2', '10.0.0.13-3', '10.0.0.13-2', '10.0.0.13-1'...
%                 '10.0.0.1-8', '10.0.0.1-2', '10.0.0.1-3', '10.0.0.4-0', '10.0.0.4-3', '10.0.0.7-3', '10.0.0.7-5', '10.0.0.7-8', '10.0.0.10-3', '10.0.0.10-6', '10.0.0.13-10', '10.0.0.13-11', '10.0.0.13-8'...
%                 '10.0.0.1-0', '10.0.0.1-1', '10.0.0.1-4', '10.0.0.4-1', '10.0.0.5-6', '10.0.0.7-6', '10.0.0.7-4', '10.0.0.7-11', '10.0.0.11-5', '10.0.0.10-1', '10.0.0.13-7', '10.0.0.13-6', '10.0.0.13-9'...
%                 '10.0.0.2-5', '10.0.0.2-4', '10.0.0.2-2', '10.0.0.5-2', '10.0.0.5-5', '10.0.0.8-3', '10.0.0.8-4', '10.0.0.8-2', '10.0.0.11-1', '10.0.0.11-2', '10.0.0.14-5', '10.0.0.14-3', '10.0.0.14-4'...
%                 '10.0.0.2-0', '10.0.0.2-3', '10.0.0.2-1', '10.0.0.5-0', '10.0.0.5-4', '10.0.0.8-1', '10.0.0.8-5', '10.0.0.8-0', '10.0.0.11-4', '10.0.0.11-6', '10.0.0.14-2', '10.0.0.14-1', '10.0.0.14-0'...
%                 '10.0.0.3-6', '10.0.0.3-11', '10.0.0.3-8', '10.0.0.5-3', '10.0.0.5-1', '10.0.0.9-1', '10.0.0.9-0', '10.0.0.9-6', '10.0.0.11-3', '10.0.0.11-0', '10.0.0.15-5', '10.0.0.15-0', '10.0.0.15-2'...
%                 '10.0.0.3-7', '10.0.0.3-9', '10.0.0.3-10', '10.0.0.6-4', '10.0.0.6-5', '10.0.0.9-2', '10.0.0.9-7', '10.0.0.9-10', '10.0.0.12-5', '10.0.0.12-2', '10.0.0.15-1', '10.0.0.15-3', '10.0.0.15-4'...
%                 '10.0.0.3-3', '10.0.0.3-2', '10.0.0.3-0', '10.0.0.6-2', '10.0.0.6-3', '10.0.0.9-4', '10.0.0.9-8', '10.0.0.9-9', '10.0.0.12-3', '10.0.0.12-1', '10.0.0.15-10', '10.0.0.15-9', '10.0.0.15-7'...
%                 '10.0.0.3-1', '10.0.0.3-5', '10.0.0.3-4', '10.0.0.6-0', '10.0.0.6-1', '10.0.0.9-3', '10.0.0.9-5', '10.0.0.9-11', '10.0.0.12-4', '10.0.0.12-0', '10.0.0.15-11', '10.0.0.15-6', '10.0.0.15-8'};


%% Calculate Link ETX
ETX_Table = [];
ETX_Index = 1;
files = dir([srcDir srcDir2 DirDelimiter srcDir3 '*.mat']);

Node_Table = [];
for File_Index = 1:length(files)
    indexedFile = files(File_Index).name;
    load ([srcDir srcDir2 DirDelimiter srcDir3 indexedFile]);
    Node_Table = cat(1, Node_Table, Unique_Packet_Log(1, 2));
end
for Sender_Index = 1:size(Node_Table, 1)
    Sender = Node_Table(Sender_Index, 1);
    for Receiver_Index = 1:size(Node_Table, 1)
        Receiver = Node_Table(Receiver_Index, 1);
        if Sender == 41 && Receiver == 11
            disp 1;
        end
        if Sender ~= Receiver
            load ([srcDir srcDir2 DirDelimiter srcDir3 num2str(Sender) '.mat']);
            Temp_Send_Log = Packet_Log(find(Packet_Log(:, 1) == TX), :);
            Num_Send = size(Temp_Send_Log, 1);
            
            load ([srcDir srcDir2 DirDelimiter srcDir3 num2str(Receiver) '.mat']);
            Num_Recv = size(find(Unique_Packet_Log(:, 1) == RX & Unique_Packet_Log(:, 10) == Sender), 1);
            if Num_Send ~= 0
                if Num_Recv ~=0
                    ETX_Table = cat(1, ETX_Table, [Sender Receiver Num_Send Num_Recv Num_Send/Num_Recv]);
                end
            end
        end
    end
end
%%            
IsOR = 1;            
SinkID = 15;         %Defined by users
SourceID = 71;     %Defined by users
% Num_Packets = 10;   %Defined by users

load ([srcDir srcDir2 DirDelimiter srcDir3 num2str(SinkID) '.mat']);
% XL
% Num_Packets = max(Packet_Log(find(Packet_Log(:, 1) == 9), 4));
Num_Packets = max(Packet_Log(find(Packet_Log(:, 1) == 10), 4));
MaxNodeID = 130;

Hop_Count = zeros(Num_Packets+1, 6);

Cell_PathInfo = cell(Num_Packets + 1, 4);
All_Com_Paths = {};
if IsOR == 1
    LastHopSender = 10;
else
    LastHopSender = 6;
end

for SeqNum = 0:Num_Packets
    CurrentNode = SinkID;
    Num_Routes = 0;
    Finished = 0;
    RouteTable = zeros(1, 2);      %All links that has a succesfull transmission (duplication allowed)
    index = 1;
%     if SeqNum == 83
%         disp 1;
%     end
%     if SeqNum == 163
%         disp 111;
%     end
    while Finished == 0
        Unfinished_Routes = 0;
        Next_CurrentNodes = zeros(1, 1);
        NC_Index = 1;
        
        for NodeIndex = 1:size(CurrentNode, 2)
            load ([srcDir srcDir2 DirDelimiter srcDir3 num2str(CurrentNode(1, NodeIndex)) '.mat']);
            ValidRecord = Unique_Packet_Log(find(Unique_Packet_Log(:, 1) == RX  & Unique_Packet_Log(:, 4) == SeqNum), :);   %& Unique_Packet_Log(:, 3) == SourceID
            
            if ~isempty(ValidRecord)
                for VR_Index = 1:size(ValidRecord, 1)
                    if isempty(find (RouteTable(:, 1) == ValidRecord(VR_Index, LastHopSender))) ...
                            && ValidRecord(VR_Index, LastHopSender) <= MaxNodeID...
                            && exist([srcDir srcDir2 DirDelimiter srcDir3 num2str(ValidRecord(VR_Index, LastHopSender)) '.mat']) ~= 0
                        RouteTable(index, :) = [CurrentNode(1, NodeIndex) ValidRecord(VR_Index, LastHopSender)];
%                         disp (num2str(RouteTable));
                        index = index + 1;
                        if ValidRecord(VR_Index, LastHopSender) ~= SourceID
                            Unfinished_Routes = Unfinished_Routes + 1;
                            Next_CurrentNodes(1, NC_Index) = ValidRecord(VR_Index, LastHopSender);
                            NC_Index = NC_Index + 1;
                        else
                            Num_Routes = Num_Routes + 1;
                        end
                    else
%                         disp (['Find a loop ' num2str(CurrentNode(1, NodeIndex)) ' and ' num2str(ValidRecord(VR_Index, 10))]);
                    end
                end
            end
        end
        Next_CurrentNodes = unique(Next_CurrentNodes);
        
        if Unfinished_Routes == 0
            Finished = 1;
        else
            CurrentNode = zeros(1, 1);
            CurrentNode = Next_CurrentNodes;
        end
    end
    
    U_RTable = unique(RouteTable, 'rows');    %All links that has a succesfull transmission, no duplication
    
%     U_RTable_int = [];
% 
%     for U_R_Idx = 1:size(U_RTable, 1)
%         if U_RTable(U_R_Idx, 1) ~= U_RTable(U_R_Idx, 2)
%             U_RTable_int=cat(1, U_RTable_int, U_RTable(U_R_Idx,:));
%         end
%     end
    
%     U_RTable = U_RTable_int;
    Complete_Paths = cell(1, 1);
    C_Index = 1;
    Incomplete_Paths = cell(1, 1);
    IC_Index = 1;
    BrokenPaths = cell(1, 1);
    B_Index = 1;
    if SeqNum == 24
        disp 222;
    end
    if U_RTable(1, :) ~= [0 0]
        for hop = 1:129
            if hop == 1
                CurrentLink = U_RTable(find(U_RTable(:, 1) == SinkID), :);
                for t = 1:size(CurrentLink, 1)
                    if CurrentLink(t, 2) == SourceID
                        Complete_Paths(C_Index, 1) = {CurrentLink(t, :)};
                        C_Index = C_Index + 1;
                    else
                        Incomplete_Paths(IC_Index, 1) = {CurrentLink(t, :)};
                        IC_Index = IC_Index + 1;
                    end
                end
            else
                TempIC_Paths = cell(1, 1);
                TIC_Index = 1;
                if ~isempty(cell2mat(Incomplete_Paths(1, 1)))
                    for i = 1:size(Incomplete_Paths, 1)
                        CurrentPath_IC = cell2mat(Incomplete_Paths(i, 1));
                        CurrentNode_IC = CurrentPath_IC(1, size(CurrentPath_IC, 2));
                        CurrentLink = U_RTable(find(U_RTable(:, 1) == CurrentNode_IC), :);
                        if ~isempty(CurrentLink)
                            for t = 1:size(CurrentLink, 1)
                                if CurrentLink(t, 2) == SourceID
                                    Complete_Paths(C_Index, 1) = {cat(2, CurrentPath_IC, CurrentLink(t, 2))};
                                    C_Index = C_Index + 1;
                                else
                                    TempIC_Paths(TIC_Index, 1) = {cat(2, CurrentPath_IC, CurrentLink(t, 2))};
                                    TIC_Index = TIC_Index + 1;
                                end
                            end
                        else
                            BrokenPaths(B_Index, 1) = Incomplete_Paths(i, 1);
                            B_Index = B_Index + 1;
                        end
                    end
                    Incomplete_Paths = cell(1, 1);
                    Incomplete_Paths = TempIC_Paths;
                else
    %                 disp 1;
                end
            end    
        end
    end
    Candidate_Paths = Complete_Paths;
    load ([srcDir srcDir2 DirDelimiter srcDir3 num2str(SinkID) '.mat']);
    
    CurrentChild = Packet_Log(find(Packet_Log(:, 1) == RX  & Packet_Log(:, 4) == SeqNum ...
                    & Packet_Log(:, LastHopSender) <= MaxNodeID, ...
                    1, 'first'), LastHopSender);    %& Packet_Log(:, 3) == SourceID
    Hop_FirstRoute = 1;
    while (size(Candidate_Paths, 1) > 1)
        T_Can_Paths = cell(1, 1);
        T_Can_Index = 1;
        for y = 1:size(Candidate_Paths, 1)
            b = cell2mat(Candidate_Paths(y, 1));
            if (b(1, Hop_FirstRoute + 1) == CurrentChild)
                T_Can_Paths(T_Can_Index, 1) = Candidate_Paths(y, 1);
                T_Can_Index = T_Can_Index + 1;
            end
        end
        Candidate_Paths = cell(1, 1);
        Candidate_Paths = T_Can_Paths;  %update candidate paths
        load ([srcDir srcDir2 DirDelimiter srcDir3 num2str(CurrentChild) '.mat']);
        CurrentChild = Packet_Log(find(Packet_Log(:, 1) == RX  & Packet_Log(:, 4) == SeqNum, 1, 'first'), LastHopSender); %& Packet_Log(:, 3) == SourceID
        Hop_FirstRoute = Hop_FirstRoute + 1;
    end
    FirstPath = Candidate_Paths;
    disp (['Done with SeqNum ' num2str(SeqNum)]);
%     save([srcDir DirDelimiter srcDir2 DirDelimiter 'Job' srcDir2 '-Source-' num2str(SourceID) '-SeqNum-' num2str(SeqNum) '.mat'], 'Complete_Paths', 'BrokenPaths', 'FirstPath', 'Num_Routes');   
     
    %% Calculate ETX for paths
    for Path_Index = 1:size(Complete_Paths, 1)
        Path_for_ETX = Complete_Paths{Path_Index, 1};
        ETX_Sum = 0;
        for Hop_Index = 1:(size(Path_for_ETX, 2)-1)
%             load ([srcDir srcDir2 DirDelimiter srcDir3 num2str(SinkID) '.mat']);
            ETX_Sum = ETX_Sum + ETX_Table(find(ETX_Table(:, 1) == Path_for_ETX(1, Hop_Index + 1) & ETX_Table(:, 2) == Path_for_ETX(1, Hop_Index)), 5);
        end
        Complete_Paths(Path_Index, 2) = {ETX_Sum};
    end
    All_Com_Paths = cat(1, All_Com_Paths, Complete_Paths);
    %%
    Cell_PathInfo(SeqNum + 1, 1) = {Complete_Paths};
    Cell_PathInfo(SeqNum + 1, 2) = {BrokenPaths};
    Cell_PathInfo(SeqNum + 1, 3) = {FirstPath};
    Cell_PathInfo(SeqNum + 1, 4) = {Num_Routes};
    
    if isempty(Complete_Paths{1, 1}) ~= 1
        Temp_Hop_Count = [];
        for TH_Index = 1:size(Complete_Paths, 1)
            Temp_Hop_Count(1, TH_Index) = size(Complete_Paths{TH_Index, 1}, 2) - 1;  %Number of Nodes - 1 = Hop Count
        end
        Hop_Count(SeqNum + 1, :) = [SeqNum size(Temp_Hop_Count, 2) max(Temp_Hop_Count(1, :)) min(Temp_Hop_Count(1, :)) mean(Temp_Hop_Count(1, :)) size(FirstPath{1, 1}, 2) - 1];
    else
        Hop_Count(SeqNum + 1, :) = [SeqNum 0 0 0 0 -1];
    end
end
save([[srcDir srcDir2 DirDelimiter num2str(srcDir2) '_RoutesInfoandHopCount.mat']], 'Hop_Count', 'Cell_PathInfo', 'All_Com_Paths');
cd(dest);
clear;
%hist(Hop_Count(find(Hop_Count(:, 6) >= 0), 6));

