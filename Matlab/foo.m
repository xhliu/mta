x = [];
for i = 1 : 1000
    if rand(1, 1) < 0.5
        x = [x 0];
    else
        x = [x 1];
    end
end
autocorr(x);

%%
t = debugs;
t = t(t(:, 3) == 20, :);
t = t(t(:, 4) == 0, :);
% s = t(t(:, 2) == 2, :);
%%
[s m n] = unique(t(:, 2));
t = t(m, [2 10]);
% t = t - 2 ^ 32;
% hist(t(:, 10));
%% debug: compare sender-based pkt time vs receiver-based
t = debugs;
% [sender receiver seqno pkt-time]
% sender-based pkt time
r = t(t(:, 3) == 19, [2 7 9 10]);
% receiver-based pkt time
s = t(t(:, 3) == 17, [8 2 7 9]);

% compare
tx_rx_delays = zeros(size(r, 1), 2);
idx = 1;
for i = 1 : size(r, 1)
    entry = r(i, :);
    tx_delay = entry(end);
    
    % find receiver delay
    IX = find(s(:, 1) == entry(1) & s(:, 2) == entry(2) & s(:, 3) == entry(3), 1);
    if isempty(IX)
        fprintf('err\n');
        continue;
    end
    rx_delay = s(IX, end);
    
    tx_rx_delays(idx, :) = [tx_delay rx_delay];
    idx = idx + 1;
end
tx_rx_delays(idx : end, :) = [];
%%
t = tx_rx_delays;
diff = t(:, 2) - t(:, 1);
cdfplot(diff);
mean(diff)
%% variance of adaptive forwarding time
t = 16 : 31;
t = t';
mean_ = mean(t);
total = 0;
for i = 1 : size(t, 1)
    total = total + (t(i) - mean_) ^ 2;
end
total
%% [link pkt sender_mac_delay receiver_mac_delay]
t = lag_mac_delays;
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

title_str = 'Inter-node MAC delay Correlation vs Lags';
figure('name', title_str);
boxplot(dataDisp, group);
set(gca, 'FontSize', 30);
xlabel('Lag');
ylabel('Inter-node MAC Delay Correlation');

maximize;
set(gcf, 'Color', 'white'); % Sets figure background
cd(dir);
export_fig 'inter_node_mac_delay_corr' -eps;
export_fig 'inter_node_mac_delay_corr' -jpg -zbuffer;
saveas(gcf, 'inter_node_mac_delay_corr.fig');
%%
srcs = unique(srcPkts(:, 2));
t = mod(srcs, 15);
isempty(find(t > 7, 1))
%% 
t = txs(:, 3:4);
t = unique(t, 'rows');
s = destPkts(:, 3:4);
s = unique(s, 'rows');
len = max(s(:, 2));
STEP = 100;
r = zeros(len, 2);
j = 1;
for i = 1 : STEP : len
   tx_cnts = size(find(t(:, 2) <= i), 1); 
   rx_cnts = size(find(s(:, 2) <= i), 1);
   r(j, :) = [tx_cnts rx_cnts];
   j = j + 1;
end
r(j : end, :) = [];
plot(r(:,2) ./ r(:,1));

%%
clc;
s = unique(srcPkts(:, 2));
t = rejs(:, 2);
[x idx idy] = intersect(t, s);
fprintf('%f \n', length(idx) / length(t));
t = expires(:, 2);
[x idx idy] = intersect(t, s);
fprintf('%f \n', length(idx) / length(t));
if ~isempty(find(x ~= t(idx), 1))
    disp('err');
end
%% MTA actually working
%deadline = srcPkts(1, 10);
t = pkt_delays(:, 3);
t = t(t < 10000);
%[s idx] = setdiff(t(:, 1 : 2), rejs(:, 3 : 4), 'rows');
%s = t(idx, :);
s = unique(txs(:, 3 : 4), 'rows');
size(t, 1) / size(s, 1)
cdfplot(t)
%% 
for job_id = 4340 : 4346
destDir = ['/home/xiaohui/Projects/tOR/RawData/' num2str(job_id)];
cd(destDir);
load('TxRx.mat');
% jitter
t = pkt_delays(:, 3);
MAX_E2E_DELAY = 100000;
t = t(t <= MAX_E2E_DELAY);
% figure; hist(t, length(t));
% Vysochanski�?Petunin bounding
qtl = 0.9;
Z = t;
mu = mean(Z);
sigma = sqrt(var(Z));
k = sqrt(4 / (9 * (1 - qtl)) - 1);
bound = mu + k * sigma;
k = sqrt(qtl / (1 - qtl));
bound_1 = mu + k * sigma;
actual = quantile(Z, qtl);
fprintf('%d: %f, %f, %f\n', job_id, actual, bound, bound_1);
if (actual > bound)
    disp('oops');
end
end
%% sample size analysis
% 0.05 significance level
Z = 1.96;
p1 = mean([0.8264996970309 0.93465727098014 0.87160006577866]);
p2 = mean([0.96931614166803
0.95204746619979
0.98161859387072
0.99233425195603
0.92145005335834
0.90515905719466
0.95746166788356]);
n = Z * (sqrt(p1 * (1 - p1)) - sqrt(p2 * (1 - p2))) / (p2 - p1);
n = n ^ 2

%% link reliability diff
% s = link_dup_ratios;
% t = link_dup_ratios;
diff = [];
for i = 1 : size(s, 1)
    if s(i, 3) < 100
        continue;
    end
    sender = s(i, 2);
    receiver = s(i, 1);
    
    for j = 1 : size(t, 1)
        if s(i, 3) < 100
            continue;
        end
        % found
        if t(j, 2) == sender && t(j, 1) == receiver
            diff = [diff; s(i, 5) - t(j, 5) s(i, 6) - t(j, 6)];
        end
    end
end
plot(diff);
%%
s = txs(:, 9);
s = s(s <= 30);
figure;
[n xout] = hist(s);
bar(xout, n / sum(n));

%% info for each traffic configuration
% idx of data in concern; period or deadline
IDX = 9;
MAX_E2E_DELAY = 100000;
[dest_seqnos m n]= unique(destPkts(:, 3 : 4), 'rows', 'first');
unique_destPkts = destPkts(m, :);
overflow_seqnos = unique(overflows(:, 3 : 4), 'rows');
periods = unique(srcPkts(:, IDX));
delay_load_curves = zeros(length(periods), 7);
for i = 1 : length(periods)
    period = periods(i);
    period_src_seqnos = unique(srcPkts(srcPkts(:, IDX) == period, 3:4), 'rows');
    
    fprintf('period: %d, total pkt #: %d\n', period, size(period_src_seqnos, 1));
    
    % reliability
    t = dest_seqnos;
    s = intersect(period_src_seqnos, t, 'rows');
%     fprintf('reliability: %f\n', size(s, 1) / size(period_src_seqnos, 1));
    reliability = size(s, 1) / size(period_src_seqnos, 1);
    
    % delay
    t = unique_destPkts(:, 3 : 4);
    [s ia ib] = intersect(period_src_seqnos, t, 'rows');
    s = unique_destPkts(ib, 10);
    s = s(s < MAX_E2E_DELAY);
    delay_qtl = quantile(s, .9);
    if reliability > 0.9
        delay_qtl_loss = quantile(s, .9 / reliability);
    else
        delay_qtl_loss = inf;
    end
    
    % overflow
    t = overflow_seqnos;
    s = intersect(period_src_seqnos, t, 'rows');
