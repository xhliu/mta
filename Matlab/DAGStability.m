%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Xiaohui Liu (whulxh@gmail.com)
%   Date:   11/14/2011
%   Function: analyze the stability of DAG, both ETX & ML
%               job 6480(6478 shorter)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DAG stability
DBG_FLAG = 21;
t = debugs;
t = t(t(:, 3) == DBG_FLAG, :);
s = t(t(:, 5) == 0, :);
r = t(t(:, 5) == 1, :);
%% [node predecessors]
% ideally, one ETX DAG corresponds to one ML DGA, but log may get lost
len = min(size(s, 1), size(r, 1));
etx_dags = zeros(len, 11);
ml_dags = zeros(len, 11);
for i = 1 : len
    etx_dags(i, 1) = s(i, 2);
    ml_dags(i, 1) = r(i, 2);
    idx = 2;
    for j = 6 : 10
        etx_dags(i, idx : idx + 1) = [floor(s(i, j) / 256), mod(s(i, j), 256)];
        ml_dags(i, idx : idx + 1) = [floor(r(i, j) / 256), mod(r(i, j), 256)];
        idx = idx + 2;
    end
end

%% relative change
t = ml_dags;
results = zeros(size(t, 1) - 1, 1);
for i = 1 : (size(t, 1) - 1)
    last = t(i, 2 : end);
    last = last(last ~= 0);
    curr = t(i + 1, 2 : end);
    curr = curr(curr ~= 0);
    
    x = intersect(last, curr);
    results(i) = size(x, 2) / size(last, 2);
end
figure;
cdfplot(results);

%% coherence
MIN_SAMPLE_SIZE = 1000;
% d = etx_dags;
d = ml_dags;
nodes = unique(d(:, 1));
wnds = [];
for k = 1 : size(nodes, 1)
    t = d(d(:, 1) == nodes(k), :);
    fprintf('%d: node %d w/ %d entries\n', k, nodes(k), size(t, 1));
    if size(t, 1) <= MIN_SAMPLE_SIZE
        continue;
    end
    wnd = [];
    i = 1;
    while i < size(t, 1)
        s = t(i, 2:end);
        s = sort(s);

        for j = (i + 1) : size(t, 1)
            r = t(j, 2:end);
            r = sort(r);
            if ~all(s == r)
                break;
            end
        end
        wnd = [wnd; j - i];

        i = j;
    end
    wnds = [wnds; median(wnd)];
end
figure;
% boxplot(wnds);

%%
% data = cell(2, 1);
data{2} = wnds;
