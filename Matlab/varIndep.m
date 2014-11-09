%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Xiaohui Liu
%   6/24/2011
%   updated: 10/17/2011
%   Function: empirically measure Var(sum(X_i)) vs sum(Var(X_i)) to see how
%   uncorrelation helps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% accuracy of estimating var(sum) w/ sum(var)
% note that ultimately only std, not var is used; so error should be
% measured in std
dir = '/home/xiaohui/Dropbox/tOR/figures';
SRC_SEQ_IDX = 4;
LINK_DELAY_IDX = 10;
seqnos = unique(destPkts(:, SRC_SEQ_IDX));
% 1) group based on queueing at each hop
t = seqno_hop_queue_levels;
% t = t(1 : 10, :);
% table: hop queue + frequency count of each hop queue cfg
s = zeros(size(t, 1), 6);
idx = 1;

for i = 1 : size(t, 1)
    fprintf('entry %d\n', i);
    found = false;
    for j = 1 : (idx - 1)
        % look up in the table
        if isempty(find(t(i, :) ~= s(j, 1:5), 1))
            % found; update
            s(j, 6) = s(j, 6) + 1;
            found = true;
            break;
        end
    end
    % not found; add new entry
    if ~found
        s(idx, 1 : 5) = t(i, :);
        s(idx, 6) = 1;
        idx = idx + 1;
    end
end
s(idx : end, :) = [];
% sanity check
if sum(s(:, end)) ~= size(t, 1)
    disp('err');
end

% 2) find frequent hop queues
[a IX] = sort(s(:, end), 'descend');
s = s(IX, :);

% 3) find all pkt times for pkt w/ the specified hop queues
clc;
nodes = [15, 27, 6, 64, 79, 76];
% hop_queue_levels = [0 0 0 0 0; 0 0 35 0 0; 0 0 36 0 0];
HOP_QUEUE_CNTS = 24;
hop_queue_levels = s(1 : HOP_QUEUE_CNTS, 1:5);
% sanity check; pkts meeting all the levels
% identical_seqs = [];
% pkts queued before a newly-arrived packet, excluding itself
t = seqno_hop_queue_levels;
hop_tx_delays = cell(size(hop_queue_levels, 1), 1);
% index for each configuration
idx = ones(size(hop_queue_levels, 1), 1);
for i = 1 : size(hop_queue_levels)
    columns = sum(hop_queue_levels(i, :)) + 5;
    hop_tx_delays{i} = zeros(size(t, 1), columns);
end
    
% each pkt
for i = 1 : size(t, 1)
    fprintf('%d-th pkt\n', i);
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
    
    % tx delay experience by this pkt and all pkts queued prior to it
    pkt_hop_tx_delay = [];
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
%                 pkt_e2e_tx_delays = pkt_e2e_tx_delays + tmp(1);
                pkt_hop_tx_delay = [pkt_hop_tx_delay tmp(1)];
            end
        end
        if ~all_queued_pkts_found
            break;
        end
    end
    
    % append into the bucket only all queued pkts tx delay found
    if all_queued_pkts_found
        %e2e_queue_level_tx_delays{IX} = [e2e_queue_level_tx_delays{IX} ; pkt_e2e_tx_delays];
        hop_tx_delays{IX}(idx(IX), :) = pkt_hop_tx_delay;
        idx(IX) = idx(IX) + 1;
    else
        fprintf('err: some queued pkt for src pkt %d not found\n', seqnos(i));
    end
end

for i = 1 : size(hop_tx_delays, 1)
    hop_tx_delays{i}(idx(i) : end, :) = [];
end

save('hop_tx_delays.mat', 'hop_tx_delays');
%% std estimation error
t = hop_tx_delays;
r = zeros(size(t, 1), 1);
for i = 1 : size(t, 1)
    s = t{i};

    % var of sum
    x = sqrt(var(sum(s, 2)));
    y = sqrt(sum(var(s)));
    
    fprintf('entry %d: %f, %f, %f, %f\n', i, x, y, y - x, (y - x) / x);
    r(i) = (y - x);
end
%
%figure;
% [n xout] = hist(r);
% bar(xout, n / sum(n));
% set(gca, 'FontSize', 30);
% xlabel('Absolute error (ms)');
% % xlim([-0.15 0.15]);
% ylabel('Frequency');
% %
% maximize;
% set(gcf, 'Color', 'white'); % Sets figure background
% cd(dir);
% export_fig 'std_absolute_err' -eps;
% export_fig 'std_absolute_err' -jpg -zbuffer;
% saveas(gcf, 'std_absolute_err.fig');
%% CIs
alphas = [.1; .05; .01];
results = [];
for i = 1 : size(alphas, 1)
    alpha = alphas(i);
    results = [results; mean(r) - std(r) * norminv(1 - alpha / 2) ...
                    mean(r) + std(r) * norminv(1 - alpha / 2)];
end
results
%%
cell_size = size(e2e_queue_level_tx_delays, 1);
varsum_sumvar = zeros(cell_size, 2);
varsum_sumvar_idx = 1;
% only consider bucket w/ sufficient samples
SAMPLE_MIN_SIZE = 400;
for cell_seq = 1 : cell_size
    tx_delays = e2e_queue_level_tx_delays{cell_seq};
    if size(tx_delays, 1) < SAMPLE_MIN_SIZE
        continue;
    end
    % compute Var(sum(X_i))
    t = tx_delays;
    var_sum = var(sum(t, 2));

    % compute sum(Var(X_i))
    sum_var = sum(var(t));
    fprintf('var_sum %f, sum_var %f\n', var_sum, sum_var);
    varsum_sumvar(varsum_sumvar_idx, :) = [var_sum sum_var];
    varsum_sumvar_idx = varsum_sumvar_idx + 1;
end
varsum_sumvar(varsum_sumvar_idx : end, :) = [];
% save('varsum_sumvar.mat', 'varsum_sumvar');
%%
t = varsum_sumvar;
relative_errs = (t(:, 2) - t(:, 1)) ./ t(:, 1);
figure;
set(gca, 'FontSize', 30);
title_str = 'Var of Sum vs Sum of Var';
h = plot(relative_errs);
title(title_str);
xlabel('sample # (e2e queue level inc as x inc)');
ylabel('relative error');
saveas(h, title_str, 'fig');
saveas(h, title_str, 'jpg');