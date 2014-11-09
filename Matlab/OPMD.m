%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Xiaohui Liu (whulxh@gmail.com)
%   Data: 3/27/2011
%   Function: measure accuracy of OPMD; get a sense, may not agree w/ e2e
%   delay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% senders = [24, 22, 77, 91];
senders = [76];
% sender_delays = zeros(length(senders), 2);
ROOT_ID = 15;
sender_pkt_delays = cell(length(senders), 1);
for j = 1 : length(senders)
SRC_ID = senders(j);
% SRC_ID = 76;

if SRC_ID == ROOT_ID
    continue;
end

NODE_IDX = 2;
SRC_IDX = 3;
SEQ_IDX = 4;
OPMD_BEGIN_IDX = 6;
OPMD_END_IDX = 9;
TX_TIMESTAMP_IDX = 10;  % CTP: 13   tOR:14
RX_TIMESTAMP_IDX = 10;
% src_seq, e2e delay, src
COLUMNS = 7;

% src_seq, tx_time
% if SRC_ID == 91
%     srcs_pkts_from_src = srcPkts(srcPkts(:, NODE_IDX) == SRC_ID, [SEQ_IDX, TX_TIMESTAMP_IDX, OPMD_BEGIN_IDX : OPMD_END_IDX]);
% else
%     srcs_pkts_from_src = intercepts(intercepts(:, NODE_IDX) == SRC_ID, [SEQ_IDX, TX_TIMESTAMP_IDX, OPMD_BEGIN_IDX : OPMD_END_IDX]);
% end
% both generated and forwarded pkts
srcs_pkts_from_src = srcPkts(srcPkts(:, NODE_IDX) == SRC_ID, [SEQ_IDX, TX_TIMESTAMP_IDX, OPMD_BEGIN_IDX : OPMD_END_IDX, SRC_IDX]);
srcs_pkts_from_src = [srcs_pkts_from_src; intercepts(intercepts(:, NODE_IDX) == SRC_ID, [SEQ_IDX, TX_TIMESTAMP_IDX, OPMD_BEGIN_IDX : OPMD_END_IDX, SRC_IDX])];

len = size(srcs_pkts_from_src, 1);
pkt_delays = zeros(len, COLUMNS);
pkt_delays_cnts = 1;
for i = 1 : len
    % find the pkt at dest
    IX = find(destPkts(:, SEQ_IDX) == srcs_pkts_from_src(i, 1) & destPkts(:, SRC_IDX) == srcs_pkts_from_src(i, end), 1);
    if isempty(IX)
        continue;
    end
    tx_time = srcs_pkts_from_src(i, 2);
    rx_time = destPkts(IX, RX_TIMESTAMP_IDX);
    % in case this received pkt is not logged in src
    pkt_delays(pkt_delays_cnts, :) = [srcs_pkts_from_src(i, 1) (rx_time - tx_time) srcs_pkts_from_src(i, [3:6 end])];
    pkt_delays_cnts = pkt_delays_cnts + 1;
end
pkt_delays(pkt_delays_cnts : end, :) = [];
sender_pkt_delays{j} = pkt_delays(:, 2);

p = (232 : 6 : 250) / 256;
% qtl_cnts = length(p) - 1;
qtl_cnts = 4;
% initial sampling pkts
% IS_PKT_CNTS = 300;
% actual_e2e_delay_distribution, OPMD
len = size(pkt_delays, 1);
actual_seq_delay_qtls = zeros(len, qtl_cnts);
OPMDs = zeros(len, qtl_cnts);
OPMD_err_qtls = zeros(len, qtl_cnts);
max_delays = zeros(len, 1);
% step size of 10
idx = 1;
for i = 1 : 1 : len
    % delay distribution up to this seqno
    actual_seq_delay_qtls(idx, :) = quantile(pkt_delays(1 : i, 2), p);
    OPMDs(idx, :) = pkt_delays(i, 3 : 6);
    OPMD = [];
    for k = 1 : qtl_cnts
        OPMD = [OPMD; length(find(pkt_delays(1 : i, 2) <= pkt_delays(i, k + 2))) / i];
    end
    OPMD_err_qtls(idx, :) = OPMD;
    max_delays(idx, :) = max(pkt_delays(1 : i, 2));
    idx = idx + 1;
end
actual_seq_delay_qtls(idx : end, :) = [];
OPMDs(idx : end, :) = [];

POI = 1;
STABLE_IDX = 200;
results = [OPMDs(STABLE_IDX : end, POI) actual_seq_delay_qtls(STABLE_IDX : end, POI) max_delays(STABLE_IDX : end)];
OPMD_errs = results(:, 1) - results(:, 2);
OPMD_relative_errs = OPMD_errs ./ results(:, 2);
MAX_errs = results(:, 3) - results(:, 2);
MAX_relative_errs = MAX_errs ./ results(:, 2);

fprintf('\n%d-th hop %f qtl error: OPMD (%f, %f) vs MAX (%f, %f)\n', j, p(POI), median(OPMD_errs), median(OPMD_relative_errs), ...
         median(MAX_errs), median(MAX_relative_errs));
