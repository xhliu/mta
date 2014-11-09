%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Xiaohui Liu
%   6/8/2011
%   Function: test MAC delay independence for various links
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% QUEUE_DELAY_IDX = 9;
SRC_IDX = 3;
SRC_SEQ_IDX = 4;
LINK_DELAY_IDX = 10;
% tmp = srcPkts(:, [2 4 10]);
% tmp = [tmp; intercepts(:, [2 4 10])];
% tmp = [tmp; destPkts(:, [2 4 10])];
% % choose buck pkts using the same path
% tmp = tmp(tmp(:, 2) <= 3500, :);
% node_seqno_timestamp = tmp;
% save('node_seqno_timestamp.mat', 'node_seqno_timestamp');
%% consider one specific path only
% t = node_seqno_timestamp;
% seqnos = t(t(:, 1) == 15, 2);
% seqnos = src_seqs(400 : 2300, :);
t = destPkts;
seqnos = unique(t(t(:, 2) == 15, SRC_SEQ_IDX));
len = length(seqnos);
% t = zeros(len, 1);
% for i = 1 : len
%     % only consider pkts not experiencing queueing
%     if isempty(find(txs(:, 4) == seqnos(i) & txs(:, 5) > 0, 1))
%         t(i) = seqnos(i);
%     end
% end
% seqnos = t(t ~= 0);

nodes = [15, 27, 6, 64, 79, 76];
len = length(seqnos);
link_delays = zeros(len, length(nodes) - 1);
% queueing_delays = zeros(len, length(nodes) - 1);

% find pkts that share the path
clc;
for i = 1 : len
    seqno = seqnos(i);    
    for j = 1 : (length(nodes) - 1)
        sender = nodes(j + 1);
%         receiver = nodes(j);

%         tx_time = t(t(:, 1) == sender & t(:, 2) == seqno, 3);
%         rx_time = t(t(:, 1) == receiver & t(:, 2) == seqno, 3);
%         if isempty(tx_time) || isempty(rx_time)
%             fprintf('tx rx log err for pkt %d\n', seqno);
%             continue;
%         end
%         link_delays(i, j) = rx_time(1) - tx_time(1);
        IX = find(txs(:, 2) == sender & txs(:, SRC_SEQ_IDX) == seqno);
        if isempty(IX)
            fprintf('log err for pkt %d @ node %d\n', seqno, sender);
            continue;
        end
        % i-th packet, j-th hop
        link_delays(i, j) = txs(IX(1), LINK_DELAY_IDX);
%         queueing_delays(i, j) = txs(IX(1), QUEUE_DELAY_IDX);
    end
end
% exclude queueing delay
% save('link_queueing_delays.mat', 'link_delays', 'queueing_delays');
tx_delays = link_delays;
save('tx_delays.mat', 'tx_delays');
%%
% link_delays = link_delays - queueing_delays;
% % MAX_ROWS = 1000;
% % link_delays = link_delays(1 : MAX_ROWS, :);
% fprintf('timestamp error: %f\n', length(find(txs(:, 10) == hex2dec('FFFFFFFF'))) / size(txs, 1));
% fprintf('error (queueing delay > link delay) ratio: %f\n', ...
%         length(find(link_delays < 0)) / (size(link_delays, 1) * size(link_delays, 2)));
    %% correlation
% r = corrcoef(link_delays);
% LINK_DELAYS = sort(link_delays);
% R = corrcoef(LINK_DELAYS);

%% inter-link: independence test
% clc;
% hsic test
hsic_params = struct('sigx', -1, 'sigy', -1);
% L1 and likelihood ratio test
params = struct('q', 4);
alpha = 0.001;
%% inter-link1: assume all packets traverse all links
for i = 1 : (len - 1)
    X = link_delays(:, i);
    
    for j = (i + 1) : len
        fprintf('processing link %d and %d\n', i, j);
        str = [int2str(i) int2str(j)];
        Y = link_delays(:, j);
%         figure;
%         title(str);
%         qqplot(X, Y);
%         saveas(gcf, str, 'fig');
%         saveas(gcf, str, 'jpg');
%         
        % independence test
        [threshold testStat] = hsicTestGamma(X, Y, alpha, params);
        if testStat > threshold
            link_independence(i, j) = false;
        else
            link_independence(i, j) = true;
        end
    %     x = sort(X);
    %     y = sort(Y);
    %     figure;
    %     plot(x, y, '.');
    %     R = corrcoef(X, Y);
    %     R = R(1, 2);
    %     r = corrcoef(x, y);
    %     r = r(1, 2);
        % r is correlation coefficient; r ^ 2 happens to be coefficient of
        % determination in simple linear regression
