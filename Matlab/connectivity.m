%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Xiaohui Liu (whulxh@gmail.com)
%   Date:   3/15/2012
%   Function: compute the # of inbound neighbors each node has
%   NetEye: job 8812
%   Indriya: job 20575 (pwr 11); job 20690 (pwr 6)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% random topology in NetEye
COLUMNS = 15;
ROWS = 7;
COLUMN_CNT = 3;
s = zeros(ROWS, COLUMNS);
for i = 1 : COLUMNS
    % randomly select COLUMN_CNT elements at every column
    j = 0;
    while j < COLUMN_CNT
        idx = ceil(rand() * ROWS);
        if s(idx, i) == 0
            s(idx, i) = 1;
            j = j + 1;
        end
    end
end

%% outbound neighbors
TX_FLAG = 0;
RX_FLAG = 1;
LASTHOP_IDX = 10;
t = debugs;
t = t(t(:, 3) == 4, :);
r = t(t(:, 4) == RX_FLAG, :);
t = t(t(:, 4) == TX_FLAG, :);
nodes = unique(t(:, 2));

link_pdr = [];
for i = 1 : length(nodes)
    tx = nodes(i);
    
    tx_cnt = sum(t(:, 2) == tx);
    
    s = r(r(:, LASTHOP_IDX) == tx, :);
    rxs = unique(s(:, 2));
    for j = 1 : length(rxs)
        rx = rxs(j);
        rx_cnt = sum(s(:, 2) == rx);
        link_pdr = [link_pdr; tx rx rx_cnt tx_cnt rx_cnt/tx_cnt];
    end
end

%%
PDR_THRESHOLD = 0.9;
cnts = [];
t = link_pdr;
txs = unique(t(:, 1));
for i = 1 : size(txs, 1)
    tx = txs(i, :);
    cnt = sum(t(:, 1) == tx & t(:, end) >= PDR_THRESHOLD);
    cnts = [cnts; cnt];
end
figure;
[n xout] = hist(cnts);
bar(xout, 100 * n / sum(n));
median(cnts)
