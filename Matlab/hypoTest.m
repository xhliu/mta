%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   @ Author: Xiaohui Liu (whulxh@gmail.com)
%   @ Date: 10/6/2011
%   @ Description: test MAC delays to see if they are unimodal (vp inequality), uncorrelated (compute E2E variance)
%                   and stationary
%       job 5686 for low traffic; 5564 for medium; job 5570 for heavy
%       traffic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dir = '~/Dropbox/tOR/figures/';
ROOT_ID = 15;
PHY_SEQ_IDX = 6;
SAMPLE_IDX = 9;
%% correlation test
%% intra-node
MIN_SAMPLE_CNTS = 100;
LAG_CNTS = 30;
nodes = unique(txs(:, 2));
results = cell(LAG_CNTS, 1);
for i = 1 : size(nodes, 1)
    node = nodes(i);
    % MAC delays occur at each node
    t = rxs;
    % filter invalid samples, i.e., sample of 0xFFFFFFFF
    % and non-samples from Send.send(), which is implicitly filtered bcoz
    % 10-th column is 0, invalid node id
    t = t(t(:, 10) == node & t(:, 8) ~= 65536, :);
    
    % not enough samples
    if size(t, 1) < MIN_SAMPLE_CNTS
        continue;
    end
    
    % rank chronically, i.e., based on last hop physical#
    [s IX] = sort(t(:, PHY_SEQ_IDX));
    t = t(IX, :);
    
    % auto correlation: lags(1) is for lag 0
    [ACF lags] = autocorr(t(:, SAMPLE_IDX), LAG_CNTS);
    for lag = 1 : LAG_CNTS
        results{lag} = [results{lag}; ACF(lag + 1)];
    end
end
%%
data = results(1:2:30, :);
group = zeros(0);
dataDisp = zeros(0);
for i = 1 : size(data, 1)
    group = [group ; ones(size(data{i})) + i - 1];
    dataDisp = [dataDisp ; data{i}];
end

title_str = 'Intra-node packet-time autocorrelation vs lags';
figure('name', title_str);
boxplot(dataDisp, group, 'notch', 'on');
set(gca, 'FontSize', 40, 'xticklabel', 1:2:30);
xlabel('Lag');
ylabel('Intra-node packet-time autocorrelation');
%%
maximize;
set(gcf, 'Color', 'white');
cd(dir);
export_fig 'intra_node_mac_delay_corr' -eps;
export_fig 'intra_node_mac_delay_corr' -jpg -zbuffer;
saveas(gcf, 'intra_node_mac_delay_corr.fig');
%%
t = results;
SIZE = size(t, 1);
s = zeros(SIZE, 3);
alpha = 0.01;
for i = 1 : SIZE
    r = sort(t{i});
    r(isnan(r)) = [];
    % err bound
    lo_idx = ceil(0.5 * size(r, 1) - 0.5 * norminv(1 - alpha / 2, 0, 1) * sqrt(size(r, 1)));
    lo = r(lo_idx);
    lo = median(r) - lo;
    hi_idx = ceil(0.5 * size(r, 1) + 0.5 * norminv(1 - alpha / 2, 0, 1) * sqrt(size(r, 1)));
    hi = r(hi_idx);
    hi = hi - median(r);
    s(i, :) = [median(r) lo hi];
end
title_str = 'Intra-node packet-time autocorrelation vs lags';
figure('name', title_str);
errorbar(1:SIZE, s(:, 1), s(:, 2), s(:, 3));
set(gca, 'FontSize', 40, 'xtick', 1:SIZE);
xlabel('Lag');
ylabel('Intra-node packet-time autocorrelation');

maximize;
set(gcf, 'Color', 'white');
cd(dir);
export_fig 'intra_node_mac_delay_corr_errorbar' -eps;
export_fig 'intra_node_mac_delay_corr_errorbar' -jpg -zbuffer;
saveas(gcf, 'intra_node_mac_delay_corr_errorbar.fig');
%% inter-node
% pre-load 'node_id.mat'
for i = 1 : 105
    if exist([num2str(i) '.mat'], 'file')
        load([num2str(i) '.mat']);
        if exist('Packet_Log', 'var')
            t = Packet_Log;
            t = t(t(:, 1) == 9 | t(:, 1) == 10, :);
            t = t(~(t(:, 1) == 10 & (t(:, 10) == 0 | t(:, 8) == 65535)), :);
            eval(['Packet_Log' num2str(i) ' = t;']);
            clear Packet_Log;
        end
    end