%         fprintf('link (%d, %d, %d) delay corrcoef %f, delay quantile corrcoef/cod %f/%f\n', ...
%             nodes(i + 2), nodes(i + 1), nodes(i), R, r, r ^ 2);
    end
end
% dependence quantification
r = corrcoef(link_delays);
save(['link_independence_' num2str(alpha) '.mat'], 'link_independence', 'r');
r
link_independence

%% pairwise independence test 2: where many pkts fail to traverse the path
% nodes = [15, 41, 65, 79, 76];
nodes = [27, 6, 64, 79, 76];
% max queue level in experiments, determing the largest offset; this offset is to pair seq x @ sender w/
% seq (x - offset) at receiver
MAX_SEQ_OFFSET = 7;
t = txs;
t = t(t(:, SRC_IDX) == nodes(end), :);
len = size(nodes, 1);
% [link #; offset]
link_independence = repmat(NaN, len * (len - 1) / 2, MAX_SEQ_OFFSET + 1);
link_corrcoef = repmat(NaN, len * (len - 1) / 2, MAX_SEQ_OFFSET + 1);

for n = 1 : (MAX_SEQ_OFFSET + 1)
    SEQ_OFFSET = n - 1;
    fprintf('\n\nseq offset of %d\n', SEQ_OFFSET);
    link_seq = 1;
    
    for i = 2 : length(nodes)
        sender = nodes(i);

        for j = 1 : (i - 1)
            receiver = nodes(j);
            % obtain sample pair
            seqs = unique(t(t(:, 2) == sender, SRC_SEQ_IDX));
            len = length(seqs);
            X = zeros(len - SEQ_OFFSET, 1);
            Y = zeros(len - SEQ_OFFSET, 1);
            % some seqs @ sender are missing @ receiver
            X_Y_idx = 1;
            for k = (1 + SEQ_OFFSET) : len
                seq = seqs(k);
                % assume no dup for now
                tmp = t(t(:, 2) == sender & t(:, SRC_SEQ_IDX) == seq, LINK_DELAY_IDX);
                X(X_Y_idx) = tmp(1);
                tmp = t(t(:, 2) == receiver & t(:, SRC_SEQ_IDX) == seq - SEQ_OFFSET, LINK_DELAY_IDX);
                if ~isempty(tmp)
                    Y(X_Y_idx) = tmp(1);
                    X_Y_idx = X_Y_idx + 1;
                end
            end
            X(X_Y_idx : end, :) = [];
            Y(X_Y_idx : end, :) = [];
            
            % independence test; independent if any test indicates independence
            indep = false;
            [threshold testStat] = GreGyoL1Test(X, Y, alpha, params);
            if testStat <= threshold
                indep = true;
            else
                [threshold testStat] = likeRatioTest(X, Y, alpha, params);
                if testStat <= threshold
                    indep = true;
                else
                    [threshold testStat] = hsicTestGamma(X, Y, alpha, hsic_params);
                    if testStat <= threshold
                        indep = true;
                    end
                end
            end
            link_independence(link_seq, n) = indep;

            corr_ = corrcoef(X, Y);
            corr_ = corr_(2, 1);
            link_corrcoef(link_seq, n) = corr_;
            link_seq = link_seq + 1;
        
            if indep
                fprintf('link (%d, %d) independent, corrcoef %f\n', sender, receiver, corr_);
            else
                fprintf('link (%d, %d)  dependent, corrcoef %f\n', sender, receiver, corr_);
            end
        end
    end
end
save('link_dependence.mat', 'link_independence', 'link_corrcoef');
%%
for i = 1 : size(link_corrcoef, 1)
    figure;
    h = plot(link_corrcoef(i, :));
    set(gca, 'FontSize', 30);
    title_str = ['cross-link ' num2str(i) ' corrcoef vs shift'];
    title(title_str);
    hold on;
    saveas(h, title_str, 'fig');
    saveas(h, title_str, 'jpg');
end
%% intra-link: time series correlation
LAG_CNTS = 100;
for i = 1 : size(link_delays, 2)
    X = link_delays(:, i);
    % autocorrelation
    [lags ACF] = autocorr(X, LAG_CNTS);
    figure;
    % excluding lag 0
    h = plot(ACF(2 : end), lags(2 : end));
    set(gca, 'FontSize', 30);
    title_str = ['link ' num2str(i) ' delay autocorrelation vs lags'];
    title(title_str);
    hold on;
    saveas(h, title_str, 'fig');
    saveas(h, title_str, 'jpg');
end

%% joint/mutual independence
t = tx_delays;
len = size(t, 1);
unique_col_1 = unique(t(:, 1));
len_1 = length(unique_col_1);
unique_col_2 = unique(t(:, 2));
len_2 = length(unique_col_2);
unique_col_3 = unique(t(:, 3));
len_3 = length(unique_col_3);
unique_col_4 = unique(t(:, 4));
len_4 = length(unique_col_4);
unique_col_5 = unique(t(:, 5));
len_5 = length(unique_col_5);

% joint_CDF = zeros(len_1, len_2, len_3, len_4, len_5);
% produce of marginal CDFs
% product_CDF = zeros(len_1, len_2, len_3, len_4, len_5);
% diff = zeros(len_1 * len_2 * len_3 * len_4);
EWMA_RATIO = 0.1;
max_diff = 0;
diff_var = 0;
diff_mean = 0;
diff_idx = 1;
% compute
for i1 = 1 : len_1
    fprintf('processing entry %d\n', i1);
    IX_1 = t(:, 1) <= unique_col_1(i1);
    CDF_1 = length(find(IX_1)) / len;
    
    for i2 = 1 : len_2
        IX_2 = t(:, 2) <= unique_col_2(i2);
        CDF_2 = length(find(IX_2)) / len;
        
        for i3 = 1 : len_3
            IX_3 = t(:, 3) <= unique_col_3(i3);
            CDF_3 = length(find(t(:, 3) <= unique_col_3(i3))) / len;
            
            for i4 = 1 : len_4
                IX_4 = t(:, 4) <= unique_col_4(i4);
                CDF_4 = length(find(t(:, 4) <= unique_col_4(i4))) / len;
                
                for i5 = 1 : len_5
                    IX_5 = t(:, 5) <= unique_col_5(i5);
                    CDF_5 = length(find(t(:, 5) <= unique_col_5(i5))) / len;           
                    product_CDF = CDF_1 * CDF_2 * CDF_3 * CDF_4 * CDF_5;

                    joint_CDF = length(find(t(:, 1) <= unique_col_1(i1) & ...
                        t(:, 2) <= unique_col_2(i2) & t(:, 3) <= unique_col_3(i3) & ...
                        t(:, 4) <= unique_col_4(i4) & t(:, 5) <= unique_col_5(i5))) / len;

%                     diff(diff_idx) = joint_CDF - product_CDF;
                    diff = abs(joint_CDF - product_CDF);
                    diff_var = diff_var * (1 - EWMA_RATIO) + abs(diff - diff_mean) * EWMA_RATIO;
                    diff_mean = diff_mean * (1 - EWMA_RATIO) + diff * EWMA_RATIO;
                    
                    if max_diff < diff
                        max_diff = diff;
                    end
%                     diff_idx = diff_idx + 1;
                end
            end
        end
    end
end
% diff(diff_idx : end, :) = [];
% diff_matrix = product_CDF - joint_CDF;
% fprintf('max CDF difference is %f (i.e., %f)\n',
% max(max(max(abs(diff_matrix)))), max(abs(diff)));
fprintf('CDF difference: max %f, mean %f, var %f\n', max_diff, diff_mean, diff_var);
%%
% save('joint_indep_diff.mat', 'diff', 'diff_matrix');
figure;
figure_title = 'joint CDF vs CDF product cdfplot';
h = cdfplot(diff);
title(figure_title);
saveas(h, figure_title, 'fig');
saveas(h, figure_title, 'jpg');

%% 
DBG_FLAG = 14;
t = debugs;
t = t(t(:, 3) == DBG_FLAG, :);
u_links = unique(t(:, [2 4]), 'rows');
len = size(u_links, 1);
link_mac_delays = cell(len, 1);
for i = 1 : len
    link = u_links(i, :);
    link_mac_delays{i} = t(t(:, 2) == link(1) & t(:, 4) == link(2), 10);
end
save('link_mac_delays.mat', 'link_mac_delays', 'u_links');