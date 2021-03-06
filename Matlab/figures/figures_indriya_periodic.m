%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Xiaohui Liu (whulxh@gmail.com)
%   Date:   10/21/2011
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
0.96113876728886
0.91416485985902
0.90621242894776
0.95257988053686
0.96891537835108
0.97019603994432
0.90730368959541
0.95995577968106
0.90102020661665
0.945099627337    
];
pdr{idx} = t;
idx = idx + 1;

% MCMP
t = [
0
0.40906105919856
0
0.73596476100733
0
0.043565762992778
0.33696109293621
0.87741239934881
0.71959122436672
0.68447708462256
0.50097661298498
0.71346301471456
0.77696083759656
0.37872561918741
0.08937295884171
0.2093159925753
0.35896524577046
0.73319866686379
0.69214245144293
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
];
pdr{idx} = t;
idx = idx + 1;

% SDRCS
t = [
0.10520438137424
0.15200017675298
0.22588571757068
0.37568277691536
0.18582913458677
0.59759605666777
0.34932221063608    
];
pdr{idx} = t;
idx = idx + 1;

% CTP
t = [
0.3899924901668
0.43720033759329
0.40832357137398
0.50214502130206
0.40371696493928
0.28840977259886
0.21824975055222
0.17126880343172
0.36415180993619
0.33386242745824
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
export_fig 'dcr_peers_periodic_indriya' -eps;
export_fig 'dcr_peers_periodic_indriya' -jpg -zbuffer;
saveas(gcf, 'dcr_peers_periodic_indriya.fig');
% saveas(h, 'foo.fig');
% xticklabel_rotate(1 : size(protocols, 1), 90, protocols);

%% PDR
metric = 'Packet delivery ratio';
PROTOCOL_CNTS = size(protocols, 1);
pdr = cell(PROTOCOL_CNTS, 1);
idx = 1;
% MTA
t = [
0.96138260799092
0.91583736138755
0.90701677140456
0.95506257110353
0.96956451351789
0.97056199821588
0.9086859688196
0.96044214106405
0.90186003903294
0.94599303135888  
];
pdr{idx} = t;
idx = idx + 1;

% MCMP
t = [
0
0.46148325358852
0
0.83042550520899
0
0.043565762992778
0.5696993361968
0.99596112583617
0.89423942394239
0.82079390722363
0.89954214920549
0.95379731953915
0.93221681566142
0.90515653775322
0.67854451501776
0.84304176812137
0.94790916510634
0.92890515871104
0.89657251518946 
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
0
0
0  
];
pdr{idx} = t;
idx = idx + 1;

% SDRCS
t = [
0.4045545880777
0.41055805657012
0.34480300365952
0.72300489465844
0.43832540940306
0.80517711171662
0.34932221063608    
];
pdr{idx} = t;
idx = idx + 1;

% CTP
t = [
0.9914825434306
0.99623655913978
0.99016558796335
0.9205524581855
0.93092096459064
0.89362064560089
0.93027530601161
0.8603359009976
0.94441670827093
0.9382128877478    
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
export_fig 'pdr_peers_periodic_indriya' -eps;
export_fig 'pdr_peers_periodic_indriya' -jpg -zbuffer;
saveas(gcf, 'pdr_peers_periodic_indriya.fig');
% saveas(h, 'foo.fig');
% xticklabel_rotate(1 : size(protocols, 1), 90, protocols);

%% NTX
metric = 'Number of transmissions per packet delivered';
PROTOCOL_CNTS = size(protocols, 1);
pdr = cell(PROTOCOL_CNTS, 1);
idx = 1;
% MTA
t = [
8.47051633298209
9.19847429813279
10.0834510150044
8.54964689866417
8.8203790282184
8.34550467914439
10.0026292335116
8.91758357573458
9.12189197544495
9.2340571330678
];
% t = t(t >= .9);
pdr{idx} = t;
idx = idx + 1;

% MCMP
t = [
10000
32.2006220839813
10000
16.8742442563483
10000
356.858695652174
26.0680831619831
16.6763401343303
18.1839456467036
17.5601012231126
25.8559880239521
16.5494884752866
15.8040786598689
18.9186164801628
18.5854355069015
21.0667073983559
22.4091876012966
19.2286751361162
17.3631990067767   
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
30.5121412803532
24.6956656667012
33.2465885596141
14.0244893153588
25.1366877573566
11.3572335025381
18.9671641791045    
];
pdr{idx} = t;
idx = idx + 1;

% CTP
t = [
9.04669558560857
8.89131968948483
9.223259762309
11.1608809359945
12.7854637456155
12.9803659931376
12.691485539788
14.0963843632272
12.8230837004405
11.386075097573
];
pdr{idx} = t;
idx = idx + 1;

% display
% pdr = pdr(3:4, :);
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
set(gca, 'xtick', 1:size(protocols, 1), 'XTickLabel', protocols);
set(gca, 'FontSize', 30, 'YGrid', 'on', 'yscale', 'log');
%xlabel('Protocols');
ylabel(metric);
%
maximize;
set(gcf, 'Color', 'white'); % Sets figure background
export_fig 'ntx_peers_periodic_indriya' -eps;
export_fig 'ntx_peers_periodic_indriya' -jpg -zbuffer;
saveas(gcf, 'ntx_peers_periodic_indriya.fig');
% saveas(h, 'foo.fig');
% xticklabel_rotate(1 : size(protocols, 1), 90, protocols);