%     fprintf('overflow ratio: %f\n', size(s, 1) / size(period_src_seqnos, 1));
    overflow_ratio = size(s, 1) / size(period_src_seqnos, 1);
    
    % queueing
    t = txs(:, 3 : 4);
    [s ia ib] = intersect(period_src_seqnos, t, 'rows');
    s = txs(ib, 5);
    queueing = median(s);
    
    title_str = ['period ' num2str(period)];
    figure;
    title(title_str);
    [n xout] = hist(s, 27);
    h = bar(xout, n / sum(n));
    saveas(h, ['period ' num2str(period)], 'fig');
    fprintf('mean and median queueing: %f, %f\n', mean(s), median(s));
    delay_load_curves(i, :) = [period size(period_src_seqnos, 1) delay_qtl, delay_qtl_loss, reliability, overflow_ratio, queueing];
end
close all;
save('delay_load_curves.mat', 'delay_load_curves');
%%
t = txs;
size(unique(t(:, 3 : 4), 'rows'), 1)
t = srcPkts;
size(unique(t(:, 3 : 4), 'rows'), 1)
%% 
x = [9.6 8.1 6.7 10.4 7.9 6.5 6.9 10.3 6.3 7.5];
z = [7.2 8.3 10.2];
y = [7.9 10.3 9.7];
y = [y z 6.7 8.1 10.1 7.3];

[mu sigma muci sigmaci] = normfit(x);
[muci(1) mu muci(2)]
%% link dup ratio
clc;
t = rxs;
nodes = unique(t(:, 2));

link_dup_ratios = zeros(size(t, 1), 6);
idx = 1;

for i = 1 : length(nodes);
    rcvr = nodes(i);
    senders = unique(t(t(:, 2) == rcvr, 10));
    % each sender
    for j = 1 : length(senders)
        sender = senders(j);
        fprintf('link (%d, %d) ...\n', rcvr, sender);
        
        s = t(t(:, 2) == rcvr & t(:, 10) == sender, :);
        rcv_cnts = size(s, 1);
        
        tx_cnts = length(find(txs(:, 2) == sender & txs(:, 10) == rcvr));
        unique_rcv_cnts = size(unique(s(:, 3 : 4), 'rows'), 1);
        
        % bi-directional reliability
        ack_cnts = length(find(txs(:, 2) == sender & txs(:, 10) == rcvr & txs(:, 9) == 1));
        
%         if (rcv_cnts >= 100)
            link_dup_ratios(idx, :) = [rcvr sender rcv_cnts (rcv_cnts / unique_rcv_cnts - 1) rcv_cnts / tx_cnts ack_cnts / rcv_cnts];
            idx = idx + 1;
%         end
    end
end
link_dup_ratios(idx : end, :) = [];
save('link_dup_ratios.mat', 'link_dup_ratios');
%% data plane stucks
node = 22;
QUEUE_SIZE = 28;

t = overflows;
s = t(t(:, 2) == node, :);
fprintf('\n overflow %u %u\n', size(s, 1), size(unique(s(:, 3 : 4), 'rows'), 1));
overflow = s;

t = txs;
s = t(t(:, 2) == node, :);
figure; hist(s(:, 5), 100);
fprintf('tx %u %u\n', size(s, 1), size(unique(s(:, 3 : 4), 'rows'), 1));
tx = s;

DBG_FLAG = 7;
t = debugs;
t = t(t(:, 3) == DBG_FLAG, :);
s = t(t(:, 2) == node, :);
fprintf('fwd %u %u\n', size(s, 1), size(unique(s(:, 9 : 10), 'rows'), 1));
figure; hist(s(:, 4), 100);
fwd = s;
% length(find(s(:, 7) == 0))
%% insane jobs, especially under heavy traffic
t = rxs;
t = unique(t(:, 10));
% queue size @ each node
% t = txs;
% nodes = unique(t(:, 2));
% len = length(nodes);
% node_queues = zeros(len, 2);
% for i = 1 : length(nodes)
%     node = nodes(i);
%     node_queues(i, :) = [node max(t(t(:, 2) == node, 9))];
% end
%% detailed routing info
% duplicate ratio
nodes = unique(rxs(:, 2));
dup_ratios = zeros(length(nodes), 3);
for i = 1 : length(nodes)
    node = nodes(i);
    dup_ratio = length(find(rxs(:, 2) == node)) / size(unique(rxs(rxs(:, 2) == node, 3 : 4), 'rows'), 1);
    dup_ratios(i, :) = [node length(find(rxs(:, 2) == node)) dup_ratio - 1];
end
save('dup_ratios.mat', 'dup_ratios');
% path ETX

% stable region
%% large dup ratio
node_rxs = rxs(rxs(:, 2) == 1 & rxs(:, 10) == 79, :);
node_txs = txs(txs(:, 2) == 79 & txs(:, 10) == 65535, :);
%% all due to retx dup?
clc;
t = node_rxs;
seqnos = unique(t(:, 4));
for i = 1 : size(seqnos, 1)
    seqno = seqnos(i);
    ntw_seqnos = unique(t(t(:, 4) == seqno, 6));
    if (size(ntw_seqnos, 1) > 1)
        fprintf('%d dup not due to retx\n', seqno);
    end
end
%% 90 percentile bounding comparison
clc;
MAX_E2E_DELAY = 100000;

s = pkt_delays;
s = s(s(:, 3) <= MAX_E2E_DELAY, :);
srcs = unique(s(:, 1));
len = size(srcs, 1);
bounds = zeros(len, 6);
for i = 1 : len
    src = srcs(i);
    t = s(s(:, 1) == src, 3);
    if isempty(t)
        continue;
    end
    bounds(i, :) = [std(t) / mean(t), quantile(t, .9), mean(t) + 1.28 * std(t), ...
                    mean(t) * 2.3, mean(t) + 3 * std(t), max(t)];
end
% bounds(8, :) = [];
save('bounds.mat', 'bounds');
h = plot(bounds(:, 2 : end));
saveas(h(1), 'bounding', 'fig');
legend('actual', 'normal', 'exp', 'Chebyshev', 'max');
%% find best qtl to disproof Normal bounding
MAX_E2E_DELAY = 100000;
s = pkt_delays(:, 3);
s = s(s <= MAX_E2E_DELAY);
%%
normal_vs_actual = [];
for qtl = .5 : .05 : .9
    normal_bound = mean(s) + icdf('normal', qtl, 0, 1) * std(s);
    actual_qtl = quantile(s, qtl);
    normal_vs_actual = [normal_vs_actual; normal_bound actual_qtl];