end

% compute
clc;
LAG_CNTS = 30;
lag_mac_delays = cell(LAG_CNTS, 1);
% idx = ones(LAG_CNTS, 1);
% for i = 1 : LAG_CNTS
%     lag_mac_delays{i} = zeros(1000000, 6);
%     idx(i) = 1;
% end
% MAX_HOP = 20;
% t stores all MAC delay samples
t = rxs;
% validate
t = t(t(:, 10) ~= 0 & t(:, 8) ~= 65535, :);
links = unique(t(:, [10 2]), 'rows');
% lag = 1;
MIN_SAMPLE_CNTS = 1000;
MAC_SAMPLE_CNTS = 5000;
LINK_CNTS = 20;
% tmp = [];
for lag = 1 : LAG_CNTS
    link_cnt = 0;
    mac_delays = zeros(1000000, 6);
    idx = 1;
    % each link
    for i = 1 : size(links, 1)
        link = links(i, :);
        sender = link(1);
        receiver = link(2);
        if ROOT_ID == receiver
            continue;
        end
        % receiver tx/rx log
        eval(['s = Packet_Log' num2str(receiver) ';']);

        r = t(t(:, 10) == sender & t(:, 2) == receiver, 3:4);
        pkts = unique(r, 'rows');
        
%         tmp = [tmp; size(pkts, 1)];
%         continue;
        
        if size(pkts, 1) < MIN_SAMPLE_CNTS || size(pkts, 1) > MAC_SAMPLE_CNTS || link_cnt > LINK_CNTS
            continue;
        end
        link_cnt = link_cnt + 1;

        % each pkt passing this link
        for j = 1 : size(pkts)
            fprintf('processing (%d, %d) \n', i, j);
            pkt = pkts(j, :);

            % find the pkt
            IX = find(s(:, 1) == 10 & s(:, 3) == pkt(1) & s(:, 4) == pkt(2) & s(:, 10) == sender, 1);
            if isempty(IX)
                fprintf('warning 1 for entry %d\n', i);
                continue;
            end
            sender_mac_delay = s(IX, 9);

            % next i-th pkt sent upon reception of the pkt in concern
            r = s(IX + 1 : end, :);
            IX = find(r(:, 1) == 9, lag);
            if size(IX, 1) < lag
                fprintf('warning 2 for entry %d\n', i);
                continue;
            end

            % MAC delay for next i-th pkt sent
            IX = IX(lag);
            next_pkt = r(IX, 3:4);
            next_receiver = r(IX, 10);

            IX = find(t(:, 2) == next_receiver & t(:, 10) == receiver ...
                    & t(:, 3) == next_pkt(1) & t(:, 4) == next_pkt(2), 1);
            if isempty(IX)
                fprintf('warning 3 for entry %d\n', i);
                continue;
            end
            receiver_mac_delay = t(IX, 9);

            mac_delays(idx, :) = [link pkt sender_mac_delay receiver_mac_delay];
            idx = idx + 1;
        end
    end
    mac_delays(idx : end, :) = [];
    lag_mac_delays{lag} = mac_delays;
end
% save('lag_mac_delays.mat', 'lag_mac_delays');
%% display [link pkt sender_mac_delay receiver_mac_delay]
t = lag_mac_delays(1:2:30, :);
results = cell(size(t, 1), 1);
for i = 1 : size(t, 1)
    s = t{i};
    
    links = unique(s(:, 1 : 2), 'rows');
    result = zeros(size(links, 1), 1);
    idx = 1;
    for j = 1 : size(links, 1)
        link = links(j, :);
        link_mac_delays = s(s(:, 1) == link(1) & s(:, 2) == link(2), 5:6);
        if size(link_mac_delays, 1) < 100
            continue;
        end
        tmp = corrcoef(link_mac_delays);
        result(idx) = tmp(1, 2);
        idx = idx + 1;
    end
    results{i} = result(1 : (idx - 1), :);
