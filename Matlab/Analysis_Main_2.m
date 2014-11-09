clear
clc

TimeSync_or_Routing = 2;     %1: Time Sync Protocols; 
                             %2: Routing Protocols
                             %3: Compare different routing protocols
%% Common Parameters
% DirDelimiter_C='\';  %'/'; %\: windows    /: unix
% srcDir_C = 'C:\Documents and Settings\Qiao Xiang\My Documents\MATLAB\RTSS 2010';
% srcDir2_C = '233';
% srcDir3_C = 'raw data\';
DirDelimiter_C ='/';  %'/'; %\: windows    /: unix
srcDir_C = '~/Downloads/Jobs';
srcDir2_C = '262'; % Defined by users
srcDir3_C = '';
%% Protocol Comparision Parameters
JobID = {'159', '177'};
Protocol_Name = {'s-tOR 4001ms', 'stOR'};
%% Time Sync Analysis Parameters
TimeSync_Format = 1;         %1: Do Time Sync data format; 
                             %0: Otherwise
                             
TimeSync_Pairwise = 1;       %1: Do Time Sync pairwise analysis; 
                             %0: Otherwise
    Nodes_Prtd_C = 99;      %# of nodes participated in the experiment
    
TimeSync_G_and_L_Dif = 1;    %1: Do Time Sync global and local timestamp difference analysis
                             %   and consecutive global timestamp difference analysis;
                             %0: Otherwise                         
%% Routing Protocols Analysis Parameters
Routing_Format = 0;          %1: Do Routing Protocol data format;
                             %0: Otherwise
    Is_OR_R = 1;
    Source_R = 71;
    Sink_R = 15;
    if Is_OR_R == 1
        Num_FC_R = 5;
    else
        Num_FC_R = 1;
    end
    Format_Table_R = [  1 1 1;  %TX/RX
                        1 1 2;  %NodeID
                        1 1 3;  %SourceID
                        1 2 4;  %Packet Seq #
                        1 1 15;  %FC
                        1 1 6;  %Last_Hop_Sender 
                        1 2 7;  %Last_Hop_Ntw_Seq
                        1 2 9;  %Last_Hop_MAC_Seq
                        1 2 11;  %Local_Ntw_Seq
                        1 2 13;  %Local_MAC_Seq
                        1 4 15 + Num_FC_R]; %Timestamp
Routing_E2E_Delay_and_Reliability = 0;
    if Is_OR_R == 1
        Timestamp_Position = 15;
    else
        Timestamp_Position = 11;
    end

Routing_Unnece_Retx = 1;
Routing_Trans_Cost = 0;
Routing_Drop_Check = 0;
Routing_Low_Reliability_Check = 0;
%% Main Code
if TimeSync_or_Routing == 1
    if TimeSync_Format == 1                     %Data_Format_FTSP_sync.m
        Data_Format_FTSP_sync(DirDelimiter_C, srcDir_C, srcDir2_C, srcDir3_C);
    end
    if TimeSync_Pairwise == 1                   %FTSP_sync_pairwise.m
        FTSP_sync_pairwise(DirDelimiter_C, srcDir_C, srcDir2_C, srcDir3_C, Nodes_Prtd_C);
    end
    if TimeSync_G_and_L_Dif == 1                %Check_Time_Sync_TimeDif.m
        Check_Time_Sync_TimeDif(DirDelimiter_C, srcDir_C, srcDir2_C, srcDir3_C);
    end    
else
    if Routing_Format == 1                      %Data_Format_Dif_Lenght.ms
        Data_Format_Dif_Lenght(Format_Table_R, DirDelimiter_C, srcDir_C, srcDir2_C, srcDir3_C, Num_FC_R);
    end
    if Routing_E2E_Delay_and_Reliability == 1   %OR_e2e_Deadline.m
        OR_e2e_Deadline(DirDelimiter_C, srcDir_C, srcDir2_C, srcDir3_C, Timestamp_Position, Source_R, Sink_R);
    end
    if Routing_Unnece_Retx == 1                 %Unnecs_Retx.m
        Unnecs_Retx(DirDelimiter_C, srcDir_C, srcDir2_C, srcDir3_C, Num_FC_R);
    end
    if Routing_Trans_Cost == 1
        Transmission_Cost(DirDelimiter_C, srcDir_C, srcDir2_C, srcDir3_C, Source_R, Sink_R);
    end
    if Routing_Drop_Check == 1
        DropCheck(DirDelimiter_C, srcDir_C, srcDir2_C, srcDir3_C);
    end
    if Routing_Low_Reliability_Check == 1
        Check_stOR_low_reliability(DirDelimiter_C, srcDir_C, srcDir2_C, srcDir3_C);
    end
end
%%