end
normal_vs_actual = [normal_vs_actual, normal_vs_actual(:, 1) - normal_vs_actual(:, 2)];
%% stable region
STABLE_IDX = 2000;
d = destPkts;
s = srcPkts;
size(unique(d(d(:, 4) > STABLE_IDX, 3 : 4), 'rows'), 1) / size(unique(s(s(:, 4) > STABLE_IDX, 3 : 4), 'rows'), 1)
%% tx cost regardless of dup
% job 3242 tx_cost 5.420369
% job 3244 tx_cost 4.219928
% job 3240 tx_cost 3.869078
% job 3235 tx_cost 3.750806
job_id = 3247;
if ~isempty(find(txs(:, 2) == 15, 1))
    disp('error');
end
fprintf('job %d tx_cost %f\n', job_id, size(txs, 1) / length(find(rxs(:, 2) == 15)));

%% TOSSIM tx cost
ROOT_ID = 0;
% t = root_fwd;
% if isempty(find(t(:, 1) == 9 & t(:, 2) == ROOT_ID))
%     disp('err1');
% end
% fprintf('tx cost: root forward %f\n', length(find(t(:, 1) == 9 & t(:, 2) ~= ROOT_ID)) ...
%     / size(unique(t(t(:, 1) == 10 & t(:, 2) == ROOT_ID, 3 : 4), 'rows'), 1));
% t = root_no_fwd;
if ~isempty(find(t(:, 1) == 9 & t(:, 2) == ROOT_ID))
    disp('err');
end
fprintf('tx cost: root not forward %f\n', length(find(t(:, 1) == 9 & t(:, 2) ~= ROOT_ID)) ...
    / size(unique(t(t(:, 1) == 10 & t(:, 2) == ROOT_ID, 3 : 4), 'rows'), 1));


%% pkt level sync: see job 2957
load '14.mat';
txs = Packet_Log;
load '15.mat';
rxs = Packet_Log;
% ratio of invalid timestamp
% sender
tx_IX = find(txs(:, 9) == 0);
r1 = length(tx_IX) / size(txs, 1);
% remove invalid entries
t = txs;
t(tx_IX, :) = [];
% receiver: eventTime or reception timestamp invalid
rx_IX = find(rxs(:, 9) == 0 | rxs(:, 6) == 0);
r2 = length(rx_IX) / size(rxs, 1);
r = rxs;
r(rx_IX, :) = [];
fprintf('ratio of invalid timstamps at sender: %f receiver: %f\n', r1, r2);

% measure skew and sync err <pkt timestamp skew, event time skew, diff>
len = size(r, 1);
results = zeros(len, 2);
results_idx = 1;
for i = 1 : len
    seqno = r(i, 4);
    rx_timestamp = r(i, 10);
    rx_event_time = r(i, 7) * 2 ^ 16 + r(i, 8);
    
    IX = find(t(:, 4) == seqno);
    if length(IX) ~= 1
        fprintf('log error: %d entries found for seqno %d\n', length(IX), seqno);
        continue;
    end
    tx_timestamp = t(IX, 10);
    tx_event_time = t(IX, 7) * 2 ^ 16 + t(IX, 8);
    
    results(results_idx, :) = [rx_timestamp - tx_timestamp, rx_event_time - tx_event_time];
    results_idx = results_idx + 1;
end
results(results_idx : end, :) = [];
results = [results abs(results(:, 1) - results(:, 2))];
%%
clc;
t = s(1 : 104, 10);
% t = repmat(13.5, 1000, 2);
[mean_ var_] = EWMA(t, 1 / 8)
%% get rid of the top 0.5 percent
t = tx_delays;
len = ceil(size(t, 1) * 0.995);
top_t = zeros(len, size(t, 2));
for i = 1 : size(t, 2)
    tmp = sort(t(:, i));
    top_t(:, i) = tmp(1 : len);
end
% tx_delays = top_t;
%%
Z = sum(t, 2);
x = quantile(Z, .9) - mean(Z);
max_M = -inf;
for i = 1 : size(t, 2)
    tmp = max(t(:, i)) - mean(t(:, i));
    if max_M < tmp
        max_M = tmp;
    end
end
M = max_M;
% M = 0;
sum(var(t)) / x ^ 2
exp(- x ^ 2 / (2 * (sum(var(t)) + M * x / 3)))
%%
nodes = [27, 6, 64, 79, 76];
len = length(nodes);
tx_delays = cell(len, 1);
for i = 1 : len
    node = nodes(i);
    fprintf('processing node %d\n', node);
    tx_delays{i} = txs(txs(:, 2) == node, 10);
end
% save('tx_delays.mat', 'tx_delays');
%%
for i = 1 : size(link_delays, 2)
COLUMN = i;
figure;
plot(link_delays(:, COLUMN));
hold on;
h = plot(queueing_delays(:, COLUMN));
set(h, 'Color', 'red');
end
%% queuing per node
nodes = unique(txs(:, 2));
len = length(nodes);
node_queue = cell(len, 1);
for i = 1 : len
    node = nodes(i);
    t = intercepts;
    t = unique(t(t(:, 2) == node, 4));
%     fprintf('node %d intercept %d pkts\n', node, length(t));
    node_queue{i} = txs(txs(:, 2) == node, 5);
    figure;
    [n xout] = hist(node_queue{i}, 26);
    h = bar(xout, n / sum(n));
    set(gca, 'FontSize', 30);
    title_str = ['queuing level at node ' num2str(node)];
    title(title_str);
    saveas(h, title_str, 'fig');
    saveas(h, title_str, 'jpg');
end
%%
figure;
h = qqplot(X, Y);
set(gca, 'FontSize', 30);
title_str = 'neighboring link delay QQ plot';
title(title_str);
hold on;
saveas(h, title_str, 'fig');
saveas(h, title_str, 'jpg');
%%
% X = Y;
% QTL = .9;
% qtl = quantile(X, QTL);
figure;
s = e2e_delays;
[n, xout] = hist(s, 100);
h = bar(xout, n / sum(n));
set(gca, 'FontSize', 30);
title_str = 'e2e delay hist (medium traffic 2 pps)';
title(title_str);
% hold on;
% qtls = quantile(s, [25, 50, 75, 90, 95, 99] / 100);
% for i = 1 : length(qtls)
%     qtl = qtls(i);
%     plot([qtl qtl], [0 .25], 'r');
% end
saveas(h, title_str, 'fig');
saveas(h, title_str, 'jpg');
%%
t = srcPkts;
t = t(t(:, 5) ~= 0, :);
fprintf('%f sent pkts async, %f received pkts async\n', length(find(srcPkts(:, 5) ~= 0)) / size(srcPkts, 1), ...
            length(find(destPkts(:, 5) ~= 0)) / size(destPkts, 1));
%% function call w/ N shortest ETX neighbor execution time
t = debugs;
t = t(t(:, 3) == 3, :);
% figure;
% hist(t(:, 10));
%% 
t = Packet_Log;
samples = t(t(:, 3) == 0, 8);
results = t(t(:, 3) == 0, 10);
figure;
first_idx = find(results ~= 65535);
results = results(first_idx + 1 : end);
plot(results);
avg_samples = t(t(:, 3) == 1, :);

tmp2 =  t(t(:, 3) == 1, 8 : 10);
figure; hold on; plot(tmp(:, 2)); 
h = plot(tmp2(:, 2));
set(h, 'Color', 'red');

