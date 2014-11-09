%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   @ Author: Xiaohui Liu (whulxh@gmail.com)
%   @ Date: 11/11/2011
%   @ Description: measure the correlation of packet time
%       job 5686 for low traffic; 5564 for medium; job 5570 for heavy
%       traffic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% packet time correlation: links along a path and links sharing sender
SRC_IDX = 3;
SRC_SEQ_IDX = 4;
QUEUE_SIZE_IDX = 7;
PKT_TIME_IDX = 9;
LAST_HOP_IDX = 10;

NTW_SIZE = 20;
ROOT_ID = 15;

%% packet time correlation of links along a path
MIN_SAMPLE_SIZE = 1000;
% all records of packet time
t = rxs;
t = t(t(:, 10) ~= 0 & t(:, 8) ~= 65535, :);

results = zeros(100000, NTW_SIZE);
idxs = ones(NTW_SIZE, 1);

%
u_paths = unique(pkt_paths, 'rows');
% each path
for i = 1 : size(u_paths, 1)
    fprintf('path %d\n', i);
    u_path = u_paths(i, :);
    
    IX = find(ismember(pkt_paths, u_path, 'rows'));
    if size(IX, 1) < MIN_SAMPLE_SIZE
        continue;
    end
    % remove invalid part
    u_path = u_path';
    IX = find(u_path == 255);
    u_path(IX : end) = [];
    
    % each link
    for j = 1 : (size(u_path, 1) - 1)
        for k = (j + 1) : (size(u_path, 1) - 1)
            lag = k - j;
            
            link_1 = u_path(j : j + 1);
            link_2 = u_path(k : k + 1);
            
            % [pkt, pkt_time at this hop]
            IX = find(t(:, LAST_HOP_IDX) == link_1(1) & t(:, 2) == link_1(2));
            if size(IX, 1) < MIN_SAMPLE_SIZE
                continue;
            end
            link_pkt_delay_1 = t(IX, [SRC_IDX SRC_SEQ_IDX PKT_TIME_IDX]);
            
            IX = find(t(:, LAST_HOP_IDX) == link_2(1) & t(:, 2) == link_2(2));
            if size(IX, 1) < MIN_SAMPLE_SIZE
                continue;
            end
            link_pkt_delay_2 = t(IX, [SRC_IDX SRC_SEQ_IDX PKT_TIME_IDX]);
            
            [x ia ib] = intersect(link_pkt_delay_1(:, [1 2]), link_pkt_delay_2(:, [1 2]), 'rows');
            if size(x, 1) < MIN_SAMPLE_SIZE
                continue;
            end
            tmp = corrcoef(link_pkt_delay_1(ia, 3), link_pkt_delay_2(ib, 3));
            
            results(idxs(lag), lag) = tmp(1, 2);
            idxs(lag) = idxs(lag) + 1;
        end
    end
end
save('link_pkt_time_corr.mat', 'results');
data = cell(NTW_SIZE, 1);
idx = 1;
for i = 1 : NTW_SIZE
    if idxs(i) < 5;
        continue;
    end
    data{idx} = results(1 : idxs(i) - 1, i);
    idx = idx + 1;
end
data(idx : end, :) = [];

%% packet time correlation of links along a path
MIN_SAMPLE_SIZE = 100;
% all records of packet time
t = rxs;
t = t(t(:, 10) ~= 0 & t(:, 8) ~= 65535, :);
%
clc;
corrcoefs = cell(NTW_SIZE * QUEUE_SIZE, 1);

