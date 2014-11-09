%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Xiaohui Liu (whulxh@gmail.com)
%   Date:   2/8/2011
%   Function: disect tx cost
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% tx cost vs 'time': consider stable region
ROOT_ID = 15; %58 Motelab; 15 NetEye
FCS_IDX = 5;
INVALID_ADDR = 255;

% data tx period at sources
period = 10;
time_unit = 900;    %1800
hourly_cnts = time_unit / period;
tx = txs(:, 4);
plot(tx);
tx = tx(tx < 2000);
max_seqno = max(tx);
len = ceil(max_seqno / hourly_cnts);
hour_entries = zeros(len, 5);
for i = 1 : len
    fprintf('processing hour %d ....\n', i);
    min_seq = (i - 1) * hourly_cnts;
    max_seq = i * hourly_cnts;
    txs_ = txs(txs(:, 4) >= min_seq & txs(:, 4) < max_seq, :);
    rxs_ = rxs(rxs(:, 4) >= min_seq & rxs(:, 4) < max_seq, :);

    nonroot_txs = txs_(txs_(:, 2) ~= ROOT_ID, :);
    unique_txs = unique(nonroot_txs(:, 3:4), 'rows');
    sendCounts = size(unique_txs, 1);

    unique_rxs = unique(rxs_(rxs_(:, 2) == ROOT_ID, 3:4), 'rows');
    rcvCounts = size(unique_rxs, 1);
    % [time, tx count, tx cost, reliability, OR percentage]
    hour_entries(i, :) = [i, sendCounts, size(nonroot_txs, 1) / rcvCounts, rcvCounts / sendCounts ...
                            length(find(nonroot_txs(:, FCS_IDX) ~= INVALID_ADDR)) / size(nonroot_txs, 1)]; 
end
figure('name', 'Tx cost vs Time');
plot(hour_entries(:, 3));
set(gca, 'FontSize', 30, 'YGrid', 'on');
% maximize(gcf);
xlabel(['Time (unit ' num2str(time_unit) ' s)']);
ylabel('Tx cost');
saveas(gcf, 'TxCost_Time.fig');
save('tx_cost_time.mat', 'hour_entries');
%% compare tx cost of unicast pkts vs OR pkts per src
% variable
% txs = txs(txs(:, 4) > 180, :);
% ROOT_ID = 58;
% remove txs of root since it broadcasts packets w/ (src, seq) intact even
% though FCS is invalid
txs = txs(txs(:, 2) ~= ROOT_ID, :);
sources = unique(txs(:, 3));
len = length(sources);
COLUMNS = 7;
src_u_b_cost = zeros(len, COLUMNS);
% application reception
% root_rxs = rxs(rxs(:, 2) == ROOT_ID & rxs(:, end - 2) == 1 & rxs(:, end) == 0, :);
root_rxs = rxs(rxs(:, 2) == ROOT_ID, :);
for i = 1 : len
    % each source
    src = sources(i);
    fprintf('processing %d \n', src);
    % source generates pkts
    src_txs = txs(txs(:, 2) == src & txs(:, 3) == src, :);
    % tx of pkts from this source
    node_txs = txs(txs(:, 3) == src, :);
    % root reception of pkts from this source
    node_root_rxs = root_rxs(root_rxs(:, 3) == src, :);
    % unicast & broadcast pkts
%     u_pkt_seqs = unique(src_txs(src_txs(:, end) ~= INVALID_ADDR, 4));
%     u_pkt_seqs = unique(src_txs(src_txs(:, end) == ROOT_ID, 4));
%     b_pkt_seqs = unique(src_txs(src_txs(:, end) == INVALID_ADDR, 4));
    pkt_seqs = unique(src_txs(:, 4));
    u_pkt_seqs = [];
    for j = 1 : length(pkt_seqs)
        pkt_seq = pkt_seqs(j);
        % never OR
        if isempty(find(node_txs(:, 4) == pkt_seq & node_txs(:, end) == INVALID_ADDR, 1))
            u_pkt_seqs = [u_pkt_seqs; pkt_seq];
        end
    end
    % rest are pkts sent by OR only or hybrid (OR + unicast)
    b_pkt_seqs = setdiff(pkt_seqs, u_pkt_seqs, 'rows');