%%
hold on;
h = plot(results);
set(h, 'Color', 'red');
%% clc;
WND_SIZE = 50;
t = samples;
s = zeros(length(t), 1);
sample_mean_mean = 0;
sample_mean_std = 0;
sample_mean = 0;
ALPHA = 1 / 16;
idx = 0;
for i = WND_SIZE : WND_SIZE : length(t)
    if i < WND_SIZE
        s(i) = mean(samples(1 : i));
    else
        s(i) = mean(samples(i - WND_SIZE + 1 : i));
    end
%     sample_mean = sample_mean * (1 - ALPHA) + t(i) * ALPHA;
    sample_mean = s(i);
%     fprintf('sample %d: %f\n', i, sample_mean);
    idx = idx + 1;
    if 1 == idx
        sample_mean_mean = sample_mean;
        continue;
    end
    if 2 == idx
        sample_mean_std = abs(sample_mean - sample_mean_mean);
        continue;
    end
%     fprintf('@%d, mean %f, mean_mean %f, mean_std %f\n', i, sample_mean, sample_mean_mean, sample_mean_std);
%     s(i) = sample_mean;
    if sample_mean > (sample_mean_mean + 4 * sample_mean_std) || ...
            sample_mean < (sample_mean_mean - 4 * sample_mean_std)
        fprintf('change @%d, mean %f, mean_mean %f, mean_std %f\n', i, sample_mean, sample_mean_mean, sample_mean_std);
        idx = 0;
%         sample_mean_std = abs(t(i + 1) - t(i));
%         sample_mean_mean = t(i);
%         continue;
    end
    diff = sample_mean - sample_mean_mean;
    sample_mean_std = sample_mean_std * (1 - ALPHA) + abs(diff) * ALPHA;
    sample_mean_mean = sample_mean_mean * (1 - ALPHA) + sample_mean * ALPHA;
end
figure;
plot(s);
% hold on;
% plot(repmat(6647, length(t), 1));
%%
actual_qtl_1 = errs(:, 2);
actual_qtl_2 = qtl(:, 2);
%%
figure;
plot(actual_qtl_2());
hold on;
h = plot(actual_qtl_1(50:end));
set(h, 'Color', 'red');
%% eviction vs time
for node = 1 : 10
t = debugs;
t = t(t(:, 3) == 18 & t(:, 2) == node, :);
figure;
plot(t(:, 9));
end
%% MD quantile convergence
t = debugs;
node = 38;
nb = 24;
% t = t(t(:, 3) == 19 & t(:, 2) == 31 & t(:, 10) <= 1, :);
t = t(t(:, 3) == 20 & t(:, 4) == 2 & t(:, 2) == node & t(:, 6) == nb, :);
%% parent candidate MD quantiles when IS phase 2 starts
t = debugs;
% src = 32;
% t = t(t(:, 3) == 19 & t(:, 2) == 31 & t(:, 10) <= 1, :);
t = t(t(:, 3) == 20 & t(:, 4) == 0, :);
% nodes w/ at least 1 parent invalid
tmp = t(t(:, 10) == 65535, :);
%% MD quantiles convergence and oscillation from beacon
for src = 1 : 45
t = debugs;
% src = 32;
t = t(t(:, 3) == 3 & t(:, 2) == src, [2 9 10]);
% t = t(t(:, 10) == 1 & t(:, 3) == 19 & t(:, 6) >= 0 & t(:, 2) == src, [2 8]);
% beacon tx
% t = t(t(:, 3) == 3 & t(:, 2) == src, [2 10]);
nodes = unique(t(:, 1));
MAX_UINT16 = 65535;
for i = 1 : length(nodes)
    node = nodes(i);
    IX = find(t(:, 1) == node & t(:, 2) < MAX_UINT16, 1);
    if isempty(IX)
        fprintf('%d never converges\n', src);
        continue;
    end
    next = IX + 1;
    if ~isempty(find(t(next:end, 1) == node & t(next:end, 2) == MAX_UINT16, 1))
        fprintf('(%d, %d) oscillates\n', src, node);
    end
    fprintf('node %d last min delay %d, last MD quantile %d\n', node, t(end, 2), t(end, 3));
end
end
%%
ROOT_ID = 15;   % 15 NetEye, 58 Motelab
PARENT_IDX = 10;
SRC_ID = 31;
%%
t = debugs;
nodes = unique(rejs(:, 2));
for i = 1 : length(nodes)
    node = nodes(i);
    tmp = t(t(:, 3) == 19 & t(:, 2) == node, :);
    figure;
    plot(tmp(:, 8));
end
%% rejection causes
t = debugs(debugs(:, 3) == 15, :);
len = size(t, 1);
fprintf('%d rejections in total\n', len);
fprintf('invalid flow: %f \n', length(find(t(:, 4) == 0)) / len);
fprintf('invalid etx: %f \n', length(find(t(:, 4) == 1)) / len);
fprintf('initial sample rejection bcoz of no parent: %f \n', length(find(t(:, 4) == 3)) / len);
fprintf('invalid min delay and backup parent: %f \n', length(find(t(:, 4) == 4)) / len);
t = t(t(:, 4) == 4, :);
fprintf('rejection bcoz of no etx parent: %f\n', length(find(t(:, 5) == 0)) / size(t, 1));
fprintf('rejection bcoz of no VALID MD but valid etx parent: %f\n', length(find(t(:, 5) == 1 & t(:, 6) == 0)) / size(t, 1));

%% evicted neighbors
t = debugs(debugs(:, 3) == 18, :);
figure;
plot(t(:, 9));

%% # of tx to get over a link at 0.99 confidence
p = 0.09 : 0.1 :0.99;
n = zeros(length(p), 1);
for i = 1 : length(p)
    n(i) = -2 / log10(1 - p(i));
end
n
%%
tmp = debugs(debugs(:, 3) == 1, :);
length(find(tmp(:, 6) == 65535));
% tmp = tmp(tmp(:, 9) == 0, :);
% tmp = tmp(tmp(:, 2) == 45, :);
%% paths taken by each packet
ROOT_ID = 15;   % 15 NetEye, 58 Motelab
PARENT_IDX = 10;
% paths taken by each packet
tmp = txs;
SRC_ID = 91; % 1, 5
SEQ_IDX = 4;
src_seqs = unique(tmp(tmp(:, 2) == SRC_ID & tmp(:, 3) == SRC_ID, SEQ_IDX));
src_txs = tmp(tmp(:, 3) == SRC_ID, :);
len = length(src_seqs);
NTW_SIZE = 10;
pkt_paths = repmat(255, len, NTW_SIZE + 1);
hop_cnts = repmat(0, len, 1);
for i = 1 : len
    node = SRC_ID;
    seq = src_seqs(i);
    hop_cnt = 0;
    path = node;
    while node ~= ROOT_ID
        fprintf('%d ', node);
        IX = src_txs(:, 2) == node & src_txs(:, SEQ_IDX) == seq;
        node = mode(src_txs(IX, PARENT_IDX));
        hop_cnt = hop_cnt + 1;
        path = [path node];
        if hop_cnt >= NTW_SIZE
            % loop
            break;
        end
    end
    pkt_paths(i, 1 : (hop_cnt + 1)) = path;
    fprintf('%d......\n', node);
    if (ROOT_ID == node)
        hop_cnts(i) = hop_cnt;
    end
