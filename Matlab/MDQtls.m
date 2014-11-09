%% MD verification 1)
SRC_ID = 76;
%use adaptive estimation
adaptive = true;
%%
t = debugs;
t = t(t(:, 3) == 20 & t(:, 2) == SRC_ID, :);
tmp = t(:, 8) + t(:, 9);
MD_samples = tmp;
t = [tmp t(:, 10)];
len = size(t, 1);
qtls = zeros(len, 2);
p = 230 / 256;
for i = 1 : len
    qtls(i, 1) = quantile(t(1 : i, 1), p);
    qtls(i, 2) = t(i, 2);
end
first_idx = find(qtls(:, 2) ~= 65535);
qtls = qtls(first_idx : end, :);
figure;
%actual quantile vs estimated
plot(qtls);
%% samples agreement
e2e_samples = pkt_delays(:, 2);
figure;
% MD_samples = MD_samples(1 : 6000);
plot(MD_samples);
hold on;
h = plot(e2e_samples);
set(h, 'Color', 'red');
legend('MD samples', 'e2e samples');
%% 2) sample distribution agreement
e2e_samples = pkt_delays(:, 2);
figure;
h = qqplot(MD_samples, e2e_samples);%, (0 : 0.1 : 1));
xlabel('MD samples');
ylabel('e2e samples');
% saveas(h, 'qqplot: MD samples vs e2e samples', 'fig');
% saveas(h, 'qqplot: MD samples vs e2e samples', 'jpg');
%% quantile comparison
x = max(MD_samples);
y = max(e2e_samples);
hi = max(x, y);
x = 0 : 1 : hi;
figure;
plot(x, x, 'Color', 'red');
hold on;

MD_qtls = quantile(MD_samples, 0.1 : 0.1 : 1);
e2e_qtls = quantile(e2e_samples, 0.1 : 0.1 : 1);
plot(MD_qtls, e2e_qtls, 'Marker', 'o');
%% 3) actual qtl vs MD qtl
p = 230 / 256;
d = pkt_delays;
s = srcPkts(:, [4 9]);

% seqno_MDQtls = seqno_MDQtls(seqno_MDQtls(:, 2) ~= 65535, :);
len = size(d, 1);
step = 1;
if mod(len, step) == 0
    errs = zeros(len / step, 3);
else
    errs = zeros(len / step + 1, 3);
end
% seqno in received pkts
for i = 1 : step : len
    seqno_src = find(s(:, 1) == d(i, 1));
    if isempty(seqno_src)
        fprintf('Error: pkt %d not found\n', i);
        continue;
    end
    % current qtl estimation
    est_qtl_value = s(seqno_src, 2);
    
    if ~adaptive
        now = d(1 : i, 2);
    else
        if i < 100
            now = d(1 : i, 2);
        else
            now = d(i - 99 : i, 2);
        end
    end
    actual_qtl_value = quantile(now, p);
    est_qtl = length(find(now <= est_qtl_value)) / length(now);
    errs(i, :) = [actual_qtl_value est_qtl_value est_qtl];
end
% start from valid
last_invalid = find(errs(:, 2) == 65535);
last_invalid = last_invalid(end);
errs = errs(last_invalid + 1: end, :);

period = 250;
figure;
% first_valid_seqno = find(seqno_MDQtls(:, 2) ~= 65535, 1);
hold on;
% errs = errs(100 : end, :);
plot(errs(:, 1));
h = plot(errs(:, 2));
set(h, 'Color', 'Red');
legend('actual', 'estimated');
title(['actual vs estimated qtl value ' num2str(period) ' ms']);
saveas(h, 'actual vs estimated qtl value', 'fig');
saveas(h, 'actual vs estimated qtl value', 'jpg');
% quantify err
len = size(errs, 1);
rmse = zeros(len, 1);
for i = 1 : len
    rmse(i) = (errs(i, 1) - errs(i, 2)) ^ 2;
end
fprintf('sqaured error: %f, RMSE: %f\n', sum(rmse), sqrt(sum(rmse) / len));

figure;
hold on;
plot(repmat(p, len, 1));
m = plot(errs(:, 3));
title(['actual vs estimated qtl ' num2str(period) ' ms']);
saveas(m, 'actual vs estimated qtl', 'fig');
saveas(m, 'actual vs estimated qtl', 'jpg');

%%
% seqnos = pkt_delays(:, 1);
% len = length(seqnos);
% pdr = zeros(len, 1);
% for i = 1 : len
%     pdr(i) = i / seqnos(i);
% end
% figure;
% plot(pdr);