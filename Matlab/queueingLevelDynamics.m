%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Xiaohui Liu
%   6/24/2011
%   Function: study the dynamics of queueing level (hop & e2e) job 7200
%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% prepare samples <seqno, queueing at each hop>
% for each received pkt at each hop, compute what pkts are queued prior to it
% for pkt i at hop j (rx_timestamp(i, j), rx_timestamp(i, j + 1))
% all pkts k w/ rx_timestamp(k, j + 1) in between
% sum all tx delays of such pkts and test bounding err
SRC_IDX = 3;
SRC_SEQ_IDX = 4;
LINK_DELAY_IDX = 10;
nodes = [15, 27, 6, 64, 79, 76];
t = node_seqno_timestamp;
QUEUE_SIZE = 39;

seqnos = unique(destPkts(:, SRC_SEQ_IDX));
seqno_hop_queue_lens = zeros(length(seqnos), length(nodes) - 1);
%% only pkts w/ info @ each hop known are considered
valid_seqno_idxs = zeros(length(seqnos), 1);
valid_idx = 1;

clc;
% for each pkt
for i = 1 : length(seqnos)
    seqno = seqnos(i);
    is_valid = true;
%     fprintf('processing seqno %d\n', seqno);
    % each hop
    for j = 1 : (length(nodes) - 1)
        sender = nodes(j + 1);
        receiver = nodes(j);
        
        tmp = t(t(:, 1) == sender & t(:, 2) == seqno, 3);
        if isempty(tmp)
            fprintf('pkt %d @ hop %d not found @ sender\n', seqno, j);
            is_valid = false;
            break;
        end
        sender_rx_time = tmp(1);
        
        tmp = t(t(:, 1) == receiver & t(:, 2) == seqno, 3);
        if isempty(tmp)
            fprintf('pkt %d @ hop %d not found @ receiver\n', seqno, j);
            is_valid = false;
            break;
        end
        receiver_rx_time = tmp(1);
        
        % find pkts queued
        pkts_in_queue = unique(t(t(:, 1) == receiver & t(:, 3) > sender_rx_time & t(:, 3) < receiver_rx_time, 2));
        seqno_hop_queue_lens(i, j) = length(pkts_in_queue);
        
        % sanity check: queued pkts should be smaller than current pkt
        if ~isempty(find(pkts_in_queue >= seqno, 1))
            fprintf('err: queued pkts @ %d should be smaller than current pkt %d\n', j, seqno);
        end
        % no overflow
        if length(pkts_in_queue) > QUEUE_SIZE
            fprintf('err: queued pkts counts %d exceed queue size %d\n', length(unique(pkts_in_queue)), QUEUE_SIZE);
        end
    end
    if is_valid
        valid_seqno_idxs(valid_idx) = i;
        valid_idx = valid_idx + 1;
    end
end
valid_seqno_idxs(valid_idx : end, :) = [];
% does not include pkt itself
save('seqno_hop_queue_lens.mat', 'seqno_hop_queue_lens', 'valid_seqno_idxs');

%% compose <seqno, e2e queueing>
seqno_e2e_queue_levels = [seqnos(valid_seqno_idxs) ...
    sum(seqno_hop_queue_lens(valid_seqno_idxs, :), 2) + length(nodes) - 1];
t = seqno_e2e_queue_levels;
%%
MAX_SEQ_INTERVAL = 10;
inter_e2e_queue_level_diff = cell(MAX_SEQ_INTERVAL, 1);
% each interval
for i = 1 : MAX_SEQ_INTERVAL
    % each packet
    for j = 1 : size(t, 1)
        seqno = t(j, 1);
        % packets seperated by interval i
        IX = find(t(:, 1) == seqno + i, 1);
        if ~isempty(IX)
            diff = abs(t(IX(1), 2) - t(j, 2));
            inter_e2e_queue_level_diff{i} = [inter_e2e_queue_level_diff{i}; diff];
        end
    end
end
save('inter_e2e_queue_level_diff.mat', 'inter_e2e_queue_level_diff');

%% display
t = inter_e2e_queue_level_diff;
group = zeros(0);
distJittersDisp = zeros(0);
for i = 1 : size(t, 1)
    group = [group ; ones(size(t{i})) + i - 1];
    distJittersDisp = [distJittersDisp ; t{i}];
