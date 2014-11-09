%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Xiaohui Liu (whulxh@gmail.com)
%   Date:   2/7/2011
%   Updated: 2/16/2011 add unnecessary forwarding. For simplicity, consider only ntw pkt w/o unnecessary
%   Function: analyze duplicate ratio and unnecessary tx
%   NetEye: [Type; NodeID; SourceID/isACK; SeqNum; FC1; FC2; FC3; FC4; FC5;
%   Last_Hop_Sender; Last_Hop_Ntw_Seq; Last_Hop_MAC_Seq; Local_Ntw_Seq; Local_MAC_Seq; Timestamp]
%   Motelab: [Type; NodeID; SourceID/isACK; SeqNum; Last_Hop_Sender; Last_Hop_Ntw_Seq; 
%   Last_Hop_MAC_Seq; Local_Ntw_Seq; Local_MAC_Seq; FC1; FC2; FC3; FC4; FC5; Timestamp]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% shared variables
% OR or pure unicast
isOR = true;
ROOT_ID = 15; % 58 Motelab; 15 NetEye
NODE_ID_IDX = 2;

DELTA_FCS_SIZE = 2;
% Motelab parameters
% FCS_IDX = 10;
% LAST_HOP_IDX = 5;
% % local
% NTW_SEQ_IDX = 8;
% PHY_SEQ_IDX = 9;
% % last hop
% LAST_NTW_SEQ_IDX = 6;
% LAST_PHY_SEQ_IDX = 7;

% NetEye parameters
FCS_IDX = 5;
LAST_HOP_IDX = 10 - DELTA_FCS_SIZE;
% local
NTW_SEQ_IDX = 13 - DELTA_FCS_SIZE;
PHY_SEQ_IDX = 14 - DELTA_FCS_SIZE;
% last hop
LAST_NTW_SEQ_IDX = 11 - DELTA_FCS_SIZE;
LAST_PHY_SEQ_IDX = 12 - DELTA_FCS_SIZE;

% UNICAST_IDX = 15;
GLOBAL_TIME_IDX = 15 - DELTA_FCS_SIZE;
PARENT_IDX = 16 -DELTA_FCS_SIZE;

INVALID_ADDR = 255;
MAX_FCS_SIZE = 5 - DELTA_FCS_SIZE;


NONE_RX_FLAG = 0;
RX_PKT_NO_TX_FLAG = -1;
INVALID_FWD_FLAG = -1;
%% analyze duplicate ratio of received packets, excluding
% packets not destinated to me (overheard unicast or non-FC in OR)
%packet destinated to root
% if isOR
%     root_rxs = rxs(rxs(:, NODE_ID_IDX) == ROOT_ID & rxs(:, UNICAST_IDX) == 1, 3:4);
% else % CTP
%     root_rxs = Packet_Log(Packet_Log(:, 1) == 3, 3:4);
% end
% dup_ratio = size(root_rxs, 1) / size(unique(root_rxs, 'rows'), 1);

%% analyze unnecessary retx & forwarding
clc;
% node_id = 71;
% format [node_id ntw_seq unicast retx_seq tx_cnts is_highest-rank-fc_forwards extra_fwd_copies]
% retx_seq: first received copy,starting from 1; 0 if none receives, -1 if
% err
entry_cnts = 0;
% unne_retxs = [];
unne_retxs = zeros(size(txs, 1), 7);
% timing correct for each ntw pkt?
timings = zeros(size(txs, 1), 2);
timing_cnts = 0;
loss_timelys = zeros(size(txs, 1), 3);
loss_timely_cnts = 0;

rcv_nums = zeros(size(txs, 1), 1);
rcv_nums_cnts = 0;
% node_txs = txs(txs(:, NODE_ID_IDX) == node_id, :);
% ntw_seqs = node_txs(:, NTW_SEQ_IDX);
node_ids = unique(txs(:, 2));
% each node
for k = 1 : length(node_ids)
    node_id = node_ids(k);
    % ignore root
    if node_id == ROOT_ID
        continue;
    end
    fprintf('\nprocessing %d-th node: %d ...........\n', k, node_id);
    node_txs = txs(txs(:, NODE_ID_IDX) == node_id, :);
    % all possible distinct network seq#
    ntw_seqs = unique(node_txs(:, NTW_SEQ_IDX));
    % neighbors who receive from the node
    node_rxs = rxs(rxs(:, LAST_HOP_IDX) == node_id, :);
    % neighbors who forward pkts from the node
    node_fwds = txs(txs(:, LAST_HOP_IDX) == node_id, :);
    % each network layer packet
    for i = 1 : length(ntw_seqs)
        ntw_seq = ntw_seqs(i);
        fprintf('   parsing %d-th packet: (node %d, ntw seq %d) ...........\n', i, node_id, ntw_seq);
        IX = find(node_txs(:, NTW_SEQ_IDX) == ntw_seq);
        phy_seqs = node_txs(IX, PHY_SEQ_IDX);
        tx_cnts = length(IX);
        % find recipients
