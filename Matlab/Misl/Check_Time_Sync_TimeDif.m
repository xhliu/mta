clear
clc

DirDelimiter='/';  %'/'; %\: windows    /: unix
srcDir = '~/Downloads/Jobs';
srcDir2 = '106'; % Defined by users
srcDir3 = '';
dest = [srcDir DirDelimiter srcDir2 srcDir3 DirDelimiter];
files = dir([dest '*.mat']);

Time_Dif = [];
for fileIndex = 1:length(files)
    indexedFile = files(fileIndex).name;
    load ([srcDir DirDelimiter srcDir2 DirDelimiter srcDir3 indexedFile]);
    Time_Dif = cat(1, Time_Dif, Packet_Log(2:size(Packet_Log, 1), 5) - Packet_Log(1:(size(Packet_Log, 1)-1), 5));
end
hist(Time_Dif, 100);