end
title_str = 'e2e queue level vs packet interval';
figure('name', title_str);
boxplot(distJittersDisp, group);
set(gca, 'FontSize', 30, 'YGrid', 'on');
xlabel('Packet Interval');
ylabel('queue level changes');
%%
LAG_CNTS = 100;
X = seqno_e2e_queue_levels(:, 2);
[lags ACF] = autocorr(X, LAG_CNTS);
figure;
% excluding lag 0
h = plot(ACF(2 : end), lags(2 : end));
set(gca, 'FontSize', 30);
title_str = ['e2e queue level autocorrelation vs lags'];
title(title_str);
hold on;
saveas(h, title_str, 'fig');
saveas(h, title_str, 'jpg');
%% hop
t = seqno_hop_queue_lens;
for i = 1 : size(t, 2)
    title_str = ['queue level at hop ' num2str(i)];
    figure('name', title_str);
    h = plot(t(:, i));
    set(gca, 'FontSize', 30, 'YGrid', 'on');
    xlabel('Packet $');
    ylabel('queue level ');
    saveas(h, title_str, 'fig');
    saveas(h, title_str, 'jpg');
    
    % autocorrelation
    LAG_CNTS = 100;
    
    X = t(:, i);
    [lags ACF] = autocorr(X, LAG_CNTS);
    figure;
    % excluding lag 0
    h = plot(ACF(2 : end), lags(2 : end));
    set(gca, 'FontSize', 30);
    title_str = ['hop ' num2str(i) ' delay autocorrelation vs lags'];
    title(title_str);
    hold on;
    saveas(h, title_str, 'fig');
    saveas(h, title_str, 'jpg');
end




%% %% link queueing changes
% MTA: job 7132     M-mDQ: 7134     mDQ: 7137
DBG_FLAG = 18;
t = debugs;
t = t(t(:, 3) == DBG_FLAG, :);
MAX_ENTRY = inf;
%% queueing at every pkt arrival (deprecated)
% clc;
% NODE_IDX = 2;
% SRC_IDX = 5;
% SEQ_IDX = 4;
% 
% % [node, [pkt id], receiver, queue level for the link]
% link_queues = zeros(100000, 5);
% idx = 1;
% 
% nodes = unique(t(:, NODE_IDX));
% % each node
% for node_idx = 1 : size(nodes, 1)
%     node = nodes(node_idx);
%     n_t = t(t(:, NODE_IDX) == node, :);
%     node_src_seqs = unique(n_t(:, [SRC_IDX SEQ_IDX]), 'rows');
%     
%     r = txs;
%     r = r(r(:, NODE_IDX) == node, :);
%     
%     % each packet
%     for i = 1 : min(size(node_src_seqs, 1), MAX_ENTRY)
%         node_src_seq = node_src_seqs(i, :);
% 
%         % find the records
%         IX = ismember(n_t(:, [SRC_IDX SEQ_IDX]), node_src_seq, 'rows');
%         % s now contains all queued pkts for this node_src_seq
%         s = n_t(IX, :);
% 
%         % each UART log 6:10 [seq0, seq1, seq2, seq3, [src0, src1, src2, src3]]
%         rcvrs = [];
%         fprintf('%d-th <%d %d %d>: ', i, node, node_src_seq(1), node_src_seq(2));
%         % each queued pkt
%         for j = 1 : size(s, 1)
%             for k = 1 : 4
%                 % right shift
%                 src = mod(floor(s(j, 10) / 2 ^ (8 * (k - 1))), 256);
%                 seq = s(j, k + 5);
% 
%                 if seq ~= 0
%                     % find the next hop for this queued pkt
%                     % caution: column for src and seq are 3 and 4 in txs
%                     IX = find(r(:, 3) == src & r(:, 4) == seq, 1);
%                     if isempty(IX)
%                         continue;
%                     end
% 
%                     receiver = r(IX, 10);
%                     rcvrs = [rcvrs; receiver];
%                     fprintf('<%d: %d, %d>, ', receiver, src, seq);
%                 else
%                     % invalid src
%                     break;
%                 end
%             end
%         end
% %         [n, m] = hist(rcvrs, unique(rcvrs));
% %         rcvr_cnts = [m; n]';
%         % calculate link occurance
%         % [receiver, pkts to be sent to the receiver]
%         rcvr_cnts = [];        
%         u_rcvrs = unique(rcvrs);
%         for j = 1 : size(u_rcvrs, 1)
%             rcvr = u_rcvrs(j);
%             rcvr_cnts = [rcvr_cnts; rcvr sum(rcvrs == rcvr)];
%             
%             % sanity check
%             if sum(rcvrs == rcvr) > 28
%                 disp('err');
%             end
%         end
%         fprintf('\n');
%         
%         len = size(rcvr_cnts, 1);
%         link_queues(idx : (idx + len - 1), :) = [repmat([node node_src_seq], len, 1) rcvr_cnts];
%         idx = idx + len;
%     end
% end
% link_queues(idx : end, :) = [];
% save('link_queues.mat', 'link_queues');
%% queueing at every pkt arrival
clc;
NODE_IDX = 2;
SRC_IDX = 5;
SEQ_IDX = 4;