%         unicast = (node_txs(IX(1), UNICAST_IDX) == 1);
        unicast = (node_txs(IX(1), FCS_IDX) == INVALID_ADDR);
        if (unicast)
            % unicast
            recipients = node_txs(IX(1), PARENT_IDX);
        else
            % OR
            recipients = [];
            for j = 1 : MAX_FCS_SIZE
                fc = node_txs(IX(1), j + FCS_IDX - 1);
                if fc == INVALID_ADDR
                    break;
                end
                recipients = [recipients; fc];
            end
        end

        % each recipient
        min_phy_seq = inf;
        % nodes received this ntw packet from the sender
        node_seq_rxs = node_rxs(node_rxs(:, LAST_NTW_SEQ_IDX) == ntw_seq, :);
        % nodes forwards this ntw pkt from the sender
        node_seq_fwds = node_fwds(node_fwds(:, LAST_NTW_SEQ_IDX) == ntw_seq, :);
        % recipients who actually receive the ntw pkt; ordered by priority
        rx_recipients = [];
        fwd_entry = [INVALID_FWD_FLAG, INVALID_FWD_FLAG];
        
        for j = 1 : length(recipients)
            recipient = recipients(j);
            % not optimized
%             IX = find(rxs(:, NODE_ID_IDX) == recipient & rxs(:, 10) == node_id & rxs(:, LAST_NTW_SEQ_IDX) == ntw_seq);
            % a particular node receives the packet from the sender
            IX = find(node_seq_rxs(:, NODE_ID_IDX) == recipient);
            % not received
            if isempty(IX)
                fprintf('not received by node %d\n', recipient);
                continue;
            end
            rx_recipients = [rx_recipients; recipient];
            % ensure correctness: agree w/ reception
%             if (node_seq_rxs(IX(1), 14) == 0) || (node_seq_rxs(IX(1), 13) ~= unicast)
%                 disp('error');
%             end
            seq = node_seq_rxs(IX(1), LAST_PHY_SEQ_IDX);
            % identify first received copy
            if min_phy_seq > seq
                min_phy_seq = seq;
            end  
        end
        
        % # of FCs receive the packet
        if ~unicast
            rcv_nums_cnts = rcv_nums_cnts + 1;
            rcv_nums(rcv_nums_cnts) = length(rx_recipients);
        end
        if isinf(min_phy_seq)
            fprintf('none receives\n');
%             continue;
            retx_seq = NONE_RX_FLAG;
        else
            % at least one copy received
            % which retx copy first received
            retx_seq = find(phy_seqs == min_phy_seq);
            if isempty(retx_seq)
                fprintf('error 1: receive pkts not sent \n');
    %             continue;
                retx_seq = RX_PKT_NO_TX_FLAG;
            end
            
            % OR only
            if ~unicast
                % check unnecessary forwarding
                len = length(rx_recipients);
                % forward or not
                fwd_bools = zeros(len, 1);
                fwd_times = [];
                for j = 1 : len
                    recipient = rx_recipients(j);
    %                 if isempty(find(txs(:, NODE_ID_IDX) == recipient & txs(:, Last_Hop_Sender) == node_id & txs(:, LAST_NTW_SEQ_IDX) == ntw_seq))
                    node_seq_fwd = node_seq_fwds(node_seq_fwds(:, NODE_ID_IDX) == recipient, :);
                    if isempty(node_seq_fwd)
                        fwd_bools(j) = 0;
                    else
                        % forwarded
                        fwd_bools(j) = 1;
                        fwd_times = [fwd_times; node_seq_fwd(1, GLOBAL_TIME_IDX)];
                    end
                end
                fwd_entry = [fwd_bools(1), sum(fwd_bools) - fwd_bools(1)];
                
                % duplicate forwarding causes
