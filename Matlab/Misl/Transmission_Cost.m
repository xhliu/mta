%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Qiao Xiang @ Wayne State University, June 29th, 2010
%   Contact: du4641@wayne.edu
%
%   This program is designed to calculate the transmission cost of tOr.
%
%   To use this program, users need to change the value of srcDir2 and SourceID.
%
%   The result will be displayed in the Command Window.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


clear
clc
DirDelimiter='/';  %'/'; %\: windows    /: unix
srcDir = '~/Downloads/Jobs';
srcDir2 = '3762'; % Defined by users
dest = [srcDir DirDelimiter srcDir2 DirDelimiter];
files = dir([dest 'Job*.mat']);


SourceID = 117;

Num_Received = 0;
Num_Trans = 0;
NullSign = 65535;


for fileIndex = 1:length(files)
    indexedFile = files(fileIndex).name;
    load ([dest indexedFile]);
    disp (['Loading file ' indexedFile]);
    
    if Packet_Log(1, 3) == SourceID   %Denominator
%         Num_Received = size(find(Packet_Log(:, 1) == 3), 1);
%         Num_Received = size(unique(Packet_Log(find(Packet_Log(:, 1) == 3), 4), 'rows'), 1);
        Num_Received = size(unique(Packet_Log(find(Packet_Log(:, 1) == 3), 3:4), 'rows'), 1);
    else
%         for i = 1:size(Packet_Log, 1)
%             if Packet_Log(i, 2) == 9
%                 Num_Trans = Num_Trans + (5 - floor(sum(Packet_Log(i, 5:9)) / NullSign));
%             end
%         end
        Num_Trans = Num_Trans + size(find(Packet_Log(:, 1) == 9), 1);
    end
end

TransmissionCost = Num_Trans / Num_Received;

disp (['Total Number of Transmissions is ' num2str(Num_Trans)]);
disp (['Packets received by the sink is ' num2str(Num_Received)]);
disp (['Transmissions cost is ' num2str(TransmissionCost)]);
clear;