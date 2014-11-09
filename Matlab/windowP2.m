%% adaptive quantile estimation
LEN = 6000;
p = 222 : 2 : 238;
POI = floor(length(p) / 2) + 1;
p = p / 256;
MIN_P2_SAMPLES = 2 * length(p) + 3; %50

distr_family = 'emp'; %'exp';
% samples = e2edelay_samples_250ms;
% samples = pkt_delays(:, 2);
% samples = ones(1000, 1) * 1000;
% quantile level err, absolute err, relative err

ALPHA = 1 / 16;
%only remember last one seems optimal
GAMMA = 1;
% # of consecutive samples out of range to claim change
MIN_CHANGE_CNTS = 5;
NUM = 4;
step = 1;
%% generate synthetic samples
t = e2edelay_samples_500_100ms;
samples = t;
boundary = 500;
theory_qtls = [repmat(quantile(t(1 : boundary), 0.9), boundary, 1);
               repmat(quantile(t(boundary + 1 : end), 0.9), length(t) - boundary, 1)];
%%
samples = pkt_delays(:, 2);           
theory_qtls = repmat(quantile(samples, 0.9), length(samples), 1);
%% lognormal
avg = 2890;
var = 564;
mu = log(avg) - log(1 + var / (avg ^ 2)) / 2;
delta = sqrt(log(1 + var / (avg ^ 2)));
samples = random('logn', mu, delta, LEN / 3, 1);

avg = 554;
var = 428;
mu = log(avg) - log(1 + var / (avg ^ 2)) / 2;
delta = sqrt(log(1 + var / (avg ^ 2)));
samples = [samples; random('logn', mu, delta, LEN / 3, 1)];

avg = 84.7;
var = 31.2;
mu = log(avg) - log(1 + var / (avg ^ 2)) / 2;
delta = sqrt(log(1 + var / (avg ^ 2)));
samples = [samples; random('logn', mu, delta, LEN / 3, 1)];
% mu = [repmat(1000, LEN, 1); repmat(500, LEN, 1)];
% samples = zeros(LEN, 1);
% theoretical quantile
theory_qtls = repmat(2920.5, LEN / 3, 1);
theory_qtls = [theory_qtls; repmat(580.7, LEN / 3, 1)];
theory_qtls = [theory_qtls; repmat(91.96, LEN / 3, 1)];
%% exponential
mu = 554;
samples = random('exp', mu, LEN / 3, 1);
theory_qtls = ones(LEN  / 3, 1) * 2.3 .* mu;
mu = 1000;
samples = [samples; random('exp', mu, LEN / 3, 1)];
theory_qtls = [theory_qtls; ones(LEN  / 3, 1) * 2.3 .* mu];
mu = 84;
samples = [samples; random('exp', mu, LEN / 3, 1)];
theory_qtls = [theory_qtls; ones(LEN  / 3, 1) * 2.3 .* mu];
mu = [[repmat(554, LEN / 3, 1); repmat(1000, LEN / 3, 1)]; repmat(84, LEN / 3, 1)];
%%
figure;
set(gca, 'FontSize', 30);
title(['time serials ' distr_family]);
h = plot(samples);
saveas(h, ['time serials ' distr_family], 'fig');
saveas(h, ['time serials ' distr_family], 'jpg');
% [estimated quantile value; estimated qtl]
qtl = zeros(size(samples, 1), 2);
% plot(qtls);
% hold on;
% plot(ones(LEN, 1) * 2.3 .* mu);

%% fixed window size and fixed weight
qtl_cnts = 1;
WND_SIZE = 50;
p2_ext_est = 65535;
for i = 1 : step : size(samples, 1)
    if i > WND_SIZE
        tmp_samples = samples(i - WND_SIZE + 1 : i);
    else
        tmp_samples = samples(1 : i);
    end
    if 0 == mod(i, WND_SIZE)