end
save('pkt_paths.mat', 'pkt_paths', 'hop_cnts');
%%
t = pkt_paths;
t = t(~isnan(t(:, end)), :);
size(unique(t, 'rows'), 1);
%%
t = hop_cnts;
t = t(t ~= 0);
figure;
plot(t);
%% no flow parent causes
tmp = debugs(debugs(:, 3) == 15, :);
% tmp = tmp(tmp(:, 9) == 0, :);
tmp = tmp(tmp(:, 2) == 17, :);
% no parent causes
unique(tmp(:, 4))
fprintf('initial sampling: no predecessor: %d, others: %d\n', ...
length(find(tmp(:, 4) == 3 & tmp(:, 10) == 0)), length(find(tmp(:, 4) == 3 & tmp(:, 10) == 1)));
fprintf('bcoz of no predecessor: %d, forward prob. all 0: %d\n', ...
length(find(tmp(:, 4) == 4 & tmp(:, 10) == 0)), length(find(tmp(:, 4) == 4 & tmp(:, 10) == 1)));
% figure;
% plot(t(:, 9))
% t = t(t(:, 4) == 2, :);
%% MD accuracy
t = debugs;
t = t(t(:, 3) == 19 & t(:, 2) == 31, :);
% figure;
% lo = 1;
% hi = size(t, 1);
% plot(t(lo:hi, 7));
% hold on;
% h = plot(t(lo:hi, 8));
% set(h, 'Color', 'green');
% h = plot(pkt_delays(lo:hi, 2));
% set(h, 'Color', 'red');
%
lo = 586;
hi = 2700;
qtl = zeros(hi - lo + 1, 3);
MDs = t(lo : hi, 7);
min_nb_MDs = t(lo : hi, 8);
e2e_delays = pkt_delays(lo : hi, 2);

% plot(MDs);
% hold on;
% h = plot(e2e_delays);
% set(h, 'Color', 'red');
for i = 1 : size(qtl, 1)
    qtl(i, 1) = quantile(MDs(1 : i), .9);
    qtl(i, 2) = min_nb_MDs(i);
    qtl(i, 3) = quantile(e2e_delays(1 : i), .9);
end
hold off;
figure;
plot(qtl(lo:end, 1:end));
%%
tmp = srcPkts;
tmp = tmp(tmp(:, 2) == 23, :);
plot(tmp(:, 9));
%%
tmp = debugs;
tmp = tmp(tmp(:, 3) == 9, :);
% tmp = tmp(tmp(:, 3) == 10 & tmp(:, 4) == 1, :);
% [unique_senders m n] = unique(tmp(:, 2));
% cnts = tmp(m, :);
figure;
title('queue delay');
[n xout] = hist(tmp(:, 10), max(tmp(:, 10)) / 10);
bar(xout, n / sum(n));
% cdfplot(tmp(:, 10))
%% task load
t = debugs(debugs(:, 3) == 24, :);
[n xout] = hist(t(:, 10), 20);
figure;
bar(xout, n / sum(n));
task_intervals = t(:, 10);
task_queue_len = t(:, 4);
%% 
t = txs;
t = t(t(:, 2) ~= 15, :);
[n xout] = hist(t(:, 3), 26);
figure;
h = bar(xout, n / sum(n));
set(gca, 'FontSize', 30);
title('tOR queue length histgram');
saveas(h, 'tOR_Task1_Queue', 'fig');
saveas(h, 'tOR_Task1_Queue', 'jpg');
%%
tmp = srcPkts(:, [2 4 10]);
tmp = [tmp; intercepts(:, [2 4 10])];
tmp = [tmp; destPkts(:, [2 4 10])];
node_seqno_timestamp = tmp;
save('node_seqno_timestamp.mat', 'node_seqno_timestamp');
%% neighbor MD update sampling success ratio
tmp = debugs(debugs(:, 3) == 6 & debugs(:, 2) == 31, :);
length(find(tmp(:, 4) == 0)) / size(srcPkts, 1);

%%
SRC_ID = 31;
ROOT_ID = 15;
nonroot_txs = txs(txs(:, 2) ~= ROOT_ID, :);
tmp = nonroot_txs;
src_txs = length(find(tmp(:, 3) == SRC_ID));
tmp = destPkts;
src_rxs = length(unique(tmp(tmp(:, 3) == SRC_ID, 3:4), 'rows'));
src_txs / src_rxs
%%
% IX = rxs(:, 2) == 27;
% tmp = rxs(IX, 10);
tmp = rxs(:, 10);
tmp = tmp(tmp ~= hex2dec('FFFFFFFF'));
figure;
cdfplot(tmp);
figure;
plot(tmp);
median(tmp)
%% FTSP sync accuracy
DBG_FSTP_FLAG = 18;
tmp = debugs(debugs(:, 3) == DBG_FSTP_FLAG, :);
tmp = tmp(tmp(:, 9) == 0, :);
% length(find(tmp(:, 4) == 0)) / length(tmp(:, 4))
% tmp = [tmp(:, 2:4) tmp(:, 15)];
% only synchronous
% [node_id, seqno, timestamp, validity, sync]
% tmp = tmp(tmp(:, 6) == 0, [2, 5, 10, 4]);
tmp = tmp(:, [2, 5, 10, 4, 6]);
[res, IX] = sort(tmp(:, 2));
tmp = tmp(IX, :);
err = [];
sync_ratio = [];
for i = min(tmp(:, 2)) : max(tmp(:, 2))
    sync_ratio = [sync_ratio; length(find(tmp(:, 2) == i & tmp(:, 5) == 0)) / length(find(tmp(:, 2) == i))];
    % valid timestamp & synchronous only
    res = tmp(tmp(:, 2) == i & tmp(:, 4) ~= 0 & tmp(:, 5) == 0, :);
    diff = max(res(:, 3)) - min(res(:, 3));
%     err = [err; sync_ratio, diff];
    err = [err; diff];
end
figure;
plot(err);
figure;
h = plot(sync_ratio * 100);
set(h,'Color','red');
%%
% node = 79;
% for node = 95 : 2: 97
senders = unique(txs(:, 2));
sender_hop_cnts = zeros(size(senders, 1), 2);
for i = 1 : length(senders)
    node = senders(i);
    hop_cnt = 0;
    while node ~= ROOT_ID
        fprintf('%d ', node);
        IX = txs(:, 2) == node;
        node = mode(txs(IX, PARENT_IDX));    % tOR: 8    CTP: 14
        hop_cnt = hop_cnt + 1;
        if hop_cnt > 10
            % loop
            break;
        end
    end
    fprintf('%d ......', node);
    sender_hop_cnts(i, :) = [senders(i) hop_cnt];
    disp(' ');
end
%% deadline catch ratio comparison
tmp = [];
for i = 1 : size(MMSPEED_delays, 1)
    tmp = [tmp; MMSPEED_delays{i}];
