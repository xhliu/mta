%% 
%p = .8 : .05 : .95; failure case
p = 232 : 2 : 256;
p = p / 256;
% IX = find(p == .9);
% POI = IX(1);
POI = 5;
samples = tmp(:, 2);
linkDelayEsts = tmp(:, 1);
errors = zeros(size(samples, 1), 1);
errors_cnts = 1;
% P2 needs at least (2 * length(p) + 3) samples to jump start
for i = (2 * length(p) + 3) : 1 : size(samples, 1)
    tmp_samples = samples(1 : i);
%     tmp_samples = [(10 : 30)'; tmp_samples];
%     [p2_etx_ests, adjusts] = P2QtlEst_Ext(tmp_samples, p);
    p2_etx_ests = linkDelayEsts(i);
    
    errors(errors_cnts, :) = length(find(tmp_samples <= p2_etx_ests)) / length(tmp_samples);
    errors_cnts = errors_cnts + 1;
%     actual_values = quantile(tmp_samples, p);
%     if actual_values(POI) ~= 0 
%         error = (p2_etx_ests - actual_values(POI)) / actual_values(POI);
% %         error = (p2_etx_ests(POI) - actual_values(POI)) / actual_values(POI);
%         errors(errors_cnts, :) = error;
%         errors_cnts = errors_cnts + 1;
%     end
end
errors(errors_cnts : end, :) = [];
% if errors(end) > 0.3
%     fprintf('error %f \n', error);
% end
figure;
hold on;
plot(errors);
plot(repmat(p(POI), 1, length(errors)));
%% function foo()
% 16-th node of 1190, node with id 53, counters P2 at 90 percentile from
% [1, 200], not tailed distributed even
% clear;
%sample from paper: 0.15 is errorneously said to be 0.5
% samples = [0.02; 0.15; 0.74; 3.39; 0.83; 22.37; 10.15; 15.43; 38.62; 15.92; 34.60;...
%         10.28; 1.47; 0.40; 0.05; 11.39; 0.27; 0.42; 0.09; 11.37];
% load('samples.mat');    
% load('~/Downloads/Jobs/3615/samples.mat');    
% p = [0.5, 0.75, 0.8, 0.85, .9, 0.99, 0.999];
p = .9: .0025 : 1;
POI = 37;
% for i = 1 : length(p)
%     markers = P2QtlEst(samples, p(i));
%     p2_est = markers(size(markers, 1), 3)
%     p2_etx_est = P2QtlEst_Ext(samples, p(i))
% end

% linkDelaySamples = Packet_Log(find(Packet_Log(:, 1) == 11), 4);
% linkDelaySamples = timeouts(177:380, 15);
% linkDelayEsts = Packet_Log(find(Packet_Log(:, 1) == 11), 3);
% linkDelayEsts = timeouts(177:380, 4);
nodes = unique(node_sample_ests(:, 1));
% nodes = unique(debugs(:, 2));
% nodes = [12, 34];
node_errors = [];
% all_adjusts = zeros(size(debugs, 1), 1);
all_adjusts = zeros(size(node_sample_ests, 1), 1);
all_adjusts_cnts = 1;
figure;
hold on;
for j = 1 : length(nodes)
%     IX = find(debugs(:, 2) == nodes(j));
    fprintf('processing %d-th node %d .....\n', j, nodes(j));
    IX = find(node_sample_ests(:, 1) == nodes(j));
%     linkDelaySamples = debugs(IX, 15);
    linkDelaySamples = node_sample_ests(IX, 2);
%     linkDelayEsts = debugs(IX, 4);
    linkDelayEsts = node_sample_ests(IX, 3);
    errors = zeros(size(linkDelaySamples, 1), 1);
    errors_cnts = 1;
    % samples = samples(find(samples <= 100));
    % [p2_etx_ests, adjusts] = P2QtlEst_Ext(samples, p);
    % P2 needs at least (2 * length(p) + 3) samples to jump start
    adjusts = zeros(1);
    for i = (2 * length(p) + 3) : 5 : 1000 % size(linkDelaySamples, 1) % (2 * length(p) + 3) : 
%     for i = size(linkDelaySamples, 1) : size(linkDelaySamples, 1)
        temp_samples = linkDelaySamples(1 : i);
%         temp_samples = temp_samples(find(temp_samples <= 100));
        [p2_etx_ests, adjusts] = P2QtlEst_Ext(temp_samples, p);
%         p2_etx_ests = linkDelayEsts(i);
        
        actual_values = quantile(temp_samples, p);

        if actual_values(POI) ~= 0 
            error = (p2_etx_ests(POI) - actual_values(POI)) / actual_values(POI);
            errors(errors_cnts, :) = error;
            errors_cnts = errors_cnts + 1;
        end
    end
    len = size(adjusts, 1);
    all_adjusts(all_adjusts_cnts : (all_adjusts_cnts + len - 1), :) = adjusts;
    all_adjusts_cnts = all_adjusts_cnts + len;
    
    errors(errors_cnts : end, :) = [];
    if errors(end) > 0.3
        fprintf('node %d error %f \n', nodes(j), error);
    end
    plot(errors);
end

all_adjusts(all_adjusts_cnts : end, :) = [];
tmp = all_adjusts(all_adjusts ~= 0);
fprintf('range of step changes: [%f, %f]\n', min(abs(tmp)), max(abs(tmp)));
hold off;