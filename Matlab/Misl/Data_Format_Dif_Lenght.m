clear
clc

DirDelimiter='/';  %'/'; %\: windows    /: unix
srcDir = '~/Downloads/Jobs';
srcDir2 = '113'; % Defined by users
srcDir3 = '';
dest = [srcDir DirDelimiter srcDir2 srcDir3 DirDelimiter];
files = dir([dest '*.txt']);

IsOR = 1;
MaxLength_PerLog = 114;

Is_Tx = 1;
Is_NodeID = 1;
Is_SourceID = 1;
Is_SeqNum = 1;
Is_FC = 0;
Is_LastSender = 0;
Is_LastSenderSeq = 0;
Is_LocalSeq = 0;
Is_LastNtwSeq = 0;
Is_LocalNtwSeq = 0;
Is_TimeStamp = 1;




Num_Tx = 1;
Num_NodeID = 1;
Num_SourceID = 1;
Num_SeqNum = 2;
Num_FC_each = 1;

if IsOR == 1
    Num_FC = 5;
%     Colmn_Packet =15;
%     EletPerLog = 4;
else
    Num_FC = 1;
%     Colmn_Packet =11;
%     EletPerLog = 6;
end
Colmn_Packet = Is_Tx + Is_NodeID + Is_SourceID + Is_SeqNum + Is_FC * Num_FC + Is_LastSender + Is_LastSenderSeq...
                + Is_LocalSeq + Is_LastNtwSeq + Is_LocalNtwSeq + Is_TimeStamp;

Num_LastSender = 1;
Num_LastSenderSeq = 2;
Num_LocalSeq = 2;

Num_LastNtwSeq = 2;
Num_LocalNtwSeq = 2;

Num_TimeStamp = 4;


Num_PerElet = Num_Tx * Is_Tx + Num_NodeID  * Is_NodeID + Num_SourceID * Is_SourceID ...
             + Num_SeqNum * Is_SeqNum + Num_FC_each * Num_FC * Is_FC + Num_LastSender * Is_LastSender ...
             + Num_LastSenderSeq * Is_LastSenderSeq + Num_LocalSeq * Is_LocalSeq + Num_LastNtwSeq * Is_LastNtwSeq ...
             + Num_LocalNtwSeq * Is_LocalNtwSeq + Num_TimeStamp * Is_TimeStamp;

Control_Data = 8; %Columns that are useless


for fileIndex = 1:length(files)
    indexedFile = files(fileIndex).name;
    disp(indexedFile);
    %Did not have the code to skip unrelavent files and directories
    disp(['Processing file ' upper(indexedFile) ': please wait ...']);
    fid = fopen([srcDir DirDelimiter srcDir2 DirDelimiter srcDir3 indexedFile]);
    if fid < 0
        disp(['   Cannot open file' srcDir DirDelimiter indexedFile]);
        continue
    end
    Raw_Data = [];
    Packet_Log = [];
    line = 0;
    while 1
        tline = fgets(fid);
        line = line + 1;
        LineLength = (length(tline) - 1) / 3;  %'xx ' 
        EletPerLog = floor(LineLength / Num_PerElet);
        NUM_COLUMNS = Control_Data + Num_PerElet * EletPerLog;  % Number of Columns in Log
%         SENDER_DATA_FORMAT = repmat('%x ', 1, NUM_COLUMNS); % '%x' means HEX
        PKT_DATA_FORMAT = repmat('%x ', 1, Num_PerElet * EletPerLog);
%         Temp_Raw_Data = [];
        if ~ischar(tline)
            if line == 1
                disp 'This file is empty';
            else
                disp 'End of file';
            end
            break;   
        end
        Temp = tline((Control_Data * 3 + 1):length(tline));
%         for All_bits_pline_Idx = (Control_Data * 3 + 1):3:LineLength
        Temp_Raw_Data = sscanf(Temp, PKT_DATA_FORMAT,[Num_PerElet * EletPerLog, inf])';
%         disp 1;
%         end
%         Temp_Raw_Data = Temp_Raw_Data';
%         for j = 1:EletPerLog
        Temp_Packet_Log = zeros(EletPerLog, Colmn_Packet);
        CurrentIndex = 0;
