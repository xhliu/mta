%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Xiaohui Liu
%   6/24/2011
%   Function: prepare samples for RVSumQtlBounds_Multihop
%       job 2929
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% prepare samples
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
%%
seqno_hop_queues = cell(length(seqnos), length(nodes) - 1);
% for each pkt
for i = 1 : length(seqnos)
    seqno = seqnos(i);
    fprintf('processing seqno %d\n', seqno);
    % each hop
    for j = 1 : (length(nodes) - 1)
        sender = nodes(j + 1);
        receiver = nodes(j);
        
        tmp = t(t(:, 1) == sender & t(:, 2) == seqno, 3);
        if isempty(tmp)
            fprintf('pkt %d @ hop %d not found @ sender\n', seqno, j);
            continue;
        end
        sender_rx_time = tmp(1);
        
        tmp = t(t(:, 1) == receiver & t(:, 2) == seqno, 3);
        if isempty(tmp)
            fprintf('pkt %d @ hop %d not found @ receiver\n', seqno, j);
            continue;
        end
        receiver_rx_time = tmp(1);
        
        % find pkts queued
        pkts_in_queue = unique(t(t(:, 1) == receiver & t(:, 3) > sender_rx_time & t(:, 3) < receiver_rx_time, 2));
        seqno_hop_queues{i, j} = pkts_in_queue;
        % sanity check: queued pkts should be smaller than current pkt
        if ~isempty(find(pkts_in_queue >= seqno, 1))
            fprintf('err: queued pkts @ %d should be smaller than current pkt %d\n', j, seqno);
        end
        % no overflow
        if length(pkts_in_queue) > QUEUE_SIZE
            fprintf('err: queued pkts counts %d exceed queue size %d\n', length(unique(pkts_in_queue)), QUEUE_SIZE);
        end
    end
end
% packets queued prior to the pkt in concern at each hop
save('seqno_hop_queues.mat', 'seqno_hop_queues');
%% how many unique e2e queueing levels
e2e_queue_levels = zeros(length(seqnos), 1);
% each pkt
for i = 1 : length(seqnos)
    % include the pkt itself
    e2e_queue_level = length(nodes) - 1;
    % each hop
    for j = 1 : (length(nodes) - 1)
        e2e_queue_level = e2e_queue_level + size(seqno_hop_queues{i, j}, 1);
        %sanity check
        if size(seqno_hop_queues{i, j}, 1) >= QUEUE_SIZE
            fprintf('error for seq %d\n', seqnos(i));
        end
    end
    e2e_queue_levels(i) = e2e_queue_level;
end
%% hash according to e2e queueing
unique_e2e_queue_levels = unique(e2e_queue_levels);
e2e_queue_level_tx_delays = cell(length(unique_e2e_queue_levels), 1);
for i = 1 : length(seqnos)
    % find the bucket each pkt belongs to according to its e2e queue level
    IX = find(unique_e2e_queue_levels == e2e_queue_levels(i));
    pkt_tx_delays = [];
    all_queued_pkts_found = true;
    
    % find all tx delays along the pkt's path
    % each hop
    for j = 1 : (length(nodes) - 1)
        sender = nodes(j + 1);
        sender_txs = txs(txs(:, 2) == sender, :);
        % include the pkt itself
        pkts_in_queue = [seqno_hop_queues{i, j}; seqnos(i)];
        % each queued pkt
        for k = 1 : length(pkts_in_queue)
            tmp = sender_txs(sender_txs(:, SRC_SEQ_IDX) == pkts_in_queue(k), LINK_DELAY_IDX);
            if isempty(tmp)
                fprintf('err: pkt %d not found in %d\n', pkts_in_queue(k), sender);
                all_queued_pkts_found = false;
                break;
            else
                pkt_tx_delays = [pkt_tx_delays tmp(1)];
            end
        end
        if ~all_queued_pkts_found
            break;
        end
    end
    
    % append into the bucket only all queued pkts tx delay found
    if all_queued_pkts_found
        e2e_queue_level_tx_delays{IX} = [e2e_queue_level_tx_delays{IX} ; pkt_tx_delays];
    else
        fprintf('err: some queued pkt for src pkt %d not found\n', seqnos(i));
    end