end

% display
data = results;
group = zeros(0);
dataDisp = zeros(0);
for i = 1 : size(data, 1)
    group = [group ; ones(size(data{i})) + i - 1];
    dataDisp = [dataDisp ; data{i}];
end

title_str = 'Inter-node packet-time correlation vs lags';
figure('name', title_str);
boxplot(dataDisp, group, 'notch', 'on');
set(gca, 'FontSize', 40, 'xticklabel', 1:2:30);
xlabel('Lag');
ylabel('Inter-node packet-time correlation');
%%
maximize;
set(gcf, 'Color', 'white'); % Sets figure background
cd(dir);
export_fig 'inter_node_mac_delay_corr' -eps;
export_fig 'inter_node_mac_delay_corr' -jpg -zbuffer;
saveas(gcf, 'inter_node_mac_delay_corr.fig');
%%
t = results;
SIZE = size(t, 1);
s = zeros(SIZE, 3);
alpha = 0.01;
for i = 1 : SIZE
    r = sort(t{i});
    r(isnan(r)) = [];
    % err bound
    lo_idx = ceil(0.5 * size(r, 1) - 0.5 * norminv(1 - alpha / 2, 0, 1) * sqrt(size(r, 1)));
    lo = r(lo_idx);
    lo = median(r) - lo;
    hi_idx = ceil(0.5 * size(r, 1) + 0.5 * norminv(1 - alpha / 2, 0, 1) * sqrt(size(r, 1)));
    hi = r(hi_idx);
    hi = hi - median(r);
    s(i, :) = [median(r) lo hi];
end
title_str = 'Inter-node packet-time correlation vs lags';
figure('name', title_str);
errorbar(1:SIZE, s(:, 1), s(:, 2), s(:, 3));
set(gca, 'FontSize', 40, 'xtick', 1:SIZE);
xlabel('Lag');
ylabel('Inter-node packet-time correlation');

maximize;
set(gcf, 'Color', 'white'); % Sets figure background
cd(dir);
export_fig 'inter_node_mac_delay_corr_errorbar' -eps;
export_fig 'inter_node_mac_delay_corr_errorbar' -jpg -zbuffer;
saveas(gcf, 'inter_node_mac_delay_corr_errorbar.fig');
%% link MAC delay stationary test
t = rxs;
t = t(t(:, 10) ~= 0 & t(:, 8) ~= 65535, :);
links = unique(t(:, [10 2]), 'rows');
results = zeros(size(links, 1), 3);
idx = 1;
SAMPLE_THRESHOLD = 1000;
for i = 1 : size(links, 1)
    link = links(i, :);
    link_mac_delays = t(t(:, 10) == link(1) & t(:, 2) == link(2), 9);
    
    if size(link_mac_delays, 1) < SAMPLE_THRESHOLD
        continue;
    end
    results(idx, :) = [link adftest(link_mac_delays)];
    idx = idx + 1;
end
results(idx : end, :) = [];
% format: [sender, receiver, link MAC delay stationary test result]
save('stationary.mat', 'results');
%% stationarity coherence window
% 1) filter out transient stationarity results
% 2) too few samples can be mistaken for non-stationary
MIN_SAMPLE_SIZE = 10000;
STEP = 100;
% number of consecutive results to claim results: e.g., 100 stationary
% together means stationary
FILTER_SIZE = 10;
%
coherence_wnd_sizes = zeros(1000000, 1);
idx = 1;

t = rxs;
t = t(t(:, 10) ~= 0 & t(:, 8) ~= 65535, :);
links = unique(t(:, [10 2]), 'rows');
results = zeros(size(links, 1), 3);
idx = 1;

valid_cnts = 0;
invalid_cnts = 0;

