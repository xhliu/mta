%% progressive consistency
ROOT_ID = 15;
SRC_ID = 76;
% exclude root
path = [42, 60, 79, 76]';
clc;
for k = 1 : size(path, 1)
node = path(k);

% actual e2e delay from src
t = pkt_delays;
MAX_E2E_DELAY = 10000;
t = t(t(:, 3) < MAX_E2E_DELAY, :);
STABLE_IDX = 1000;
t = t(STABLE_IDX:end, :);

if node ~= SRC_ID
% delay from intermediate nodes
r = intercepts;

% delays from this node to sink
delays = zeros(size(t, 1), 3);
idx = 1;
for i = 1 : size(t, 1) 
    seqno = t(i, 2);
    e2e_delay_sample = t(i, 3);
    
    % find the corresponding elapsed at that node: either src or forwarder
    IX = find(r(:, 2) == node & r(:, 4) == seqno, 1);
    if isempty(IX)
        disp('err 1');
        continue;
    end
    elapsed_time = r(IX, 10);
    
    if e2e_delay_sample < elapsed_time
        disp('err 2');
        continue;
    end
    delays(idx, :) = [t(i, 1:2) e2e_delay_sample - elapsed_time];
    idx = idx + 1;
end
delays(idx:end, :) = [];
t = delays;
end
%% estimation
DBG_FLAG = 16;
s = debugs;
s = s(s(:, 3) == DBG_FLAG & s(:, 2) == node, :);

% [e2e_delay_sample sample_mean sample_std sample_qtl est_mean est_var
% est_qtl]
results = zeros(size(t, 1), 7);
idx = 1;
% ALPHA = 1 / 2;
% sample_mean = 0;
% each pkt; one src only
for i = 1 : size(t, 1) 
    seqno = t(i, 2);
    
    e2e_delay_sample = t(i, 3);
    
    sample_mean = mean(t(1:i, 3));
    sample_std = std(t(1:i, 3));
    sample_qtl = quantile(t(1:i, 3), 230 / 256);
    
    % find the corresponding estimation at that moment
    IX = find(s(:, 7) == seqno, 1);
    if isempty(IX)
        disp('err');
        continue;
    end
    
    est_mean = s(IX, 8);
    est_std = sqrt(s(IX, 10));
    est_qtl = s(IX, 9);
    
    results(idx, :) = [e2e_delay_sample sample_mean sample_std sample_qtl ...
                                        est_mean est_std est_qtl];
    idx = idx + 1;
end
results(idx : end, :) = [];

% figure;
% h = plot(results(:, [1 2 5]));
% str = 'mean';
% legend({'sample', ['sample ' str], ['estimated ' str]});
%% estimate err for stable region
% time-invariant mean, std and qtl
const = mean(results(:, 1));
% const = quantile(results(:, 1), 230 / 256);
ests = results(:, 5); % + 3 * results(:, 6);
errs = ests - const;
errs = errs / const;

fprintf('node %d: %f %f %f\n', node, mean(errs) + norminv(.995, 0, 1) * std(errs) / sqrt(size(errs, 1)), mean(errs), mean(errs) - norminv(.995, 0, 1) * std(errs) / sqrt(size(errs, 1)));
end