%     if isempty(u_pkt_seqs)
%         continue;
%     end
    
    
    u_tx_cnts = 0;
    u_rx_cnts = 0;
    for j = 1 : length(u_pkt_seqs)
        seq = u_pkt_seqs(j);
        u_tx_cnts = u_tx_cnts + length(find(node_txs(:, 4) == seq));
        if ~isempty(find(node_root_rxs(:, 4) == seq, 1))
            u_rx_cnts = u_rx_cnts + 1;
        end
    end
    
    b_tx_cnts = 0;
    b_rx_cnts = 0;
    for j = 1 : length(b_pkt_seqs)
        seq = b_pkt_seqs(j);
        b_tx_cnts = b_tx_cnts + length(find(node_txs(:, 4) == seq));
        if ~isempty(find(node_root_rxs(:, 4) == seq, 1))
            b_rx_cnts = b_rx_cnts + 1;
        end
    end
    % [src, gen pkt #, OR ratio, unicast pkt reliability, unicast pkt tx
    % cost, OR pkt reliability, OR pkts tx cost];
    total_pkt_cnts = length(u_pkt_seqs) + length(b_pkt_seqs);
    
%     src_u_b_cost(i, :) = [src, total_tx_cnts, b_tx_cnts / total_tx_cnts, u_tx_cnts / length(u_pkt_seqs), b_tx_cnts / length(b_pkt_seqs)];
    src_u_b_cost(i, :) = [src, total_pkt_cnts, length(b_pkt_seqs) / total_pkt_cnts, u_rx_cnts / length(u_pkt_seqs), ...
                          u_tx_cnts / u_rx_cnts, b_rx_cnts / length(b_pkt_seqs), b_tx_cnts / b_rx_cnts];
end
% src_u_b_cost(src_u_b_cost(:, 1) == 0, :) = [];
save('src_u_b_cost.mat', 'src_u_b_cost');
% compare; only for nodes using both unicast and OR
% tmp = src_u_b_cost((src_u_b_cost(:, 3) ~= 0) & (src_u_b_cost(:, 3) ~= 1), :);
% fprintf('OR is better in %f of all sources \n', length(find(tmp(:, 5) > tmp(:, 7))) / size(tmp, 1));
% figure;
% bar(tmp(:, [5 7 9]))

% sanity check
nonroot_txs = txs(txs(:, 2) ~= ROOT_ID, :);
unique_txs = unique(nonroot_txs(:, 3:4), 'rows');
sendCounts = size(unique_txs, 1);
if sum(src_u_b_cost(:, 2)) ~= sendCounts
    disp('error');
end

%% tx cost per source and tx cost vs distance
COLUMNS = 15;
sources = unique(txs(:, 3));
len = length(sources);
tx_cost_dist = zeros(len, 6);
for i = 1 : len
    source = sources(i);
    src_txs = txs(txs(:, 3) == source, :);
    src_rxs = rxs(rxs(:, 3) == source, :);
    
    nonroot_txs = src_txs(src_txs(:, 2) ~= ROOT_ID, :);
    unique_txs = unique(nonroot_txs(:, 3:4), 'rows');
    sendCounts = size(unique_txs, 1);

    unique_rxs = unique(src_rxs(src_rxs(:, 2) == ROOT_ID, 3:4), 'rows');
    rcvCounts = size(unique_rxs, 1);
    % [source, distance, tx count, tx cost, reliability, OR percentage]
    tx_cost_dist(i, :) = [source, floor(distance(source, ROOT_ID, COLUMNS)), sendCounts, ...
                            size(nonroot_txs, 1) / rcvCounts, rcvCounts / sendCounts ...
                            length(find(nonroot_txs(:, UNICAST_IDX) == 0)) / size(nonroot_txs, 1)]; 
                        
end

% present
% figure('name', 'Tx cost vs Distance');
% boxplot(tx_cost_dist(:, 4), tx_cost_dist(:, 2));
% set(gca, 'FontSize', 30, 'YGrid', 'on');
% % maximize(gcf);
% xlabel('Distance (grid unit)');
% ylabel('Tx cost');
% saveas(gcf, 'TxCost_Distance.fig');

figure('name', 'Tx cost vs Source');
bar(tx_cost_dist(:, 1), tx_cost_dist(:, 4));
set(gca, 'FontSize', 30, 'YGrid', 'on');
% maximize(gcf);
xlabel('Source ID');
ylabel('Tx cost');
saveas(gcf, 'TxCost_Src.fig');
