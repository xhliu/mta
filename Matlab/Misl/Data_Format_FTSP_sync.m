%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Qiao Xiang @ Wayne State University, June 17th, 2010
%   Contact: du4641@wayne.edu
%
%   This program is designed to format data from raw txt files into mat
%   files for FTSP-time-sync.
%
%   To use this program, users need to change the value of srcDir2.
%
%   For details about the log format, please refer to the excel file named
%   Data Format.xlsx which is stored in the same folder with this program.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


clear
clc

% DirDelimiter='\';  %'/'; %\: windows    /: unix
% srcDir = 'C:\Documents and Settings\Qiao Xiang\My Documents\MATLAB\RTSS 2010';
% srcDir2 = '57';
% srcDir3 = 'raw data\';
% files = dir([srcDir DirDelimiter srcDir2 DirDelimiter srcDir3 '*.txt']);
DirDelimiter='/';  %'/'; %\: windows    /: unix
srcDir = '~/Downloads/Jobs';
srcDir2 = '111'; % Defined by users
srcDir3 = '';
dest = [srcDir DirDelimiter srcDir2 srcDir3 DirDelimiter];
files = dir([dest '*.txt']);

NUM_COLUMNS = 21;  % Number of Columns in Log
SENDER_DATA_FORMAT = repmat('%x ', 1, NUM_COLUMNS); % '%x' means HEX
Control_Data = 8; %Columns that are useless

for fileIndex = 1:length(files)
    indexedFile = files(fileIndex).name;
    fid = fopen([srcDir DirDelimiter srcDir2 DirDelimiter srcDir3 indexedFile]);
    Raw_Data = fscanf(fid, SENDER_DATA_FORMAT,[NUM_COLUMNS inf]);
    Raw_Data = Raw_Data';
    disp (indexedFile);

    if ~isempty(Raw_Data)
        Packet_Log = zeros(size(Raw_Data, 1), 9);
        index = 9;
        Packet_Log(:, 1) = Raw_Data(:, index) * power(16, 6) + Raw_Data(:, index + 1) * power(16, 4) ...
                            + Raw_Data(:, index + 2) * power(16, 2) + Raw_Data(:, index + 3) * power(16, 0);
        index = index + 4;
        Packet_Log(:, 2) = Raw_Data(:, index);
        index = index + 1;
        Packet_Log(:, 3) = Raw_Data(:, index) * power(16, 2) + Raw_Data(:, index + 1) * power(16, 0);
        index = index + 2;
        Packet_Log(:, 4) = Raw_Data(:, index) * power(16, 2) + Raw_Data(:, index + 1) * power(16, 0);
        index = index + 2;
        Packet_Log(:, 5) = Raw_Data(:, index) * power(16, 6) + Raw_Data(:, index + 1) * power(16, 4) ...
                            + Raw_Data(:, index + 2) * power(16, 2) + Raw_Data(:, index + 3) * power(16, 0);
        index = index + 4;
        
%         Packet_Log(:, 6) = Raw_Data(:, index) * power(16, 6) + Raw_Data(:, index + 1) * power(16, 4) ...
%                             + Raw_Data(:, index + 2) * power(16, 2) + Raw_Data(:, index + 3) * power(16, 0);
%         index = index + 4;
%         Packet_Log(:, 7) = Raw_Data(:, index) * power(16, 2) + Raw_Data(:, index + 1) * power(16, 0);
%         index = index + 2;
%         Packet_Log(:, 8) = Raw_Data(:, index);
%         index = index + 1;
%         Packet_Log(:, 9) = Raw_Data(:, index);
%         index = index + 1;

%         for index = 2:9
%             Packet_Log(:, index) = Raw_Data(:, (index - 1) * 2 + 8) * power(16, 2) + Raw_Data(:, (index - 1) * 2 + 9) * power(16, 0);
%         end
        Unique_Packet_Log = unique(Packet_Log, 'rows', 'first');
        [pathstr, prename, ext, versn] = fileparts(indexedFile);
        save([srcDir DirDelimiter srcDir2 DirDelimiter srcDir3 prename '.mat'], 'Packet_Log', 'Unique_Packet_Log');
        disp (['Done with ' indexedFile ', go to next']);
    else
        disp (['File ' indexedFile ' is empty, go to next']);
    end
end