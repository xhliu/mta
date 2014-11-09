%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   @ Author: Xiaohui Liu (whulxh@gmail.com)
%   @ Date: 10/25/2011
%   @ Description: convergence speed of P2 for various samples like path
%   delay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% estimation error of P2
p = 222 : 2 : 238;
POI = floor(length(p) / 2) + 1;
p = p / 256;
STABLE_IDX = 100;

% samples = t(:, 8);
% estimates = t(:, 10);
samples = path_delays(1000:2000);
% quantile level err, absolute err, relative err
qtl = zeros(size(samples, 1), 3);
qtl_cnts = 1;

step = 1;

% P2 needs at least (2 * length(p) + 3) samples to jump start
for i = (2 * length(p) + 3) : step : size(samples, 1) % (2 * length(p) + 3) : 1 : size(samples, 1)
    tmp_samples = samples(1 : i);

    [p2_ext_ests, adjusts] = P2QtlEst_Ext(tmp_samples, p);
    estimated_qtl = length(find(tmp_samples <= p2_ext_ests(POI))) / length(tmp_samples);
    actual_values = quantile(tmp_samples, p);
    qtl(qtl_cnts, :) = [estimated_qtl, p2_ext_ests(POI) - actual_values(POI), ...
                        (p2_ext_ests(POI) - actual_values(POI)) / actual_values(POI)];

%     p2_ext_ests = estimates(i);
%     estimated_qtl = length(find(tmp_samples <= p2_ext_ests)) / length(tmp_samples);
%     actual_values = quantile(tmp_samples, p);
%     qtl(qtl_cnts, :) = [estimated_qtl - p(POI), p2_ext_ests - actual_values(POI), ...
%                         (p2_ext_ests - actual_values(POI)) / actual_values(POI)];
    
    qtl_cnts = qtl_cnts + 1;
end

qtl(qtl_cnts : end, :) = [];
% disp
figure;
hold on;
plot(repmat(.9, 1, length(qtl)));
set(gca, 'FontSize', 40);
xlabel('Number of samples');
ylabel('Estimated quantile');
title('');
%
maximize;
set(gcf, 'Color', 'white'); % Sets figure background
cd('/home/xiaohui/Dropbox/tOR/figures');
export_fig 'qtl_est_converge' -eps;
export_fig 'qtl_est_converge' -jpg -zbuffer;
saveas(gcf, 'qtl_est_converge.fig');
%%
figure;
h = plot(qtl(:, 2));
title('absolute error');
saveas(h, 'estimated quantile value - actual quantile value', 'fig');
saveas(h, 'estimated quantile value - actual quantile value', 'jpg');

figure;
h = plot(qtl(:, 3));
title('relative error');
saveas(h, 'relative error: estimated quantile value - actual quantile value', 'fig');
saveas(h, 'relative error: estimated quantile value - actual quantile value', 'jpg');
% figure;
% hist(abs(qtl(STABLE_IDX : end) - p(POI)));
% plot(repmat((p(POI - 1) + p(POI)) / 2, 1, length(qtl)));