%                 if (sum(fwd_bools) == 2)
                
                    timing_correct = 1;
                    diff = -1;
                    for j = 1 : (length(fwd_times) - 1)
                        if (fwd_times(j) >= fwd_times(j + 1))
                            timing_correct = 0;
                            break;
                        else
                            % for simplicity; consider FCS size 2 only
                            if diff == -1
                                diff = fwd_times(j + 1) - fwd_times(j);
                            end
                        end
                    end
                    timing_cnts = timing_cnts + 1;
                    timings(timing_cnts, :) = [timing_correct, diff];
                    
                % ??consider a simple case??
                if length(rx_recipients) == 2
                    fwd_hear_fwd_timely = zeros(3, 1);
                    % distinguish coordination ack loss & lateness; only
                    % data suppress
%                     fc_idx = find(fwd_bools == 1);
%                     hi_fc = rx_recipients(fc_idx(1));
%                     lo_fc = rx_recipients(fc_idx(2));
                    % if hi forwards
                    %   if lo hears from hi
                    %       if lo forwards (late)
                    %
                    hi_fc = rx_recipients(1);
                    lo_fc = rx_recipients(2);
                    hi_fwd = node_seq_fwds(node_seq_fwds(:, NODE_ID_IDX) == hi_fc, :);
                    if isempty(hi_fwd)
                        fwd_hear_fwd_timely(1) = 0;
                    else
                        fwd_hear_fwd_timely(1) = 1;                    
                        hi_fwd_ntw_seq = hi_fwd(1, NTW_SEQ_IDX);
                        lo_rx_idx = find(rxs(:, 2) == lo_fc & rxs(:, LAST_HOP_IDX) == hi_fc & rxs(:, LAST_NTW_SEQ_IDX) == hi_fwd_ntw_seq);

    %                     loss_timely = [];
                        if isempty(lo_rx_idx)
                            %loss
                           %loss_timely = [1 0];
                           fwd_hear_fwd_timely(2) = 0;
                        else
                            %receive
                            fwd_hear_fwd_timely(2) = 1;
                            lo_rx_time = rxs(lo_rx_idx(1), GLOBAL_TIME_IDX);
                            IX = find(node_seq_fwds(:, NODE_ID_IDX) == lo_fc);

                            if isempty(IX)
                                fwd_hear_fwd_timely(3) = 0;
                            else
                                fwd_hear_fwd_timely(3) = 1;
%                                 lo_fwd_time = node_seq_fwds(IX(1), GLOBAL_TIME_IDX);
%         %                         loss_timely = [0, lo_fwd_time - lo_rx_time];
%                                 if (lo_fwd_time < lo_rx_time)
%                                     fwd_hear_fwd_timely(4) = 0;
%                                 else
%                                     fwd_hear_fwd_timely(4) = 1;
%                                 end
                            end
                        end
                    end
                    loss_timely_cnts = loss_timely_cnts + 1;
%                     loss_timelys(loss_timely_cnts, :) = loss_timely;
                    loss_timelys(loss_timely_cnts, :) = fwd_hear_fwd_timely;
                    
                end
            end
        end
        
        %
        fprintf('%d-th copy first received out of %d copies tx \n', retx_seq, tx_cnts);
%         unne_retxs = [unne_retxs; [node_id ntw_seq unicast retx_seq tx_cnts is_highest-rank-fc_forwards extra_fwd_copies]];
        entry_cnts = entry_cnts + 1;
        unne_retxs(entry_cnts, :) = [node_id ntw_seq unicast retx_seq tx_cnts fwd_entry];
    end
end
% validation
unique_node_ntw_seqs = size(unique(txs(txs(:, 2) ~= ROOT_ID, [NODE_ID_IDX, NTW_SEQ_IDX]), 'rows'), 1);
if entry_cnts ~= unique_node_ntw_seqs
    disp('error 2: these two should match');
