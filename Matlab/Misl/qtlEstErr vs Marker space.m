%% 
%p = .8 : .05 : .95; failure case
% p = 232 : 6 : 250;
% p = p / 256;
% IX = find(p == .9);
% POI = IX(1);
spaces = [0.2 0.1 0.05 0.02];
errs = cell(length(spaces), 1);

% each space
for j = 1 : length(spaces)
% marker_cnts = 2;
% space = (1 - 0.7) / (marker_cnts - 1);
% p = 0.7 : space : 1.0;
% POI = marker_cnts / 2;
space = spaces(j);
p = 0.8 : space : 1.0;
POI = ceil(0.2 / space) + 1;
STABLE_IDX = 100;

fprintf('processing space %d ....\n', j);
% quantile level err, absolute err, relative err
qtl = zeros(size(samples, 1), 3);
qtl_cnts = 1;

% each link
for k = 1 : size(link_delay_samples, 1)
fprintf('processing link %d ....\n', k);
samples = link_delay_samples{k};
if size(samples, 1) < STABLE_IDX || size(samples, 1) > 1000
    continue;
end
% linkDelayEsts = tmp(:, 8);

% P2 needs at least (2 * length(p) + 3) samples to jump start
for i = STABLE_IDX : 10 : size(samples, 1) % (2 * length(p) + 3) : 1 : size(samples, 1)
    tmp_samples = samples(1 : i);
%     tmp_samples = [(10 : 30)'; tmp_samples];
    [p2_ext_ests, adjusts] = P2QtlEst_Ext(tmp_samples, p);
%     p2_etx_ests = linkDelayEsts(i);
    
    estimated_qtl = length(find(tmp_samples <= p2_ext_ests(POI))) / length(tmp_samples);
    actual_values = quantile(tmp_samples, p);
    qtl(qtl_cnts, :) = [estimated_qtl - p(POI), p2_ext_ests(POI) - actual_values(POI), ...
                        (p2_ext_ests(POI) - actual_values(POI)) / actual_values(POI)];
    qtl_cnts = qtl_cnts + 1;
    
%     if actual_values(POI) ~= 0 
%         error = (p2_etx_ests - actual_values(POI)) / actual_values(POI);
% %         error = (p2_etx_ests(POI) - actual_values(POI)) / actual_values(POI);
%         qtl(qtl_cnts, :) = error;
%         qtl_cnts = qtl_cnts + 1;
%     end
end

end
qtl(qtl_cnts : end, :) = [];
% if qtl(end) > 0.3
%     fprintf('error %f \n', error);
% end
% figure;
% hold on;
% plot(qtl);
% plot(repmat(p(POI), 1, length(qtl)));
% figure;
% hist(abs(qtl(STABLE_IDX : end) - p(POI)));
errs{j} = qtl;
% plot(repmat((p(POI - 1) + p(POI)) / 2, 1, length(qtl)));
end

%% disp
group = zeros(0);
errsDisp = zeros(0);
for i = 1 : size(errs, 1)
    group = [group ; ones(size(errs{i}(:, 1))) + i - 1];
    errsDisp = [errsDisp ; errs{i}(:, 1)];
end
figure('name', 'P^2 Estimation Error of 80 Percentile');
set(gca, 'FontSize', 30, 'YGrid', 'on');
set(gca, 'XTick', 1 : 4, 'XTickLabel', 100 * spaces / 2);
boxplot(errsDisp * 100, group);
% plot(errs * 100)
title('P^2 Estimation Error of 80 Percentile');
xlabel('Marker Interval between 60 and 100 percentile (%)');
ylabel('Estimation Error (%)');