%         [p2_ext_ests, adjusts] = P2QtlEst_Ext(tmp_samples, p);
        p2_ext_ests = quantile(tmp_samples, p);
        p2_ext_est = p2_ext_ests(POI);
    end
    qtl(i) = p2_ext_est;
%     estimated_qtl = length(find(tmp_samples <= p2_ext_ests(POI))) / length(tmp_samples);
%     actual_values = quantile(tmp_samples, p);
%     qtl(qtl_cnts, :) = [actual_values(POI), p2_ext_est];
end
%% adaptive window size (AIMD), fixed weight
% clc;
first_change = true;
qtl_cnts = 1;
% range of window size
WMIN = 100;
WMAX = 16 * WMIN;
% change detection

% states for current window
wnd_idx = 0;
sample_mean = 0;
sample_std = 0;
change_cnts = 0;
wnd_size = WMIN;

sampled = false;
% EWMA of estimated qtl
p2_ext_est = NaN;
% P2 needs at least (2 * length(p) + 3) samples to jump start
for i = (2 * length(p) + 3) : step : size(samples, 1)
    % ready to compute the current window of samples
    if wnd_idx >= (wnd_size - 1)
%         fprintf('window boundary at %d w/ size %d, changes %d, mean %f, std %f\n', i, wnd_size, change_cnts, sample_mean, sample_std);
        sampled = true;
        tmp_samples = samples(i - wnd_size + 1 : i);
        [p2_ext_ests, adjusts] = P2QtlEst_Ext(tmp_samples, p);
        % last estimation
        if isnan(p2_ext_est)
            p2_ext_est = p2_ext_ests(POI);
        else
            p2_ext_est = p2_ext_est * (1 - GAMMA) + p2_ext_ests(POI) * GAMMA;
        end

        % ready for next window
        wnd_idx = 0;
%         sample_mean = 0;
%         sample_std = 0;
        change_cnts = 0;
        % addictively increase window size
        wnd_size = wnd_size + 10;
        if wnd_size > WMAX
            wnd_size = WMAX;
        end
    else
        % in the middle of a window
        sample = samples(i);
        % detect possible changes; valid only after some samples
        if ((sample > (sample_mean + 3 * sample_std)) || (sample < (sample_mean - 3 * sample_std)))
            % drastically changes
            change_cnts = change_cnts + 1;
            if change_cnts >= MIN_CHANGE_CNTS
                lo = i - wnd_size + 1;
                if lo < 1
                    lo = 1;
                end
                tmp_samples = samples(lo : i - change_cnts);
                if length(tmp_samples) >= (2 * length(p) + 3)
                    % compute current window if large enough, excluding outliers
                    sampled = true;
                    [p2_ext_ests, adjusts] = P2QtlEst_Ext(tmp_samples, p);
                    % last estimation
                    if isnan(p2_ext_est)
                        p2_ext_est = p2_ext_ests(POI);
                    else
                        p2_ext_est = p2_ext_est * (1 - GAMMA) + p2_ext_ests(POI) * GAMMA;
                    end
                end
                wnd_idx = 0;
                
                change_cnts = 0;
                % multiplicatively decrease window size
                wnd_size = floor(wnd_size / 2);
                if wnd_size < WMIN
                    wnd_size = WMIN;
                end
                fprintf('window shrinks at %d to size %d, mean %f, std %f\n', i, wnd_size, sample_mean, sample_std);
%                 continue;
            end
        else
            % normal
            change_cnts = 0;
        end
        wnd_idx = wnd_idx + 1;
    end
    %update mean and std
    diff = sample - sample_mean;
    sample_std = sample_std * (1 - ALPHA) + abs(diff) * ALPHA;
    sample_mean = sample_mean * (1 - ALPHA) + sample * ALPHA;
    if ~sampled
        continue;
    end
    % compare using the last 100 samples
    tmp_samples = samples(i - WMIN + 1 : i);