for k = 1 : size(links, 1)
    link = links(k, :);
    fprintf('link (%u, %u)\n', link(1), link(2));
    link_mac_delays = t(t(:, 10) == link(1) & t(:, 2) == link(2), 9);
    
    if size(link_mac_delays, 1) < MIN_SAMPLE_SIZE
        continue;
    end
    
    % s now contain pkt time series for the link
    s = link_mac_delays;
    i = 1;
    % ensure the remaining time series is long enough
    for i = 1 : STEP : (size(s, 1) - MIN_SAMPLE_SIZE)
        fprintf('seq #%d of link %d\n', i, k);
        % expected sequences: [non-stationary] stationary [non-stationary]
        stationary_found = false;
        stationary_cnt = 0;
        nonstationary_cnt = 0;
        % level stationarity test
        for j = (i + 1) : STEP : size(s, 1)
            x = s(i : j);
            % non-stationary
            if kpsstest(x, 'alpha', .01, 'trend', false)
                nonstationary_cnt = nonstationary_cnt + 1;
                stationary_cnt = 0;
                if stationary_found && nonstationary_cnt >= FILTER_SIZE
                    break;
                end
            else
                stationary_cnt = stationary_cnt + 1;
                nonstationary_cnt = 0;
                if stationary_cnt >= FILTER_SIZE
                    stationary_found = true;
                end
            end
        end

        if stationary_found
            coherence_wnd_sizes(idx, :) = j - i;
            idx = idx + 1;
            valid_cnts = valid_cnts + 1;
            
            if (j - i) < 200
                fprintf('%d %d %d\n', i, j, size(s, 1));
                plot(x);
            end
%         else
%             plot(x);
%             fprintf('%d %d %d\n', i, j, size(s, 1));
%             invalid_cnts = invalid_cnts + 1;
        end
    end
end
coherence_wnd_sizes(idx : end, :) = [];
save('coherence_wnd_sizes.mat', 'coherence_wnd_sizes');
%
t = coherence_wnd_sizes;
% remove outliers caused at the end of time series
t = t(t >= MIN_SAMPLE_SIZE);
% boxplot(t, 'notch', 'on');
[n xout] = hist(t, 100);
bar(xout, 100 * n / sum(n));

%% path delay stationary test
title_str = 'Path delay time series';
% figure('name', title_str);
% plot(link_mac_delays);
set(gca, 'FontSize', 30);
xlabel('Time');
ylabel('Delay for a path (ms)');
%
maximize;
set(gcf, 'Color', 'white'); % Sets figure background
% cd(dir);
export_fig 'path_delay_time_series' -eps;
export_fig 'path_delay_time_series' -jpg -zbuffer;
saveas(gcf, 'path_delay_time_series.fig');

%% packet time serials for a typical link
% mode(t(:, [2 10]))
t = rxs;
link_mac_delays = t(t(:, 2) == 15 & t(:, 10) == 101, 9);
title_str = 'Packet-time time series';
figure('name', title_str);
s = link_mac_delays;
plot(s);
% plot(link_mac_delays);
%%
set(gca, 'FontSize', 30);
xlabel('Sample');
ylabel('Packet-time for a link (ms)');
maximize;
set(gcf, 'Color', 'white'); % Sets figure background
cd(dir);
export_fig 'packet_time_time_series' -eps;
export_fig 'packet_time_time_series' -jpg -zbuffer;
saveas(gcf, 'packet_time_time_series.fig');

%% unimodality test
% find a frequent path
t = pkt_paths;
% t = [1 2 3;
%      2 3 4
%      3 4 5
%      2 3 4];
u_t = unique(t, 'rows');
u_t_cnts = zeros(size(u_t, 1), 1);
u_t_paths = cell(size(u_t, 1), 1);
% count the frequency of each path
% each path
for i = 1 : size(u_t, 1)
    u_path = u_t(i, :);
    tmp = zeros(size(t, 1), 1);
    tmp_idx = 1;
    % each packet
    for j = 1 : size(t, 1)
        path = t(j, :);
        if isempty(find(u_path ~= path, 1))
            % match
            u_t_cnts(i) = u_t_cnts(i) + 1;
            tmp(tmp_idx) = j;
            tmp_idx = tmp_idx + 1;
        end
    end
    u_t_paths{i} = tmp(1 : (tmp_idx - 1));
end
sum(u_t_cnts)
% [x idx] = max(u_t_cnts);
save('paths_cnts.mat', 'u_t', 'u_t_paths', 'u_t_cnts');

