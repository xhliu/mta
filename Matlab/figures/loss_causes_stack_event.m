%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Xiaohui Liu (whulxh@gmail.com)
%   Date:   9/28/2011
%   Function: prepares figures for loss causes only for MTA and other protocols
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
traffic = 'event';
dir = '/home/xiaohui/Dropbox/tOR/figures';
protocols = {'MTA'; 'MCMP'; 'MM'; 'MM-CD'; 'SDRCS'; 'CTP';};
PROTOCOL_NUM = 6;
CAUSE_NUM = 5;
results = zeros(PROTOCOL_NUM, CAUSE_NUM);
row = 1;
column = 1;
legends = {'Success', 'Overflow', 'Tx failure', 'Rejection', 'Expiration'};
%% MTA
% catch ratio 
t = [
0.91988993926527
0.94658297406511
0.90075400023023
0.96229169998263
0.91845943170978
0.92191590139516
0.99035254883278   
];
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0
0
0.002354452054795
0.000565610859729
0
0.001276505212396
0    
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.085356468201217
0.051686290161644
0.10737728310502
0.031548516842634
0.096760165253316
0.078434153606127
0.005478799428299    
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0.006996431819772
0.001130845473292
0.002497146118721
0.001194067370538
0.012466478219903
0.003971349549677
0    
];
results(row, column) = mean(t);
column = column + 1;

% expire: either at on the way to sink or at sink
results(row, end) = 1 - sum(results(row, 1 : end - 1));
row = row + 1;
column = 1;

%% MCMP
% catch ratio 
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
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.19532531108066
0.22477496435012
0.31609624294938
0.2167490341226
0.36942411200028
0.32147392490305
0.19538068475292
0.24432653470554
0.31504293381614
0.24871916054045
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.24407456939239
0.25818621007897
0.33300143905037
0.25840650614616
0.27151293582107
0.29896717766027
0.23834248707949
0.24993762836328
0.25049103734416
0.24465223967267
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0.002544153211555
0.066129312085736
0.008297977354451
0.0309641477318
0.020814910452233
0.000612428496402
0.026337982883272
0.027445566804167
0.020676392892942
0.011759771183946
];
results(row, column) = mean(t);
column = column + 1;

% expire: either at on the way to sink or at sink
results(row, end) = 1 - sum(results(row, 1 : end - 1));
row = row + 1;
column = 1;

%% MMSPEED
% catch ratio 
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
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.28771962513875
0.32573884803361
0.33384809316462
0.26157950161185
0.31328353162652
0.36505633673681
0.27586663076235
0.33321723530442
0.287529041656
0.37289083963172
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.2669055697875
0.28866866386874
0.29815891309671
0.20213261059298
0.24533670613797
0.28822759117986
0.22406619578234
0.27284062727108
0.24421030382881
0.31022190765278
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0.024421824945464
0.042083419178269
0.031042349792261
0.079581065305192
0.097035050943729
0.017290460928357
0.10846362717184
0.074680490303017
0.052879749571726
0.049493484163577
];
results(row, column) = mean(t);
column = column + 1;

% expire: either at on the way to sink or at sink
results(row, end) = 1 - sum(results(row, 1 : end - 1));
row = row + 1;
column = 1;

%% MMSPEEDCD
% catch ratio 
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
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.25009021415948
0.27271624228347
0.28772571148828
0.30534547037655
0.33520083017379
0.31335133176603
0.29751165648124
0.30702161682235
0.37735186380268
0.2988575780868
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.2189143766519
0.21847315321294
0.2573498556844
0.24773311747531
0.27268354016582
0.27111830590124
0.26635423749441
0.25577339481957
0.31866001745978
0.25412302933482
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0.10309670990631
0.063783869559224
0.087912754992766
0.035287566152007
0.059116939371888
0.009635331949922
0.074178916006342
0.037684481368401
0.027056817428632
0.15011306512374
];
results(row, column) = mean(t);
column = column + 1;

% expire: either at on the way to sink or at sink
results(row, end) = 1 - sum(results(row, 1 : end - 1));
row = row + 1;
column = 1;

%% SDRCS
% catch ratio 
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
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.02692485674268
0.14669666937794
0.028015772540359
0.009678727856423
0.11682641412424
0.026793421224697
0.052032479257344
0.062242294973428
0.069338472751891
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.2333024957961
0.22803278023502
0.23640605962534
0.14836203819076
0.36705907512621
0.23142903679944
0.25531726663927
0.22097067291018
0.20037180708617
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0.01623818679842
0.010937618819412
0.023824436491014
0.011641546792341
0.000614067879759
0.0037882729238
0.027455734668855
0.001052575450509
0.006278680603518    
];
results(row, column) = mean(t);
column = column + 1;

% expire: either at on the way to sink or at sink
results(row, end) = 1 - sum(results(row, 1 : end - 1));
row = row + 1;
column = 1;

%% CTP
% catch ratio 
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
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.07776926825872
0.038646722732233
0.002344736367462
0.017256864254555
0.063451776649746
0.026960005086793
0.000525885240154
0.066230520435166
0.022153273347813
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.000348116688714
0
0.000180364335959
0
0.000141003948111
0
0
0.000294031167304
0
];
results(row, column) = mean(t);
column = column + 1;

% rej
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
];
results(row, column) = mean(t);
column = column + 1;

% expire: either at on the way to sink or at sink
results(row, end) = 1 - sum(results(row, 1 : end - 1));
row = row + 1;
column = 1;

%% protocols
figure;
% title([metric 'for different protocols']);
h = bar(results * 100, 'stack');
set(h, 'linewidth', 2);
% color
colors = [
    128 0 0;
    0 0 143;
    100 0 0;
    0 255 0;
    60 0 0;
] / 255;
for i =1 : length(colors)
    set(h(i), 'facecolor', colors(i, :)) % use color name
end

set(gca, 'xtick', 1:size(protocols, 1), 'XTickLabel', protocols);
set(gca, 'FontSize', 30, 'YGrid', 'on', 'FontWeight', 'bold', 'ytick', 0:10:100);
h_legend = legend(legends);
set(h_legend, 'FontSize', 35);
ylabel('Ratio (%)');
ylim([0 100]);
%%
maximize;
set(gcf, 'Color', 'white');
cd(dir);
str = ['protocol_components_' traffic];
% export_fig(str, '-eps');
% export_fig(str, '-jpg', '-zbuffer');
% saveas(gcf, [str '.fig']);