%     estimated_qtl = length(find(tmp_samples <= p2_ext_ests(POI))) / length(tmp_samples);
    actual_values = quantile(tmp_samples, p);
    
    %latest estimation
    if wnd_idx >= (2 * length(p) + 3)
        [p2_ext_ests, adjusts] = P2QtlEst_Ext(samples(i - wnd_idx : i), p);
        beta = wnd_idx / (wnd_size - 1);
%         beta = 1;
    else
        beta = 0;
    end
    % sanity
    if beta > 1
        fprintf('err: %d, %d, %d\n', i, wnd_idx, wnd_size);
    end
    qtl_est = p2_ext_est * (1 - beta) + p2_ext_ests(POI) * beta;
    
    % debug using exponential
%     if mu(i) == 500 && first_change
    if i > 2000 && i < 2010
        first_change = false;
        fprintf('quantile changes @ %d w/window size %d index %d, change number %d, mean %f, std %f\n', ...
                i, wnd_size, wnd_idx, change_cnts, sample_mean, sample_std);
    end
%     qtl(qtl_cnts, :) = [actual_values(POI), qtl_est];
%     exponential
%     qtl(qtl_cnts, :) = [mu(i) * 2.3, qtl_est];
%     lognormal
    qtl(qtl_cnts, :) = [qtls(i), qtl_est];
    qtl_cnts = qtl_cnts + 1;
end
qtl(qtl_cnts : end, :) = [];
% adaptive window size & weight

%% adapt according to theoretical quantile
clc;
tmp = [];
WND_SIZE = 50;

wnd_size = 0;
idx = 0;
% change_cnts = 0;
sample_std = 0;
sample_mean = 0;
last_qtl_est = 0;
len = length(samples);
qtl = zeros(len, 1);
for i = 1 : len
%     sample = samples(i);
    wnd_size = wnd_size + 1;
    %debug
%     if i >= LEN / 3 && i <= (LEN / 3 + 10)
%         fprintf('@%d, change # %d, sample %f, mean %f, std %f\n', i, change_cnts, samples(i), sample_mean, sample_std);
%     end

    if mod(i, WND_SIZE) == 0
        sample = mean(samples(i - WND_SIZE + 1 : i));
        fprintf('@%d, sample %f, mean %f, std %f\n', i, sample, sample_mean, sample_std);
        tmp = [tmp; sample, sample_mean, sample_std];
        idx = idx + 1;
        if 1 == idx
            sample_mean = sample;
        else
            if 2 == idx
                sample_std = abs(sample - sample_mean);
            else
                % if samples change drastically
                %       reset estimator
                % else
                %       take the sample
                if ((sample > (sample_mean + NUM * sample_std)) || (sample < (sample_mean - NUM * sample_std)))
            %         change_cnts = change_cnts + 1;
            %         if change_cnts >= MIN_CHANGE_CNTS
            %             %reset
                        fprintf('estimator resets @ %d with size %d\n', i, wnd_size);
                        % excluding the most recent MIN_CHANGE_CNTS samples but the last one
                        idx = 0;
                        last_qtl_est = quantile(samples(i - wnd_size + 1 : i), 0.9);
                        wnd_size = 1;
%                         change_cnts = 0;
%                         sample_std = 0;
%                         sample_mean = sample;
            %         end
            %     else
            %         change_cnts = 0;
                else
                %update mean and std
                diff = sample - sample_mean;
                sample_std = sample_std * (1 - ALPHA) + abs(diff) * ALPHA;
                sample_mean = sample_mean * (1 - ALPHA) + sample * ALPHA;
                end
            end
        end
    end
    % final qtl
    if wnd_size < MIN_P2_SAMPLES
%         qtl_est = max(samples(i - wnd_size + 1 : i));
        qtl_est = last_qtl_est;
    else
%         qtl_est = P2QtlEst_Ext(samples(i - wnd_size + 1 : i), 0.9);
        qtl_est = quantile(samples(i - wnd_size + 1 : i), 0.9);
%         last_qtl_est = qtl_est;
    end
    qtl(i) = qtl_est;
