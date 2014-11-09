clear variables;
close all;
clc;

jobID = 3428;
srcDir = ['~/Data/Jobs/' num2str(jobID)];
%srcDir = ['~/Documents/Jobs/' num2str(jobID)];
saveDir = srcDir;
DirDelimiter = '/';

NUM_DATA_COLUMNS = 25;

DATA_FORMAT = repmat('%x ', 1, NUM_DATA_COLUMNS);    

files = dir(srcDir);

fileNum = 0;
    
allBytes = zeros(0);   

for fileIndex = 1:length(files)
    indexedFile = files(fileIndex).name;
    %skip directories, and files that does not start with senderFilePrefix/receierFilePrefix
    if files(fileIndex).isdir
        continue
    end
    
    fileNum = fileNum + 1;    
    disp(['Processing file(#' num2str(fileNum) '): <' indexedFile '> ...please wait...']);
    %%Processing this file
    fid = fopen([srcDir DirDelimiter indexedFile]);
    if fid < 0
        disp(['cannot open file' srcDir DirDelimiter indexedFile]);
        continue
    end 
    
    [tmpBytes, count] = fscanf(fid, DATA_FORMAT, [NUM_DATA_COLUMNS inf]);
    tmpBytes = tmpBytes';
%     allBytes = [allBytes, tmpBytes];            %merge all the data file
    
    if isempty(tmpBytes)
        disp('!Note: data file is empty ?!');
        continue    
    end
    
%     if ~isempty(find(tmpBytes(:, 9) > 11))
%         disp(['file ' num2str(fileNum) ' contains flow table look up']);
%     end
    
    save ([saveDir DirDelimiter '' num2str(tmpBytes(1,11)) '.mat'] ,'tmpBytes');       %num2str(tmpBytes(1,9))
end