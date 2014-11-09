%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Xiaohui Liu (whulxh@gmail.com)
%   Date:   10/12/2011
%   Function: misc figures to analyze details of protocols
%       job 5686 for low traffic; 5564 for medium; job 5570 for heavy
%       traffic
%   1): actual queue size is queue size in record plus 1 bcoz it's snapshot
%       prior to enqueue
%   2): proportional correlation uses heavy traffic bcoz it groups by median
%   queue level, which in medium traffic is mostly 1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% queueing dynamics
dir = '~/Dropbox/tOR/figures/';
ROOT_ID = 15;
QUEUE_SIZE_IDX = 7;
MEDIAN_CI_MIN_SAMPLE = 4;
QUEUE_SIZE = 28;
%% queueing autocorrelation 1): node-level
MIN_SAMPLE_CNTS = 1000;
% LAG_CNTS = 200;
% LAG_STEP = 10;
LAGS = [1 2 5 10 20 50 100 200 500]';
t = rxs;
% correlation
nodes = unique(t(:, 2));
results = cell(size(LAGS, 1), 1);

for i = 1 : size(nodes, 1)
    node = nodes(i);
    % queue levels at a node
    s = t(t(:, 2) == node, QUEUE_SIZE_IDX);
    
    if size(s, 1) < MIN_SAMPLE_CNTS
        continue;
    end
    
    % auto correlation: lags(1) is for lag 0
    ACF = autocorr(s, LAGS(end));
    for j = 1 : size(LAGS, 1)
        lag = LAGS(j);
        results{j} = [results{j}; ACF(lag + 1)];
    end
end

data = results;
group = zeros(0);
dataDisp = zeros(0);
for i = 1 : size(data, 1)
    group = [group ; ones(size(data{i})) + i - 1];
    dataDisp = [dataDisp ; data{i}];
end
title_str = 'Queueing Level Autocorrelation vs Lags';
figure('name', title_str);
boxplot(dataDisp, group, 'notch', 'on');
set(gca, 'FontSize', 40, 'xticklabel', LAGS');
xlabel('Lag (h)');
ylabel('Autocorrelation coefficient');
%%
maximize;
set(gcf, 'Color', 'white');
cd(dir);
str = 'heavy_traffic_node_queue_autocorr';
export_fig(str, '-eps');
export_fig(str, '-jpg', '-zbuffer');
saveas(gcf, [str '.fig']);

%% errobar
alpha = 0.01;
t = results;
SIZE = size(t, 1);
s = zeros(SIZE, 3);
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
title_str = 'Queueing Level Autocorrelation vs Lags';
figure('name', title_str);
errorbar(1:SIZE, s(:, 1), s(:, 2), s(:, 3));
set(gca, 'FontSize', 40, 'xtick', 1:SIZE);
xlabel('Lag (h)');
ylabel('Autocorrelation coefficient');
%
maximize;
set(gcf, 'Color', 'white');
cd(dir);
export_fig 'heavy_traffic_node_queue_autocorr_errorbar_99' -eps;
export_fig 'heavy_traffic_node_queue_autocorr_errorbar_99' -jpg -zbuffer;
saveas(gcf, 'heavy_traffic_node_queue_autocorr_errorbar_99.fig');

%% coherence
t = rxs;
nodes = unique(t(:, 2));
ROOT_ID = 15;
coherence_wnds = zeros(1000000, 1);
idx = 1;
for k = 1 : size(nodes, 1)
    node = nodes(k);
    fprintf('processing node %d\n', node);
    
    % skip root
    if ROOT_ID == node
        continue;
    end
    % queue levels at a node
    s = t(t(:, 2) == node, QUEUE_SIZE_IDX);
    
%     if ~all(s <= 28)
%         disp('err');
%     end
%     s = floor(rand(10, 1) * 3);
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
% cdfplot(coherence_wnds);

s = coherence_wnds;
% cut the extreme tail showing up at srcs to make fig look better
s = s(s < quantile(s, .99));
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
export_fig 'node_queue_level_coherence_medium' -eps;
export_fig 'node_queue_level_coherence_medium' -jpg -zbuffer;
saveas(gcf, 'node_queue_level_coherence_medium.fig');
%% queueing 2): path-level
% group by source
srcs = unique(destPkts(:, 3));
NTW_SIZE = 10;
MAX_SEQ = 5000;
% paths = cell(size(srcs, 1), 1);
% [src seqno [path] pkt_path_q_levels]
pkt_path_qs = cell(size(srcs, 1), 1);
for i = 1 : size(srcs, 1)
    src = srcs(i);
    seqs = destPkts(destPkts(:, 3) == src, 4);
    seqs = unique(seqs);
    % invalid log
    if size(seqs, 1) < MAX_SEQ
        fprintf('error 0\n');
        continue;
    end
    % [pkt path queue]
    pkt_path_q = zeros(size(seqs, 1), 2 + NTW_SIZE + 1);
    seq_idx = 1;
    % each seq
    for j = 1 : MAX_SEQ %size(seqs, 1)
        seq = seqs(j);
        total_q = 0;
        t = txs;
        t = t(t(:, 3) == src & t(:, 4) == seq, :);
        r = rxs;
        r = r(r(:, 3) == src & r(:, 4) == seq, :);
        
        % each hop
        node = src;
        path = zeros(1, NTW_SIZE);
        idx = 1;
        while node ~= ROOT_ID
            fprintf('%d-th src %d, %d-th seq %d, hop %d\n', i, src, j, seq, idx);
            
            path(idx) = node;
            idx = idx + 1;
            if idx > NTW_SIZE
                break;
            end
            
            % queue level
            IX = find(r(:, 2) == node, 1);
            if isempty(IX)
                fprintf('error 1\n');
                break;
            end
            % queue level excluding the pkt itself
            total_q = total_q + r(IX, QUEUE_SIZE_IDX) + 1;

            % find next hop
            IX = find(t(:, 2) == node, 1);
            if isempty(IX)
                fprintf('error 2\n');
                break;
            end
            node = t(IX, 10);
        end
        % only consider pkt reaching sink
        if ROOT_ID == node
            path(idx) = node;
            % counted more than once at source
            pkt_path_q(seq_idx, :) = [src seq path total_q - 1];
            seq_idx = seq_idx + 1;
        end
    end
    pkt_path_qs{i} = pkt_path_q(1 : seq_idx - 1, :);