end
%% fixed window size and adaptive weight
% clc;
qtl_cnts = 1;
WND_SIZE = 200;
fprintf('window size %d\n', WND_SIZE);
% MIN_P2_SAMPLES = 100;
p2_ext_est = 65535;
for i = 1 : step : size(samples, 1)
%     if i > WND_SIZE
%         tmp_samples = samples(i - WND_SIZE + 1 : i);
%     else
%         tmp_samples = samples(1 : i);
%     end
    wnd_size = mod(i, WND_SIZE);
    if 0 == wnd_size
        wnd_size = WND_SIZE;
    end
    if wnd_size < MIN_P2_SAMPLES
        alpha = 0;
    else
        alpha = (wnd_size - MIN_P2_SAMPLES + 1) / (WND_SIZE - MIN_P2_SAMPLES + 1);
%         alpha = alpha ^ 2;
    end
    if 65535 == p2_ext_est
        alpha = 1;
    end
%     alpha = 0;
    if 0 == mod(i, WND_SIZE)
        tmp_samples = samples(i - WND_SIZE + 1 : i);
%         [p2_ext_ests, adjusts] = P2QtlEst_Ext(tmp_samples, p);
        p2_ext_ests = quantile(tmp_samples, p);
        p2_ext_est = p2_ext_ests(POI);
%         fprintf('%d, %d, %f, %f, %f\n', i, wnd_size, alpha, p2_ext_est, quantile(samples(i - wnd_size + 1 : i), .9));
    end
    estimated_qtl_value = p2_ext_est * (1 - alpha) + quantile(samples(i - wnd_size + 1 : i), .9) * alpha;
    % synthetic samples
%     estimated_qtl = cdf('exp', estimated_qtl_value, mu(i));
    % empirical samples
    if i <= boundary
        tmp_samples = samples(1 : boundary);
    else
        tmp_samples = samples(boundary + 1 : end);
    end
    estimated_qtl = length(find(tmp_samples <= estimated_qtl_value)) / length(tmp_samples);
%     actual_values = quantile(tmp_samples, p);
    qtl(i, :) = [estimated_qtl_value estimated_qtl];
end
%% display
t = [qtl theory_qtls];
first_idx = find(t(:, 1) ~= 65535);
t = t(first_idx + 1 : end, :);
% figure;
% title('samples');
% plot(samples);
% disp
figure;
set(gca, 'FontSize', 30);
title(['actual vs estimated qtl value ' distr_family]);
hold on;
plot(t(:, 1));
h = plot(t(:, 3));
set(h, 'Color', 'red');
legend('Estimation', 'Actual');
saveas(h, ['actual vs estimated qtl value ' distr_family], 'fig');
saveas(h, ['actual vs estimated qtl value ' distr_family], 'jpg');

figure;
set(gca, 'FontSize', 30);
title(['actual vs estimated qtl ' distr_family]);
hold on;
plot(t(:, 2));
h = plot(repmat(p(POI), size(t, 1), 1));
set(h, 'Color', 'red');
legend('Estimation', 'Actual');
saveas(h, ['actual vs estimated qtl ' distr_family], 'fig');
saveas(h, ['actual vs estimated qtl ' distr_family], 'jpg');
%% quantify err
len = size(t, 1);
errs = zeros(len, 1);
for i = 1 : len
    errs(i) = (t(i, 1) - t(i, 2)) ^ 2;
end
fprintf('sqaured error: %f, RMSE: %f\n', sum(errs), sqrt(sum(errs) / len));

%% compare this P2 w/ counterpart in T2
% t = debugs;
% t = t(t(:, 3) == 20 & t(:, 2) == SRC_ID, 10);
% % t2_qtl = Packet_Log(:, 10);
% t2_qtl = t;
% lo = size(t2_qtl, 1) - size(qtl, 1) + 1;
% figure;
% title('Matlab P2 vs T2 P2')
% plot(t2_qtl(lo: end));
% hold on;
% h = plot(qtl(:, 2));
% set(h, 'Color', 'red');