u_paths = unique(pkt_paths, 'rows');
% each path
for i = 1 : size(u_paths, 1)
    fprintf('path %d\n', i);
    u_path = u_paths(i, :);
    
    IX = find(ismember(pkt_paths, u_path, 'rows'));
    if size(IX, 1) < MIN_SAMPLE_SIZE
        continue;
    end
    % pkts go through this path
    u_path_pkts = pkt_delays(IX, 1:2);
    
    % remove invalid part
    u_path = u_path';
    IX = find(u_path == 255);
    % start from 2nd bcoz receiver-based
    u_path = u_path(2 : IX - 1);
    
    % pkt time pairs for each lag
    results = cell(NTW_SIZE * QUEUE_SIZE, 1);
    idxs = ones(NTW_SIZE * QUEUE_SIZE, 1);

    % each pkt thru this path
    for j = 1 : size(u_path_pkts, 1)
        pkt = u_path_pkts(j, :);
        s = t(t(:, SRC_IDX) == pkt(1) & t(:, SRC_SEQ_IDX) == pkt(2), :);
        if isempty(s)
            disp('err 0');
            continue;
        end

        % pkt time and queueing at each hop
        pkt_times = [];
        queues = [];
        
        abort = false;
        for k = 1 : size(u_path, 1)
            node = u_path(k);
            
            IX = find(s(:, 2) == node, 1);
            if isempty(IX)
                % nothing can be missing bcoz otherwise intermediate
                % queueing is lost
                disp('err 1');
                abort = true;
                break;
            end
            pkt_times = [pkt_times s(IX, PKT_TIME_IDX)];
            % include pkt itself
            queues = [queues s(IX, QUEUE_SIZE_IDX) + 1];
        end
        
        if abort
            continue;
        end
        
        % each pair <k m>
        for k = 1 : (size(u_path, 1) - 1)
            for m = (k + 1) : size(u_path, 1)
                % how many pkts in btw
                lag = sum(queues(k : m - 1));
                results{lag}(idxs(lag), :) = [pkt_times(k) pkt_times(m)];
                idxs(lag) = idxs(lag) + 1;
            end
        end
    end
    
    for lag = 1 : size(results, 1)
        tmp = results{lag}(1 : idxs(lag) - 1, :);
        % remove lags w/ few samples
        if size(tmp, 1) < 100
            continue;
        end
        tmp = corrcoef(tmp);
        corrcoefs{lag} = [corrcoefs{lag}; tmp(1, 2)];
    end     
end
save('lag_corrcoefs.mat', 'corrcoefs');

% display
MIN_SAMPLE_SIZE = 10;
t = corrcoefs;
data = cell(size(t, 1), 1);
idx = 1;
lags = [];
for i = 1 : size(t, 1)
    % remove lags w/ few samples
    if size(t{i}, 1) < MIN_SAMPLE_SIZE
        continue;
    end
    data{idx} = t{i};
    idx = idx + 1;
    lags = [lags; i];
end
data(idx : end, :) = [];

group = zeros(0);
dataDisp = zeros(0);
for i = 1 : size(data, 1)
    group = [group ; ones(size(data{i})) + i - 1];
    dataDisp = [dataDisp ; data{i}];
end
figure;
boxplot(dataDisp, group, 'notch', 'on');
%
set(gca, 'FontSize', 40, 'xticklabel', lags);
ylabel('Correlation coefficient');
xlabel('Lag');
title('');

%% packet time correlation of links sharing sender
MIN_SAMPLE_SIZE = 1000;
% all records of packet time
t = rxs;
t = t(t(:, 10) ~= 0 & t(:, 8) ~= 65535, :);

corrcoefs = zeros(100000, 1);
idx = 1;

senders = unique(t(:, LAST_HOP_IDX), 'rows');
% each sender
for i = 1 : size(senders, 1)
    sender = senders(i);
    
    % all records of links from the sender
    s = t(t(:, LAST_HOP_IDX) == sender, :);
    receivers = unique(s(:, 2));
    
    % each outgoing link from the sender
    link_pkt_times = cell(size(receivers, 1), 1);
    for j = 1 : size(receivers, 1)
        receiver = receivers(j);
        
        link_pkt_times{j} = s(s(:, 2) == receiver, PKT_TIME_IDX);
    end
    
    % corrcoef
    r = link_pkt_times;
    for j = 1 : (size(r, 1) - 1)
        for k = (j + 1) : size(r, 1)
            % ensure same size
            if size(r{j}, 1) < size(r{k}, 1)
                len = size(r{j}, 1);
            else
                len = size(r{k}, 1);
            end
            if len < MIN_SAMPLE_SIZE
                continue;
            end
            r1 = r{j}(1:len);
            r2 = r{k}(1:len);
            
            tmp = corrcoef(r1, r2);
            corrcoefs(idx) = tmp(1, 2);
            idx = idx + 1;
        end
    end