% 
[cnts IX] = sort(u_t_cnts, 'descend');
s = pkt_delays(:, 3);
SAMPLE_THRESHOLD = 300;
ALPHA = .05;
p_values = zeros(size(u_t_cnts, 1), 1);
p_cnts = 0;
for i = 1 : size(u_t_cnts, 1)
    if cnts(i) < SAMPLE_THRESHOLD
        break;
    end
    p_cnts = p_cnts + 1;
    path_idx = IX(i);
    fprintf('%d-th frequent path: %d with pkts %d\n', i, path_idx, cnts(i));
    t = s(u_t_paths{path_idx});
    t = t(t < 100000);
 
%     % TODO
%     p_values(i) = (quantile(t, .9) <= (mean(t) + std(t) * 1.8559));
%     continue;

    %     figure; cdfplot(t);
    [dip p_values(i)] = hartigansdipsigniftest(t, 500);
    if p_values(i) < ALPHA
        hist(t, length(t) / 5); 
        saveas(gcf, ['path' num2str(i) '.fig']);
        saveas(gcf, ['path' num2str(i) '.jpg']);
    end
end
p_values(p_cnts + 1 : end) = [];
% ratio of not unimodal
length(find(p_values < ALPHA)) / size(p_values, 1)
% close all;

%% VP equality gives a bound always?
clc;
s = zeros(1000, 3);
idx = 1;
for job_id = 5406 : 5486
    dir_ = ['/home/xiaohui/Projects/tOR/RawData/' num2str(job_id)];
    if ~exist(dir_)
        continue;
    end
    disp('1');
    cd(dir_);
    if ~exist('TxRx.mat')
        continue;
    end
    disp('2');
    load('TxRx.mat');
    
    t = pkt_delays(:, 3);
    t = t(t < 100000);
    fprintf('%f, %f\n', quantile(t, .9), (mean(t) + std(t) * 1.8559));
    s(idx, :) = [job_id, quantile(t, .9), (mean(t) + std(t) * 1.8559)];
    idx = idx + 1;
end
s(idx : end, :) = [];
find(s(:, 2) > s(:, 3))

%% stationarity comparison of path delay and packet time
% path [61 31 66 39 27 15] link [101 15] in job 5564
t = get(get(gca,'Children'), 'YData');
packet_times = t';
% path_delays = t';
% save('packet_time_path_delay_series.mat', 'path_delays', 'packet_times');
% t = path_delays;
t = packet_times(1:2500);
MAX_LAG = 1500;
diff = zeros(MAX_LAG, 1);
% qqplot(t(1 : end - LAG), t(1 + LAG : end))
for lag = 1 : MAX_LAG
    [h p ks2stat] = kstest2(t(1 : end - lag), t(1 + lag : end));
    diff(lag) = ks2stat;
end
hold on; plot(diff);

%
set(gca, 'FontSize', 40);
xlabel('Shift');
ylabel('K-S test statistic');
legend('Path delay', 'Packet time');
%
maximize;
set(gcf, 'Color', 'white'); % Sets figure background
% cd(dir);
export_fig 'path_delay_vs_packet_time_stationarity' -eps;
export_fig 'path_delay_vs_packet_time_stationarity' -jpg -zbuffer;
saveas(gcf, 'path_delay_vs_packet_time_stationarity.fig');

%% stationarity threshold: max shift retaining distribution
% t = packet_times(1 : 2500);
t = path_delays;
MAX_LAG = 1500;
WND_SIZE = 1000;
stationarity = zeros(MAX_LAG, 1);
%
for lag = 1 : MAX_LAG
    [h p ks2stat] = kstest2(t(1 : WND_SIZE), t(1 + lag : lag + WND_SIZE));
    stationarity(lag) = h;
end
plot(stationarity);
% hold on;
%%
set(gca, 'FontSize', 40, 'ytick', [0 1], 'yticklabel', {'Identical', 'Different'});
xlabel('Shift');
ylabel('');
ylim([-0.5 1.5]);
legend('Path delay', 'Packet time');
%
maximize;
set(gcf, 'Color', 'white'); % Sets figure background
% cd(dir);
export_fig 'path_delay_vs_packet_time_stationarity_binary' -eps;
export_fig 'path_delay_vs_packet_time_stationarity_binary' -jpg -zbuffer;
saveas(gcf, 'path_delay_vs_packet_time_stationarity_binary.fig');