end
figure('name', 'MMSPEED E2E delay CDF');
set(gca, 'FontSize', 30, 'YGrid', 'on');
cdfplot(tmp);
title('MMSPEED E2E delay CDF');
xlabel('E2E delay (ms)');
% length(find(tmp < 200)) / length(tmp);

%%
pdr = [99.8 94 95];
in_time_ratio = [92.9 28.0 34.4];
figure('name', 'Packet Delivery Ratio');
set(gca, 'FontSize', 30, 'YGrid', 'on');
bar(pdr);
set(gca, 'XTickLabel', {'MTA', 'SPEED', 'MMSPEED'});
% xlabel('link delay (ms)');
ylabel('Packet delivery ratio (%)');
%% OPMD convergence test
tmp = srcPkts;
[unique_senders m n] = unique(tmp(:, 2));
cnts = tmp(m, :);
%% sender = 71;
% receiver = 45;
unique_links = unique(tmp(:, [2 4]), 'rows');
len = size(unique_links, 1);
link_delay_samples = cell(len, 1);
for i = 1 : len
    sender = unique_links(i, 2);
    receiver = unique_links(i, 1);
    link_delay_samples{i} = tmp(tmp(:, 2) == receiver & tmp(:, 4) == sender, 10);
end
% figure('name', 'Link Delay Empirical CDF');
% set(gca, 'FontSize', 30, 'YGrid', 'on');
% cdfplot(link_delay_samples);
% xlabel('link delay (ms)');
% ylabel('');
% hist(tmp(:, 13));
% median(tmp(:, 13))
%% debug 
cnts = 0;
diff = zeros(size(rxs, 1), 1);
LAST_HOP_IDX = 3;   %5
LAST_SEQ_IDX = 4;   %4
SEQ_IDX = 4;        %4

% LAST_HOP_IDX = 5;
% LAST_SEQ_IDX = 7;
% SEQ_IDX = 9;

clc;
for i = 1 : size(rxs, 1)
    rx = rxs(i, :);
%     txs_rx_idx = find(txs(:, 2) == rx(:, 8) & txs(:, 9) == rx(1, 9));
    txs_rx_idx = find(txs(:, 2) == rx(1, LAST_HOP_IDX) & txs(:, SEQ_IDX) == rx(1, LAST_SEQ_IDX));
    if isempty(txs_rx_idx)
        fprintf('error%d: tx %d (largest %d) not unique %d for link (%d, %d)\n', rx(1, 1), rx(1, LAST_SEQ_IDX), ...
            max(txs(txs(:, 2) == rx(1, LAST_HOP_IDX), SEQ_IDX)), length(txs_rx_idx), rx(1, LAST_HOP_IDX), rx(1, 2));
        cnts = cnts + 1;
        diff(cnts) = rx(1, LAST_SEQ_IDX) - max(txs(txs(:, 2) == rx(1, LAST_HOP_IDX), SEQ_IDX));
        continue;
    end
    tx = txs(txs_rx_idx, :);
    if find(tx(1, 5 : 10) ~= rx(1, 5 : 10))
%     if find(tx(1, [3:4 8]) ~= rx(1, [3:4 6]))
        fprintf('%d-th reception corrupted', i);
        tx(1, :)
        rx(1, :)
    end
end
diff((cnts + 1) : end) = [];
% find(tmp(:, 13) == 65535);
figure;
hist(diff);
%% UART
clear;
clc;
DirDelimiter='/';
% srcDir = '~/Projects/tOR/RawData';
srcDir = '~/Downloads/Jobs';
srcDir2 = '1556'; % Defined by users
srcDir3 = '';
uarts = [];
dest = [srcDir DirDelimiter srcDir2 srcDir3 DirDelimiter];
files = dir([dest '*.mat']);
% for each node
for fileIndex = 1:length(files)
    indexedFile = files(fileIndex).name;
    if strcmp(indexedFile, 'debugs.mat') || strcmp(indexedFile, 'TxRx.mat')
        disp (['Skip file ' indexedFile]);
        continue;
    end
    load ([dest indexedFile]);
    
    uarts = [uarts; [size(Packet_Log, 1) Packet_Log(end, end)]];
    if (size(Packet_Log, 1) - 1) ~= Packet_Log(end, end)
        disp (['uart loss in file ' indexedFile]);
    end
end
%%
MAX_UINT16 = 65535;
% tmp(:, 1) = [];
tmp = srcPkts;
% IX = tmp(:, 9) ~= MAX_UINT16 & tmp(:, 10) ~= MAX_UINT16 & tmp(:, 11) ~= MAX_UINT16 & ...
%         tmp(:, 12) ~= MAX_UINT16 & tmp(:, 13) ~= MAX_UINT16;
% tmp = tmp(IX, :);
IX = find(~(tmp(:, 6) <= tmp(:, 7) & tmp(:, 7) <= tmp(:, 8) & tmp(:, 8) <= tmp(:, 9) ...
                &tmp(:, 9) <= tmp(:, 10)));
if isempty(IX)
    disp('correct');
else
    disp('wrong');
end
tmp(IX, :);
%% 
% tmp = cnts;
% err_nodes = tmp(tmp(:, 9) == 65535, 2);
err_nodes = unique(srcPkts(:, 2));
for i = 1 : length(err_nodes)
    node_src_pkts = srcPkts(srcPkts(:, 2) == err_nodes(i), :);
    first_convrg_idx = find(node_src_pkts(:, 9) ~= 65535, 1);
    if isempty(first_convrg_idx)
        fprintf('%d-th node %d never converged \n', i, err_nodes(i));
    end
    if ~isempty(find(node_src_pkts(first_convrg_idx + 1 : end, 9) == 65535, 1))
        fprintf('%d-th node %d not converged after initial convergence\n', i, err_nodes(i));
    end
%     if ~isempty(find( & srcPkts(:, 9) ~= 65535))
%         fprintf('%d-th node %d converged \n', i, err_nodes(i));
%     end
end
%%
ROOT_ID = 15;
% root is not representative
tmp = debugs(debugs(:, 2) ~= ROOT_ID, :);
% tmp = debugs;
% tmp = srcPkts;
% tmp = tmp(tmp(:, 3) == 4, :);
senders = unique(debugs(:, 2));
for i = 1 : length(senders)
    node = senders(i);
%     fprintf('processing %d-th node %d\n', i, node);
    tmp_ = tmp(tmp(:, 2) == node & tmp(:, 3) == 18 & tmp(:, 8) == node & tmp(:, 9) ~= 65535 & tmp(:, 13) ~= 65535 & tmp(:, 12) == 0, :);
    if isempty(tmp_)
       fprintf('%d\n', node);
    end
end 
%% link quality among FCs
% OR
b_txs = txs(txs(:, FCS_IDX) ~= INVALID_ADDR, :);
len = size(b_txs, 1);
% C(5, 2)
inter_fc_pdrs = zeros(len * 10, 1);
idx = 1;

for i = 1 : len
    % each FCS used
    entry = b_txs(i, FCS_IDX : FCS_IDX + MAX_FCS_SIZE - 1);
    fcs = entry(entry ~= INVALID_ADDR);
    for j = 1 : (length(fcs) - 1)
        % each FC
        sender_idx = find(senders == fcs(j));
        for k = (j + 1) : length(fcs)
            % each lower rank FC
            receiver_idx = find(senders == fcs(k));
            inter_fc_pdrs(idx) = b_link_pdrs(sender_idx, receiver_idx);
            fprintf('%d-th entry link (%d, %d) added \n', idx, fcs(j), fcs(k));
            idx = idx + 1;
        end
    end
