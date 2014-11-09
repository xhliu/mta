%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Xiaohui Liu (whulxh@gmail.com)
%   Date:   2/8/2011
%   Function: compute link PDR (unicast, broadcast) based on raw tx, rx 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% shared variables
INVALID_ETX = 65535;
SEQ_IDX = 4;
%bidirectional
U_ETX_IDS = 15;

PARENT_IDX = 8;
LAST_HOP_IDX = 8;
%% link reliability in single path; only consider link btw child & parent
senders = unique(txs(:, 2), 'rows');
link_pdrs = [];
for i = 1 : length(senders)
    sender = senders(i);
    sender_txs = txs(txs(:, 2) == sender, :);
    parents = unique(sender_txs(:, PARENT_IDX), 'rows');
    % each parent
    for j = 1 : length(parents)
        parent = parents(j);
        link_tx_cnts = length(find(sender_txs(:, PARENT_IDX) == parent));
        link_rx_cnts = length(find(rxs(:, 2) == parent & rxs(:, LAST_HOP_IDX) == sender));
        fprintf('link(%d, %d) receives %d out of %d \n', sender, parent, link_rx_cnts, link_tx_cnts);
        if link_tx_cnts < link_rx_cnts
            disp('log err');
        end
        link_pdrs = [link_pdrs; sender parent link_tx_cnts link_rx_cnts link_rx_cnts/link_tx_cnts];
    end
end

%% broadcast link reliablity
senders = unique(txs(:, 2), 'rows');
% receivers = unique(rxs(:, 2), 'rows');
% receivers(receivers == 15) = [];
% b_link_pdrs = zeros(length(senders), length(receivers));
b_link_pdrs = zeros(length(senders), length(senders));

for i = 1 : length(senders)
    sender = senders(i);
    node_tx_cnts = size(find(txs(:, 2) == sender), 1);
    % neighbors receiving packet from the sender
    node_rxs = rxs(rxs(:, LAST_HOP_IDX) == sender, :);
    
    for j = 1 : length(senders)
        receiver = senders(j);
        if sender == receiver
            continue;
        end
        link_rx_cnts = size(find(node_rxs(:, 2) == receiver), 1);
%         RXs = size(find(rxs(:, 2) == receiver & rxs(:, 10) == sender), 1);
        if node_tx_cnts < link_rx_cnts || node_tx_cnts == 0
            disp('logerr');
        end
        b_link_pdrs(i, j) = link_rx_cnts / node_tx_cnts;
        fprintf('link quality from %d to %d: %d out %d = %f \n', sender, receiver, link_rx_cnts, node_tx_cnts, link_rx_cnts / node_tx_cnts);
    end
end
save('b_link_pdrs.mat', 'b_link_pdrs');

%% unicast bidirectional: two phases: IS + data delivery
% ignore IS
% unicasts = unicasts(unicasts(:, U_ETX_IDS) == INVALID_ETX, :);
U_TX_ID = 1;
U_RX_ID = 2;
U_ACK_ID = 3;
% senders = unique(unicasts(:, 2), 'rows');
% receivers = unique(unicasts(:, 3), 'rows');
% u_link_pdrs = zeros(length(senders), length(receivers));
u_link_pdrs = zeros(length(senders), length(senders));
counts = 0;
for i = 1 : length(senders)
    sender = senders(i);
    node_txs = unicasts(unicasts(:, U_TX_ID) == sender, :);
    for j = 1 : length(senders) 
        receiver = senders(j);
        if sender == receiver
            continue;
        end
%         tx = unicasts(unicasts(:, 2) == sender & unicasts(:, 3) == receiver, :);
        tx = node_txs(node_txs(:, U_RX_ID) == receiver, :);
        total = size(tx, 1);
        success = size(find(tx(:, U_ACK_ID) == 1), 1);
        counts  = counts + total;
        if total == 0
%             fprintf('link (%d, %d) empty \n', SENDER, RECEIVER);
            continue;
        end
        u_link_pdrs(i, j) = success / total;
        fprintf('unicast link quality from %d to %d: %d out %d = %f \n', sender, receiver, success, total, success / total);
    end
end
save('u_link_pdrs.mat', 'u_link_pdrs');