%% path queue level dynamics
COLUMNS = 13;
MIN_SAMPLE_SIZE = 100;
% merge all paths
s = pkt_path_qs;
t = zeros(1000000, COLUMNS);
idx = 1;
for i = 1 : size(s, 1)
    r = s{i};
    
    len = size(r, 1);
    t(idx : idx + len - 1, :) = r;
    idx = idx + len;
end
% t now contains all paths and their queue levels;
t(idx : end, :) = [];

% for each path
coherence_wnds = zeros(1000000, 1);
idx = 1;
r = t(:, 3 : end - 1);
u_paths = unique(r, 'rows');
for k = 1 : size(u_paths)
    path = u_paths(k, :);
    
    IX = find(ismember(r, path, 'rows'));
    % queue levels for a path
    s = t(IX, end);
    if size(s, 1) < MIN_SAMPLE_SIZE
        continue;
    end
    
    i = 1;
    while i < size(s, 1)
        for j = (i + 1) : size(s, 1)
            if s(j) ~= s(i)
                break;
            end
        end
        coherence_wnds(idx) = j - i;
        idx = idx + 1;
        
%         if (j - i) > 1000
%             plot(s);
%         end  
        
        i = j;
    end     
end
coherence_wnds(idx : end) = [];
%
s = coherence_wnds;
s = s(s < quantile(s, .999));
figure;
[n xout] = hist(s, 100);
bar(xout, 100 * n / sum(n));
set(gca, 'FontSize', 30);
xlabel('Coherence window size');
ylabel('Frequency (%)');
%
maximize;
set(gcf, 'Color', 'white'); % Sets figure background
cd('~/Dropbox/tOR/figures/');
export_fig 'path_queue_level_coherence_heavy' -eps;
export_fig 'path_queue_level_coherence_heavy' -jpg -zbuffer;
saveas(gcf, 'path_queue_level_coherence_heavy.fig');
%% time series
[a,b,uIdx] = unique(pkt_paths, 'rows');
modeIdx = mode(uIdx);
modeRow = a(modeIdx,:); %# the first output argument
%
QUEUE_SIZE_IDX = 7;
% medium traffic
path = [61; 31; 66; 39; 27; 15];
% path = modeRow;
t = pkt_paths;
IX = find(t(:, 1) == 61 & t(:, 2) == 31 & t(:, 3) == 66 & t(:, 4) == 39 & ...
            t(:, 5) == 27 & t(:, 6) == 15);
% IX = find(ismember(t, path, 'rows'));
%
seqnos = unique(pkt_delays(IX, 2));
%
t = rxs(rxs(:, 3) == path(1), :);
total_queue_sizes = zeros(size(seqnos, 1), 1);
idx = 1;
% each packet
for i = 1 : size(seqnos, 1)
    seqno = seqnos(i);
    
    s = t(t(:, 4) == seqno, :);
    total_queue_size = 0;
    % each node along the path excluding sink
    is_break = false;
    for j = 1 : (size(path, 1) - 1)
        node = path(j);
        IX = find(s(:, 2) == node, 1);
        if isempty(IX)
            disp('err');
            is_break = true;
            break;
        end
        % include pkt itself
        total_queue_size = total_queue_size + s(IX, QUEUE_SIZE_IDX) + 1;
    end
    if is_break
        continue;
    end
%     fprintf('%d-th pkt queueing: %d\n', i, total_queue_size);
    total_queue_sizes(idx) = total_queue_size;
    idx = idx + 1;
end
total_queue_sizes(idx : end) = [];
% time series
figure;
plot(total_queue_sizes);
set(gca, 'FontSize', 40);
xlabel('Sample');
ylabel('Path queue level');
%
maximize;
set(gcf, 'Color', 'white'); % Sets figure background
cd('/home/xiaohui/Dropbox/tOR/figures');
export_fig 'path_queueing_time_series' -eps;
export_fig 'path_queueing_time_series' -jpg -zbuffer;
saveas(gcf, 'path_queueing_time_series.fig');

% 2) stationarity
t = total_queue_sizes;
MAX_LAG = 1500;
diff = zeros(MAX_LAG, 1);
% qqplot(t(1 : end - LAG), t(1 + LAG : end))
for lag = 1 : MAX_LAG
    [h p ks2stat] = kstest2(t(1 : end - lag), t(1 + lag : end));
    diff(lag) = ks2stat;
