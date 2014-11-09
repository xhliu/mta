%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Xiaohui Liu
%   @date: 6/24/2011
%   @updated: 10/20/2011 to reorder according to importance and remove
%   inequalities requiring independence bcoz only uncorrelation is proved
%   
%   Function: empirically measure the tightness of all types of bounding of
%   quantile of sum of random variables (> 2) job 2929
%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% compute bounds
load e2e_queue_level_tx_delays;
load tx_delays;
cell_size = size(e2e_queue_level_tx_delays, 1);
%only consider bucket w/ sufficient samples
SAMPLE_MIN_SIZE = 400;
% for qtl = 0.93 : 0.02 : 0.99
% quantile concerned
qtl = 0.90;
ALPHA = 0.1;
% [bounding tech, e2e queue size, bound given]
BOUND_CNTS = 20;
hop_queue_levels = [0 0 0 0 0; 0 0 35 0 0; 0 0 36 0 0];
% bounds = zeros(BOUND_CNTS, cell_size);
bounds = zeros(BOUND_CNTS, size(tx_delays, 1));
queue_idx = 1;

for cell_seq = 1 : cell_size

    e2e_tx_delays = e2e_queue_level_tx_delays{cell_seq};
    if size(e2e_tx_delays, 1) < SAMPLE_MIN_SIZE
        continue;
    end

% study time-varying behavior
% for tx_delays_idx = 1000 : 1000 : size(tx_delays)
%     s = tx_delays(1 : tx_delays_idx, :);
    % tx_delays contains the pkt-time each pkts gets at each hop
    s = tx_delays;
    
    % compute mean and variance using sum(hop_tx_delay * queue level) at
    % all hops
    t = [];
    % queueing at each hop, including the pkt per se
    hop_queue_level = hop_queue_levels(cell_seq, :) + 1;
    % construct equivalent tx_delays for each queued element; element in
    % the same queue has the same tx_delay; equivalently to use 
    for i = 1 : size(s, 2)
        tmp = repmat(s(:, i), 1, hop_queue_level(i));
        t = [t tmp];
    end
    % sum over row
    Z = sum(t, 2);
    mean_Z = mean(Z);
    % caution: this can be quite different from var(sum(t, 2)) since t's
    % columns are not independent; and the columns are identical if
    % belonging to the same hop
    var_Z = sum(var(t));
    % EWMA
%     [mean_columns  var_columns] = EWMA(t, ALPHA);
%     mean_Z = sum(mean_columns);
%     var_Z = sum(var_columns);

    bound_cnts = 1;
    HOPCOUNTS = size(t, 2);
    % % [bounding tech, links]
    % BOUND_CNTS = 18;

    path_len_link_bounds = cell(HOPCOUNTS - 1, 1);
    % for path_len = HOPCOUNTS : HOPCOUNTS
    path_len = HOPCOUNTS;
    link_cnts = HOPCOUNTS - path_len + 1;
%     bounds = zeros(BOUND_CNTS, link_cnts);

% for i = 1 : link_cnts
%     fprintf('path len %d, link %d ....\n', path_len, i);
    % t is the samples used, each column is a R.V.
%     t = tx_delays(:, i : i + path_len - 1);
    
% actual quantile
%fprintf('%f quantile of sum: %f\n', qtl, quantile(Z, qtl));
bounds(bound_cnts, queue_idx) = quantile(e2e_tx_delays, qtl);
bound_cnts = bound_cnts + 1;

% MAX
%fprintf('max of sum: %f\n', max(Z));
bounds(bound_cnts, queue_idx) = sum(max(t));
bound_cnts = bound_cnts + 1;

% parametric
% normal
bound = norminv(qtl, mean_Z, sqrt(var_Z));
bounds(bound_cnts, queue_idx) = bound;
bound_cnts = bound_cnts + 1;

% exponential
bound = expinv(qtl, mean_Z);
bounds(bound_cnts, queue_idx) = bound;
bound_cnts = bound_cnts + 1;

