%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Xiaohui Liu (whulxh@gmail.com)
%   Date:   9/28/2011
%   Function: prepares figures for display
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% deadline success ratio
cd ~/Dropbox/tOR/figures/;
% protocols = {'MTA'; 'M-DB'; 'M-mDQ'; 'mDQ'; 'M-FIFO'; 'M-MD';};
% 'm' for min
protocols = {'MTA'; 'MCMP'; 'MM'; 'MM-CD'; 'SDRCS'; 'CTP';};
%% Deadline success ratio
metric = 'Deadline success ratio';
PROTOCOL_CNTS = size(protocols, 1);
pdr = cell(PROTOCOL_CNTS, 1);
idx = 1;
% MTA
t = [
0.910584638899503
0.977879213483146
0.974232663887836
0.935282651072125
0.934402852049911
0.959104938271605
0.937572702597906
0.965596330275229
0.922779922779923
0.91348402182385
0.98932384341637    
];
pdr{idx} = t;
idx = idx + 1;

% MCMP
t = [
0.108377721447369
0.265318916399909
0.271623111652553
0.246891651865009
0.298796585379943
0.328089037424725
0.182734385511885
0.421233188680233
0.260595136037918
0.333162350324607
0.253613666228647  
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED
t = [
0
0
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED-CD
t = [
0
0
];
pdr{idx} = t;
idx = idx + 1;

% SDRCS
t = [
0.03130643405243
0.001488469601677
0.074303592799124
0.596304849884527
0.464697138610182
0.303535776972212
0.000995520159283
0.040557869566894
0.009988014382741
0.015151515151515
];
pdr{idx} = t;
idx = idx + 1;

% CTP
t = [
0.449692163205677
0.065714400939663
0.510553738838119
0.998509131569139
0.109437201984686
0.176602924634421
0.219823899306485
0.147677199618977
0.60344850163524
0.410137940270524
];
pdr{idx} = t;
idx = idx + 1;

% display
data = pdr;
group = zeros(0);
dataDisp = zeros(0);
for i = 1 : size(data, 1)
    group = [group ; ones(size(data{i})) + i - 1];
    dataDisp = [dataDisp ; data{i}];
end
figure('name', metric);
% title([metric 'for different protocols']);
h = boxplot(dataDisp * 100, group, 'notch', 'on');
set(gca, 'FontSize', 30, 'YGrid', 'on', 'xtick', 1:size(protocols, 1), 'XTickLabel', protocols, 'ytick', 0:10:100);
set(gca, 'FontSize', 30, 'YGrid', 'on');
%xlabel('Protocols');
ylabel([metric ' (%)']);
%
maximize;
set(gcf, 'Color', 'white'); % Sets figure background
export_fig 'dcr_peers_indriya_sparse' -eps;
export_fig 'dcr_peers_indriya_sparse' -jpg -zbuffer;
saveas(gcf, 'dcr_peers_indriya_sparse.fig');
% saveas(h, 'foo.fig');
% xticklabel_rotate(1 : size(protocols, 1), 90, protocols);

%% PDR
metric = 'Packet delivery ratio';
PROTOCOL_CNTS = size(protocols, 1);
pdr = cell(PROTOCOL_CNTS, 1);
idx = 1;
% MTA
t = [
0.910584638899503
0.977879213483146
0.974232663887836
0.935282651072125
0.934402852049911
0.959104938271605
0.937572702597906
0.965596330275229
0.922779922779923
0.91348402182385
0.98932384341637    
];
pdr{idx} = t;
idx = idx + 1;

% MCMP
t = [
0.199484092863285
0.340130151843818
0.33044846577498
0.290408525754885
0.550670241286863
0.737055837563452
0.543732590529248
0.441541476159373
0.688638799571276
0.479865771812081
0.511826544021025   
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED
t = [
0
0
0
0
0
0
0
0
0
0
0  
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED-CD
t = [
0
0
0
0
0
0
0
0
0
0
0   
];
pdr{idx} = t;
idx = idx + 1;

% SDRCS
t = [
0.127461910070606
0.078888888888889
0.083454281567489
0.596304849884527
0.469230769230769
0.304015296367113
0.180686908909905
0.231266149870801
0.403915301638034
0.065151515151515   
];
pdr{idx} = t;
idx = idx + 1;

% CTP
t = [
0.956241956241956
0.765949820788531
0.98009763424709
0.998509131569139
0.827688872348344
0.931383577052868
0.91574109536576
0.863517060367454
0.869381482904341
0.773402973081559   
];
pdr{idx} = t;
idx = idx + 1;

% display
data = pdr;
group = zeros(0);
dataDisp = zeros(0);
for i = 1 : size(data, 1)
    group = [group ; ones(size(data{i})) + i - 1];
    dataDisp = [dataDisp ; data{i}];
end
figure('name', metric);
% title([metric 'for different protocols']);
h = boxplot(dataDisp * 100, group, 'notch', 'on');
set(gca, 'FontSize', 30, 'YGrid', 'on', 'xtick', 1:size(protocols, 1), 'XTickLabel', protocols, 'ytick', 0:10:100);
ylabel([metric ' (%)']);
%
maximize;
set(gcf, 'Color', 'white'); % Sets figure background
export_fig 'pdr_peers_indriya_sparse' -eps;
export_fig 'pdr_peers_indriya_sparse' -jpg -zbuffer;
saveas(gcf, 'pdr_peers_indriya_sparse.fig');
% saveas(h, 'foo.fig');
% xticklabel_rotate(1 : size(protocols, 1), 90, protocols);

%% NTX
metric = 'Number of transmissions per packet delivered';
PROTOCOL_CNTS = size(protocols, 1);
pdr = cell(PROTOCOL_CNTS, 1);
idx = 1;
% MTA
t = [
16.1355434326479
12.3917414721724
14.2065344224037
15.0020842017507
13.9160625715376
13.4871279163315
13.8734491315136
13.3883610451306
15.573640167364
17.0593003412969
12.0843688685415    
];
pdr{idx} = t;
idx = idx + 1;

% MCMP
t = [
142.711206896552
83.6926020408163
85.4488095238095
110.360856269113
49.6718597857838
34.517217630854
64.7622950819672
65.2840236686391
44.7696498054475
84.025641025641
69.5301668806162    
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED
t = [
10000
10000
10000
10000
10000
10000
10000
10000
10000
10000
10000   
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED-CD
t = [
10000
10000
10000
10000
10000
10000
10000
10000
10000
10000
10000   
];
pdr{idx} = t;
idx = idx + 1;

% SDRCS
t = [
109.655976676385
193.291079812207
200.139130434783
22.5972114639814
32.4821600771456
55.9748427672956
64.0633608815427
55.6070763500931
28.4134520276954
228.682170542636 
];
pdr{idx} = t;
idx = idx + 1;

% CTP
t = [
24.2234185733513
18.6172204024333
13.7333333333333
13.0220231429638
19.2985611510791
13.4311594202899
15.6051861145964
16.0290924880591
23.7238179407866
29.4690909090909
];
pdr{idx} = t;
idx = idx + 1;

% display
data = pdr;
group = zeros(0);
dataDisp = zeros(0);
for i = 1 : size(data, 1)
    group = [group ; ones(size(data{i})) + i - 1];
    dataDisp = [dataDisp ; data{i}];
end
figure('name', metric);
% title([metric 'for different protocols']);
h = boxplot(dataDisp, group, 'notch', 'on');
set(gca, 'FontSize', 30, 'YGrid', 'on', 'xtick', 1:size(protocols, 1), 'XTickLabel', protocols);
set(gca, 'FontSize', 30, 'YGrid', 'on', 'yscale', 'log');
ylabel(metric);
%%
maximize;
set(gcf, 'Color', 'white'); % Sets figure background
export_fig 'ntx_peers_indriya_sparse' -eps;
export_fig 'ntx_peers_indriya_sparse' -jpg -zbuffer;
saveas(gcf, 'ntx_peers_indriya_sparse.fig');
% saveas(h, 'foo.fig');
% xticklabel_rotate(1 : size(protocols, 1), 90, protocols);