end
plot(diff);
set(gca, 'FontSize', 40);
xlabel('Shift');
ylabel('K-S test statistic');
%
maximize;
set(gcf, 'Color', 'white'); % Sets figure background
cd('/home/xiaohui/Dropbox/tOR/figures');
export_fig 'path_queueing_stationarity' -eps;
export_fig 'path_queueing_stationarity' -jpg -zbuffer;
saveas(gcf, 'path_queueing_stationarity.fig');

% 3) stationary or not
t = total_queue_sizes;
% t = path_delays;
MAX_LAG = 1500;
stationarity = zeros(MAX_LAG, 1);
%
for lag = 1 : MAX_LAG
    [h p ks2stat] = kstest2(t(1 : end - lag), t(1 + lag : end), 0.1);
    stationarity(lag) = h;
end
figure;
plot(stationarity);
%
set(gca, 'FontSize', 40, 'ytick', [0 1], 'yticklabel', {'Identical', 'Different'});
xlabel('Shift');
ylabel('');
ylim([-0.5 1.5]);
% legend('Path delay', 'Packet time');
%
maximize;
set(gcf, 'Color', 'white'); % Sets figure background
% cd(dir);
export_fig 'path_queueing_stationarity_binary' -eps;
export_fig 'path_queueing_stationarity_binary' -jpg -zbuffer;
saveas(gcf, 'path_queueing_stationarity_binary.fig');
%% queueing dynamics
t = s(IX, end);
LAG_CNTS = 301;
STEP = 30;
diffs = cell(LAG_CNTS, 1);
relative_diffs = cell(LAG_CNTS, 1);
for lag = 1 : STEP : LAG_CNTS
    diff = t(1 + lag : end) - t(1 : end - lag);
    diffs{lag} = diff;
    relative_diff = diff ./ t(1 : end - lag);
    relative_diffs{lag} = relative_diff;
end

data = diffs;
group = zeros(0);
dataDisp = zeros(0);
for i = 1 : size(data, 1)
    group = [group ; (ones(size(data{i})) + i - 1)];
    dataDisp = [dataDisp; data{i}];
end
figure;
boxplot(dataDisp, group, 'notch', 'on');
set(gca, 'FontSize', 30);
xlabel('Lag');
ylabel('Path queue size changes');
%% find stationary shift threshold for all paths
t = pkt_paths;
r = unique(t, 'rows');
stationarity_thresholds = zeros(size(r, 1), 1);
idx = 1;

MAX_E2E_DELAY = 100000;
MAX_LAG = 1000;

for i = 1 : size(r, 1)
    fprintf('path %d\n', i);
    path = r(i, :);
    IX = zeros(size(t, 1), 1);
    % find all such paths
    for j = 1 : size(t, 1)
        if all(t(j, :) == path)
            IX(j) = 1;
        end
    end
    IX = find(IX > 0);

    s = pkt_delays(IX, 3);
    s = s(s < MAX_E2E_DELAY);
    plot(s);
    if size(s, 1) <= MAX_LAG
        continue;
    end
    for lag = 1 : MAX_LAG
        [h p ks2stat] = kstest2(s(1 : end - lag), s(1 + lag : end), .1);
        if 1 == h
            fprintf('stationary threshold: %d\n', lag);
            break;
        end
    end
    stationarity_thresholds(idx) = lag;
    idx = idx + 1;
end
stationarity_thresholds(idx : end) = [];
plot(stationarity_thresholds);
save('stationarity_threshold.mat', 'stationarity_thresholds');
%% stationary coherence for all paths
MIN_SAMPLE_SIZE = 100;
coherence_wnd_sizes = zeros(1000000, 1);
idx = 1;

t = pkt_paths;
r = unique(t, 'rows');
stationarity_thresholds = zeros(size(r, 1), 1);
idx = 1;

MAX_E2E_DELAY = 100000;
SAMPLE_THRESHOLD = 1000;