% lognormal
% mu = mean(log(X)) + mean(log(Y));
% sigma = std(log(X)) + std(log(Y));
mu = mean(log(Z));
sigma = std(log(Z));
bound = logninv(qtl, mu, sigma);
bounds(bound_cnts, queue_idx) = bound;
bound_cnts = bound_cnts + 1;

% Vysochanskij Petunin bound
mu = mean_Z;
sigma = sqrt(var_Z);
bound = mu + sqrt(qtl / (1 - qtl)) * sigma * 2 / 3;
%fprintf('Chebyshev bound: %f\n', bound);
bounds(bound_cnts, queue_idx) = bound;
bound_cnts = bound_cnts + 1;

% Chebyshev
mu = mean_Z;
sigma = sqrt(var_Z);
bound = mu + sqrt(qtl / (1 - qtl)) * sigma;
%fprintf('Chebyshev bound: %f\n', bound);
bounds(bound_cnts, queue_idx) = bound;
bound_cnts = bound_cnts + 1;

% tighter Chebyshev 
sigma2 = mean_Z;
tau4 = var_Z + mean_Z ^ 2;
% compute boundary
lo = sigma2;
hi = tau4 / sigma2;
% TinyOS implementation??
sample_qtl = quantile(Z, qtl);
if sample_qtl < lo
    bound = max(Z);
    % consistent w/ range 3
    bound = [bound bound];
else
    if sample_qtl < hi;
        bound = sigma2 / (1 - qtl);
        bound = [bound bound];
    else
        % only solution >= hi is valid
        syms x;
        RHS = 1 - qtl;
        x_ = solve((tau4 - sigma2 ^ 2) / (tau4 + x ^ 2 - 2 * sigma2 * x) - RHS);
        bound = double(x_);
    end
end
% fprintf('tighter Chebyshev bound %f\n', bound);
bounds(bound_cnts, queue_idx) = double(bound(1));
bound_cnts = bound_cnts + 1;
bounds(bound_cnts, queue_idx) = double(bound(2));
bound_cnts = bound_cnts + 1;

% OPMD
OPMD_STEP_SIZE = 0.02;
QUANTILE_CNTS = length(qtl : OPMD_STEP_SIZE : 1);
% node OPMD at current hop
opmd = zeros(QUANTILE_CNTS, 1);
% diffusion: start from 1 hop neighbor
for hop = 1 : HOPCOUNTS
%     fprintf('processing hop %d\n', hop);
    if 1 == hop
        opmd = quantile(t(:, 1), qtl : OPMD_STEP_SIZE : 1);
        continue;
    end
    Y = t(:, hop);
    % each OPMD quantile
    for e2e_qtl_idx = 1 : QUANTILE_CNTS
        % each combination
        min_bound = inf;
        for node_qtl_idx = e2e_qtl_idx : QUANTILE_CNTS
            e2e_qtl = qtl + (e2e_qtl_idx - 1) * OPMD_STEP_SIZE;
            node_qtl = qtl + (node_qtl_idx - 1) * OPMD_STEP_SIZE;
            link_qtl = e2e_qtl / node_qtl;
            % mimic implementation where all quantiles are approximated
            % using nearby dicrete quantile level
%             if ((link_qtl - qtl) / OPMD_STEP_SIZE) == 0
%             link_qtl_idx = ceil((link_qtl - qtl) / OPMD_STEP_SIZE) + 1;
%             link_qtl = qtl + (link_qtl_idx - 1) * OPMD_STEP_SIZE;
            
            qtl_sum = opmd(node_qtl_idx) + quantile(Y, link_qtl);
%             fprintf('qtl %f (<%f, %f>; <%f, %f>) is %f\n', e2e_qtl, node_qtl, opmd(node_qtl_idx), ...
%                 link_qtl, quantile(Y, link_qtl), qtl_sum);
            if min_bound > qtl_sum
                min_bound = qtl_sum;
            end
        end
        % update
        opmd(e2e_qtl_idx) = min_bound;
    end
end
%fprintf('OPMD bound: %f\n', min_bound);
bounds(bound_cnts, queue_idx) = opmd(1);
bound_cnts = bound_cnts + 1;

