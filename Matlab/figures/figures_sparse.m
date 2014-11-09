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
0.940592831452313
0.974038941587619
0.965656195143122
0.958218121259207
0.958892312662903
0.940928272511475
0.965680157497288
0.93973217986859
0.959237187127533
0.946097153759424    
];
pdr{idx} = t;
idx = idx + 1;

% MCMP
t = [
0.214397728585814
0.115473441108545
0.011365236805589
0.001800115207373
0.234031390350374
0.004330708661417
0.05109022556391
0.023316703447651
0.050462802209787
0
0.000164609053498
0.070132369016067  
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED
t = [
0.134009661835749
0.013357079252004
0.128542611841727
0.082957610777011
0.006889797989317
0.026961161794149
0.084670760490745
0.083883458909702
0.041010806142101
0.091189663932641
0.031441179420319
0.12062885492089   
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED-CD
t = [
0.237027792651961
0.043981594658757
0.169090909090909
0.005011042761065
0.050623501878853
0.083928318511027
0.18688351140662
0.018981416423872
0.041677498555748
0.005317701664533
0.06449673687844
0.068504804921758
0.06745243869893    
];
pdr{idx} = t;
idx = idx + 1;

% SDRCS
t = [
0.916708424236351
0.201854636849214
0.318661343048517
0.173375374382891
0.232964894242068
0.138439611784443
0.681302545404871
0.326455173653208
0.079646790222938
0.714818276179389
0.365654127628902
0.327961588041162
0.527676727189271
];
pdr{idx} = t;
idx = idx + 1;

% CTP
t = [
0.871259057915811
0.661773587308497
0.722262074254095
0.590802224067564
0.83562901278257
0.872791613801355
0.704711358072679
0.707985404183087
0.861874193159859
0.537249180437304
0.657674484169187
0.869430374059413
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
export_fig 'dcr_peers_sparse' -eps;
export_fig 'dcr_peers_sparse' -jpg -zbuffer;
saveas(gcf, 'dcr_peers_sparse.fig');
% saveas(h, 'foo.fig');
% xticklabel_rotate(1 : size(protocols, 1), 90, protocols);

%% PDR
metric = 'Packet delivery ratio';
PROTOCOL_CNTS = size(protocols, 1);
pdr = cell(PROTOCOL_CNTS, 1);
idx = 1;
% MTA
t = [
0.940592831452313
0.974038941587619
0.965771580039184
0.958343789209536
0.959823502090107
0.941423628274839
0.966037287733048
0.940317682784396
0.959237187127533
0.947453954496208   
];
pdr{idx} = t;
idx = idx + 1;

% MCMP
t = [
0.480503144654088
0.327174749807544
0.036575398447078
0.011520737327189
0.241649048625793
0.095669291338583
0.063074352548037
0.050276641808997
0.177397868561279
0.016282225237449
0.010205761316872
0.119712351945854   
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED
t = [
0.19
0.170080142475512
0.186355022109918
0.296722990271377
0.246534945443822
0.211920529801325
0.387028176501861
0.35361216730038
0.184432777904588
0.150062111801242
0.357988165680473
0.279351032448378
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED-CD
t = [
0.378158844765343
0.180924287118977
0.416666666666667
0.234579439252336
0.299419492820043
0.395046284713535
0.377416073245168
0.338720103425986
0.196129404968226
0.389964788732394
0.287157670832226
0.302875695732839
0.463398253861652   
];
pdr{idx} = t;
idx = idx + 1;

% SDRCS
t = [
0.937055281882868
0.300015740594995
0.548347799604081
0.400230680507497
0.28804347826087
0.437372802960222
0.735344425439279
0.610699439725285
0.241666666666667
0.818644662921348
0.534900808229243
0.349002601908066
0.638512934726743    
];
pdr{idx} = t;
idx = idx + 1;

% CTP
t = [
0.978064516129032
0.939986810287975
0.986448433650123
0.947014925373134
0.993018036738426
0.985274431057564
0.957918406681658
0.978109637324924
0.986389748121962
0.955300859598854
0.965745743704761
0.981869303858833    
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
export_fig 'pdr_peers_sparse' -eps;
export_fig 'pdr_peers_sparse' -jpg -zbuffer;
saveas(gcf, 'pdr_peers_sparse.fig');
% saveas(h, 'foo.fig');
% xticklabel_rotate(1 : size(protocols, 1), 90, protocols);

%% NTX
metric = 'Number of transmissions per packet delivered';
PROTOCOL_CNTS = size(protocols, 1);
pdr = cell(PROTOCOL_CNTS, 1);
idx = 1;
% MTA
t = [
8.73127637130802
8.62749871860584
7.21778042959427
8.62241424456664
8.17844180982337
9.12562352323445
8.10387215734481
8.52279219972674
8.12027833001988
9.57904516866781    
];
pdr{idx} = t;
idx = idx + 1;

% MCMP
t = [
32.3821989528796
27.9788235294118
214.558659217877
572.661538461539
34.153980752406
79.7222222222222
106.735099337748
188.583732057416
47.1727158948686
494.25
551.887096774194
72.6908127208481    
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED
t = [
77.2392344497608
114.701570680628
66.8632768361582
67.6384814495255
89.8672248803828
94.2391304347826
56.8921703296703
46.1478494623656
81.9727722772277
95.3956953642384
61.2689706987228
64.9239704329462   
];
pdr{idx} = t;
idx = idx + 1;

% MMSPEED-CD
t = [
47.6133651551313
93.4782608695652
55.6673835125448
112.839309428951
74.680612244898
38.2672577580747
48.6078167115903
77.5362595419847
99.0220913107511
70.6207674943567
67.9148148148148
58.302450229709
48.3115942028986    
];
pdr{idx} = t;
idx = idx + 1;

% SDRCS
t = [
7.5981308411215
20.9706190975866
11.5723410163843
21.2036503362152
27.1630727762803
19.1840101522843
10.7064918587439
13.4385912992009
38.9334402566159
8.9262277503753
15.6136675824176
21.5029821073559
14.5537966192648  
];
pdr{idx} = t;
idx = idx + 1;

% CTP
t = [
7.21862042970222
6.21258185219832
6.10749330954505
6.47945513902961
7.04511592868503
6.66195652173913
6.92421193829645
5.7678520625889
5.81641429979393
5.74409118176365
5.43924839016151
8.38451663868865
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
export_fig 'ntx_peers_sparse' -eps;
export_fig 'ntx_peers_sparse' -jpg -zbuffer;
saveas(gcf, 'ntx_peers_sparse.fig');
% saveas(h, 'foo.fig');
% xticklabel_rotate(1 : size(protocols, 1), 90, protocols);