end
% remove unused entries
inter_fc_pdrs(idx : end, :) = [];
[x, nout] = hist(inter_fc_pdrs);
figure;
bar(nout, x / sum(x));

%% EAX
x = .1;
y = .8;
z = .6;
EAX = (1 + x * (1 - z) / y) / (1 - (1 - x) * (1 - z))

%% Shared constants
ROOT_ID = 15;
INVALID_ADDR = 255;
FCS_IDX = 5;

%%
tmp = src_u_b_cost;
tmp(isnan(tmp)) = 0;
sum(tmp(:, 2) .* tmp(:, 3) .* tmp(:, end) + tmp(:, 2) .* (1 - tmp(:, 3)) .* tmp(:, 5)) / sum(tmp(:, 2))


%% cut tail
qtls = quantile(node_sample_ests, [.9, .95, .99, 1]);
node_sample_ests = node_sample_ests(node_sample_ests(:, 2) < 200, :);
figure;
cdfplot(node_sample_ests(:, 2));
%% sanity check of FTSP
INVALID_DELAY = hex2dec('FFFFFFFF');
len = size(debugs, 1);
% reception prior to tx
length(find(debugs(:, 15) >= debugs(:, 16))) / len
% asynchronous
length(find(debugs(:, 15) == INVALID_DELAY | debugs(:, 16) == INVALID_DELAY)) / len
% sample distribution
IX = find(debugs(:, 15) ~= INVALID_DELAY & debugs(:, 16) ~= INVALID_DELAY & debugs(:, 15) < debugs(:, 16));
figure;
cdfplot(debugs(IX, 16) - debugs(IX, 15));

debugs = debugs(debugs(:, 15) ~= INVALID_DELAY & debugs(:, 16) ~= INVALID_DELAY & debugs(:, 15) < debugs(:, 16) ...
                    & (debugs(:, 16) - debugs(:, 15)) <= 7 * debugs(:, 11), :);
% debugs = debugs(debugs(:, 15) < 7 * debugs(:, 3), :);

%% coordination time
INVALID_DELAY = hex2dec('FFFFFFFF');
len = size(debugs, 1);
length(find(debugs(:, 15) == INVALID_DELAY | debugs(:, 16) == INVALID_DELAY)) / len
length(find(debugs(:, 15) >= debugs(:, 16))) / len
IX = find(debugs(:, 15) >= debugs(:, 16));
tmp = debugs(IX, 15) - debugs(IX, 16);
tmp = tmp(tmp < 1000);
% remove invalid entries
debugs(IX, :) = [];
IX = find((debugs(:, 16) - debugs(:, 15)) < (7 * debugs(:, 4)) & debugs(:, 2) == 2);
samples = debugs(IX, 16) - debugs(IX, 15);
ests = debugs(IX, 10);

%% FCS size
INVALID_ADDR = 255;
ROOT_ID = 15;
% UNICAST_IDX = 15;
FCS_IDX = 5;
MAX_FCS_SIZE = 5;
% b_tx = txs(txs(:, 2) ~= ROOT_ID & txs(:, UNICAST_IDX) == 0, :);
b_tx = txs(txs(:, 2) ~= ROOT_ID & txs(:, FCS_IDX) ~= INVALID_ADDR, :);
len = size(b_tx, 1);
FCS_size = zeros(len, 1);
for i = 1 : len
    FCS_size(i) = length(find(b_tx(i, FCS_IDX : (FCS_IDX + MAX_FCS_SIZE - 1)) ~= INVALID_ADDR));
end
figure;
[n, xout] = hist(FCS_size);
bar(xout, n / sum(n));
%% generate random topology
COLUMNS = 7;
ROWS = 15;
% ratio of nodes used
usage = 0.8;
topology = zeros(COLUMNS, ROWS);
for i = 1 : COLUMNS
    for j = 1 : ROWS
        if rand(1) < usage
           topology(i, j) = 1; 
        end
    end
end
fprintf('%f percent nodes selected \n', 100 * length(find(topology == 1)) / (COLUMNS * ROWS));

%% FCS ETX computation
tmp = debugs(:, [2:4, 15]);
% tmp = beacons;
% tmp = ETXs;
tmp = [tmp(:, 2) tmp(:, 3) - tmp(:, 4)];
IX = find(tmp(:, 2) > 0);
tmp(IX, :);
    
%% node OR usage
tmp_txs = txs(:, [2 10]);
node_ids = unique(tmp_txs(:, 1));
len = length(node_ids);
% preallocate
node_OR_usage = zeros(len, 3);
for i = 1 : len
    node_id = node_ids(i);
    node_txs = tmp_txs(tmp_txs(:, 1) == node_id, 2);
    node_OR_usage(i, :) = [node_id, length(find(node_txs == 0)) / length(node_txs), length(node_txs)];
    fprintf('OR usage at node %d: %f \n', node_OR_usage(i, 1), node_OR_usage(i, 2));
end
[tmp, IX] = sort(node_OR_usage(:, 2), 'descend');
node_OR_usage = node_OR_usage(IX, :);
%% degree of estimation
y = zeros(100, 1);
i = 0;
for p = 0 : 0.01 : 1
    i = i + 1;
    y(i) = 0.23 * sqrt(p * (1 - p) / 5);
end
plot(0 : 0.01 : 1, y);

%% # of nodes using OR
% OR_counts = 0;
% tmp = unique(txs(:, 2), 'rows');
% Tx_OR = [];
% for i = 1 : length(tmp)
%     sender = tmp(i);
%     OR_IX = find(txs(:, 2) == sender & txs(:, 10) ~= 1);
%     if ~isempty(OR_IX)
%         OR_counts = OR_counts + 1;
%         Tx_OR = [Tx_OR; sender, length(OR_IX) / length(find(txs(:, 2) == sender))];
%     end
% end
% OR_counts / i
% i

% TX_FLAG = 9;
% RX_FLAG = 10;
% NUM_COLUMNS = 3;
% SENDER_DATA_FORMAT = repmat('%x ', 1, NUM_COLUMNS); % '%x' means HEX
% 
% fid = fopen('../../LinkQuality/result.txt');
% Raw_Data = fscanf(fid, SENDER_DATA_FORMAT,[NUM_COLUMNS inf]);
% TxRx = Raw_Data';
% 
% NODE_COUNTS = 25;
% link_pdrs = zeros(NODE_COUNTS, NODE_COUNTS);
% 
% for i = 1 : NODE_COUNTS
%     for j = 1 : NODE_COUNTS
%         % link (i - 1, j - 1)
%         tx_counts = size(find(TxRx(:, 1) == TX_FLAG & TxRx(:, 2) == (i - 1)), 1);
%         rx_counts = size(find(TxRx(:, 1) == RX_FLAG & TxRx(:, 2) == (j - 1) ...
%                         & TxRx(:, 3) == (i - 1)), 1);
%         link_pdrs(i, j) = rx_counts / tx_counts;
%     end
% end
% link_pdrs;

