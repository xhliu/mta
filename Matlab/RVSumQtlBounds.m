%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Xiaohui Liu
%   6/22/2011
%   Function: impirically measure the tightness of all types of bounding of
%   quantile of sum of random variables
%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% prepare samples
t = tx_delays;
link_cnts = size(t, 2);
% [bounding tech, links]
BOUND_CNTS = 11;
bounds = zeros(BOUND_CNTS, link_cnts - 1);

for i = 1 : (link_cnts - 1)
    fprintf('\n\nround %d ....\n', i);
    bound_cnts = 1;
%% actual quantile
X = t(:, i);
Y = t(:, i + 1);
Z = X + Y;
% quantile concerned
qtl = 0.9;
fprintf('%f quantile of sum: %f\n', qtl, quantile(Z, qtl));
bounds(bound_cnts, i) = quantile(Z, qtl);
bound_cnts = bound_cnts + 1;
%% MAX
fprintf('max of sum: %f\n', max(Z));
bounds(bound_cnts, i) = max(Z);
bound_cnts = bound_cnts + 1;
%% parametric
%% normal
bound = norminv(qtl, mean(Z), std(Z));
bounds(bound_cnts, i) = bound;
bound_cnts = bound_cnts + 1;
%% exponential
bound = expinv(qtl, mean(Z));
bounds(bound_cnts, i) = bound;
bound_cnts = bound_cnts + 1;
%% lognormal
% mu = mean(log(X)) + mean(log(Y));
% sigma = std(log(X)) + std(log(Y));
mu = mean(log(Z));
sigma = std(log(Z));
bound = logninv(qtl, mu, sigma);
bounds(bound_cnts, i) = bound;
bound_cnts = bound_cnts + 1;
%% Chebyshev
mu = mean(X) + mean(Y);
sigma = std(X) + std(Y);
bound = mu + sqrt(qtl / (1 - qtl)) * sigma;
fprintf('Chebyshev bound: %f\n', bound);
bounds(bound_cnts, i) = bound;
bound_cnts = bound_cnts + 1;
%% OPMD
min_bound = inf;
for p = qtl : 0.1 : 1
    % p * q = qtl
    q = qtl / p;
    sum = quantile(X, p) + quantile(Y, q);
    if min_bound > sum
        min_bound = sum;
    end
end
fprintf('OPMD bound: %f\n', min_bound);
bounds(bound_cnts, i) = min_bound;
bound_cnts = bound_cnts + 1;
%% tail probability (refer to asymptotic tail probabilities sum dependent subexponential random variables)
% search min bound c such that F_X(c) + F_Y(c) >= (1 + qtl)
len = length(X);
lo = min(min(X), min(Y));
hi = max(max(X), max(Y));

% version 1: empirical CDF
found = false;
for c =  lo: .1 : hi
    qtl_1 = length(find(X <= c)) / len;
    qtl_2 = length(find(Y <= c)) / len;
    if (qtl_1 + qtl_2) >= (1 + qtl)
        found = true;
        break;
    end
end
if found
    fprintf('tail probability bound: %f\n', c);
else
    fprintf('error: c does exist\n');
end
bounds(bound_cnts, i) = c;
bound_cnts = bound_cnts + 1;

% version 2: assume lognormal
parmhat_x = lognfit(X);
parmhat_y = lognfit(Y);
found = false;
for c =  lo: .1 : hi
    qtl_1 = logncdf(c, parmhat_x(1), parmhat_x(2));
    qtl_2 = logncdf(c, parmhat_y(1), parmhat_y(2));
    if (qtl_1 + qtl_2) >= (1 + qtl)
        found = true;
        break;
    end
end
if found
    fprintf('tail probability bound: %f\n', c);
else
    fprintf('error: c does exist\n');
end
bounds(bound_cnts, i) = c;
bound_cnts = bound_cnts + 1;
%% Hoeffding
a1 = min(X);
b1 = max(X);
a2 = min(Y);
b2 = max(Y);

bound = mean(X) + mean(Y) + sqrt(- log(1 - qtl) * ((b1 - a1) ^ 2 + (b2 - a2) ^ 2) / 2);
fprintf('Hoeffding bound: %f\n', bound);
bounds(bound_cnts, i) = bound;
bound_cnts = bound_cnts + 1;
%% Markovian
bound = (mean(X) + mean(Y)) / (1 - qtl);
fprintf('Markovian bound: %f\n', bound);
bounds(bound_cnts, i) = bound;
bound_cnts = bound_cnts + 1;
end
save('bounds.mat', 'bounds');
%% display
ColorSet = varycolor(BOUND_CNTS);
figure;
% set(gca, 'FontSize', 30);
hold on;
for m = 1 : BOUND_CNTS
    h = plot(bounds(m, :), 'Color', ColorSet(m,:));
end
legend('actual', 'MAX', 'normal', 'exp', 'lognormal', 'Chebyshev', 'OPMD', 'Tail', ...
        'lognormal Tail', 'Hoeffding', 'Markov');
xlabel('link seq#');
ylabel('90 percentile of sum');
saveas(h, 'bounding comparisons.fig');
saveas(h, 'bounding comparisons.jpg');