fprintf('OPMD quantile errors: ');
OPMD_err_qtls(end, :)
end
disp('');
p
%% e2e delay from a source
% senders = [15, 24, 22, 77, 91];
senders = 31;    %1 for NetEye
sender_delays = zeros(length(senders), 2);
sender_pkt_delays = cell(length(senders), 1);
for j = 1 : length(senders)
SRC_ID = senders(j);
% SRC_ID = 76;

ROOT_ID = 15;
if SRC_ID == ROOT_ID
    continue;
end

NODE_IDX = 2;
SRC_IDX = 3;
SEQ_IDX = 4;
OPMD_BEGIN_IDX = 6;
OPMD_END_IDX = 9;
TX_TIMESTAMP_IDX = 10;  % CTP: 13   tOR:14
RX_TIMESTAMP_IDX = 10;
% src_seq, e2e delay
COLUMNS = 2;

% src_seq, tx_time
srcs_pkts_from_src = srcPkts(srcPkts(:, NODE_IDX) == SRC_ID, [SEQ_IDX, TX_TIMESTAMP_IDX, OPMD_BEGIN_IDX : OPMD_END_IDX]);
% src_seq, rx_time
dest_pkts_from_src = destPkts(destPkts(:, SRC_IDX) == SRC_ID, [SEQ_IDX, RX_TIMESTAMP_IDX]);
% may receive duplicates; only consider the first copy
[unique_dest_pkts, m, n] = unique(dest_pkts_from_src(:, 1), 'first');
dest_pkts_from_src = dest_pkts_from_src(m, :);

len = size(dest_pkts_from_src, 1);
pkt_delays = zeros(len, COLUMNS);
pkt_delays_cnts = 1;
for i = 1 : len
    % find the received pkt at src
    if isempty(srcs_pkts_from_src(srcs_pkts_from_src(:, 1) == dest_pkts_from_src(i, 1), 2))
        continue;
    end
    tx_time = srcs_pkts_from_src(srcs_pkts_from_src(:, 1) == dest_pkts_from_src(i, 1), 2);
    rx_time = dest_pkts_from_src(i, 2);
    % in case this received pkt is not logged in src
    pkt_delays(pkt_delays_cnts, :) = [dest_pkts_from_src(i, 1) (rx_time - tx_time)];
    pkt_delays_cnts = pkt_delays_cnts + 1;
end
pkt_delays(pkt_delays_cnts : end, :) = [];
sender_pkt_delays{j} = pkt_delays(:, 2);
figure;
title(num2str(SRC_ID));
plot(pkt_delays(:, 2));
end
save('pkt_delays.mat', 'pkt_delays');
fprintf('median delay %d, 90% delay %d \n', quantile(pkt_delays(:, 2), .5), quantile(pkt_delays(:, 2), .9));
%% compare actual e2e delay w/ OPMD
p = (232 : 6 : 250) / 256;
% qtl_cnts = length(p) - 1;
qtl_cnts = 4;
% initial sampling pkts
% IS_PKT_CNTS = 300;
% actual_e2e_delay_distribution, OPMD
len = size(pkt_delays, 1);
actual_seq_delay_qtls = zeros(len, qtl_cnts);
OPMDs = zeros(len, qtl_cnts);
% step size of 10
idx = 1;
for i = 1 : 1 : len
    % delay distribution up to this seqno
    actual_seq_delay_qtls(idx, :) = quantile(pkt_delays(1 : i, 2), p);
    OPMDs(idx, :) = srcs_pkts_from_src(srcs_pkts_from_src(:, 1) == pkt_delays(i, 1), 3 : 6);
    idx = idx + 1;
end
actual_seq_delay_qtls(idx : end, :) = [];
OPMDs(idx : end, :) = [];
%% disp
STABLE_IDX = 50;
for idx = 1 : qtl_cnts
figure;
hold on;
% idx = 1;
% start from 3 to remove the first invalid OPMD
plot(actual_seq_delay_qtls(STABLE_IDX : end, idx));
h = plot(OPMDs(STABLE_IDX : end, idx));
set(h,'Color','red');
legend('actual delay quantile', 'OPMD estimated quantile');
title([num2str(p(idx)) ' quantile of src ' num2str(SRC_ID)]);
hold off;
end
%% 
% sender_delays(j, :) = [SRC_ID quantile(pkt_delays(:, 2), 0.9)];
% end
% 
% %% 
% % actual per-hop delay
% tmp = [sender_hop_cnts sender_delays];
% tmp = [tmp(:, [1 2 4]) tmp(:, 4) ./ tmp(:, 2)];
% actual_per_hop_delays = tmp(tmp(:, 1) ~= ROOT_ID, 4);
% median(actual_per_hop_delays)

% estimated per-hop delay
% DBG_LINK_DELAY = 3;
% DELAY_SAMPLE_IDX = 14;
% tmp = debugs;
% % tmp = rxs;
% tmp = tmp(tmp(:, DBG_LINK_DELAY) == 3, :);
% median(tmp(:, DELAY_SAMPLE_IDX))