end
% remove empty cells; they can result from corrupt log of fake srcs
idx = 1;
for i = 1 : size(pkt_path_qs, 1)
    if ~isempty(pkt_path_qs{i})
        pkt_path_qs{idx} = pkt_path_qs{i};
        idx = idx + 1;
    end
end
pkt_path_qs(idx : end, :) = [];
save('pkt_path_qs.mat', 'pkt_path_qs');

%% manually search path consecutively used most
t = pkt_path_qs;
sequential_path_qs = cell(12, 1);
% for job 5570
sequential_path_qs{1} = t{1}(551:716, 13);
sequential_path_qs{2} = t{1}(788:935, 13);
sequential_path_qs{3} = t{10}(803:996, 13);
sequential_path_qs{4} = t{5}(1558:1889, 13);
sequential_path_qs{5} = t{3}(486:618, 13);
sequential_path_qs{6} = t{3}(1566:1768, 13);
sequential_path_qs{7} = t{4}(575:716, 13);
sequential_path_qs{8} = t{4}(799:935, 13);
sequential_path_qs{9} = t{4}(1754:1988, 13);
sequential_path_qs{10} = t{6}(1406:1485, 13);
sequential_path_qs{11} = t{7}(407:573, 13);
sequential_path_qs{12} = t{7}(1517:1707, 13);
% % for job 5564
% sequential_path_qs{1} = t{1}(1:669, 13); %t{10}(501:1000, 13);
% sequential_path_qs{2} = t{2}(482:729, 13);
% sequential_path_qs{3} = t{3}(317:723, 13);
% sequential_path_qs{4} = t{4}(206:585, 13);
% sequential_path_qs{5} = t{7}(23:274, 13);
% sequential_path_qs{6} = t{7}(278:701, 13);
% sequential_path_qs{7} = t{7}(795:1000, 13);
% sequential_path_qs{8} = t{8}(23:282, 13);
% sequential_path_qs{9} = t{9}(27:282, 13);
% sequential_path_qs{10} = t{10}(14:233, 13);
save('sequential_path_qs.mat', 'sequential_path_qs');
%% display
MIN_SAMPLE_CNTS = 100;
LAGS = [1:4 5:5:50]';
t = sequential_path_qs;
results = cell(size(LAGS, 1), 1);

for i = 1 : size(t, 1)
    s = t{i};
    
    if size(s, 1) < MIN_SAMPLE_CNTS
        continue;
    end
    
    % auto correlation: lags(1) is for lag 0
    ACF = autocorr(s, LAGS(end));
    for j = 1 : size(LAGS, 1)
        lag = LAGS(j);
        results{j} = [results{j}; ACF(lag + 1)];
    end
end

data = results;
group = zeros(0);
dataDisp = zeros(0);
for i = 1 : size(data, 1)
    group = [group ; ones(size(data{i})) + i - 1];
    dataDisp = [dataDisp ; data{i}];
end
title_str = 'Path queueing level autocorrelation vs lags';
figure('name', title_str);
boxplot(dataDisp, group, 'notch', 'on');
set(gca, 'FontSize', 30, 'xticklabels', LAGS);
xlabel('Lag (h)');
ylabel('Autocorrelation coefficient');
%%
maximize;
set(gcf, 'Color', 'white');
cd(dir);
str = 'medium_traffic_path_queue_autocorr';
export_fig(str, '-eps');
export_fig(str, '-jpg', '-zbuffer');
saveas(gcf, [str '.fig']);
%% errorbar
alpha = 0.01;
t = results;
SIZE = size(t, 1);
s = zeros(SIZE, 3);
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
title_str = 'Queueing Level Autocorrelation vs Lags';
figure('name', title_str);
errorbar(1:SIZE, s(:, 1), s(:, 2), s(:, 3));
set(gca, 'FontSize', 40, 'xtick', 1:SIZE);
xlabel('Lag (h)');
ylabel('Autocorrelation coefficient');
%
maximize;
set(gcf, 'Color', 'white');
cd(dir);
export_fig 'heavy_traffic_path_queue_autocorr_errorbar_99' -eps;
export_fig 'heavy_traffic_path_queue_autocorr_errorbar_99' -jpg -zbuffer;
saveas(gcf, 'heavy_traffic_path_queue_autocorr_errorbar_99.fig');
%% show max of MAC delay is conservative
t = rxs;
% validate
t = t(t(:, 10) ~= 0 & t(:, 8) ~= 65535, :);
% mode(t(:, [2 10]))
t = t(t(:, 2) == 15 & t(:, 10) == 101, 9);
figure('name', 'Packet-time distribution of a link');
cdfplot(t);
set(gca, 'FontSize', 30, 'YGrid', 'on');
set(gca, 'YTick', 0 : .1 : 1);
% xlabel('Packet-time distribution of a link (ms)');
xlabel('');
ylabel('');
title('');

maximize;
set(gcf, 'Color', 'white');
cd(dir);
export_fig 'link_mac_delay_dist' -eps;
export_fig 'link_mac_delay_dist' -jpg -zbuffer;
saveas(gcf, 'link_mac_delay_dist.fig');

