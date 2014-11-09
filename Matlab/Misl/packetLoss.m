%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Xiaohui Liu
%   Contact: xiaohui@wayne.edu
%   Function: analyze the causes of packet loss
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear
clc
DirDelimiter='/';  %'/'; %\: windows    /: unix
srcDir = '~/Downloads/Jobs';
srcDir2 = '3758'; % Defined by users
dest = [srcDir DirDelimiter srcDir2 DirDelimiter];
files = dir([dest 'Job*.mat']);

falseFCs = cell(130, 1);
SWFs = cell(130, 1);
emptyFCSs = cell(130, 1);

for fileIndex = 1:length(files)
    indexedFile = files(fileIndex).name;
    load ([dest indexedFile]);
    disp (['Loading file ' indexedFile]);
    
    if ~isempty(Packet_Log)
        nodeId = Packet_Log(1, 2);

        if ~isempty(find(Packet_Log(:, 1) == 4))
                falseFCs{nodeId + 1} = Packet_Log(find(Packet_Log(:, 1) == 4), 3:4);
                disp (['False FC in ' indexedFile]);
        end        

        if ~isempty(find(Packet_Log(:, 1) == 5))
                SWFs{nodeId + 1} = Packet_Log(find(Packet_Log(:, 1) == 5), 3:4);
                disp (['Sliding windown full in  ' indexedFile]);
        end

        if ~isempty(find(Packet_Log(:, 1) == 6))
                emptyFCSs{nodeId + 1} = Packet_Log(find(Packet_Log(:, 1) == 6), 3:4);
                disp (['Empty FCS in  ' indexedFile]);
        end
        disp (['Done with ' indexedFile ', go to next']);
    else
        disp (['File ' indexedFile ' is empty, go to next']);
    end
    save([dest 'packetLoss.mat'], 'falseFCs', 'SWFs', 'emptyFCSs');
end