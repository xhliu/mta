% tx
% FLAG = 10;
% % txCounts = size(find(Packet_Log(:, 1) == FLAG), 1);
% rxCounts = size(find(Packet_Log(:, 1) == FLAG & Packet_Log(:, 10) == 169), 1);
% 
%link reliablity
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

tx_id = 169;
rx_id = 137;
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

%% function foo()
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