%         for temp_Entry = 1:size(Raw_Data, 1)
%             Current_R_Index = 0;
        Current_R_Index = 0;
            for temp_Ele = 1:EletPerLog
                PL_Index = 1;
                if Is_Tx == 1
                    for i = 1:1:Num_Tx        %TX/RX
                        Temp_Packet_Log((CurrentIndex + 1), PL_Index) = Temp_Packet_Log((CurrentIndex + 1), PL_Index) +...
                                                            Temp_Raw_Data(1, (temp_Ele - 1) * Num_PerElet + Current_R_Index + i) * power(16, (Num_Tx - i) * 2);
                    end
                    Current_R_Index = Current_R_Index + Num_Tx;
                    PL_Index = PL_Index + 1;
                end

                if Is_NodeID == 1
                    for i = 1:1:Num_NodeID    %NodeID
                        Temp_Packet_Log((CurrentIndex + 1), PL_Index) = Temp_Packet_Log((CurrentIndex + 1), PL_Index) +...
                                                            Temp_Raw_Data(1, (temp_Ele - 1) * Num_PerElet + Current_R_Index + i) * power(16, (Num_NodeID - i) * 2);
                    end
                    Current_R_Index = Current_R_Index + Num_NodeID;
                    PL_Index = PL_Index + 1;
                end
                
                if Is_SourceID == 1
                    for i = 1:1:Num_SourceID  %SourceID
                        Temp_Packet_Log((CurrentIndex + 1), PL_Index) = Temp_Packet_Log((CurrentIndex + 1), PL_Index) +...
                                                            Temp_Raw_Data(1, (temp_Ele - 1) * Num_PerElet + Current_R_Index + i) * power(16, (Num_SourceID - i) * 2);
                    end
                    Current_R_Index = Current_R_Index + Num_SourceID;
                    PL_Index = PL_Index + 1;
                end
                
                if Is_SeqNum == 1
                    for i = 1:1:Num_SeqNum    %Sequence Number
                        Temp_Packet_Log((CurrentIndex + 1), PL_Index) = Temp_Packet_Log((CurrentIndex + 1), PL_Index) +...
                                                            Temp_Raw_Data(1, (temp_Ele - 1) * Num_PerElet + Current_R_Index + i) * power(16, (Num_SeqNum - i) * 2);
                    end
                    Current_R_Index = Current_R_Index + Num_SeqNum;   %Jump New Columns
                    PL_Index = PL_Index + 1;
                end
                %+ Num_LastSender + Num_LastSenderSeq + Num_LocalSeq +
                %Num_LastNtwSeq + Num_LocalNtwSeq
                %%
                if Is_LastSender ==1
                    Current_R_Index = Current_R_Index + Num_LastSender;
                end
                if Is_LastSenderSeq ==1
                    Current_R_Index = Current_R_Index + Num_LastSenderSeq;
                end
                if Is_LocalSeq ==1
                    Current_R_Index = Current_R_Index + Num_LocalSeq;
                end
                if Is_LastNtwSeq ==1
                    Current_R_Index = Current_R_Index + Num_LastNtwSeq;
                end
                if Is_LocalNtwSeq ==1
                    Current_R_Index = Current_R_Index + Num_LocalNtwSeq;
                end  %These are to jump to FC columns
                %%
                
                
                if Is_FC == 1
                    for j = 1:1:Num_FC        %FC Set
                        for i = 1:1:Num_FC_each
                            Temp_Packet_Log((CurrentIndex + 1), PL_Index) = Temp_Packet_Log((CurrentIndex + 1), PL_Index) +...
                                                                Temp_Raw_Data(1, (temp_Ele - 1) * Num_PerElet + Current_R_Index + i) * power(16, (Num_FC_each - i) * 2);
                        end
                        Current_R_Index = Current_R_Index + Num_FC_each;
                        PL_Index = PL_Index + 1;
                    end  
                    Current_R_Index = Current_R_Index - Num_FC * Num_FC_each;
                end
                %%
                if Is_LastSender ==1
                    Current_R_Index = Current_R_Index - Num_LastSender;
                end
                if Is_LastSenderSeq ==1
                    Current_R_Index = Current_R_Index - Num_LastSenderSeq;
                end
                if Is_LocalSeq ==1
                    Current_R_Index = Current_R_Index - Num_LocalSeq;
                end
                if Is_LastNtwSeq ==1
                    Current_R_Index = Current_R_Index - Num_LastNtwSeq;
                end
                if Is_LocalNtwSeq ==1
                    Current_R_Index = Current_R_Index - Num_LocalNtwSeq;
                end  %These are to go back to new columns
                %%
                %%Adding New Columns
                % - (Num_LastSender + Num_LastSenderSeq + Num_LocalSeq + Num_LastNtwSeq + Num_LocalNtwSeq);
                if Is_LastSender == 1
                    for i = 1:1:Num_LastSender    %Last Hop Sender
                        Temp_Packet_Log((CurrentIndex + 1), PL_Index) = Temp_Packet_Log((CurrentIndex + 1), PL_Index) +...
                                                            Temp_Raw_Data(1, (temp_Ele - 1) * Num_PerElet + Current_R_Index + i) * power(16, (Num_LastSender - i) * 2);
                    end
                    Current_R_Index = Current_R_Index + Num_LastSender;
                    PL_Index = PL_Index + 1;
                end
                
                if Is_LastNtwSeq == 1
                    for i = 1:1:Num_LastNtwSeq    %Last Hop Network Sequence Number
                        Temp_Packet_Log((CurrentIndex + 1), PL_Index) = Temp_Packet_Log((CurrentIndex + 1), PL_Index) +...
                                                            Temp_Raw_Data(1, (temp_Ele - 1) * Num_PerElet + Current_R_Index + i) * power(16, (Num_LastNtwSeq - i) * 2);
                    end
                    Current_R_Index = Current_R_Index + Num_LastNtwSeq;
                    PL_Index = PL_Index + 1;
                end
                
                if Is_LastSenderSeq == 1
                    for i = 1:1:Num_LastSenderSeq    %Last Hop MAC Sequence Number
                        Temp_Packet_Log((CurrentIndex + 1), PL_Index) = Temp_Packet_Log((CurrentIndex + 1), PL_Index) +...
                                                            Temp_Raw_Data(1, (temp_Ele - 1) * Num_PerElet + Current_R_Index + i) * power(16, (Num_LastSenderSeq - i) * 2);
                    end
                    Current_R_Index = Current_R_Index + Num_LastSenderSeq;
                    PL_Index = PL_Index + 1;
                end
                
                if Is_LocalNtwSeq == 1
                    for i = 1:1:Num_LocalNtwSeq    %Local Network Sequence Number
                        Temp_Packet_Log((CurrentIndex + 1), PL_Index) = Temp_Packet_Log((CurrentIndex + 1), PL_Index) +...
                                                            Temp_Raw_Data(1, (temp_Ele - 1) * Num_PerElet + Current_R_Index + i) * power(16, (Num_LocalNtwSeq - i) * 2);
                    end
                    Current_R_Index = Current_R_Index + Num_LocalNtwSeq;
                    PL_Index = PL_Index + 1;
                end
                
                if Is_LocalSeq == 1
                    for i = 1:1:Num_LocalSeq    %Local MAC Sequence Number
                        Temp_Packet_Log((CurrentIndex + 1), PL_Index) = Temp_Packet_Log((CurrentIndex + 1), PL_Index) +...
                                                            Temp_Raw_Data(1, (temp_Ele - 1) * Num_PerElet + Current_R_Index + i) * power(16, (Num_LocalSeq - i) * 2);
                    end
                    Current_R_Index = Current_R_Index + Num_LocalSeq;
                    PL_Index = PL_Index + 1;
                end
                
                if Is_FC == 1
                    Current_R_Index = Current_R_Index + Num_FC * Num_FC_each;   %Add back to the latest index
                end
                
                if Is_TimeStamp == 1
                    for i = 1:1:Num_TimeStamp    %Time Stamp
                        Temp_Packet_Log((CurrentIndex + 1), PL_Index) = Temp_Packet_Log((CurrentIndex + 1), PL_Index) +...
                                                            Temp_Raw_Data(1, (temp_Ele - 1) * Num_PerElet + Current_R_Index + i) * power(16, (Num_TimeStamp - i) * 2);
                    end
                    Current_R_Index = Current_R_Index + Num_TimeStamp;
                    PL_Index = PL_Index + 1;                
                end
                
                
                CurrentIndex = CurrentIndex + 1;
                
                Current_R_Index = 0;
            end
%         end
%         end
        Packet_Log = cat(1, Packet_Log, Temp_Packet_Log);
        if rem(line, 200) == 0
            disp (num2str(line));
        end
    end
%     Packet_Log = Packet_Data;
    Unique_Packet_Log = unique(Packet_Log, 'rows', 'first');
    
    [pathstr, prename, ext, versn] = fileparts(indexedFile);
    save([srcDir DirDelimiter srcDir2 DirDelimiter srcDir3 prename '.mat'], 'Packet_Log', 'Unique_Packet_Log');
    disp (['Done with ' indexedFile ', go to next']);
end