%% proportional correlation lag with queueing level
% previously rx log is used, here tx log is
%% proportional correlation: node queue level
% [1,2,3,   5,7,    9,10,11;]
% queue_medians = [2 6 10];
% 1) queue level autocorrelation
MIN_SAMPLE_CNTS = 1000;
% use tx queue log instead
t = txs;
LAG = 1;
QUEUE_SIZE = 28;
QUEUE_SIZE_IDX = 5;
nodes = unique(t(:, 2));
% idx = 1;
dataDisps = [];
lo_errs = [];
hi_errs = [];
alpha = 0.1;


lags = [1 5 10 15 20 50 100];
lags = lags';

LAG_CNTS = size(lags, 1);
legends = cell(LAG_CNTS, 1);
for i = 1 : LAG_CNTS
    legends{i} = ['Lag ' num2str(lags(i))];
end
for lag_idx = 1 : size(lags, 1)
    lag = lags(lag_idx);
    % include empty queue
    results = cell(QUEUE_SIZE + 1, 1);
    % each node
    for i = 1 : size(nodes, 1)
        node = nodes(i);
        s = t(t(:, 2) == node, QUEUE_SIZE_IDX);

        % validate
        s = s(s <= QUEUE_SIZE);

        if size(s, 1) < MIN_SAMPLE_CNTS
            continue;
        end

        % include pkt itself
        idx = median(s) + 1;
%         idx = ceil((median(s + 1)) / 4);
        ACF = autocorr(s, lag);
        results{idx} = [results{idx}; ACF(lag + 1)];
    end
    % remove invalid entries
    idx = 1;
    % remember all path queue level medians
    queue_medians = [];
    for i = 1 : size(results, 1)
        if ~isempty(results{i})
            results{idx} = results{i};
            idx = idx + 1;           
            % record valid queue level medians
            queue_medians = [queue_medians i];
        end
    end
    results(idx : end, :) = [];
    %
    data = results;
    dataDisp = zeros(0);
    lo_err = [];
    hi_err = [];
    for i = 1 : size(data, 1)
        s = data{i};
        % validate
        s(isnan(s)) = [];

        dataDisp = [dataDisp ; median(s)];
        % CI for median
        if size(s, 1) >= MEDIAN_CI_MIN_SAMPLE
            r = sort(s);
            lo_idx = ceil(0.5 * size(r, 1) - 0.5 * norminv(1 - alpha / 2, 0, 1) * sqrt(size(r, 1)));
            lo = r(lo_idx);
            lo = median(r) - lo;
            hi_idx = ceil(0.5 * size(r, 1) + 0.5 * norminv(1 - alpha / 2, 0, 1) * sqrt(size(r, 1)));
            hi = r(hi_idx);
            hi = hi - median(r);
        else
            lo = 0;
            hi = 0;
        end 
        lo_err = [lo_err; lo];
        hi_err = [hi_err; hi];
    end
    dataDisps = [dataDisps dataDisp];
    lo_errs = [lo_errs lo_err];
    hi_errs = [hi_errs hi_err];