end
corrcoefs(idx : end, :) = [];
hist(corrcoefs);
%% packet time correlation across hops
% all records of packet time
t = rxs;
t = t(t(:, 10) ~= 0 & t(:, 8) ~= 65535, :);
%
pkts = unique(srcPkts(:, [SRC_IDX SRC_SEQ_IDX]), 'rows');
% pkt time for a packet at each hop
hop_pkt_times = zeros(size(pkts, 1), NTW_SIZE);
hop_queues = zeros(size(pkts, 1), NTW_SIZE);
idx = 1;
% each packet
for i = 1 : size(pkts, 1)
    pkt = pkts(i, :);
    s = t(t(:, SRC_IDX) == pkt(1) & t(:, SRC_SEQ_IDX) == pkt(2), :);
    
    % each hop
    node = pkt(1);
    hop = 1;
    valid = true;
    while node ~= ROOT_ID
        fprintf('%d-th packet, %d-th hop: %d\n', i, j, node);
        IX = find(s(:, LAST_HOP_IDX) == node, 1);
        if isempty(IX)
            fprintf('not found\n');
            break;
        end
        hop_pkt_times(idx, hop) = s(IX, PKT_TIME_IDX);
        hop_queues(idx, hop) = s(IX, QUEUE_SIZE_IDX);
        if hop < NTW_SIZE
            hop = hop + 1;
        else
            % most likely loop here
            valid = false;
            break;
        end
        node = s(IX, 2);
    end
    % skip loops
    if valid
        idx = idx + 1;
    end
end
%
hop_pkt_times(idx : end, :) = [];
hop_queues(idx : end, :) = [];
save('hop_pkt_time_queues.mat', 'hop_pkt_times', 'hop_queues');
%% group by hop distance
t = hop_pkt_times;
% pkt time for the same pkt across various hops
lag_pkt_times = cell(NTW_SIZE, 1);
idxs = ones(NTW_SIZE, 1);
% initialize
for i = 1 : NTW_SIZE
    % pkt time for a pkt at hop j and hop (j + lag)
    lag_pkt_times{i} = zeros(1000000, 2);
end

% each pkt
for i = 1 : size(t, 1)
    entry = t(i, :);
    
    % each lag
    for lag = 1 : (NTW_SIZE - 1)
        % each hop
        
        for j = 1 : (NTW_SIZE - lag)
            % reach the last hop
            if 0 == entry(j) || 0 == entry(j + lag)
                break;
            end
            fprintf('pkt %d at lag %d\n', i, lag);
            lag_pkt_times{lag}(idxs(lag), :) = [entry(j) entry(j + lag)];
            idxs(lag) = idxs(lag) + 1;
        end
    end
end
save('lag_pkt_times.mat', 'lag_pkt_times');
%% remove invalid entries
MIN_SAMPLE_SIZE = 1000;
for i = 1 : NTW_SIZE
    % reach max hops
    if idxs(i) < MIN_SAMPLE_SIZE
        break;
    end
    lag_pkt_times{i}(idxs(i):end, :) = [];
end
lag_pkt_times(i : end, :) = [];
%% correlation
t = lag_pkt_times;
results = [];
for i = 1 : size(t, 1)
    result = corrcoef(t{i});
    results = [results; result(1, 2)];
end
bar(results(1:5))

%% pkt time correlation across hops
MIN_SAMPLE_SIZE = 1000;
lags = [1 2 5 10 20 50]';
LAG_CNTS = 50;
% all records of packet time
t = rxs;
t = t(t(:, 10) ~= 0 & t(:, 8) ~= 65535, :);
%
clc;
corrcoefs = cell(size(lags, 1), 1);