% tail probability (refer to asymptotic tail probabilities sum dependent subexponential random variables)
% search min bound c such that sum(^F(c)) <= (1 - qtl)
len = size(t, 1);
lo = min(min(t));
hi = max(max(t));

% version 1: empirical CDF
found = false;
for c =  lo: .1 : hi
    qtl_sum = 0;
    for j = 1 : size(t, 2)
        qtl_sum = qtl_sum + length(find(t(:, j) > c)) / len;
    end
    if qtl_sum <= (1 - qtl)
        found = true;
        break;
    end
end
if found
    fprintf('tail probability bound: %f\n', c);
else
    fprintf('error 1: c does not exist\n');
end
bounds(bound_cnts, queue_idx) = c;
bound_cnts = bound_cnts + 1;

% version 2: assume lognormal
parmhats = zeros(size(t, 2), 2);
for j = 1 : size(t, 2)
    parmhats(j, :) = lognfit(t(:, j));
end
found = false;
for c =  lo: .1 : hi
    qtl_sum = 0;
    for j = 1 : size(t, 2)
        qtl_sum = qtl_sum + (1 - logncdf(c, parmhats(j, 1), parmhats(j, 2)));
    end
    if qtl_sum <= (1 - qtl)
        found = true;
        break;
    end
end
if found
    fprintf('tail probability bound: %f\n', c);
else
    fprintf('error 2: c does not exist\n');
end
bounds(bound_cnts, queue_idx) = c;
bound_cnts = bound_cnts + 1;

% Hoeffding
a = min(t);
b = max(t);
n = size(t, 2);
% sum((b_i - a_i) ^ 2) for all i
sum_ = 0;
for j = 1 : n
    sum_ = sum_ + (b(j) - a(j)) ^ 2;
end
bound = mean_Z + n * sqrt(-sum_ * log(1 - qtl) / (2 * n ^ 2));
%fprintf('Hoeffding bound: %f\n', bound);
bounds(bound_cnts, queue_idx) = bound;
bound_cnts = bound_cnts + 1;

% Markovian
bound = mean_Z / (1 - qtl);
%fprintf('Markovian bound: %f\n', bound);
bounds(bound_cnts, queue_idx) = bound;
bound_cnts = bound_cnts + 1;

% Bennett's inequality
n = size(t, 2);
var_ = var_Z / n;
% compute a
mean_t = mean(t);
max_a = -inf;
for j = 1 : n
    diff = max(abs(t(:, j) - mean_t(j)));
    if max_a < diff
        max_a = diff;
    end
end
a = max_a;
% solve equation
syms x;
RHS = - a ^ 2 * log(1 - qtl) / (n * var_);
x_ = solve((1 + x) * log(1 + x) - x - RHS);
t_ = n * var_ * x_ / a;
bound = mean_Z + t_;
bounds(bound_cnts, queue_idx) = bound;
bound_cnts = bound_cnts + 1;

% Bernstein: usually two solutions
RHS = log(1 - qtl);
t_ = solve(- x ^ 2 / (2 + 2 * a * x / (3 * sigma)) - RHS);
bound = mean_Z + t_ * sigma;
% fprintf('Bernstein %f\n', double(bound));
bounds(bound_cnts, queue_idx) = double(bound(1));
bound_cnts = bound_cnts + 1;
bounds(bound_cnts, queue_idx) = double(bound(2));
bound_cnts = bound_cnts + 1;


% general Chernoff inequality
% tmp = t;
% t = top_t;
syms x;
RHS = log(1 - qtl);
% Theorem 2.6  & 2.10
% version_ = 2.6;
% a = max(t);
% M = max(- mean(t));
a = 0;
max_M = -inf;
for i = 1 : size(t, 2)
    tmp = max(t(:, i)) - mean(t(:, i));
    if max_M < tmp
        max_M = tmp;
    end
