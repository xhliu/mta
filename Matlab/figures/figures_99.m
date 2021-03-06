%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Xiaohui Liu (whulxh@gmail.com)
%   Date:   12/1/2011
%   Function: prepares figures for display of probability 99%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% deadline success ratio
cd ~/Dropbox/tOR/figures/;
% 'm' for min
protocols = {'MTA'; 'MCMP'; 'MM'; 'MM-CD'; 'SDRCS'; 'CTP';};
%% Deadline success ratio
metric = 'Deadline success ratio';
PROTOCOL_CNTS = size(protocols, 1);
pdr = cell(PROTOCOL_CNTS, 1);
idx = 1;
% MTA
t = [
0.99236018394897
0.9935112815219
0.99505260957425
0.99354791938524
0.9946721918011
0.99579882009415
0.99697488584475
0.99784409268357
0.99417514922576
0.99610646211065    
];
pdr{idx} = t;
idx = idx + 1;

% MCMP
t = [
0.48142198654435
0.62733479439942
0.49363265216266
0.70215534852391
0.3640285899935
0.36258525323292
0.45040799612445
0.68061407311391
0.54066013962309
0.63260120130052
0.68027204081862
0.78111322972031
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED
t = [
0.23963670237541
0.24892441261094
0.15605996351592
0.23515775886074
0.18527905563501
0.48185206767673
0.39531815682016
0.31148639301436
0.32162192332102
0.33818846367146   
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED-CD
t = [
0.20280066031171
0.29836959092092
0.17871282943793
0.22845605994433
0.46057295338122
0.10198843651444
0.48342869447046
0.38921800897603
0.25990053204578
];
pdr{idx} = t;
idx = idx + 1;

% SDRCS
t = [
0.80761402836492
0.81652836195288
0.90955997063326
0.89438718206635
0.78474173268464
0.68680524345248
0.87977440789652
0.63272342078531
0.58792747632822
0.91563482459972
0.85374640100486    
];
pdr{idx} = t;
idx = idx + 1;

% CTP
t = [
0.99894800952328
0.87194533704511
0.75689674218591
0.98666034241484
0.91688645263507
0.70229514749475
0.89416443785704
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
%xlabel('Protocols');
ylabel([metric ' (%)']);
%%
maximize;
set(gcf, 'Color', 'white'); % Sets figure background
export_fig 'dcr_peers_99' -eps;
export_fig 'dcr_peers_99' -jpg -zbuffer;
saveas(gcf, 'dcr_peers_99.fig');
% saveas(h, 'foo.fig');
% xticklabel_rotate(1 : size(protocols, 1), 90, protocols);

%% PDR
metric = 'Packet delivery ratio';
PROTOCOL_CNTS = size(protocols, 1);
pdr = cell(PROTOCOL_CNTS, 1);
idx = 1;
% MTA
t = [
0.99236018394897
0.9935112815219
0.99505260957425
0.99354791938524
0.9946721918011
0.99579882009415
0.99697488584475
0.99787141141797
0.99417514922576
0.99610646211065    
];
% t = t(t >= .9);
pdr{idx} = t;
idx = idx + 1;

% MCMP
t = [
0.5790547024952
0.74773464593355
0.74341156417989
0.78001795771774
0.68163742690059
0.5646828723107
0.7657980964269
0.7673343605547
0.6047266650752
0.72777558277361
0.7782374844849
0.92566651604157
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED
t = [
0.63903120633442
0.5481249108798
0.7028457028457
0.54830394282032
0.46513448128647
0.66694630872483
0.47577203113231
0.5914979530032
0.6187223345538
0.573573068952
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED-CD
t = [
0.38128469468676
0.57713476961786
0.53370064279155
0.57154038822793
0.71207482046429
0.40421832052505
0.55351749135043
0.55426507363156
0.57995834297616    
];
pdr{idx} = t;
idx = idx + 1;

% SDRCS
t = [
0.85833661030279
0.87162222025339
0.94893244104525
0.91804736118969
0.7921760391198
0.76320422535211
0.89817408260947
0.6999722453511
0.66430786066022
0.93665158371041
0.8731136738056    
];
pdr{idx} = t;
idx = idx + 1;

% CTP
t = [
0.99894800952328
0.97275043499876
0.94778713731782
0.99649356145336
0.98525822834905
0.96709874189859
0.98868748777466    
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
export_fig 'pdr_peers_99' -eps;
export_fig 'pdr_peers_99' -jpg -zbuffer;
saveas(gcf, 'pdr_peers_99.fig');
% saveas(h, 'foo.fig');
% xticklabel_rotate(1 : size(protocols, 1), 90, protocols);

%% NTX
metric = 'Number of transmissions per packet delivered';
PROTOCOL_CNTS = size(protocols, 1);
pdr = cell(PROTOCOL_CNTS, 1);
idx = 1;
% MTA
t = [
7.43022647432544
7.91695116520707
6.49698879551821
6.71681867931412
6.97879779794673
7.88812423326651
6.58461670578806
5.81830115407756
6.88923050149375
7.59766057989616    
];
pdr{idx} = t;
idx = idx + 1;

% MCMP
t = [
30.3111663559146
16.9513764213046
23.1978835978836
15.7358727501046
25.2728208647907
37.1698169223157
28.0503939146971
21.859312248996
21.1727459339965
20.4645313065509
17.4292633941757
14.2086404686356
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED
t = [
42.3112244897959
42.439646201873
37.4606307222787
50.8812907361898
61.5101728621692
31.8772798742138
40.5079155672823
36.6727979520243
34.7305246422893
43.0998046875
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED-CD
t = [
74.1464226289518
50.0133514986376
72.7336545079147
58.3015612161052
31.7513876944727
67.3148764918124
37.3472566722889
41.8671546019651
46.904728651237
];
pdr{idx} = t;
idx = idx + 1;

% SDRCS
t = [
11.6560531439698
9.70359829233584
7.945428595416
9.71881327581653
8.54704129416773
13.1996667948225
8.61319227884578
10.9545003965107
12.2468152866242
8.45493015766019
7.62206120985698  
];
pdr{idx} = t;
idx = idx + 1;

% CTP
t = [
7.0514355392972
7.80684830868496
9.41549693164986
8.31878298853364
8.1667280334728
11.0555051839003
9.22534375309131
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
ylabel(metric);
%
maximize;
set(gcf, 'Color', 'white'); % Sets figure background
export_fig 'ntx_peers_99' -eps;
export_fig 'ntx_peers_99' -jpg -zbuffer;
saveas(gcf, 'ntx_peers_99.fig');
% saveas(h, 'foo.fig');
% xticklabel_rotate(1 : size(protocols, 1), 90, protocols);