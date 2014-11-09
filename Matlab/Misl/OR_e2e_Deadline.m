clear
clc
close all

% DirDelimiter='\';  %'/'; %\: windows    /: unix
% srcDir = 'C:\Documents and Settings\Qiao Xiang\My Documents\MATLAB';
% srcDir2 = '99'; % Defined by users
% srcDir3 = 'raw data\';
% files = dir([srcDir DirDelimiter srcDir2 DirDelimiter srcDir3 '*.mat']);
DirDelimiter='/';  %'/'; %\: windows    /: unix
srcDir = '~/Downloads/Jobs';
srcDir2 = '113'; % Defined by users
srcDir3 = '';
dest = [srcDir DirDelimiter srcDir2 srcDir3 DirDelimiter];
files = dir([dest '*.txt']);

alpha = 0.05;
z_alpha = 1.960;

IsOR = 1;
Outlier_Threshold = power(10, 5);
Base_Station_Rcv = 3;
Source_Snd = 1;
% if IsOR == 1
%     Time_Stamp = 15;
% else
%     Time_Stamp = 11;
% end
Time_Stamp = 5;
Source = 77;
Base_Station = 117;

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

            
Cell_E2E_Latency = cell(1, size(Source, 2));
for i = size(Source, 2);
    %Physical Distance
    Distance_y = abs(floor(Base_Station / 13) - floor(Source(1, i) / 13));
    Distance_x = abs(rem(Base_Station, 13) - rem(Source(1, i), 13));
    Distance(i, 1) = sqrt(power(Distance_y, 2) + power(Distance_x, 2));
    
    load ([srcDir DirDelimiter srcDir2 DirDelimiter srcDir3 'Job' srcDir2 '-' cell2mat(SensorIPTable(1, Source(1, i) + 1)) '.mat']);
    Temp_Source_Log = Unique_Packet_Log(find(Unique_Packet_Log(:, 1) == Source_Snd & Unique_Packet_Log(:, 3) == Source(1, i)), :);
    MaxSeq = max(Temp_Source_Log(:, 4));
    
    E2E_Latency_Log = [];
    E2E_Latency = [];
    E2E_Index = 1;
    for ID = 0:MaxSeq
        if isempty(find(Temp_Source_Log(:, 4) == ID)) ~= 1
            E2E_Latency_Log(E2E_Index,:) = Temp_Source_Log(find(Temp_Source_Log(:, 4) == ID, 1, 'first'), :);
            E2E_Latency(E2E_Index,:) = [E2E_Latency_Log(E2E_Index, 2) E2E_Latency_Log(E2E_Index, 3) E2E_Latency_Log(E2E_Index, 4) E2E_Latency_Log(E2E_Index, Time_Stamp)];
            E2E_Index = E2E_Index + 1;
        end
    end
    
%     E2E_Latency = [Temp_Source_Log(:, 2) Temp_Source_Log(:, 3) Temp_Source_Log(:, 4) Temp_Source_Log(:, 15)];
    
    load ([srcDir DirDelimiter srcDir2 DirDelimiter srcDir3 'Job' srcDir2 '-' cell2mat(SensorIPTable(1, Base_Station + 1)) '.mat']);
    Temp_Sink_Log = Unique_Packet_Log(find(Unique_Packet_Log(:, 1) == Base_Station_Rcv & Unique_Packet_Log(:, 3) == Source(1, i)), :);
    for j = 1:size(E2E_Latency, 1)
        if isempty(find(Temp_Sink_Log(:, 4) == E2E_Latency(j, 3) & Temp_Sink_Log(:, 3) == Source(1, i))) ~= 1
            E2E_Latency(j, 5)...
                = min(Temp_Sink_Log(find(Temp_Sink_Log(:, 4) == E2E_Latency(j, 3) & Temp_Sink_Log(:, 3) == Source(1, i)), Time_Stamp));
            E2E_Latency(j, 6) = E2E_Latency(j, 5) - E2E_Latency(j, 4);   %E2E Latency
            if E2E_Latency(j, 6) >= Outlier_Threshold
                E2E_Latency(j, 7) = 2;  % Received by the sink, but is an outlier
            else
                E2E_Latency(j, 7) = 1;  % Received by the sink
            end
        else
            E2E_Latency(j, 5) = 0;
            E2E_Latency(j, 6) = 0;
            E2E_Latency(j, 7) = 0;  % Not received by the sink
        end
    end
    Cell_E2E_Latency(1, i) = {E2E_Latency};
%    Cell_E2E_Latency(2, i) = Distance;
    Reliability = [size(E2E_Latency, 1) size(find(E2E_Latency(:, 7) ~= 0), 1) size(find(E2E_Latency(:, 7) ~= 0), 1)/size(E2E_Latency, 1)];
end

Unique_Distance = unique(Distance, 'rows');  %unique function returns values by default in ascending order
% Unique_Distance = sort(Unique_Distance, 'ascend');