end
% save('e2e_queue_level_tx_delays.mat', 'e2e_queue_level_tx_delays');

%% hash according to hop queueing
hop_queue_levels = [0 0 0 0 0; 0 0 35 0 0; 0 0 36 0 0];
% sanity check; pkts meeting all the levels
% identical_seqs = [];
% pkts queued before a newly-arrived packet, excluding itself
t = seqno_hop_queue_levels;
e2e_queue_level_tx_delays = cell(size(hop_queue_levels, 1), 1);
% each pkt
for i = 1 : size(t, 1)
    % find the bucket each pkt belongs to according to its e2e queue level
    %IX = find(unique_e2e_queue_levels == e2e_queue_levels(i));
    % all hop queue levels compliant?
    found = false;
    for j = 1 : size(hop_queue_levels, 1)
        if isempty(find(seqno_hop_queue_levels(i, :) ~= hop_queue_levels(j, :), 1))
            found = true;
            break;
        end
    end
    if ~found
        % not found
        continue;
    end
    IX = j;
%     identical_seqs = [identical_seqs; i];
    % found; compute e2e delay

    pkt_e2e_tx_delays = 0;
    all_queued_pkts_found = true;
    
    % find all tx delays along the pkt's path
    % each hop
    for j = 1 : (length(nodes) - 1)
        sender = nodes(j + 1);
        sender_txs = txs(txs(:, 2) == sender, :);
        % include the pkt itself
        pkts_in_queue = [seqno_hop_queues{i, j}; seqnos(i)];
        % each queued pkt
        for k = 1 : length(pkts_in_queue)
            tmp = sender_txs(sender_txs(:, SRC_SEQ_IDX) == pkts_in_queue(k), LINK_DELAY_IDX);
            if isempty(tmp)
                fprintf('err: pkt %d not found in %d\n', pkts_in_queue(k), sender);
                all_queued_pkts_found = false;
                break;
            else
                pkt_e2e_tx_delays = pkt_e2e_tx_delays + tmp(1);
            end
        end
        if ~all_queued_pkts_found
            break;
        end
    end
    
    % append into the bucket only all queued pkts tx delay found
    if all_queued_pkts_found
        e2e_queue_level_tx_delays{IX} = [e2e_queue_level_tx_delays{IX} ; pkt_e2e_tx_delays];
    else
        fprintf('err: some queued pkt for src pkt %d not found\n', seqnos(i));
    end
end
% pkts are group by queue level at each hop; e2e_queue_level_tx_delays
% contains the e2e tx delay for each group
save('e2e_queue_level_tx_delays.mat', 'e2e_queue_level_tx_delays');
%% queueing level experienced by each pkt at each hop
% seqno_hop_queues store queue elements, seqno_hop_queue_levels queue levels
t = seqno_hop_queues;
seqno_hop_queue_levels = zeros(size(t));

for i = 1 : size(t, 1)
    for j = 1 : size(t, 2)
        seqno_hop_queue_levels(i, j) = size(t{i, j}, 1);
    end
end
save('seqno_hop_queue_levels.mat', 'seqno_hop_queue_levels');
%% display
t = seqno_hop_queue_levels;
for i = 1 : size(t, 2)
    figure;
    set(gca, 'FontSize', 30);
    title_str = ['queueing level at hop ' num2str(i)];
    h = plot(t(:, i));
    title(title_str);
    xlabel('packet seq#');
    ylabel('queueing level');
    saveas(h, title_str, 'fig');
    saveas(h, title_str, 'jpg');
end

figure;
set(gca, 'FontSize', 30);
title_str = ['e2e queueing level'];
h = plot(sum(t, 2));
title(title_str);
xlabel('packet seq#');
ylabel('e2e queueing level');
saveas(h, title_str, 'fig');
saveas(h, title_str, 'jpg');