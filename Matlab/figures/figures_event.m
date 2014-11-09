%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Xiaohui Liu (whulxh@gmail.com)
%   Date:   9/28/2011
%   Function: prepares figures for display
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
0.91988993926527
0.94658297406511
0.90075400023023
0.96229169998263
0.91845943170978
0.92191590139516
0.99035254883278    
];
pdr{idx} = t;
idx = idx + 1;

% MCMP
t = [
0.33760747951716
0.22776952082903
0.13308790125566
0.26637908191106
0.10242114459985
0.15253338467193
0.20942332492246
0.14124795751108
0.20636576926128
0.24826805437132  
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED
t = [
0.25819960894219
0.22394715359898
0.13757629988491
0.24499458679177
0.18633462051374
0.15747594562291
0.2182403397752
0.18038209234836
0.21162842743199
0.12879023948037   
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED-CD
t = [
0.24120468315361
0.25063762147987
0.19580606933556
0.21423390655855
0.16368552720526
0.18211351149254
0.12081972383534
0.13572003837362
0.10281558101138
0.15047848457133    
];
pdr{idx} = t;
idx = idx + 1;

% SDRCS
t = [
0.69558654847021
0.57386786913222
0.65719984615961
0.81697636804308
0.4753466087188
0.71005556157976
0.61798412659532
0.69881624232579
0.67022029622658
];
pdr{idx} = t;
idx = idx + 1;

% CTP
t = [
0.71435293547248
0.87387571914872
0.98537216696599
0.90912770188897
0.7072068471761
0.88505217070401
0.98694252301934
0.6794371805059
0.92922080874367
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
export_fig 'dcr_peers_event' -eps;
export_fig 'dcr_peers_event' -jpg -zbuffer;
saveas(gcf, 'dcr_peers_event.fig');
% saveas(h, 'foo.fig');
% xticklabel_rotate(1 : size(protocols, 1), 90, protocols);

%% PDR
metric = 'Packet delivery ratio';
PROTOCOL_CNTS = size(protocols, 1);
pdr = cell(PROTOCOL_CNTS, 1);
idx = 1;
% MTA
t = [
0.91996081998181
0.94671722211136
0.9009703196347
0.9624183006536
0.91853301442342
0.92234593291256
0.99035254883278    
];
pdr{idx} = t;
idx = idx + 1;

% MCMP
t = [
0.46244504723599
0.3380599117288
0.21452686408797
0.38634266379576
0.18502867491699
0.28830705147278
0.42609210137067
0.33654916512059
0.3098635558796
0.43327702702703   
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED
t = [
0.39309683604986
0.29481650600372
0.26073500967118
0.41050696594427
0.29560428754056
0.27927129492861
0.35515011101458
0.28626788553259
0.34319526627219
0.22371801459254
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED-CD
t = [
0.35221849934004
0.38810365135454
0.2890318689052
0.34246301479408
0.27392271899656
0.34236090668237
0.29789674952199
0.35869565217391
0.21246513417332
0.2086774803463   
];
pdr{idx} = t;
idx = idx + 1;

% SDRCS
t = [
0.72152203580316
0.61413406577092
0.71175373134328
0.82821950140139
0.5155004428698
0.73592293836636
0.66498386162377
0.71573445666589
0.72401103955842    
];
pdr{idx} = t;
idx = idx + 1;

% CTP
t = [
0.91192647775534
0.94941259549336
0.99194372632718
0.97581472927893
0.92364636209814
0.9649647103707
0.99257917494449
0.91855336665687
0.97213775985107    
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
export_fig 'pdr_peers_event' -eps;
export_fig 'pdr_peers_event' -jpg -zbuffer;
saveas(gcf, 'pdr_peers_event.fig');
% saveas(h, 'foo.fig');
% xticklabel_rotate(1 : size(protocols, 1), 90, protocols);

%% NTX
metric = 'Number of transmissions per packet delivered';
PROTOCOL_CNTS = size(protocols, 1);
pdr = cell(PROTOCOL_CNTS, 1);
idx = 1;
% MTA
t = [
18.4214769183968
13.8287661607645
18.9484478935698
11.8658743633277
20.1086561982167
17.302475780409
7.25460012026458    
];
pdr{idx} = t;
idx = idx + 1;

% MCMP
t = [
67.4225323624596
94.2358333333333
160.992356115108
92.0530785562633
180.296356715606
113.308221534228
79.4971071511224
102.363836824697
113.79025210084
76.2680311890838    
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED
t = [
95.8407982261641
134.140542090922
153.434347181009
96.374499175112
141.659015302728
152.11706629055
112.104648002175
139.437001041305
117.16569257744
202.358291226458   
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED-CD
t = [
105.483136350533
93.6613555892767
129.752695652174
119.132807939288
145.704209748892
117.784178847807
134.938061617458
113.80329153605
200.283838841105
175.463996185026    
];
pdr{idx} = t;
idx = idx + 1;

% SDRCS
t = [
24.851246105919
26.3534388976188
23.9380436077684
14.4027072758037
43.020618556701
21.9258273917208
28.2003733665215
22.5896457765668
22.0055061414655  
];
pdr{idx} = t;
idx = idx + 1;

% CTP
t = [
13.6962131623149
8.88207451484211
8.25280320019395
8.02222076129117
12.1120525150752
9.53314443858724
8.22511332195208
13.5956306017926
9.32918422060513
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
export_fig 'ntx_peers_event' -eps;
export_fig 'ntx_peers_event' -jpg -zbuffer;
saveas(gcf, 'ntx_peers_event.fig');
% saveas(h, 'foo.fig');
% xticklabel_rotate(1 : size(protocols, 1), 90, protocols);