% [node, [pkt id], receiver, queue level for the link]
link_queues = zeros(100000, 5);
idx = 1;

nodes = unique(t(:, NODE_IDX));
% each node
for node_idx = 1 : size(nodes, 1)
    node = nodes(node_idx);
    n_t = t(t(:, NODE_IDX) == node, :);
    node_src_seqs = unique(n_t(:, [SRC_IDX SEQ_IDX]), 'rows');
    
    r = txs;
    r = r(r(:, NODE_IDX) == node, :);
    
    % each packet
    for i = 1 : min(size(node_src_seqs, 1), MAX_ENTRY)
        node_src_seq = node_src_seqs(i, :);

        % find the records
        IX = ismember(n_t(:, [SRC_IDX SEQ_IDX]), node_src_seq, 'rows');
        % s now contains all queued pkts for this node_src_seq
        s = n_t(IX, :);

        % each UART log 6:10 [seq0, seq1, seq2, seq3, [src0, src1, src2, src3]]
        rcvrs = [];
        fprintf('%d-th <%d %d %d>: ', i, node, node_src_seq(1), node_src_seq(2));
        src_seqs = [];
        % each queued pkt
        for j = 1 : size(s, 1)
            for k = 1 : 4
                % right shift
                src = mod(floor(s(j, 10) / 2 ^ (8 * (k - 1))), 256);
                seq = s(j, k + 5);

                if seq ~= 0
                    % queued pkt
                    src_seqs = [src_seqs; src seq];
                else
                    % invalid src
                    break;
                end
            end
        end
        
        % find corresponding next-hops for all queued pkts
        IX = ismember(r(:, 3:4), src_seqs, 'rows');
        r_ = r(IX, :);
        
        % each queued pkt
        for j = 1 : size(src_seqs, 1)
            % find the next hop for this queued pkt
            src_seq = src_seqs(j, :);
            % caution: column for src and seq are 3 and 4 in txs
            IX = find(r_(:, 3) == src_seq(1) & r_(:, 4) == src_seq(2), 1);
            if isempty(IX)
                continue;
            end

            receiver = r_(IX, 10);
            rcvrs = [rcvrs; receiver];
            fprintf('<%d: %d, %d>, ', receiver, src_seq(1), src_seq(2));
        end
%         [n, m] = hist(rcvrs, unique(rcvrs));
%         rcvr_cnts = [m; n]';
        % calculate link occurance
        % [receiver, pkts to be sent to the receiver]
        rcvr_cnts = [];        
        u_rcvrs = unique(rcvrs);
        for j = 1 : size(u_rcvrs, 1)
            rcvr = u_rcvrs(j);
            rcvr_cnts = [rcvr_cnts; rcvr sum(rcvrs == rcvr)];
            
            % sanity check
            if sum(rcvrs == rcvr) > 28
                disp('err');
            end
        end
        fprintf('\n');
        
        len = size(rcvr_cnts, 1);
        link_queues(idx : (idx + len - 1), :) = [repmat([node node_src_seq], len, 1) rcvr_cnts];
        idx = idx + len;
    end
end
link_queues(idx : end, :) = [];
save('link_queues.mat', 'link_queues');