for k = 1 : size(r, 1)
    fprintf('path %d\n', k);
    path = r(k, :);
    IX = find(ismember(t, path, 'rows'));

    s = pkt_delays(IX, 3);
    s = s(s < MAX_E2E_DELAY);
    if size(s, 1) <= SAMPLE_THRESHOLD
        continue;
    end
    
    % s now contain pkt time series for the path
    i = 1;
    while i <= (size(s, 1) - MIN_SAMPLE_SIZE)
        % level stationarity test
        for j = (i + MIN_SAMPLE_SIZE) : 10 : size(s, 1)
            x = s(i : j);
            % non-stationary
            if kpsstest(x, 'alpha', .01, 'trend', false)
                plot(x);
                break;
            end
        end

        coherence_wnd_sizes(idx, :) = j - i;
        idx = idx + 1;

        i = j;
    end
end
coherence_wnd_sizes(idx : end, :) = [];
save('path_delay_coherence_wnd_sizes.mat', 'coherence_wnd_sizes');
%
t = coherence_wnd_sizes;
% remove outliers caused at the end of time series
t = t(t >= MIN_SAMPLE_SIZE);
% boxplot(t, 'notch', 'on');
[n xout] = hist(t, 100);
bar(xout, 100 * n / sum(n));
%% find stationary shift threshold for all links
t = rxs;
t = t(t(:, 10) ~= 0 & t(:, 8) ~= 65535, :);
% [sender receiver pkt_time]
t = t(:, [10 2 9]);
r = unique(t(:, 1:2), 'rows');
stationarity_thresholds = zeros(size(r, 1), 1);
idx = 1;

MAX_PKT_TIME = 1000;
MAX_LAG = 5000;

for i = 1 : size(r, 1)
    fprintf('link %d\n', i);
    link = r(i, :);
    % find all such links
    IX = find(t(:, 1) == link(1) & t(:, 2) == link(2));

    s = t(IX, 3);
    s = s(s < MAX_PKT_TIME);
    plot(s);
    if size(s, 1) <= MAX_LAG
        continue;
    end
    for lag = 1 : 100 : MAX_LAG
        [h p ks2stat] = kstest2(s(1 : end - lag), s(1 + lag : end), .1);
        if 1 == h
            fprintf('stationary threshold: %d\n', lag);
            break;
        end
    end
    stationarity_thresholds(idx) = lag;
    idx = idx + 1;
end
stationarity_thresholds(idx : end) = [];
plot(stationarity_thresholds);
%
t = cell(2, 1);
t{1} = path_delay_stationarity_thresholds;
t{2} = pkt_time_stationarity_thresholds;

data = t;
group = zeros(0);
dataDisp = zeros(0);
for i = 1 : size(data, 1)
    group = [group ; ones(size(data{i})) + i - 1];
    dataDisp = [dataDisp ; data{i}];
end

title_str = 'Inter-node MAC delay Correlation vs Lags';
figure('name', title_str);
boxplot(dataDisp, group, 'notch', 'on');
set(gca, 'FontSize', 40, 'xticklabel', {'Path delay', 'Packet time'});
xlabel('');
ylabel('Stationarity threshold');
%
maximize;
set(gcf, 'Color', 'white'); % Sets figure background
cd('/home/xiaohui/Dropbox/tOR/figures');
export_fig 'stationarity_threshold' -eps;
export_fig 'stationarity_threshold' -jpg -zbuffer;
saveas(gcf, 'stationarity_threshold.fig');

%% slack comparision btw. EDF vs FIFO
% job_ids = [5192:5194 5328:5333]';
job_ids = [4569 4571 4572 4642 4643 4646 4658 4748]';   % EDF
slacks = zeros(1000000, 1);
idx = 1;
for i = 1 : size(job_ids, 1)
    MAX_E2E_DELAY = 100000;
    load(['/home/xiaohui/Projects/tOR/RawData/' num2str(job_ids(i)) '/TxRx.mat']);
    deadline = srcPkts(1, 10);

    t = pkt_delays(:, 3);
    t = t(t <= MAX_E2E_DELAY);
    t = deadline - t;
    t = t(t >= 0);

    slacks(idx : idx + size(t, 1) - 1) = t;
    idx = idx + size(t, 1);
end
slacks(idx : end, :) = [];
save('edf_slacks.mat', 'slacks');
cdfplot(slacks);