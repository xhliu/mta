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
0.99559550651107
0.99449259412092
0.98911856101553
0.99671318599741
0.99610418588429
0.99691694427128
0.99634961491786
0.99797118926116
0.9965933580647    
];
pdr{idx} = t;
idx = idx + 1;

% MCMP
t = [
0.62844831282671
0.67589339914378
0.58300635965609
0.5571628558753
0.42495481940366
0.69626113637481
0.75052336262265
0.76228202702012
0.3180889645164
0.21203611600959
0.41061131534154
0.52827013617205 
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED
t = [
0.045142296909017
0.036421994687095
0.03069287403663
0.24119183234171
0.095292782871355
0.45875052564168
0.74604028531108
0.48306960182863
0.60961937047833
0.59639903174485   
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED-CD
t = [
0.15071517312864
0.20614994001438
0.010649040978829
0.28177346982126
0.18908034190096
0.11231665421555
0.35117546010283
0.2390014759863
0.036681477703798
0.069376869251023
0.11715096939529
];
pdr{idx} = t;
idx = idx + 1;

% SDRCS
t = [
0.33367343266212
0.62268088666514
0.48882485494182
0.94736234163237
0.75746890096067
0.84912610982236
0.6592171293348    
];
pdr{idx} = t;
idx = idx + 1;

% CTP
t = [
0.99866301131405
0.99837944479719
0.99761065889118
0.99633257403189
0.99635538997327
0.99295522436554
0.99910877050841
0.99688060314276
0.9976100781788
0.98703783367245
0.9950174367478
0.99400450835611
0.9959069868382
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
%
maximize;
set(gcf, 'Color', 'white'); % Sets figure background
export_fig 'dcr_peers_light' -eps;
export_fig 'dcr_peers_light' -jpg -zbuffer;
saveas(gcf, 'dcr_peers_light.fig');
% saveas(h, 'foo.fig');
% xticklabel_rotate(1 : size(protocols, 1), 90, protocols);

%% PDR
metric = 'Packet delivery ratio';
PROTOCOL_CNTS = size(protocols, 1);
pdr = cell(PROTOCOL_CNTS, 1);
idx = 1;
% MTA
t = [
0.99656713517715
0.99514059867824
0.99067357512953
0.9967943515663
0.99675351026702
0.99732262382865
0.99659298316772
0.99801176709272
0.99671506204883    
];
% t = t(t >= .9);
pdr{idx} = t;
idx = idx + 1;

% MCMP
t = [
0.83452129782745
0.89361891219339
0.89324147641557
0.73020277481323
0.6157227677552
0.9523294140798
0.82750011776344
0.88629551373397
0.75123502356482
0.61693313483073
0.74065864471184
0.69529753106695  
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED
t = [
0.70284984167546
0.60938120356191
0.40890397545532
0.58136307840102
0.64151568714096
0.45931465565353
0.74915392694597
0.48513576779026
0.61287081592724
0.59687629414897
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED-CD
t = [
0.73912192576163
0.52272158237356
0.60263307804291
0.71096449890041
0.78936032737454
0.56248437890527
0.73273304533389
0.66533957845433
0.53103891926664
0.6510752345096
0.49396709323583    
];
pdr{idx} = t;
idx = idx + 1;

% SDRCS
t = [
0.48596198732911
0.80718046515484
0.65933749794509
0.98724782680007
0.94122716304722
0.90460752529718
0.89971074558563    
];
pdr{idx} = t;
idx = idx + 1;

% CTP
t = [
0.99955434914719
0.99963542088633
0.99898756732677
0.99920273348519
0.99951405199644
0.99890688259109
0.99991897913713
0.99959491209592
0.99971644995342
0.99939251579459
0.99955442135537
0.99967596905504
0.99979740680713    
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
export_fig 'pdr_peers_light' -eps;
export_fig 'pdr_peers_light' -jpg -zbuffer;
saveas(gcf, 'pdr_peers_light.fig');
% saveas(h, 'foo.fig');
% xticklabel_rotate(1 : size(protocols, 1), 90, protocols);

%% NTX
metric = 'Number of transmissions per packet delivered';
PROTOCOL_CNTS = size(protocols, 1);
pdr = cell(PROTOCOL_CNTS, 1);
idx = 1;
% MTA
t = [
3.25172234498895
3.70030600950583
4.25287656903766
4.28235294117647
3.78743587655728
3.60886719544438
4.33002319807904
3.30663522523988
4.11087602229727    
];
pdr{idx} = t;
idx = idx + 1;

% MCMP
t = [
18.2979842842501
16.4627548483342
19.2775995045882
23.0901052323882
31.0107556791841
15.8448186796157
14.1943985882621
13.9072462161113
34.1785336356765
48.1668240478439
26.2719110731082
26.9299267774191   
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED
t = [
57.4429339234904
64.4929262844378
95.7391443167305
50.1214541448637
46.8835887721715
63.8042527339004
48.4924059506192
74.2815440289506
48.1619499568594
53.5189810684904
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED-CD
t = [
44.8907325684025
50.4352772123099
83.0780380212163
34.4700986890558
32.4364256480218
53.9815596534104
31.2596249467254
39.9292502639916
68.0284675953967
60.9039498186808
83.687515420676  
];
pdr{idx} = t;
idx = idx + 1;

% SDRCS
t = [
11.8789625360231
8.06127375449409
7.95680359035093
3.99738339494123
6.23599157663432
6.69711120764553
7.64697696737044  
];
pdr{idx} = t;
idx = idx + 1;

% CTP
t = [
4.13209306095979
4.24180410908944
4.54220042159883
4.52891827197082
4.05894984199011
4.80330725894703
4.23210306688814
4.20959636894148
4.23784440842788
4.81659034728695
5.14508023990922
4.77055224666748
4.35213779128673
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
export_fig 'ntx_peers_light' -eps;
export_fig 'ntx_peers_light' -jpg -zbuffer;
saveas(gcf, 'ntx_peers_light.fig');
% saveas(h, 'foo.fig');
% xticklabel_rotate(1 : size(protocols, 1), 90, protocols);