%% %% link queue changes
% 
MIN_SAMPLE_CNTS = 1000;
MEDIAN_CI_MIN_SAMPLE = 4;
% use tx queue log instead
t = link_queues;
links = unique(t(:, 1:2), 'rows');
LAG = 1;
QUEUE_SIZE = 28;
% in link_queues
QUEUE_SIZE_IDX = 3;
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
    
    % each link
    for i = 1 : size(links, 1)
        link = links(i, :);
        s = t(t(:, 1) == link(1) & t(:, 2) == link(2), QUEUE_SIZE_IDX);

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
figure;
% bar(dataDisps);
barerrorbar({1:size(dataDisps, 1), dataDisps}, {repmat((1:size(dataDisps, 1))', 1, size(lags, 1)), dataDisps, lo_errs, hi_errs, 'x'});
h = legend(legends);
set(h, 'FontSize', 40);
set(gca, 'FontSize', 30, 'xtick', 1:size(queue_medians', 1), 'xticklabel', queue_medians');
xlabel('Maximum link queueing level');
ylabel('Median of link queueing level change');
%%
maximize;
set(gcf, 'Color', 'white');
cd(dir);
str = 'medium_traffic_proportional_link_queue_change_group_max';
export_fig(str, '-eps');
% export_fig(str, '-jpg', '-zbuffer');
saveas(gcf, [str '.fig']);


%% %% link queue changes
MIN_SAMPLE_CNTS = 1000;
MEDIAN_CI_MIN_SAMPLE = 4;
% use tx queue log instead
load link_queues.mat;
t = link_queues;
links = unique(t(:, 1:2), 'rows');
LAG = 1;
QUEUE_SIZE = 28;
% in link_queues
QUEUE_SIZE_IDX = 3;
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
% include empty queue
results = cell(size(lags, 1), 1);

for lag_idx = 1 : size(lags, 1)
    lag = lags(lag_idx);
    fprintf('lag %d\n', lag);
    % each link
    for i = 1 : size(links, 1)
        link = links(i, :);
        s = t(t(:, 1) == link(1) & t(:, 2) == link(2), QUEUE_SIZE_IDX);

        % validate
        s = s(s <= QUEUE_SIZE);

        % include pkt itself
        results{lag_idx} = [results{lag_idx}; abs(s(1 + lag : end) - s(1 : end - lag))];
    end
end

%%
figure;
hold all;
for i = 1 : size(results, 1)
%     cdfplot(results{i});
    DOWN_SCALE = 1;
    [f, x] = ecdf(results{i});
    plot(x(1:DOWN_SCALE:end), f(1:DOWN_SCALE:end));
%     subplot(2, 2, i);
%     x = results{i};
%     [n x] = hist(x, 20);
%     bar(x, 100 * n / sum(n));
%     set(gca, 'FontSize', 30, 'xtick', 0:5:10, 'ytick', 0:20:100);
%     title(legends{i});
%     ylabel('Frequency (%)');
%     xlabel('Link queueing level changes');
end

%% link queueing dynamics
MIN_SAMPLE_CNT = 1000;
MAX_ENTRY = 10000;
% [node, [pkt_src pkt_seq], receiver, queue level for the link]
t = link_queues;
nodes = unique(t(:, 1));

% result
links = zeros(MAX_ENTRY, 2);
link_results = cell(MAX_ENTRY, 1);
idx = 1;

% each node
for node_id = 1 : size(nodes, 1)
    node = nodes(node_id);
    % s records all activities at a node
    r = t(t(:, 1) == node, :);
    receivers = unique(r(:, 4));
    
    % filter receivers rarely used
    rcvrs = [];
    for i = 1 : size(receivers, 1)
        receiver = receivers(i);
        if sum(r(:, 4) == receiver) >= MIN_SAMPLE_CNT
            rcvrs = [rcvrs; receiver];
        end
    end
    if isempty(rcvrs)
        continue;
    end
    
    pkts = unique(r(:, 2:3), 'rows');
    
    % store queueing for each link
    rcvr_qs = zeros(size(receivers, 1), size(pkts, 1));
    idxs = ones(size(receivers, 1), size(pkts, 1));
    
    % each snapshot, i.e., every new arrival
    for i = 1 : size(pkts, 1)
        pkt = pkts(i, :);
        % queueing when the pkt arrives at this node [rcvr, queueing]
        rcvr_q = r(r(:, 2) == pkt(1) & r(:, 3) == pkt(2), 4:5);
        % sanity check
%         if size(rcvr_q, 1) > 3
%             pkt;
%         end

        % each link: 0 queueing if no queued pkt
        for j = 1 : size(rcvrs, 1)
            rcvr = rcvrs(j);
            
            q = sum(rcvr_q(rcvr_q(:, 1) == rcvr, 2));
            rcvr_qs(j, idxs(j)) = q;
            idxs(j) = idxs(j) + 1;
            if q > 28
                fprintf('link <%u, %u> queueing: %u\n', node, rcvr, q);
            end
        end
    end
    
    % changes
    % each link
    for j = 1 : size(rcvrs, 1)
        s = rcvr_qs(j, 1 : idxs(j) - 1);
        
        links(idx, :) = [node rcvrs(j)];
        link_results{idx} = s;
        idx = idx + 1;
    end
end
links(idx : end, :) = [];
link_results(idx : end, :) = [];
save('results.mat', 'links', 'link_results');

%% link queueing changes distribution
t = link_results;
lags = [1 3 5 10];
lags = lags';

LAG_CNTS = size(lags, 1);
legends = cell(LAG_CNTS, 1);
for i = 1 : LAG_CNTS
    legends{i} = ['Lag ' num2str(lags(i))];
end
% include empty queue
results = cell(size(lags, 1), 1);

for lag_idx = 1 : size(lags, 1)
    lag = lags(lag_idx);
    fprintf('lag %d\n', lag);
    % each link
    for i = 1 : size(t, 1)
        s = t{i};

        r = s(1 + lag : end) - s(1 : end - lag);
        fprintf('median %u, max %u\n', median(r), max(r));
        results{lag_idx} = [results{lag_idx}; r'];
    end
end

%% link pkt time
MIN_SAMPLE_CNT = 1000;
NODE_IDX = 2;
LAST_HOP_IDX = 8;
PKT_TIME_IDX = 9;
MAX_PKT_TIME = 10000;
t = debugs;
% link pkt time records
t = t(t(:, 3) == 17, :);

% pre-compute link pkt time
links = unique(t(:, [LAST_HOP_IDX NODE_IDX]), 'rows');
% [sender, receiver, link pkt time[mean, var]]
link_pkt_times = zeros(10000, 4);
idx = 1;
for i = 1 : size(links, 1)
    link = links(i, :);
    
    s = t(t(:, LAST_HOP_IDX) == link(1) & t(:, NODE_IDX) == link(2), PKT_TIME_IDX);
    s = s(s < MAX_PKT_TIME);
    if size(s, 1) < MIN_SAMPLE_CNT
        continue;
    end
%     plot(s);
    fprintf('%f, %f\n', mean(s), var(s));
    link_pkt_times(idx, :) = [link mean(s) var(s)];
    idx = idx + 1;
end
link_pkt_times(idx : end, :) = [];


%% node queueing changes
% [node, [pkt_src pkt_seq], receiver, queue level for the link]
t = link_queues;
nodes = unique(t(:, 1));
% [node queueing, node delay]
node_qs = cell(length(nodes), 1);

% each node
for i = 1 : length(nodes)
    node = nodes(i);
    % all entries of node
    s = t(t(:, 1) == node, :);
    
    pkts = unique(s(:, 2:3), 'rows');
    node_q = [];
    % each pkt
    for j = 1 : size(pkts, 1)
        pkt = pkts(j, :);
%         fprintf('<%u, %u> @ %u\n', pkt(1), pkt(2), node);
        
        pkt_link_qs = s(s(:, 2) == pkt(1) & s(:, 3) == pkt(2), :);
        
        valid = true;
        % node delay = sum(link pkt time * link queueing) over all outgoing links
        total = 0;
        for k = 1 : size(pkt_link_qs, 1)
            link_q = pkt_link_qs(k, :);
            link = [node link_q(4)];
            % look up link pkt time
            IX = find(ismember(link_pkt_times(:, 1:2), link, 'rows'));
            if isempty(IX)
                valid = false;
                % sanity
                disp('err 1');
                break;
            end
            link_delay = link_pkt_times(IX(1), 3);
            
            total = total + link_q(5) * link_delay;
        end
        
        if ~valid
            continue;
        end
        % node queue
        pkt_node_q = sum(pkt_link_qs(:, 5));
        
        node_q = [node_q; [pkt_node_q total]];
        % sanity
        if pkt_node_q < 1 || pkt_node_q > 28
            disp('err');
        end
    end
    node_qs{i} = node_q;
end
save('node_qs.mat', 'node_qs');


%% path delay (e.g. mean/var/qtl) dynamics
NEXT_HOP_IDX = 10;
ROOT_ID = 15;
INVALID_ID = 255;
% only consider pkts reaching sink

t = txs;
% [node, [pkt id], receiver, queue level for the link]
l = link_queues;

% [e2e q, e2e instant delay mean/var]
q_pkt_delays = zeros(size(pkt_delays, 1), 3);


for i = 1 : size(pkt_delays, 1)
    fprintf('pkt %u\n', i);
    pkt = pkt_delays(i, 1:2);
    pkt_q = 0;
    pkt_delay = zeros(1, 2);
    
    % find the path
    path = pkt_paths(i, :);
    
    % sanity
    if pkt(1) ~= path(1)
        fprintf('err @ %u\n', i);
    end
    
    for j = 1 : length(path)
        node = path(j);
        if node == ROOT_ID || node == INVALID_ID
            break;
        end
        
        % queueing
        s = l(l(:, 1) == node & l(:, 2) == pkt(1) & l(:, 3) == pkt(2), :);
        if isempty(s)
            fprintf('err 2 @ %u\n', i);
            break;
        end
        pkt_q = pkt_q + sum(s(:, 5));
        
        % node delay
        valid = true;
        % each queued pkt
        for k = 1 : size(s, 1)
            link = s(k, [1 4]);
            IX = link_pkt_times(:, 1) == link(1) & link_pkt_times(:, 2) == link(2);
            link_pkt_time = link_pkt_times(IX, 3:4);
            if isempty(link_pkt_time)
                valid = false;
%                 fprintf('err 3 @ %u\n', i);
                break;
            end 
            pkt_delay = pkt_delay + link_pkt_time * s(k, 5);
        end
        if ~valid
            break;
        end
    end
    
    if node == ROOT_ID
        % success
        q_pkt_delays(i, :) = [pkt_q pkt_delay];
%     else
%         fprintf('err 4 @ %u\n', i);
    end
end
save('q_pkt_delays.mat', 'q_pkt_delays');


%% group by paths
t = q_pkt_delays;
IX = (t(:, 1) ~= 0);
s = t(IX, :);
paths = pkt_paths(IX, :);
pkts = pkt_delays(IX, 1:2);

u_paths = unique(paths, 'rows');
u_path_lens = [];
path_q_delays = cell(size(u_paths, 1), 1);

for i = 1 : size(u_paths, 1)
    path = u_paths(i, :); 
    IX = ismember(paths, path, 'rows');
    path_q_delays{i} = s(IX, :);
    
    u_path_lens = [u_path_lens; sum(path ~= INVALID_ID) - 1];
end

%% categorize based on queueing & lag
MIN_SAMPLE_SIZE = 400;
MAX_Q_CNT = 4;
lags = [1 5 10];
lags = lags';

results = cell(MAX_Q_CNT, size(lags, 1));
t = link_results;
% [node queueing, node delay]
% t = node_qs;
% t = path_q_delays;
fprintf('\n');
for i = 1 : size(t, 1)
    s = t{i};
    if length(s) < MIN_SAMPLE_SIZE
        continue;
    end
    % link 
    q = s';
    % 1: queueing 2: node/path delay mean 3: variance
%     q = s(:, 2) + 3 * sqrt(s(:, 3));
%     q = s(:, 1);
    % queueing
    s = s(:, 1);
    fprintf('%u ', max(s));
%     idx = max(s);
%     idx = ceil(idx / 6);
    % aggregate
    idx = 1;
    % group by path lens
%     idx = u_path_lens(i) - 1;
    for j = 1 : size(lags, 1)
        lag = lags(j);
        results{idx, j} = [results{idx, j}; q(1 + lag : end) - q(1 : end - lag)];
    end
end

%%
q_idx = 1;
% close all;
figure;
hold all;
t = results;
legends = cell(size(lags, 1), 1);
for i = 1 : size(legends, 1)
    legends{i} = ['Lag ' num2str(lags(i))];
end
for i = 1 : size(t, 2)
    s = t{q_idx, i};
%     s = t{i};
%     cdfplot(s');
    DOWN_SCALE = 1;
    [f, x] = ecdf(s);
    plot(x(1:DOWN_SCALE:end), f(1:DOWN_SCALE:end), 'LineWidth', 3);
end
legend(legends);
hold off;

%%
% legend(legends);
bound = 10;
grid on;
% set(gca, 'FontSize', 40);
set(gca, 'FontSize', 40, 'xtick', -bound:2:bound, 'ytick', 0:0.2:1);
ylabel('CDF');
xlabel('Link queueing level changes');
% ylim([0.7 1]);
xlim([-bound bound] * 1);
%%
% maximize;
set(gcf, 'Color', 'white');
cd('~/Dropbox/tOR/figures');
str = ['medium_traffic_proportional_link_queue_change_cdf'];
export_fig(str, '-eps');
export_fig(str, '-jpg', '-zbuffer');
saveas(gcf, [str '.fig']);
