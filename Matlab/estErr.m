%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   @ Author: Xiaohui Liu (whulxh@gmail.com)
%   @ Date: 10/26/2011
%   @ Description: analyse the estimation error of MTA, DB and DS
%                   job 6092 M-DB, 6132 M-DS and 6122 MTA
%       single path, single src
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
dir = '~/Dropbox/tOR/figures/';
SRC_ID = 76;

% actual delay
t = pkt_delays;
MAX_E2E_DELAY = 10000;
t = t(t(:, 3) < MAX_E2E_DELAY, :);
STABLE_IDX = 1000;
t = t(STABLE_IDX:end, :);

% estimation
DBG_FLAG = 16;
s = debugs;
s = s(s(:, 3) == DBG_FLAG & s(:, 2) == SRC_ID, :);

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


figure;
h = plot(results(:, [1 2 5]));
str = 'mean';
legend({'sample', ['sample ' str], ['estimated ' str]});
% saveas(gcf, 'time_series.fig');
% save('results.mat', 'results');
%% estimate err for stable region
% time-invariant mean, std and qtl
% results = mta_results;
const = mean(results(:, 1));
% const = quantile(results(:, 1), 230 / 256);
ests = results(:, 5); % + 3 * results(:, 6);
errs = ests - const;
errs = errs / const;
[mean(errs) + norminv(.995, 0, 1) * std(errs) / sqrt(size(errs, 1)) mean(errs) mean(errs) - norminv(.995, 0, 1) * std(errs) / sqrt(size(errs, 1))]
%% compare 99% CI
% row: mean, std & qtl
% column: ci upper, mean, ci lower
mta_ = [
0.0027   -0.0125   -0.0277

-0.0320   -0.0993   -0.1666

0.1993    0.1612    0.1232
];

mta = [
0.4303   -1.9714   -4.3731

-0.8148   -2.5302   -4.2457

38.5333   31.1793   23.8252
];

db_ = [
-0.0083   -0.0210   -0.0338

-0.4591   -0.4911   -0.5231

0.0528    0.0324    0.0121
];

db = [
-0.9704   -2.4571   -3.9439
 
-7.4675   -7.9881   -8.5087

7.1116    4.3695    1.6273
];

ds_ = [
-91.0160  -91.1670  -91.3179  
];

ds = [   
-0.6907   -0.6918   -0.6930
];

%% errorbar
row = 1;
% errorbar(1:3, [mta(3, 2); db(3, 2); ds(1, 2)], [mta(3, 2) - mta(3, 3) ; db(3, 2) - db(3, 3); ds(1, 2) - ds(1, 3)], 'xr', 'MarkerSize', 10, 'LineWidth', 2);
errorbar(1:2, [mta(row, 2); db(row, 2);], [mta(row, 2) - mta(row, 3);
            db(row, 2) - db(row, 3)], 'xr', 'MarkerSize', 10, 'LineWidth', 2);

%% boxplot        
% data = results;
group = zeros(0);
dataDisp = zeros(0);
for i = 1 : size(data, 1)
    group = [group ; ones(size(data{i})) + i - 1];
    dataDisp = [dataDisp ; data{i}];
end
figure;
boxplot(dataDisp * 100, group, 'notch', 'on');
set(gca, 'FontSize', 30, 'xtick', 1 : 3, 'XTickLabel', {'MTA', 'M-DB', 'M-DS'});
xlabel('');
ylabel('Relative estimation error of delay quantile (%)');

%% cdf
% make cdf sparser w/ markers
DOWN_SCALE = 30;
[f, x] = ecdf(errs);
plot(x(1:DOWN_SCALE:end), f(1:DOWN_SCALE:end), 'b');
hold on;
%
title('');
legend('M-DS', 'M-DB', 'MTA');
set(gca, 'FontSize', 40);
grid on;
xlabel('Relative estimation error of path delay quantile');
ylabel('F(x)');
% hold on;
%
maximize;
set(gcf, 'Color', 'white'); % Sets figure background
cd('~/Dropbox/tOR/figures/');
export_fig 'relative_qtl_est_err_cdf' -eps;
export_fig 'relative_qtl_est_err_cdf' -jpg -zbuffer;
saveas(gcf, 'relative_qtl_est_err_cdf.fig');