end
M = max_M;
x_ = solve(- x ^ 2 / (2 * (var_Z + sum(a .* a) + M * x / 3)) - RHS);
x_ = double(x_);
% x ^ 2 + b * x + c = 0; c is negative, so two roots must bear opposite
% signs
if x_(1) * x_(2) >= 0
    fprintf('error: should be negative\n');
    exit;
end
if x_(1) > 0
    root_ = x_(1);
else
    root_ = x_(2);
end
bound = mean_Z + root_;
bounds(bound_cnts, queue_idx) = bound;
bound_cnts = bound_cnts + 1;

% Theorem 2.8
version_ = 2.8;
M = max(max(t));
sum_mean_square = sum(mean(t .* t));
% sanity check
% mean_square = mean(t) .* mean(t);
% square_mean = var(t) + mean_square;
% figure;
% hold on;
% plot(square_mean);
% h = plot(mean(t .* t));
% set(h, 'Color', 'r');
x_ = solve(- x ^ 2 / (2 * (sum_mean_square + M * x / 3)) - RHS);
x_ = double(x_);
% x ^ 2 + b * x + c = 0; c is negative, so two roots must bear opposite
% signs
if x_(1) * x_(2) >= 0
    fprintf('error: should be negative\n');
    exit;
end
if x_(1) > 0
    root_ = x_(1);
else
    root_ = x_(2);
end
bound = mean_Z + root_;
bounds(bound_cnts, queue_idx) = bound;
bound_cnts = bound_cnts + 1;

% Theorem 2.11
version_ = 2.11;
n = size(t, 2);
M = zeros(n, 1);
for i = 1 : n
    M(i) = max(t(:, i)) - mean(t(:, i));
end
% sort
M = sort(M);
% try out all k's
min_root = inf;
for k = 1 : n
    sum_diff_square = 0;
    for i = k : n
        sum_diff_square = sum_diff_square + (M(i) - M(k)) ^ 2;
    end
    x_ = solve(- x ^ 2 / (2 * (var_Z + sum_diff_square + M(k) * x / 3)) - RHS);
    x_ = double(x_);
    if x_(1) * x_(2) >= 0
        fprintf('error: should be negative\n');
        exit;
    end
    if x_(1) > 0
        root_ = x_(1);
    else
        root_ = x_(2);
    end
    if min_root > root_
        min_root = root_;
        min_root_k = k;
    end
end
% fprintf('root %f w/ k = %d\n', min_root, min_root_k);
% fprintf('Chernoff bound %f\n', bound);
bound = mean_Z + min_root;
bounds(bound_cnts, queue_idx) = bound;
bound_cnts = bound_cnts + 1;
% recover
% t = tmp;

% end
    path_len_link_bounds{path_len} = bounds;

    queue_idx = queue_idx + 1;
% end % tx_delays_idx
end % cell_seq
bounds(:, queue_idx : end) = [];
save('bounds.mat', 'bounds');


%% %% display
load bounds;
% legend('Ground truth', 'Chebyshev', 'Markov', 'OPMD', 'Normal', 'MAX');
final_bounds = bounds([1, 7, 14, 10, 3, 2], 1:2);
%%
% if path_len == HOPCOUNTS
%     % to facilita view
%     bounds = [bounds bounds bounds];
% end
COLORS = char('-', '--', ':');
STYLES = char('r', 'g', 'b');
MARKERS = char('+', 'o', '*');
color_style_markers = cell(length(COLORS), length(STYLES), length(MARKERS));
for i = 1 : length(COLORS)
    for j = 1 : length(STYLES)
        for k = 1 : length(MARKERS)
            color_style_markers{i, j, k} = [COLORS(i, :) STYLES(j, :), MARKERS(k, :)];
        end
    end
end
MARKERS = [];
close all;
figure;
hold on;
% filter some boundings
% for m = setdiff(1 : BOUND_CNTS, [5 6  8 9 12 17 18 19])
for m = 1 : size(final_bounds)
    h = plot(final_bounds(m, :), color_style_markers{m});