% pre-load 'node_id.mat'
for i = 1 : 105
    if exist([num2str(i) '.mat'], 'file')
        load([num2str(i) '.mat']);
        if exist('Packet_Log', 'var')
            t = Packet_Log;
            t = t(t(:, 1) == 9 | t(:, 1) == 10, :);
            t = t(~(t(:, 1) == 10 & (t(:, 10) == 0 | t(:, 8) == 65535)), :);
            eval(['Packet_Log' num2str(i) ' = t;']);
            clear Packet_Log;
        end
    end
end

u_paths = unique(pkt_paths, 'rows');
% each path; group corrcoef by path
for i = 1 : size(u_paths, 1)
    fprintf('path %d\n', i);
    u_path = u_paths(i, :);
    
    IX = find(ismember(pkt_paths, u_path, 'rows'));
    if size(IX, 1) < MIN_SAMPLE_SIZE
        continue;
    end
    % pkts go through this path
    u_path_pkts = pkt_delays(IX, 1:2);
    
    % remove invalid part
    u_path = u_path';
    IX = find(u_path == 255);
    % start from 2nd bcoz receiver-based
    u_path = u_path(2 : IX - 1);
    
    % pkt time pairs for each lag
    results = cell(LAG_CNTS, 1);
    idxs = ones(LAG_CNTS, 1);
    for lag = 1 : LAG_CNTS
        results{lag} = zeros(100000, 2);
    end
    
    % each pkt thru this path
    for j = 1 : size(u_path_pkts, 1)
        fprintf('path %d, pkt %d\n', i, j);
        pkt = u_path_pkts(j, :);
        
        s = t(t(:, SRC_IDX) == pkt(1) & t(:, SRC_SEQ_IDX) == pkt(2), :);
        if isempty(s)
            disp('err 0');
            continue;
        end

        % pkt time at first hop
        IX = find(s(:, 2) == u_path(1), 1);
        if isempty(IX)
            disp('err 1');
            continue;
        end
        first_pkt_time = s(IX, PKT_TIME_IDX);
        
        % pkt times for next pkts at each hop after the pkt reaches
        for k = 2 : size(u_path)
            sender = u_path(k - 1);
            receiver = u_path(k);
            % receiver tx/rx log
            eval(['s = Packet_Log' num2str(receiver) ';']);

            % find the pkt
            IX = find(s(:, 1) == 10 & s(:, 3) == pkt(1) & s(:, 4) == pkt(2) & s(:, 10) == sender, 1);
            if isempty(IX)
                fprintf('warning 1 for entry %d\n', i);
                continue;
            end

            % next pkts sent upon reception of the pkt in concern
            r = s(IX + 1 : end, :);
            IXs = find(r(:, 1) == 9, LAG_CNTS);

            % MAC delay for next pkts sent
            m = t(t(:, LAST_HOP_IDX) == receiver, :);
            if ROOT_ID == receiver
                continue;
            end
            for lag_idx = 1 : size(lags, 1)
                lag = lags(lag_idx);
                if lag > size(IXs, 1)
                    continue;
                end
                IX = IXs(lag);
                next_pkt = r(IX, 3:4);
                next_receiver = r(IX, 10);

                IX = find(m(:, 2) == next_receiver & m(:, 3) == next_pkt(1) & m(:, 4) == next_pkt(2), 1);
                if isempty(IX)
                    fprintf('warning 3 for entry %d: %d -> %d\n', i, receiver, next_receiver);
                    continue;
                end
                results{lag}(idxs(lag), :) = [first_pkt_time m(IX, PKT_TIME_IDX)];
                idxs(lag) = idxs(lag) + 1;
            end
        end
    end
    
    % group corrcoef by path
    for lag_idx = 1 : size(lags)
        lag = lags(lag_idx);
        tmp = results{lag}(1 : idxs(lag) - 1, :);
        if isempty(tmp)
            continue;
        end
        tmp = corrcoef(tmp);
        corrcoefs{lag_idx} = [corrcoefs{lag_idx}; tmp(1, 2)];
    end
end
save('inter_node_corrcoefs.mat', 'corrcoefs');