%% largest alpha
clc;
alpha = 0.01;
exit = false;
% for alpha = 0.1 : 0.01 : 0.5
for i = 10 : 10 : 1000
    results = mta_results(1 : i, :);
    const = mean(results(:, 1));
    % const = quantile(results(:, 1), 230 / 256);
    % ests = results(:, 5) + 3 * results(:, 6);
    ests = results(:, 5);
    errs = ests - const;
    errs = errs / const;
    mean_1 = mean(errs);
    lo_1 = mean(errs) - norminv(1 - alpha / 2, 0, 1) * std(errs) / sqrt(size(errs, 1));
    hi_1 = mean(errs) + norminv(1 - alpha / 2, 0, 1) * std(errs) / sqrt(size(errs, 1));

    results = db_results(1 : i, :);
    const = mean(results(:, 1));
    ests = results(:, 5);
    errs = ests - const;
    errs = errs / const;
    mean_2 = mean(errs);
    lo_2 = mean(errs) - norminv(1 - alpha / 2, 0, 1) * std(errs) / sqrt(size(errs, 1));
    hi_2 = mean(errs) + norminv(1 - alpha / 2, 0, 1) * std(errs) / sqrt(size(errs, 1));
    
    
    % CI includes 0
    % mean
    if lo_1 <= 0 && hi_1 >= 0
        if hi_1 >= lo_2
            fprintf('sample size %d: mta <%f %f %f>, db <%f %f %f>\n', i, ...
                lo_1, mean_1, hi_1, lo_2, mean_2, hi_2);
            
            % std
            results = mta_results(1 : i, :);
            const = std(results(:, 1));
            ests = results(:, 6);
            errs = ests - const;
            errs = errs / const;
            mean_1 = mean(errs);
            lo_1 = mean(errs) - norminv(1 - alpha / 2, 0, 1) * std(errs) / sqrt(size(errs, 1));
            hi_1 = mean(errs) + norminv(1 - alpha / 2, 0, 1) * std(errs) / sqrt(size(errs, 1));

            results = db_results(1 : i, :);
            const = std(results(:, 1));
            ests = results(:, 6);
            errs = ests - const;
            errs = errs / const;
            mean_2 = mean(errs);
            lo_2 = mean(errs) - norminv(1 - alpha / 2, 0, 1) * std(errs) / sqrt(size(errs, 1));
            hi_2 = mean(errs) + norminv(1 - alpha / 2, 0, 1) * std(errs) / sqrt(size(errs, 1));
            
            if lo_1 <= 0 && hi_1 >= 0
                if lo_1 >= hi_2
                    exit = true;
                    break;
                end
            end

        end
    end
    
    if exit
        break;
    end
end
% 70 for mean
i

%% %% quantile estimation err grouped by queue levels at each hop
path = [76 79 60 42]';
MAX_E2E_DELAY = 100000;
%% MTA
load TxRx;
t = debugs;
% queue size: only no pkt is being transmitted
s = t(t(:, 3) == 18 & t(:, 7) >= 0, :);
% estimated qtl; only for farthest src
% r = t(t(:, 3) == 16 & t(:, 2) == path(1), :);
r = srcPkts;
r = r(r(:, 2) == path(1), :);

src_pkt_delays = pkt_delays(pkt_delays(:, 1) == path(1), :);

% [seqno [queue levels at each node except sink] delay [delay estimation (mean, std, qtl)]]
seqnos = unique(destPkts(:, 4));
seqno_queues_delay_ests = zeros(size(seqnos, 1), 9);
idx = 1;
for i = 1 : size(seqnos, 1)
    seqno = seqnos(i);
    
    fprintf('processing # %d\n', seqno);
    % find queue level at each hop
    path_queues = zeros(1, size(path, 1));
    tmp_s = s(s(:, 9) == seqno, :);
    abort = false;
    for j = 1 : size(path, 1)
        node = path(j);
        IX = find(tmp_s(:, 2) == node, 1);
        if isempty(IX)
            fprintf('err: queue level not found\n');
            abort = true;
            break;
        end
        path_queues(j) = tmp_s(IX, 10);
    end
    if abort
        continue;
    end
    
    % find the true delay
    IX = find(src_pkt_delays(:, 2) == seqno, 1);
    if isempty(IX)
        fprintf('err: e2e delay not found\n');
        continue;
    end
    pkt_delay = src_pkt_delays(IX, 3);
    % invalid delay
    if pkt_delay > MAX_E2E_DELAY
        continue;
    end
    
    % find the estimated delay 
    IX = find(r(:, 4) == seqno, 1);
    if isempty(IX)
        fprintf('err: delay qtl not found\n');
        continue;
    end
    qtl_est = r(IX, 9) + 3 * sqrt(r(IX, 10));
    
    seqno_queues_delay_ests(idx, :) = [seqno path_queues pkt_delay r(IX, 9) sqrt(r(IX, 10)) qtl_est];
    idx = idx + 1;
end
seqno_queues_delay_ests(idx : end, :) = [];
save('seqno_queues_delay_ests.mat', 'seqno_queues_delay_ests');

%% non-MTA
load TxRx;
SEQ_IDX = 7;
t = debugs;
DBG_FLAG = 16;
% queue size: only no pkt is being transmitted
s = t(t(:, 3) == 18, :);
% estimated qtl; only for farthest src
r = t(t(:, 3) == DBG_FLAG & t(:, 2) == path(1), :);
% r = srcPkts;
% r = r(r(:, 2) == path(1), :);

src_pkt_delays = pkt_delays(pkt_delays(:, 1) == path(1), :);