%% link ETX estimation accurary
% nodes = unique(ETXs(:, 1), 'rows');
% counts = size(nodes, 1);
% estETX = zeros(counts, counts);
% for i = 1 : counts
%     sender = nodes(i);
%     for j = 1 : counts
%         if i == j
%             continue;
%         end
%         receiver = nodes(j);
%         IX = find(ETXs(:, 1) == sender & ETXs(:, 2) == receiver);
%         if isempty(IX)
%             estETX(i, j) = inf;
%         else
%             estETX(i, j) = ETXs(IX(length(IX)), 3) / 256;
%         end
%     end
% end
% %empiracal ETX computed from actual tx / rx
% empETX = zeros(counts, counts);
% for i = 1 : counts
%     SENDER = nodes(i);
%     for j = 1 : counts
%         if i == j
%             continue;
%         end
%         RECEIVER = nodes(j);
%         TXs = size(find(txs(:, 2) == SENDER), 1);
%         if isempty(TXs)
%             continue;
%         end
%         RXs = size(find(rxs(:, 2) == RECEIVER & rxs(:, 10) == SENDER), 1);
%         if TXs < RXs
%             disp('logerr');
%         end
%         empETX(i, j) = TXs / RXs;
% %         fprintf('link quality from %d to %d: %d out %d = %f \n', SENDER, RECEIVER, RXs, TXs, RXs / TXs);
%     end
% end
% empETX
%% path ETX hist
% ETXs = [];
% for i = 1 : size(All_Com_Paths, 1)
%     ETX = All_Com_Paths(i, 2);
%     ETXs = [ETXs; ETX{1, 1}(1)]
% end
% [n, xout] = hist(ETXs, 50); 
% bar(xout, n / sum(n));

% %% from interception to next ACK
% nodeId = 11;
% % IX = find(Packet_Log(:, 1) == 2);
% IX = find(Packet_Log(:, 1) == 10 & Packet_Log(:, 16) == 0);
% entry_counts = size(Packet_Log, 1);
% intervals = [];
% for i = 1 : length(IX)
%     intercept_time = Packet_Log(IX(i), 15);
%     % am I FC?
%     fc = false;
%     for j = 5 : 9
%         if Packet_Log(IX(i), j) == nodeId
%             fc = true;
%             break;
%         end
%     end
%     if ~fc 
%         continue;
%     end
%     remain_log = Packet_Log(IX(i) : entry_counts, :);
%     if isempty(remain_log)
%         continue;
%     end
%     ackIX = find(remain_log(:, 1) == 9 & remain_log(:, 3) ~= 0);
%     if ~isempty(ackIX)
%         next_ack_time = remain_log(ackIX(1), 15);
%     end
%     intervals = [intervals; IX(i), next_ack_time - intercept_time];
% end
% 
% %% sync accuracy
% DirDelimiter='/';
% srcDir = '~/Downloads/Jobs';
% srcDir2 = '88'; % Defined by users
% srcDir3 = '';
% dest = [srcDir DirDelimiter srcDir2 srcDir3 DirDelimiter];
% files = dir([dest '*.mat']);
% SEQ_POS = 4;
% SYNC_FLAG = 22;
% TIMESTAMP_POS = 15;
% syncCnts = 20;
% timestamps = zeros(syncCnts, length(files));
% for i = 1 : syncCnts
%     for fileIndex = 1:length(files)
%         indexedFile = files(fileIndex).name;
%         load ([dest indexedFile]);
%         disp (['Loading file ' indexedFile]);
%         IDX = find(Packet_Log(:, 1) == SYNC_FLAG & Packet_Log(:, SEQ_POS) == i);
%         if isempty(IDX)
%             time = 0;
%         else
%             time = Packet_Log(IDX, TIMESTAMP_POS);
%         end
%         timestamps(i, fileIndex) = time;
%     end
% end
% 
% temp = [];
% for i = 2 : 7
%     temp = [temp; timestamps(i, :) - timestamps(i, 1)]
% end

save('link_pdr ')
allSenders = unique(txs(:, 2), 'rows');
allReceivers = unique(rxs(:, 2), 'rows');
for i = 1 : length(allSenders)
    for j = 1 : length(allReceivers)
        SENDER = allSenders(i);
        RECEIVER = allReceivers(j);
        if SENDER == RECEIVER
            continue;
        end
        TXs = size(find(txs(:, 2) == SENDER), 1);
        RXs = size(find(rxs(:, 2) == RECEIVER & rxs(:, 10) == SENDER), 1);
        if TXs < RXs
            disp('logerr');
        end
        fprintf('link quality from %d to %d: %d out %d = %f \n', SENDER, RECEIVER, RXs, TXs, RXs / TXs);
    end
end

tx_id = 43;
rx_id = 15;
tx = txs(find(txs(:, 2) == tx_id), :);
rx = rxs(find(rxs(:, 2) == rx_id & rxs(:, 10) == tx_id), :);


result = Packet_Log; %[Packet_Log(:, 1) Packet_Log(:, 3:4) Packet_Log(:, 11)];
idx = find(result(:, 1) >= 18 & result(:, 1) <= 20);
answers = [result(idx, 1) result(idx, 3:4) result(idx, 15)];

for i = 1 : size(swfs, 1)
   if (swfs(i, 2) == (swfs(i, 3) + 1))
%    if mod(swfs(i, 2), 256) ~= swfs(i, 1)
       disp(['sth smells bad from ' num2str(i)]);
       break;
   end
end

%% quantile estimation error analysis
% clear;
%sample from paper: 0.15 is errorneously said to be 0.5
% samples = [0.02; 0.15; 0.74; 3.39; 0.83; 22.37; 10.15; 15.43; 38.62; 15.92; 34.60;...
%         10.28; 1.47; 0.40; 0.05; 11.39; 0.27; 0.42; 0.09; 11.37];
% load('samples.mat');    
% load('~/Downloads/Jobs/3615/samples.mat');    
% p = [0.25, 0.5, 0.75, 0.8, 0.85, .9];
p = [.9];
IX = find(p == .9);
POI = IX(1);
% for i = 1 : length(p)
%     markers = P2QtlEst(samples, p(i));
%     p2_est = markers(size(markers, 1), 3)
%     p2_etx_est = P2QtlEst_Ext(samples, p(i))
% end
errors = [];
% samples = samples(find(samples <= 100));
% [p2_etx_ests, adjusts] = P2QtlEst_Ext(samples, p);
for i = 1 : size(linkDelaySamples, 1) % (2 * length(p) + 3) : 
    temp_samples = linkDelaySamples(1 : i);
%     temp_samples = temp_samples(find(temp_samples <= 100));
    [p2_etx_ests, adjusts] = P2QtlEst_Ext(temp_samples, p);
    p2_etx_ests = linkDelayEsts(i);
    actual_values = quantile(temp_samples, p);
    
    if actual_values(POI) ~= 0 
        error = (p2_etx_ests - actual_values(POI)) / actual_values(POI);
        errors = [errors; error];
    end
end
plot(errors);
% end