end
%%
%%
% legends = {'Ground truth', 'Chebyshev', 'Markov', 'OPMD', 'Normal', 'Maximum'};
% columnlegend(2, legends, 'NorthWest');
% h_legend = legend(legends);
% set(h_legend, 'FontSize', 40);
%% bar
h = bar(final_bounds');
set(h, 'linewidth', 2);
% color
colors = [
    128 0 0;
    0 0 143;
    100 0 0;
    0 255 0;
    60 0 0;
] / 255;
for i =1 : length(colors)
    set(h(i), 'facecolor', colors(i, :)) % use color name
end

set(gca, 'FontSize', 30, 'yscale', 'log', 'ygrid', 'on', 'xtick', 1:2, 'xticklabel', {'5', '40'});
maximize;
legends = {'Ground truth'; 'Chebyshev'; 'Markov'; 'OPMD'; 'Normal'; 'Maximum'};
legend(legends);
% gridLegend(h, 3);
xlabel('Number of packet-time random variables');
ylabel('Bounds of 90 percentile (ms)');
ylim([0 10^6]);
%%
maximize;
set(gcf, 'Color', 'white'); % Sets figure background
cd('/home/xiaohui/Dropbox/tOR/figures');
export_fig 'bounding' -eps;
export_fig 'bounding' -jpg -zbuffer;
saveas(gcf, 'bounding.fig');
% set(gca, 'FontSize', 30);
% for m = 1 : BOUND_CNTS
%     h = plot(bounds(m, :), color_style_markers{m});
% end
% legend('actual', 'MAX', 'normal', 'exp', 'lognormal', 'p-v', 'Chebyshev', 'TighterChebyshev1',...
%         'TighterChebyshev2', 'OPMD', 'Tail', 'lognormal Tail', 'Hoeffding', 'Markov', ...
%         'Bennett', 'Bernstein1', 'Bernstein2', 'Chernoff 2.6', 'Chernoff 2.8', 'Chernoff 2.11');
% for m = [1 2 3 4 5 6 7 8  17 18 19]
%     h = plot(bounds(m, :), color_style_markers{m});
% end
% legend('actual', 'MAX', 'normal', 'exp', 'lognormal', 'Chebyshev', 'TighterChebyshev1',...
%         'TighterChebyshev2', 'Chernoff 2.6', 'Chernoff 2.8', 'Chernoff 2.11');
% legend('Ground truth', 'Chebyshev', 'Markov', 'OPMD', 'Normal', 'MAX');

% title(['bounding comparisons']);
% xlabel('e2e queue level seq#');
% % xlabel('pkt seq#');
% ylabel([num2str(qtl * 100) ' percentile of sum']);

% saveas(h, ['bounding comparisons EWMAV Chernoff 005.fig']);
% saveas(h, ['bounding comparisons Chernoff 0.5% Outlier Removal.fig']);
% saveas(h, ['bounding comparisons Chernoff 0.5% Outlier Removal.jpg']);
% saveas(h, ['bounding comparisons vs time serials' num2str(sum(hop_queue_level)) '.fig']);
% saveas(h, ['bounding comparisons vs time serials' num2str(sum(hop_queue_level)) '.jpg']);
% end

%% tight Chebyshev
clc;
qtl = .9;
for i = 1 : size(tx_delays, 2)
    t = tx_delays(:, i);
    fprintf('column %d of quantile %f\n', i, quantile(t, qtl));
    
    fprintf('Chebyshev bound: %f\n', mean(t) + sqrt(qtl / (1 - qtl)) * std(t));
    sigma2 = mean(t);
    tau4 = var(t) + mean(t) ^ 2;
    lo = sigma2;
    hi = tau4 / sigma2;
    fprintf('range: [%f, %f]\n', lo, hi);
    % 1
    x = sigma2 / (1 - qtl);
    fprintf('in range: %f\n', x);

    syms x_;
    x_ = solve((tau4 - sigma2 ^ 2) / (tau4 + x_ ^ 2 - 2 * sigma2 * x_) - (1 - qtl));
    x_ = double(x_);
    fprintf('upper: %f, %f\n\n', x_(1), x_(2));
end