end
%
figure;
barerrorbar({1:size(dataDisps, 1), dataDisps}, {repmat((1:size(dataDisps, 1))', 1, size(lags, 1)), dataDisps, lo_errs, hi_errs, 'x'});
legend(legends);
set(gca, 'FontSize', 30, 'xticklabel', queue_medians);
xlabel('Median node queue level');
ylabel('Median autocorrelation coefficient');
%
maximize;
set(gcf, 'Color', 'white');
cd(dir);
export_fig 'medium_traffic_proportional_queue_autocorr' -eps;
export_fig 'medium_traffic_proportional_queue_autocorr' -jpg -zbuffer;
saveas(gcf, 'medium_traffic_proportional_queue_autocorr.fig');
%% 2) queue level change
% heavy [1,2,3,   5,7,    9,10,11;]
% 1) queue level autocorrelation
MIN_SAMPLE_CNTS = 1000;
% use tx queue log instead
t = txs;
LAG = 1;
QUEUE_SIZE = 28;
QUEUE_SIZE_IDX = 5;
nodes = unique(t(:, 2));
% idx = 1;
dataDisps = [];
lo_errs = [];
hi_errs = [];
alpha = 0.1;

lags = [1 3 5 10];
lags = lags';

LAG_CNTS = size(lags, 1);
legends = cell(LAG_CNTS, 1);
for i = 1 : LAG_CNTS
    legends{i} = ['Lag ' num2str(lags(i))];
end
for lag_idx = 1 : size(lags, 1)
    lag = lags(lag_idx);
    % include empty queue
    results = cell(QUEUE_SIZE + 1, 1);
    % each node
    for i = 1 : size(nodes, 1)
        node = nodes(i);
        s = t(t(:, 2) == node, QUEUE_SIZE_IDX);

        % validate
        s = s(s <= QUEUE_SIZE);

        if size(s, 1) < MIN_SAMPLE_CNTS
            continue;
        end

        % include pkt itself
%         idx = max(s) + 1;    % medium traffic
        idx = ceil((max(s) + 1) / 3) * 3;
%         idx = ceil((median(s + 1)) / 4);      % heavy traffic
        results{idx} = [results{idx}; abs(s(1 + lag : end) - s(1 : end - lag))];
    end
    % remove invalid entries
    idx = 1;
    % remember all path queue level medians
    queue_medians = [];
    for i = 1 : size(results, 1)
        if ~isempty(results{i})
            results{idx} = results{i};
            idx = idx + 1;           
            % record valid queue level medians
            queue_medians = [queue_medians i];
        end
    end
    results(idx : end, :) = [];
    %
    data = results;
    dataDisp = zeros(0);
    lo_err = [];
    hi_err = [];
    for i = 1 : size(data, 1)
        s = data{i};
        % validate
        s(isnan(s)) = [];

        dataDisp = [dataDisp ; median(s)];
        % CI for median
        if size(s, 1) >= MEDIAN_CI_MIN_SAMPLE
            r = sort(s);
            lo_idx = ceil(0.5 * size(r, 1) - 0.5 * norminv(1 - alpha / 2, 0, 1) * sqrt(size(r, 1)));
            lo = r(lo_idx);
            lo = median(r) - lo;
            hi_idx = ceil(0.5 * size(r, 1) + 0.5 * norminv(1 - alpha / 2, 0, 1) * sqrt(size(r, 1)));
            hi = r(hi_idx);
            hi = hi - median(r);
%             fprintf('lag %d, %d-th path: %d, %d, %d   %d, %d, %d\n', lag, i, lo_idx, size(s, 1) / 2, hi_idx, ...
%                                     lo, median(s), hi);
        else
            lo = 0;
            hi = 0;
        end 
        lo_err = [lo_err; lo];
        hi_err = [hi_err; hi];
    end
    dataDisps = [dataDisps dataDisp];
    lo_errs = [lo_errs lo_err];
    hi_errs = [hi_errs hi_err];
end
%%
% dataDisps([2 4 6], :) = [];
% lo_errs([2 4 6], :) = [];
% hi_errs([2 4 6], :) = [];
% queue_medians([2 4 6]) = [];
figure;
% bar(dataDisps);
barerrorbar({1:size(dataDisps, 1), dataDisps}, {repmat((1:size(dataDisps, 1))', 1, size(lags, 1)), dataDisps, lo_errs, hi_errs, 'x'});
h = legend(legends);
set(h, 'FontSize', 40);
set(gca, 'FontSize', 30, 'xtick', 1:size(queue_medians', 1), 'xticklabel', queue_medians');
xlabel('Maximum node queueing level');
ylabel('Median of node queueing level change');
%%
maximize;
set(gcf, 'Color', 'white');
cd(dir);
str = 'medium_traffic_proportional_link_queue_change_group_max';
export_fig(str, '-eps');
export_fig(str, '-jpg', '-zbuffer');
saveas(gcf, [str '.fig']);
%% proportional correlation: path queue level
% path queue level autocorrelation
% median path queue [3,  6,7,9,9.5,   13,14,14,16,17,   24,   29;]
% path of median queue 3 only has 80 samples < MAX_LAG
% queue_medians = {'8', '15', '24', '29'};
t = sequential_path_qs;
LAG = 1;
QUEUE_SIZE = 28;
% idx = 1;
dataDisps = [];
lo_errs = [];
hi_errs = [];
alpha = 0.1;

MAX_PATH_QUEUE = 1000;
    
lags = [1 5 10 15 20 50 100];
lags = lags';

LAG_CNTS = size(lags, 1);
legends = cell(LAG_CNTS, 1);
for i = 1 : LAG_CNTS
    legends{i} = ['Lag ' num2str(lags(i))];
end
MAX_LAG = lags(end);
for lag_idx = 1 : size(lags, 1)
    lag = lags(lag_idx);    
    % include empty queue
    results = cell(MAX_PATH_QUEUE, 1);
    % each path
    for i = 1 : size(t, 1)
        s = t{i};

        if size(s, 1) <= MAX_LAG
            continue;
        end

        idx = median(s) + 1;
%         % which group falls in 
%         m = median(s);
%         if m <= 3.1
%             idx = 1;
%         elseif m <= 10
%             idx = 2;
%         elseif m <= 17
%             idx = 3;
%         elseif m <= 24
%             idx = 4;
%         else
%             idx = 5;
%         end
        ACF = autocorr(s, lag);
        results{idx} = [results{idx}; ACF(lag + 1)];
    %     % auto correlation: lags(1) is for lag 0
    %     [ACF lags] = autocorr(s, LAG_CNTS);
    %     for lag = 1 : LAG_CNTS
    %         results{lag} = [results{lag}; ACF(lag + 1)];
    %     end
    end
    % remove invalid entries
    idx = 1;
    % remember all path queue level medians
    queue_medians = [];
    for i = 1 : size(results, 1)
        if ~isempty(results{i})
            results{idx} = results{i};
            idx = idx + 1;           
            % record valid queue level medians
            queue_medians = [queue_medians i];
        end
    end
    results(idx : end, :) = [];
    %
    data = results;
    dataDisp = zeros(0);
    lo_err = [];
    hi_err = [];
    for i = 1 : size(data, 1)
        s = data{i};
        % validate
        s(isnan(s)) = [];

        dataDisp = [dataDisp ; median(s)];
        % CI for median
        if size(s, 1) >= MEDIAN_CI_MIN_SAMPLE
            r = sort(s);
            lo_idx = ceil(0.5 * size(r, 1) - 0.5 * norminv(1 - alpha / 2, 0, 1) * sqrt(size(r, 1)));
            lo = r(lo_idx);
            lo = median(r) - lo;
            hi_idx = ceil(0.5 * size(r, 1) + 0.5 * norminv(1 - alpha / 2, 0, 1) * sqrt(size(r, 1)));
            hi = r(hi_idx);
            hi = hi - median(r);
        else
            lo = 0;
            hi = 0;
        end 
        lo_err = [lo_err; lo];
        hi_err = [hi_err; hi];
    end
    dataDisps = [dataDisps dataDisp];
    lo_errs = [lo_errs lo_err];
    hi_errs = [hi_errs hi_err];
end
%
figure;
barerrorbar({1:size(dataDisps, 1), dataDisps}, {repmat((1:size(dataDisps, 1))', 1, size(lags, 1)), dataDisps, lo_errs, hi_errs, 'x'});
legend(legends);
set(gca, 'FontSize', 30, 'xticklabel', queue_medians);
xlabel('Median path queue level');
ylabel('Median path queue level autocorrelation coefficient');
%
maximize;
set(gcf, 'Color', 'white');
cd(dir);
export_fig 'medium_traffic_proportional_path_queue_autocorr' -eps;
export_fig 'medium_traffic_proportional_path_queue_autocorr' -jpg -zbuffer;
saveas(gcf, 'medium_traffic_proportional_path_queue_autocorr.fig');

%% path queue level changes
MIN_SAMPLE_CNTS = 100;
LAG_CNTS = 5;
t = sequential_path_qs;
QUEUE_SIZE_IDX = 5;
MAX_PATH_QUEUE = 1000;
dataDisps = [];
lo_errs = [];
hi_errs = [];
alpha = 0.1;

lags = [1 5 10 15 20 50 100];
lags = lags';

LAG_CNTS = size(lags, 1);
legends = cell(LAG_CNTS, 1);
for i = 1 : LAG_CNTS
    legends{i} = ['Lag ' num2str(lags(i))];
end
for lag_idx = 1 : size(lags, 1)
    lag = lags(lag_idx);  
    % include empty queue
    results = cell(MAX_PATH_QUEUE, 1);
    % each node
    for i = 1 : size(t, 1)
        s = t{i};

        % s now contains all the queue levels at a node
        if size(s, 1) < MIN_SAMPLE_CNTS
            continue;
        end

%         idx = median(s) + 1;
        idx = max(s) + 1;
%         % which group falls in 
%         m = median(s);
%         if m <= 3.1
%             idx = 1;
%         elseif m <= 10
%             idx = 2;
%         elseif m <= 17
%             idx = 3;
%         elseif m <= 24
%             idx = 4;
%         else
%             idx = 5;
%         end
        results{idx} = [results{idx}; abs(s(1 + lag : end) - s(1 : end - lag))];
    end
    % remove invalid entries
%     results = results([1 2 3]);
    idx = 1;
    % remember all path queue level medians
    queue_medians = [];
    for i = 1 : size(results, 1)
        if ~isempty(results{i})
            results{idx} = results{i};
            idx = idx + 1;
            % record valid queue level medians
            queue_medians = [queue_medians i];
        end
    end
    results(idx : end, :) = [];

    %
    data = results;
    dataDisp = zeros(0);
    lo_err = [];
    hi_err = [];
    for i = 1 : size(data, 1)
        s = data{i};
        % validate
        s(isnan(s)) = [];
        dataDisp = [dataDisp ; max(s)];
        % CI for median
        if size(s, 1) >= MEDIAN_CI_MIN_SAMPLE
            r = sort(s);
            lo_idx = ceil(0.5 * size(r, 1) - 0.5 * norminv(1 - alpha / 2, 0, 1) * sqrt(size(r, 1)));
            lo = r(lo_idx);
            lo = median(r) - lo;
            hi_idx = ceil(0.5 * size(r, 1) + 0.5 * norminv(1 - alpha / 2, 0, 1) * sqrt(size(r, 1)));
            hi = r(hi_idx);
            hi = hi - median(r);
        else
            lo = 0;
            hi = 0;
        end
        lo_err = [lo_err; lo];
        hi_err = [hi_err; hi];
    end
    dataDisps = [dataDisps dataDisp];
    lo_errs = [lo_errs lo_err];
    hi_errs = [hi_errs hi_err];
end
%%
figure;
bar(dataDisps);
% barerrorbar({1:size(dataDisps, 1), dataDisps}, {repmat((1:size(dataDisps, 1))', 1, size(lags, 1)), dataDisps, lo_errs, hi_errs, 'x'});
h = legend(legends);
set(h, 'FontSize', 20);
set(gca, 'FontSize', 30, 'xtick', 1:size(queue_medians', 1), 'xticklabel', queue_medians);
xlabel('Maximum path queueing level');
ylabel('Maximum path queueing level change');
%%
maximize;
set(gcf, 'Color', 'white');
cd(dir);
str = 'medium_traffic_proportional_max_path_queue_change_group_max';
export_fig(str, '-eps');
export_fig(str, '-jpg', '-zbuffer');
saveas(gcf, [str '.fig']);
%% path delay correlation
t = pkt_path_qs;
% each cell contains consecutive pkts sharing paths
path_pkts = {t{1}(1:669, 1:2);
t{2}(482:729, 1:2);
t{3}(317:723, 1:2);
t{4}(206:585, 1:2);
t{7}(23:274, 1:2);
t{7}(278:701, 1:2);
t{7}(795:1000, 1:2);
t{8}(23:282, 1:2);
t{9}(27:282, 1:2);
t{10}(14:233, 1:2)};

t = path_pkts;
s = pkt_delays;
% validate
MAX_E2E_DELAY = 100000;
s = s(s(:, 3) < MAX_E2E_DELAY, :);

path_delays = cell(size(t, 1), 1);
% each path
for i = 1 : size(t, 1)
    r = t{i};
    
    delays = zeros(size(r, 1), 1);
    idx = 1;
    % each consecutive pkt using this path
    for j = 1 : size(r, 1)
        pkt = r(j, :);
        IX = find(s(:, 1) == pkt(1) & s(:, 2) == pkt(2), 1);

        if isempty(IX)
            disp('error');
            continue;
        end
        delays(idx) = s(IX, 3);
        idx = idx + 1;
    end
    path_delays{i} = delays(1 : idx - 1, :);
end
save('sequential_path_delays.mat', 'path_delays');
% plot    
MIN_SAMPLE_CNTS = 100;
LAG_CNTS = 14;
t = path_delays;
results = cell(LAG_CNTS, 1);

% time series of a path's delay
title_str = 'Delay of consecutive packets traversing a path';
figure('name', title_str);
plot(t{1});
set(gca, 'FontSize', 30);
xlabel('Packet sequence number');
ylabel('Delay of packets traversing a path (ms)');

maximize;
set(gcf, 'Color', 'white');
cd(dir);
export_fig 'path_delay_timeseries' -eps;
export_fig 'path_delay_timeseries' -jpg -zbuffer;
saveas(gcf, 'path_delay_timeseries.fig');

% autocorrelation
for i = 1 : size(t, 1)
    s = t{i};
    
    if size(s, 1) < MIN_SAMPLE_CNTS
        continue;
    end
    
    % auto correlation: lags(1) is for lag 0
    [ACF lags] = autocorr(s, LAG_CNTS);
    for lag = 1 : LAG_CNTS
        results{lag} = [results{lag}; ACF(lag + 1)];
    end
end

data = results;
group = zeros(0);
dataDisp = zeros(0);
for i = 1 : size(data, 1)
    group = [group ; ones(size(data{i})) + i - 1];
    dataDisp = [dataDisp ; data{i}];
end
title_str = 'Path delay autocorrelation vs lags';
figure('name', title_str);
boxplot(dataDisp, group, 'notch', 'on');
set(gca, 'FontSize', 30);
xlabel('Lag (h)');
ylabel('Autocorrelation coefficient');
%
maximize;
set(gcf, 'Color', 'white');
cd(dir);
export_fig 'path_delay_autocorr' -eps;
export_fig 'path_delay_autocorr' -jpg -zbuffer;
saveas(gcf, 'path_delay_autocorr.fig');

%% highly variance of path delay: both in time and magnitude
% 1) relative diff
STEP = 5;
alpha = 0.01;
LAG_CNTS = length(1 : STEP : 101);
MIN_SAMPLE_CNTS = 100;
t = path_delays;
% diff and relative diff between two neighboring samples [median lower upper]
results = zeros(LAG_CNTS, 3);
for lag_idx = 1 : LAG_CNTS
    lag = STEP * (lag_idx - 1) + 1;
    diffs = zeros(100000, 1);
    idx = 1;
    for i = 1 : size(t, 1)
        s = t{i};

        if size(s, 1) < MIN_SAMPLE_CNTS
            continue;
        end

        diff = s(lag + 1 : end) - s(1 : end - lag);
        diffs(idx : idx + size(diff, 1) - 1, :) = 100 * abs(diff ./ s(1 : end - lag)); %[diff, diff ./ s(1:end-1)];
        idx = idx + size(diff, 1);
    end
    diffs(idx : end, :) = [];
    r = sort(diffs);
    % err bound
    lo_idx = ceil(0.5 * size(r, 1) - 0.5 * norminv(1 - alpha / 2, 0, 1) * sqrt(size(r, 1)));
    lo = r(lo_idx);
    lo = median(r) - lo;
    hi_idx = ceil(0.5 * size(r, 1) + 0.5 * norminv(1 - alpha / 2, 0, 1) * sqrt(size(r, 1)));
    hi = r(hi_idx);
    hi = hi - median(r);
    results(lag_idx, :) = [median(r) lo hi];
end


title_str = 'Path delay relative difference vs lags';
figure('name', title_str);
errorbar((1 : LAG_CNTS) * 5, results(:, 1), results(:, 2), results(:, 3));
set(gca, 'FontSize', 40);
% xlim([0 110]);
xlabel('Lag (h)');
ylabel('Relative delay difference (%)');
%
maximize;
set(gcf, 'Color', 'white');
cd(dir);
export_fig 'path_delay_relative_diff_99' -eps;
export_fig 'path_delay_relative_diff_99' -jpg -zbuffer;
saveas(gcf, 'path_delay_relative_diff_99.fig');

%% 2) absolute difference
alpha = 0.01;
STEP = 5;
LAG_CNTS = length(1 : STEP : 101);
MIN_SAMPLE_CNTS = 100;
t = path_delays;
% diff and relative diff between two neighboring samples [median lower upper]
results = zeros(LAG_CNTS, 3);
for lag_idx = 1 : LAG_CNTS
    lag = 1 + (lag_idx - 1) * STEP;
    
    diffs = zeros(100000, 1);
    idx = 1;
    for i = 1 : size(t, 1)
        s = t{i};

        if size(s, 1) < MIN_SAMPLE_CNTS
            continue;
        end

        diff = s(lag + 1 : end) - s(1 : end - lag);
        diffs(idx : idx + size(diff, 1) - 1, :) = abs(diff); %[diff, diff ./ s(1:end-1)];
        idx = idx + size(diff, 1);
    end
    diffs(idx : end, :) = [];
    r = sort(diffs);
    % err bound
    lo_idx = ceil(0.5 * size(r, 1) - 0.5 * norminv(1 - alpha / 2, 0, 1) * sqrt(size(r, 1)));
    lo = r(lo_idx);
    lo = median(r) - lo;
    hi_idx = ceil(0.5 * size(r, 1) + 0.5 * norminv(1 - alpha / 2, 0, 1) * sqrt(size(r, 1)));
    hi = r(hi_idx);
    hi = hi - median(r);
    results(lag_idx, :) = [median(r) lo hi];
end


title_str = 'Path delay difference vs lags';
figure('name', title_str);
errorbar((1:LAG_CNTS) * STEP, results(:, 1), results(:, 2), results(:, 3));
set(gca, 'FontSize', 40);
xlim([0 110]);
xlabel('Lag (h)');
ylabel('Delay difference (ms)');
%
maximize;
set(gcf, 'Color', 'white');
cd(dir);
export_fig 'path_delay_diff_99' -eps;
export_fig 'path_delay_diff_99' -jpg -zbuffer;
saveas(gcf, 'path_delay_diff_99.fig');

%% pdr vs link length for Indriya 
NODE_CNTS = 127;
INVALID_PDR = -1;
t = pdrOfAllPairs;
t = t(1 : NODE_CNTS, 1 : NODE_CNTS);
s = indriya_locations;
% [link length pdr]
link_len_pdr = zeros(NODE_CNTS * NODE_CNTS, 4);
idx = 1;
for i = 1 : NODE_CNTS
    for j = 1 : NODE_CNTS
        if j == i
            continue;
        end
        if INVALID_PDR == t(i, j)
            continue;
        end
        % compute link length: s(i) is i's location
        len = sqrt((s(i, 1) - s(j, 1)) ^ 2 + (s(i, 2) - s(j, 2)) ^ 2 + ...
                    (s(i, 3) - s(j, 3)) ^ 2);
        link_len_pdr(idx, :) = [i j ceil(len / 5) t(i, j)];
        idx = idx + 1;
    end
end
link_len_pdr(idx : end, :) = [];
figure;
boxplot(link_len_pdr(:, 4) * 100, link_len_pdr(:, 3) * 5, 'notch', 'on');
set(gca, 'FontSize', 30);
xlabel('Link length (feet?)');
ylabel('PDR (%)');

maximize;
set(gcf, 'Color', 'white'); % Sets figure background
cd(dir);
export_fig 'indriya_pdr_vs_link_len' -eps;
export_fig 'indriya_pdr_vs_link_len' -jpg -zbuffer;
saveas(gcf, 'indriya_pdr_vs_link_len.fig');

%% sample size to estimate mean
%% path delay
precision = .1;
% confidence level
alpha = 0.1;
z = norminv(1 - alpha / 2, 0, 1);
MAX_MAC_DELAY = 2000;

t = rxs;
t = t(t(:, 10) ~= 0 & t(:, 8) ~= 65535, :);
links = unique(t(:, [10 2]), 'rows');
results = zeros(size(links, 1), 1);
idx = 1;
SAMPLE_THRESHOLD = 1000;
for i = 1 : size(links, 1)
    link = links(i, :);
    link_mac_delays = t(t(:, 10) == link(1) & t(:, 2) == link(2), 9);
    
    s = link_mac_delays;
    s = s(s < MAX_MAC_DELAY);
    if size(s, 1) < SAMPLE_THRESHOLD
        continue;
    end
    n = (std(s) * z) / (mean(s) * precision);
    results(idx, :) = n ^ 2;
    idx = idx + 1;
end
results(idx : end, :) = [];
%
figure;
[n xout] = hist(results, size(results, 1));
bar(xout, n / sum(n) * 100);
set(gca, 'FontSize', 40);
xlabel('Sample size');
ylabel('Frequency (%)');
%
maximize;
set(gcf, 'Color', 'white'); % Sets figure background
cd(dir);
export_fig 'path_delay_sample_size' -eps;
export_fig 'path_delay_sample_size' -jpg -zbuffer;
saveas(gcf, 'path_delay_sample_size.fig');
%
figure;
cdfplot(results);
set(gca, 'FontSize', 40);
xlabel('Sample size');
ylabel('F(x)');
title('');
%
maximize;
set(gcf, 'Color', 'white'); % Sets figure background
cd(dir);
export_fig 'path_delay_sample_size_cdf' -eps;
export_fig 'path_delay_sample_size_cdf' -jpg -zbuffer;
saveas(gcf, 'path_delay_sample_size_cdf.fig');

%% link delay
precision = .1;
% confidence level
alpha = 0.1;
z = norminv(1 - alpha / 2, 0, 1);
MAX_MAC_DELAY = 2000;

% t = rxs;
% t = t(t(:, 10) ~= 0 & t(:, 8) ~= 65535, :);
% links = unique(t(:, [10 2]), 'rows');
DBG_FLAG = 17;
t = debugs;
t = t(t(:, 3) == DBG_FLAG, :);
links = unique(t(:, [8 2]), 'rows');

results = zeros(size(links, 1), 1);
idx = 1;
SAMPLE_THRESHOLD = 1000;
for i = 1 : size(links, 1)
    link = links(i, :);
    link_mac_delays = t(t(:, 8) == link(1) & t(:, 2) == link(2), 10);
    
    s = link_mac_delays;
    s = s(s < MAX_MAC_DELAY);
    if size(s, 1) < SAMPLE_THRESHOLD
        continue;
    end
    n = (std(s) * z) / (mean(s) * precision);
    results(idx, :) = n ^ 2;
    idx = idx + 1;
end
results(idx : end, :) = [];
%
figure;
[n xout] = hist(results, size(results, 1));
bar(xout, n / sum(n) * 100);
set(gca, 'FontSize', 40);
xlabel('Sample size');
ylabel('Frequency (%)');
%
maximize;
set(gcf, 'Color', 'white'); % Sets figure background
cd(dir);
export_fig 'link_delay_sample_size' -eps;
export_fig 'link_delay_sample_size' -jpg -zbuffer;
saveas(gcf, 'link_delay_sample_size.fig');
%
figure;
cdfplot(results);
set(gca, 'FontSize', 40);
xlabel('Sample size');
ylabel('F(x)');
title('');
%
maximize;
set(gcf, 'Color', 'white'); % Sets figure background
cd(dir);
export_fig 'link_delay_sample_size_cdf' -eps;
export_fig 'link_delay_sample_size_cdf' -jpg -zbuffer;
saveas(gcf, 'link_delay_sample_size_cdf.fig');

%% sample size to estimate variance
% http://stats.stackexchange.com/questions/7004/calculating-required-sample
% -size-precision-of-variance-estimate
alpha = 0.1;
x = 1 : 1000;
x = x';
y = zeros(size(x, 1), 1);
for i = 1 : size(x, 1)
    n = x(i);
    y(i) = (n - 1) * (1 / chi2inv(alpha / 2, n - 1) - 1 / chi2inv(1 - alpha / 2, n - 1));
    if y(i) <= .1
        fprintf('%d\n', n);
        break;
    end
end
plot(x, y);

%% queueing level change vs lags 1): node-level
MIN_SAMPLE_CNTS = 1000;
% LAG_CNTS = 200;
% LAG_STEP = 10;
LAGS = [1 2 5 10 20 50 100 200 500]';
t = rxs;
% correlation
nodes = unique(t(:, 2));
results = cell(size(LAGS, 1), 1);

for i = 1 : size(nodes, 1)
    node = nodes(i);
    % queue levels at a node
    s = t(t(:, 2) == node, QUEUE_SIZE_IDX);
    
    if size(s, 1) < MIN_SAMPLE_CNTS
        continue;
    end
    
    % queue changes
    for j = 1 : size(LAGS, 1)
        lag = LAGS(j);
        results{j} = [results{j}; abs(s(1 + lag : end) - s(1 : end - lag))];
    end
end
%
data = results;
group = zeros(0);
dataDisp = zeros(0);
for i = 1 : size(data, 1)
    group = [group ; ones(size(data{i})) + i - 1];
    dataDisp = [dataDisp ; data{i}];
end
figure;
boxplot(dataDisp, group, 'notch', 'on');
set(gca, 'FontSize', 40, 'xticklabel', LAGS');
xlabel('Lag');
ylabel('Node queueing level change');
%
maximize;
set(gcf, 'Color', 'white');
cd(dir);
str = 'node_queue_change_lag_heavy';
export_fig(str, '-eps');
export_fig(str, '-jpg', '-zbuffer');
saveas(gcf, [str '.fig']);

%% queueing level change vs lags 1): path-level
MIN_SAMPLE_CNTS = 100;
t = sequential_path_qs;
LAGS = [1 2 5 10 20 50 100 200 500]';
results = cell(size(LAGS, 1), 1);

for i = 1 : size(t, 1)
    s = t{i};
    
    if size(s, 1) < MIN_SAMPLE_CNTS
        continue;
    end
    
    % queue changes
    for j = 1 : size(LAGS, 1)
        lag = LAGS(j);
        results{j} = [results{j}; abs(s(1 + lag : end) - s(1 : end - lag))];
    end
end
%
data = results;
group = zeros(0);
dataDisp = zeros(0);
for i = 1 : size(data, 1)
    group = [group ; ones(size(data{i})) + i - 1];
    dataDisp = [dataDisp ; data{i}];
end
figure;
boxplot(dataDisp, group, 'notch', 'on');
set(gca, 'FontSize', 40, 'xticklabel', LAGS');
xlabel('Lag');
ylabel('Path queueing level change');
%
maximize;
set(gcf, 'Color', 'white');
cd(dir);
str = 'path_queue_change_lag_medium';
export_fig(str, '-eps');
export_fig(str, '-jpg', '-zbuffer');
saveas(gcf, [str '.fig']);

%% %% distribution of path ETX
%% link pdrs
NODE_CNT = 105;
PARENT_IDX = 10;
LAST_HOP_IDX = 10;
MIN_SAMPLE_SIZE = 10;
link_pdrs = - ones(NODE_CNT, NODE_CNT);
t = txs;
r = rxs;
nodes = unique(t(:, 2));
for i = 1 : size(nodes, 1)
    sender = nodes(i);
    % txs by this node; rxs from this node
    n_t = t(t(:, 2) == sender, :);
    n_r = r(r(:, LAST_HOP_IDX) == sender, :);
    receivers = unique(n_t(:, PARENT_IDX));
    
    for j = 1 : size(receivers, 1)
        receiver = receivers(j);
        if receiver > NODE_CNT
            fprintf('warning\n');
            continue;
        end

        link_tx = sum(n_t(:, PARENT_IDX) == receiver);
        if link_tx < MIN_SAMPLE_SIZE
            continue;
        end
        
        link_rx = sum(n_r(:, 2) == receiver);
        
        link_pdrs(sender, receiver) = link_rx / link_tx;
        if link_rx > link_tx
            fprintf('err: %d, %d\n', link_tx, link_rx);
        end
    end
end
end
%% path ETX
srcs = unique(srcPkts(:, 2));
for src_id = 1 : size(srcs, 1)
t = pkt_paths;
SRC_ID = srcs(src_id);
t = t(pkt_delays(:, 1) == SRC_ID, :);
INVALID_ID = 255;
ROOT_ID = 15;
path_etxs = [];

for i = 1 : size(t, 1)
    fprintf('path %d\n', i);
    path = t(i, :);
    path_etx = 0;
    
    if sum(isnan(path)) > 0
        continue;
    end
    % all constituent links must have valid pdr
    valid = true;
    for j = 1 : (length(path) - 1)
        sender = path(j);
        receiver = path(j + 1);
        if INVALID_ID == sender || ROOT_ID == sender || INVALID_ID == receiver
            break;
        end
        
        link_pdr = link_pdrs(sender, receiver);
        % invalid
        if -1 == link_pdr
            valid = false;
            break;
        end
        
        path_etx = path_etx + 1 / link_pdr;
    end
    % only consider pkt reaching the sink
    if valid && ROOT_ID == sender
        path_etxs = [path_etxs; path_etx];
    end
end
%%
y = path_etxs;
y = y(~isinf(y));
% cdfplot(y);
figure;
y = y(y < 20);
[n x] = hist(y);
bar(x, 100 * n / sum(n));
set(gca, 'FontSize', 40);
ylabel('Frequency (%)');
xlabel('Path ETX');
end