end
% remove the remaining part
unne_retxs((entry_cnts + 1) : end, :) = [];
timings((timing_cnts + 1) : end, :) = [];
loss_timelys((loss_timely_cnts + 1) : end, :) = [];
rcv_nums((rcv_nums_cnts + 1) : end, :) = [];
save('unne_retxs.mat', 'unne_retxs');
save('timings.mat', 'timings');
save('loss_timelys.mat', 'loss_timelys');
save('rcv_nums.mat', 'rcv_nums');
%% display the result
% tmp = timings(timings(:, 1) == 1 & timings(:, 2) ~= -1, 2);
% tmp = timings(:, 1);
%% unneceessary forwarding of OR
% only consider ntw pkt w/o unnecessary retx
length(unne_retxs(:, 3) == 0 & unne_retxs(:, 4) == unne_retxs(:, 5)) / length(unne_retxs(:, 3) == 0)
fwd_entries = unne_retxs(unne_retxs(:, 3) == 0 & unne_retxs(:, 4) == unne_retxs(:, 5), :);
len = size(fwd_entries, 1);
% validation
if ~isempty(find((fwd_entries(:, 6) == INVALID_FWD_FLAG & fwd_entries(:, 7) ~= INVALID_FWD_FLAG) ...
                   | (fwd_entries(:, 6) ~= INVALID_FWD_FLAG & fwd_entries(:, 7) == INVALID_FWD_FLAG), 1))
    disp('error: should be both or neither');
end

% ratio of various cases
fprintf('none FC received: %f\n', length(find(fwd_entries(:, 6) == INVALID_FWD_FLAG & fwd_entries(:, 7) == INVALID_FWD_FLAG)) / len);
fprintf('none recipient forwards: %f\n', length(find(fwd_entries(:, 6) == 0 & fwd_entries(:, 7) == 0)) / len);

fprintf('legal forwarding: %f\n', length(find(fwd_entries(:, 6) == 1 & fwd_entries(:, 7) == 0)) / len);
%unne_fwd_0 = fwd_entries(fwd_entries(:, 6) == 1 & fwd_entries(:, 7) > 0, 7);
unne_fwd_0 = fwd_entries((fwd_entries(:, 6) + fwd_entries(:, 7)) >= 2, 6 : 7);
fprintf('duplicate: %f\n', size(unne_fwd_0, 1) / len);
figure;
[n, nout] = hist(unne_fwd_0(:, 1) + unne_fwd_0(:, 2));
bar(nout, n / sum(n));

unne_fwd_1 = fwd_entries(fwd_entries(:, 6) == 0 & fwd_entries(:, 7) == 1, 7);
fprintf('no duplicate but priority inversion:%f\n', length(unne_fwd_1) / len);
% figure;
% [n, nout] = hist(unne_fwd_1);
% bar(nout, n / sum(n));

%% unneceessary forwarding cause 1: coordination ack loss
% coordination ack reliablity: based on outgoing link reliablity
INVALID_ADDR = 255;
ROOT_ID = 15;
UNICAST_IDX = 15;

% b_tx = txs(txs(:, 2) ~= ROOT_ID & txs(:, UNICAST_IDX) == 0, :);
b_tx = txs(txs(:, 2) ~= ROOT_ID & txs(:, FCS_IDX) ~= INVALID_ADDR, :);
% sanity check
if ~isempty(find(b_tx(:, FCS_IDX + 1) == INVALID_ADDR, 1))
    disp('error: FCS size 1');
end
len = size(b_tx, 1);
FCS = [];
co_ack_reli = [];
for i = 1 : len
    tmp = b_tx(i, 5:9);
    fcs = tmp(tmp ~= INVALID_ADDR);
    FCS = [FCS; tmp];
    
    fcs_len = length(fcs);
    for j = 1 : (fcs_len - 1)
        for k = (j + 1) : fcs_len
            s = fcs(j);
            t = fcs(k);
            s_idx = find(senders == s);
            t_idx = find(senders == t);
            co_ack_reli = [co_ack_reli; s t b_link_pdrs(s_idx, t_idx)];
        end
    end
end
figure;
[n, xout] = hist(co_ack_reli(:, 3));
bar(xout, n / sum(n));

%% unneceessary forwarding cause 2: timing, lower priority FC tx before
%% higher ones
% check frequency of 2 FCs receive only first
figure;
[n, xout] = hist(rcv_nums);
bar(xout, n / sum(n));
% for two FCs receive only
tmp = loss_timelys;
len = size(tmp, 1);
fprintf('FC1 not forward: %f\n', length(find(tmp(:, 1) == 0)) / len);

tmp = tmp(tmp(:, 1) == 1, :);
len = size(tmp, 1);
fprintf('FC2 not hear FC1: %f\n', length(find(tmp(:, 2) == 0)) / len);

tmp = tmp(tmp(:, 2) == 1, :);
len = size(tmp, 1);
fprintf('FC2 not forward (timely suppression): %f\n', length(find(tmp(:, 3) == 0)) / len);