Distance_vs_Latency = zeros(1, 3);
Temp_All_Delay = [];
Temp_All_Delay_wOlr = [];
for k = 1:size(Unique_Distance, 1)
    Distance_vs_Latency(k, 1) = Unique_Distance(k, 1);
    Temp_All_Delay = [];
    Temp_All_Delay_wOlr = [];
    for t= 1:size(Distance, 1)
        if Distance(t, 1) == Distance_vs_Latency(k, 1);
            Temp_Valid = Cell_E2E_Latency{1, t};
            Valid_Latency = Temp_Valid(find(Temp_Valid(:, 7) == 1), 6);
            Temp_All_Delay = cat(1, Temp_All_Delay, Valid_Latency);
            Valid_Latency_wOlr = Temp_Valid(find(Temp_Valid(:, 7) ~= 0), 6);
            Temp_All_Delay_wOlr = cat(1, Temp_All_Delay_wOlr, Valid_Latency_wOlr);
        end
    end
    
    True_DELAY = Temp_All_Delay(find(Temp_All_Delay>=0));
    
    Distance_vs_Latency(k, 2) = mean(Temp_All_Delay);
    Distance_vs_Latency(k, 3) = z_alpha * std(Temp_All_Delay) / sqrt(size(Temp_All_Delay, 1));
    
    Distance_vs_Latency(k, 4) = mean(True_DELAY);
    Distance_vs_Latency(k, 5) = z_alpha * std(True_DELAY) / sqrt(size(True_DELAY, 1));
    
end

True_DELAY = Temp_All_Delay(find(Temp_All_Delay>=0));   
figure;
[a b] = hist(True_DELAY, 100);
a = 100 * a / sum(a);
bar(b, a);
maximize(gcf);
set(gca, 'Xscale', 'log');
set(gca, 'Fontsize', 16);
title('Hist of positive delay without Positive Outliers', 'Fontsize', 20);
saveas(gcf, [srcDir DirDelimiter srcDir2 DirDelimiter srcDir2 '_Hist_All_Pos_Delay_without_POutliers.emf']);
saveas(gcf, [srcDir DirDelimiter srcDir2 DirDelimiter srcDir2 '_Hist_All_Pos_Delay_without_POutliers.fig']);

figure;
[a b] = hist(Temp_All_Delay_wOlr, 100);
a = 100 * a / sum(a);
bar(b, a);
maximize(gcf);
% set(gca, 'Xscale', 'log');
set(gca, 'Fontsize', 16);
title('Hist of all delay with Positive Outliers', 'Fontsize', 20);
saveas(gcf, [srcDir DirDelimiter srcDir2 DirDelimiter srcDir2 '_Hist_All_Delay_with_POutliers.emf']);
saveas(gcf, [srcDir DirDelimiter srcDir2 DirDelimiter srcDir2 '_Hist_All_Delay_with_POutliers.fig']);

figure;
[a b] = hist(Temp_All_Delay, 100);
a = 100 * a / sum(a);
bar(b, a);
maximize(gcf);
% set(gca, 'Xscale', 'log');
set(gca, 'Fontsize', 16);
title('Hist of all delay without Positive Outliers', 'Fontsize', 20);
saveas(gcf, [srcDir DirDelimiter srcDir2 DirDelimiter srcDir2 '_Hist_All_Delay_without_POutliers.emf']);
saveas(gcf, [srcDir DirDelimiter srcDir2 DirDelimiter srcDir2 '_Hist_All_Delay_without_POutliers.fig']);





figure;
bar(Distance_vs_Latency(:, 2));
colormap Summer;
hold on;
errorbar(Distance_vs_Latency(:, 2), Distance_vs_Latency(:, 3), 'k', 'linestyle', 'none');
maximize(gcf);
set(gca, 'XTickLabel', Distance_vs_Latency(:,1));
title('Mean of positive delay with Positive Outliers', 'Fontsize', 20);
saveas(gcf, [srcDir DirDelimiter srcDir2 DirDelimiter srcDir2 'Mean_Positive_Delay_with_POutliers.emf']);
saveas(gcf, [srcDir DirDelimiter srcDir2 DirDelimiter srcDir2 'Mean_Positive_Delay_with_POutliers.fig']);



figure;
bar(Distance_vs_Latency(:, 4));
colormap Summer;
hold on;
errorbar(Distance_vs_Latency(:, 4), Distance_vs_Latency(:, 5), 'k', 'linestyle', 'none');
maximize(gcf);
set(gca, 'XTickLabel', Distance_vs_Latency(:,1));
title('Mean of positive delay without Positive Outliers', 'Fontsize', 20);
saveas(gcf, [srcDir DirDelimiter srcDir2 DirDelimiter srcDir2 'Mean_Positive_Delay_without_POutliers.emf']);
saveas(gcf, [srcDir DirDelimiter srcDir2 DirDelimiter srcDir2 'Mean_Positive_Delay_without_POutliers.fig']);

All_Laty  = [];
for i = 1:size(Cell_E2E_Latency, 2)
    Temp_Laty = Cell_E2E_Latency{1, i};
    if isempty(Temp_Laty) ~= 1
        Valid_temp_Laty = Temp_Laty(find(Temp_Laty(:, 7) == 1 & Temp_Laty(:, 6) >= 0),:);
        All_Laty = cat(1, All_Laty, Valid_temp_Laty);
    end
end
figure;
boxplot(All_Laty(:, 6));
maximize(gcf);