% [seqno [queue levels at each node except sink] delay [delay estimation (mean, std, qtl)]]
seqnos = unique(destPkts(:, 4));
seqno_queues_delay_ests = zeros(size(seqnos, 1), 9);
idx = 1;
for i = 1 : size(seqnos, 1)
    seqno = seqnos(i);
    
    fprintf('processing # %d\n', seqno);
    tmp_s = s(s(:, 9) == seqno, :);
    % find queue level at each hop
    path_queues = zeros(1, size(path, 1));
    abort = false;
    for j = 1 : size(path, 1)
        node = path(j);
        IX = find(tmp_s(:, 2) == node, 1);
        if isempty(IX)
            fprintf('err: queue level not found\n');
            abort = true;
            break;
        end
        path_queues(j) = tmp_s(IX, 10);
    end
    if abort
        continue;
    end
    
    % find the true delay
    IX = find(src_pkt_delays(:, 2) == seqno, 1);
    if isempty(IX)
        fprintf('err: e2e delay not found\n');
        continue;
    end
    pkt_delay = src_pkt_delays(IX, 3);
    % invalid delay
    if pkt_delay > MAX_E2E_DELAY
        continue;
    end
    
    % find the estimated delay 
    IX = find(r(:, SEQ_IDX) == seqno, 1);
    if isempty(IX)
        fprintf('err: delay qtl not found\n');
        continue;
    end
    qtl_est = r(IX, 8) + 3 * sqrt(r(IX, 10));
    
    seqno_queues_delay_ests(idx, :) = [seqno path_queues pkt_delay r(IX, 8) sqrt(r(IX, 10)) qtl_est];
    idx = idx + 1;
end
seqno_queues_delay_ests(idx : end, :) = [];
save('seqno_queues_delay_ests.mat', 'seqno_queues_delay_ests');

%% group by queue levels
load seqno_queues_delay_ests;
MIN_SAMPLE_SIZE = 1000;
STABLE_IDX = 10;
t = seqno_queues_delay_ests;
queues = t(:, 2 : size(path, 1) + 1);
u_queues = unique(queues, 'rows');

% queue levels
queue_levels = zeros(size(u_queues, 1), size(path, 1));
% qtl estimation error corresponding to the queue level
queue_level_errs = cell(size(u_queues, 1), 1);
idx = 1;

for i = 1 : size(u_queues, 1)
    fprintf('processing queue %d\n', i);
    u_queue = u_queues(i, :);

    % find the pkts w/ the queue level
    IX = find(ismember(queues, u_queue, 'rows'));
    
    if size(IX, 1) < MIN_SAMPLE_SIZE
        continue;
    end
    queue_pkt_delay_qtl = quantile(t(IX, 6), 230 / 256);
%     queue_pkt_delay_qtl = mean(t(IX, 6));
    plot(t(IX, 6));
    
    queue_est_qtls = t(IX, 9);
    queue_est_qtls = queue_est_qtls(STABLE_IDX : end);
    plot(queue_est_qtls);
    
    errs = (queue_est_qtls - queue_pkt_delay_qtl) / queue_pkt_delay_qtl;
    hist(errs, size(errs, 1));
%     plot(errs(STABLE_IDX:end));
    
    queue_levels(idx, :) = u_queue;
    queue_level_errs{idx} = errs;
    idx = idx + 1;
end
queue_levels(idx : end, :) = [];
queue_level_errs(idx : end, :) = [];
save('queue_level_errs.mat', 'queue_level_errs', 'queue_levels');

% merge all qtl relative errs
load queue_level_errs;
len = size(queue_level_errs, 1);
t = [];
for i = 1 : len
    t = [t; queue_level_errs{i}];
end
db_queue_level_errs = t;


%% %%compare queue levels
%% merge all qtl relative errs
jobs = [7096 7116 7112 7111];
for i = 1 : length(jobs)
cd(['/home/xiaohui/Projects/tOR/RawData/' num2str(jobs(i))]);
load queue_level_errs;
len = size(queue_level_errs, 1);
t = [];
for j = 1 : len
    t = [t; queue_level_errs{j}];
end
% MTA, DB, DS and ST: 7096 7112 7116 7111
hold all;
grid on;
if i == 2
    % special case for DS
    DOWN_SCALE = 1;
else
    DOWN_SCALE = 1000;
end
errs = t;
[f, x] = ecdf(errs);
plot(x(1:DOWN_SCALE:end), f(1:DOWN_SCALE:end));
end
%%
set(gca, 'FontSize', 40, 'ytick', 0:0.1:1);
xlabel('Relative error');
ylabel('CDF');
legend({'MTA', 'M-DS', 'M-DB', 'M-ST'});

maximize;
set(gcf, 'Color', 'white');
cd('/home/xiaohui/Dropbox/tOR/figures');
str = 'qtl_est_err';
export_fig(str, '-eps');
export_fig(str, '-jpg', '-zbuffer');
saveas(gcf, [str '.fig']);