%% unnecessary retx
fprintf('error 1 ratio: %f\n', length(find(unne_retxs(:, 4) == RX_PKT_NO_TX_FLAG)) / entry_cnts);
fprintf('none reception ratio: %f\n', length(find(unne_retxs(:, 4) == NONE_RX_FLAG)) / entry_cnts);

% unnecessary retx is based on at least one reception
total_tx_cnts = length(find(txs(:, 2) ~= ROOT_ID));
tmp = unne_retxs(unne_retxs(:, 4) > 0, :);
fprintf('unnecessary retx (%d out of %d tx) ratio: %f\n', sum(tmp(:, 5) - tmp(:, 4)), ...
            total_tx_cnts, sum(tmp(:, 5) - tmp(:, 4)) / total_tx_cnts);

%further distinguish unicast vs OR
% total_tx_cnts = length(find(txs(:, 2) ~= ROOT_ID & txs(:, UNICAST_IDX) == 0));
total_tx_cnts = length(find(txs(:, 2) ~= ROOT_ID & txs(:, FCS_IDX) ~= INVALID_ADDR));

tmp = unne_retxs(unne_retxs(:, 4) > 0 & unne_retxs(:, 3) == 0, :);
fprintf('unnecessary retx (%d out of %d tx) ratio: %f\n', sum(tmp(:, 5) - tmp(:, 4)), ...
            total_tx_cnts, sum(tmp(:, 5) - tmp(:, 4)) / total_tx_cnts);
fprintf('OR packet w/o unnecessary retx ratio: %f \n', ...
            length(find(tmp(:, 4) == tmp(:, 5))) / size(tmp, 1));
tmp = tmp(:, 5) - tmp(:, 4);
figure;
[n, xout] = hist(tmp);
bar(xout, n / sum(n));

% total_tx_cnts = length(find(txs(:, 2) ~= ROOT_ID & txs(:, UNICAST_IDX) == 1));
total_tx_cnts = length(find(txs(:, 2) ~= ROOT_ID & txs(:, FCS_IDX) == INVALID_ADDR));

tmp = unne_retxs(unne_retxs(:, 4) > 0 & unne_retxs(:, 3) == 1, :);
fprintf('unnecessary retx (%d out of %d tx) ratio: %f\n', sum(tmp(:, 5) - tmp(:, 4)), ...
            total_tx_cnts, sum(tmp(:, 5) - tmp(:, 4)) / total_tx_cnts);
fprintf('unicast packet w/o unnecessary retx ratio: %f \n', ...
            length(find(tmp(:, 4) == tmp(:, 5))) / size(tmp, 1));
tmp = tmp(:, 5) - tmp(:, 4);
figure;
[n, xout] = hist(tmp);
bar(xout, n / sum(n));
% clear;

%% convergence of OR retx timeout estimation
% hourly_cnts = 180;
% hours = 2;
% OR_txs = txs(txs(:, 2) ~= ROOT_ID & txs(:, UNICAST_IDX) == 0, :);
% OR_unne_retxs = unne_retxs(unne_retxs(:, 4) > 0 & unne_retxs(:, 3) == 0, :);
% result = zeros(hours, 2);
% for i = 1 : hours
%     fprintf('processing hour %d ....\n\n', i);
%     min_seq = (i - 1) * hourly_cnts;
%     max_seq = i * hourly_cnts;
%     total_tx_cnts = length(find(OR_txs(:, NTW_SEQ_IDX) >= min_seq & OR_txs(:, NTW_SEQ_IDX) < max_seq));
%     tmp = OR_unne_retxs(OR_unne_retxs(:, 2) >= min_seq & OR_unne_retxs(:, 2) < max_seq, :);
%     fprintf('unnecessary retx (%d out of %d tx) ratio: %f\n', sum(tmp(:, 5) - tmp(:, 4)), ...
%                 total_tx_cnts, sum(tmp(:, 5) - tmp(:, 4)) / total_tx_cnts);
%     fprintf('OR packet w/o unnecessary retx ratio: %f \n', ...
%             length(find(tmp(:, 4) == tmp(:, 5))) / size(tmp, 1));
%     result(i, :) = [sum(tmp(:, 5) - tmp(:, 4)) / total_tx_cnts ...
%             length(find(tmp(:, 4) == tmp(:, 5))) / size(tmp, 1)];
% end
% 
% plot(result);