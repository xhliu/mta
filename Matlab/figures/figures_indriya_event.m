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
0.92807336286492
0.95214626391097
0.92298029010761
0.92682577752996
0.90718920310083
0.91265997962366
0.90290142415819
0.91325688998807
0.96193455492847
0.90645551802885
0.96652719665272
0.93693132640526
0.95435559010562
0.94838842166091    
];
pdr{idx} = t;
idx = idx + 1;

% MCMP
t = [
0.043876274841343
0.55268341686946
0.44941360587345
0.58566278868883
0.19360262314262
0.20664053139659
0.26458029425682
0.28746149978252
0.49511400651466
0.62837264451391
0.40899451703667
0.21383361262102
0.46343546152888
0.30792065077779
0.29829623938342
0.44774655731647
0.44205101688997
0.4721986447721
0.66201685382558
0.44385860787859  
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED
t = [
0.034570252246145
0.03102922842499
0.030540827147402
0.059712586719524
0.031788079470199
0.060789638604554
0.057971014492754
0.052382023726354
0.036334669673432
0.018177975058127
0.055555555555556
0.059011893870082
0.051702395964691
0.057072469718744
0.035192961407718
0.060969368572215
0.060560344827586    
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED-CD
t = [
0.044361525704809
0.00064892926671
0.01509900990099
0.010110736639384
0.032754010695187
0.005578202102553
0.008693552282057
0.037114261884904
0.03559083344002
0.00743123336291
0.023076923076923
0.039167182024325
0.075289980194587
0.082703423743886
0.001899134838574
0.003191489361702    
];
pdr{idx} = t;
idx = idx + 1;

% SDRCS
t = [
0.34018076660669
0.033910262744052
0.42154637780125
0.42630536128563
0.22081944495216
0.35953281894928
0.1511482501392
0.052483072109076
0.45368571514243
0.33005873465582
0.34596254048062
0.49622197112633
0.49600320477042
0.27040640530806
];
pdr{idx} = t;
idx = idx + 1;

% CTP
t = [
0.73406494040538
0.86731244601666
0.47086582484942
0.93007538734943
0.25710845429636
0.22866040390304
0.25222014782655
0.30585245138116
0.57152157507172
0.78754502152508
0.67509752817559
0.31146787683834
0.79190769558596
0.47503034047467
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
export_fig 'dcr_peers_indriya_event' -eps;
export_fig 'dcr_peers_indriya_event' -jpg -zbuffer;
saveas(gcf, 'dcr_peers_indriya_event.fig');
% saveas(h, 'foo.fig');
% xticklabel_rotate(1 : size(protocols, 1), 90, protocols);

%% PDR
metric = 'Packet delivery ratio';
PROTOCOL_CNTS = size(protocols, 1);
pdr = cell(PROTOCOL_CNTS, 1);
idx = 1;
% MTA
t = [
0.9299164660909
0.95214626391097
0.92434988179669
0.92696245733788
0.90745098039216
0.91293566606971
0.90351414227991
0.91424541607898
0.96230353634578
0.90719223415208
0.96652719665272
0.93723468768951
0.95449485109936
0.95069033530572    
];
pdr{idx} = t;
idx = idx + 1;

% MCMP
t = [
0.42533509533698
0.82997416020672
0.80075424261471
0.85958904109589
0.56850134609632
0.41570117712485
0.79683740116879
0.6462734741784
0.84364820846906
0.88838891120932
0.76723788962353
0.66342916342916
0.80004019292604
0.57309817254569
0.61862835959221
0.75112877009211
0.74574554294976
0.89404313591236
0.93514515132798
0.79718618673488   
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED
t = [
0.046660395108184
0.035461975342845
0.052173913043478
0.064915758176412
0.032008830022075
0.062460831418425
0.058324496288441
0.053053588133102
0.11313789359392
0.02578735996618
0.062634062634063
0.064043915827996
0.054854981084489
0.058098952987066
0.037592481503699
0.062035266624177
0.060991379310345  
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED-CD
t = [
0.058250414593698
0.00064892926671
0.017574257425743
0.010110736639384
0.032754010695187
0.005578202102553
0.008693552282057
0.039824854045038
0.057739085904494
0.010980479148181
0.02967032967033
0.055040197897341
0.29763070295673
0.20008892841263
0.006752479426039
0.009787234042553   
];
pdr{idx} = t;
idx = idx + 1;

% SDRCS
t = [
0.60332541567696
0.45294422379554
0.86463730569948
0.73543788187373
0.75846678918351
0.7634603107044
0.64840744729958
0.5867418899859
0.89085192394071
0.64168971586623
0.70814633482932
0.79060787244644
0.82557847082495
0.54457448345615   
];
pdr{idx} = t;
idx = idx + 1;

% CTP
t = [
0.98206852385527
0.99295994993742
0.89691056910569
0.99653092006033
0.87720773759462
0.84207679826934
0.87407892582283
0.84558441558442
0.98684764309764
0.99784482758621
0.98646778409965
0.88669555448564
0.98153034300792
0.89478733610489   
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
export_fig 'pdr_peers_indriya_event' -eps;
export_fig 'pdr_peers_indriya_event' -jpg -zbuffer;
saveas(gcf, 'pdr_peers_indriya_event.fig');
% saveas(h, 'foo.fig');
% xticklabel_rotate(1 : size(protocols, 1), 90, protocols);

%% NTX
metric = 'Number of transmissions per packet delivered';
PROTOCOL_CNTS = size(protocols, 1);
pdr = cell(PROTOCOL_CNTS, 1);
idx = 1;
% MTA
t = [
9.64996954933009
9.30055101018534
10.9186969982501
10.1172312223859
10.8506194180351
10.2015995171269
10.1454126575417
10.9162295587782
9.14992982008422
10.9852464332036
9.67847304210941
10.0386606276286
9.67079749234582
10.7005532503458    
];
pdr{idx} = t;
idx = idx + 1;

% MCMP
t = [
80.4917887261429
30.6980074719801
40.5313971742543
36.9532638676065
55.9321231254933
79.441248606466
35.1078515962036
50.2603859250851
23.6795366795367
27.5201700434153
38.0408019697503
35.8676556705056
30.739512685255
62.0797182054134
50.7014981273408
42.0880019235393
40.6033686498234
29.6220562894888
25.2534125935711
36.3119413247765    
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED
t = [
965.108870967742
920.51171875
730.134146341463
578.900763358779
1026.47586206897
542.538461538462
513.036363636364
576.813602015113
290.90019193858
1315.49180327869
594.085616438356
612.382142857143
635.155172413793
550.86925795053
896.531914893617
546.63698630137
516.512367491166   
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED-CD
t = [
588.103202846975
% 49367.6666666667
1597.43661971831
3279.42857142857
978.972789115646
5613.30769230769
3397.61111111111
728.984293193717
616.951219512195
3121.38383838384
1168.05925925926
641.543071161049
105.823026315789
179.538888888889
4886.8125
3021.10869565217   
];
pdr{idx} = t;
idx = idx + 1;

% SDRCS
t = [
19.9269192913386
34.9313762866946
14.3394756554307
16.7161451121573
16.1251298026999
17.1729616724739
21.8653298528714
23.3774038461538
14.4031932773109
20.9190830721003
17.8112156712118
17.8147156136758
14.9858339680122
20.59936322632  
];
pdr{idx} = t;
idx = idx + 1;

% CTP
t = [
10.0629279426149
9.91665353710414
10.7516316171139
9.77766005751476
11.8622106560745
10.7951188182402
13.3300861745972
13.2890493011826
9.51498027508263
9.53964825671089
10.6832424006235
10.8403619909502
11.115275142315
10.927805575411
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
%%
maximize;
set(gcf, 'Color', 'white'); % Sets figure background
export_fig 'ntx_peers_indriya_event' -eps;
export_fig 'ntx_peers_indriya_event' -jpg -zbuffer;
saveas(gcf, 'ntx_peers_indriya_event.fig');
% saveas(h, 'foo.fig');
% xticklabel_rotate(1 : size(protocols, 1), 90, protocols);