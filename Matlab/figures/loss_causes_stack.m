%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Xiaohui Liu (whulxh@gmail.com)
%   Date:   9/28/2011
%   Function: prepares figures for loss causes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
traffic = 'medium';
dir = '/home/xiaohui/Dropbox/tOR/figures';
variants = {'MTA'; 'M-DS'; 'M-DB'; 'M-ST'; 'M-MD'; 'M-mDQ'; 'mDQ'; 'M-FCFS'};
protocols = {'MTA'; 'MCMP'; 'MM'; 'MM-CD'; 'SDRCS'; 'CTP';};
PROTOCOL_NUM = 12;
CAUSE_NUM = 5;
results = zeros(PROTOCOL_NUM, CAUSE_NUM);
row = 1;
column = 1;
legends = {'Success', 'Overflow', 'Tx failure', 'Rejection', 'Expiration'};
%% MTA
% catch ratio 
t = [
0.92045437637412
0.93249791918938
0.92999275793906
0.98483568650575
0.90040777162498
0.94069335571503
0.92939276010077
0.95235432186125
0.96778631692596
0.95013441753727   
];
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.000230129735638
0
0
0
0
0
0
0.000373180743874
0
0    
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.0029916865633
0.004301201979731
0.003892312682452
0.000544425087108
0.005735911536869
0.002261018889525
0.003030121204848
0.012688145291703
0.000992720052945
0.005896124165438    
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0.058309121767396
0.03317228376149
0.034264146492496
0.00745862369338
0.042280172668677
0.030595306239267
0.035191407656306
0.008541692581996
0.015773218619016
0.025058527703113    
];
results(row, column) = mean(t);
column = column + 1;

% expire: either at on the way to sink or at sink
results(row, end) = 1 - sum(results(row, 1 : end - 1));
row = row + 1;
column = 1;

%% M-DS
% catch ratio 
t = [
0.40896606439988
0.52977002305801
0.52717192503643
0.47062553125939
0.50505261240502
0.44737988551148
0.49825985409379
0.49681542595648
0.41871911732251 
];
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.006619066589036
0.000097526088229
0.00012258657677
0.001315356790529
0.000588518538334
0.004304745408696
0.006559055886082
0.002679707911838
0.000423139696548    
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.011093065301995
0.025974448164884
0.017376647257125
0.029694179546202
0.02391525333048
0.012608573830204
0.018189798107871
0.028002947678703
0.023514477422475    
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0.033217908252383
0.053054191996359
0.054305853509041
0.036468267017428
0.060189395965973
0.075829746045493
0.060372573880815
0.065049909559858
0.045759535755304   
];
results(row, column) = mean(t);
column = column + 1;

% expire: either at on the way to sink or at sink
results(row, end) = 1 - sum(results(row, 1 : end - 1));
row = row + 1;
column = 1;

%% M-DB
% catch ratio 
t = [
0.4812920650988
0.4952417668419
0.49850425317429
0.5214987422981
0.50831762259799
0.64726049107454
0.51814314351861
0.50474368983996
0.46777135820379
0.50358366755648   
];
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.005506337740221
0.000111006271854
0.000900090009001
0
0.001182223655221
0.000064863462412
0
0.002318494965554
0.001852487135506
0.010946003791353    
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.036009268093226
0.020119886773603
0.052350396329956
0.028079149279849
0.030657208877425
0.023934617629889
0.018317635595973
0.018150503444621
0.031766723842196
0.017978352595854    
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0.17805642633229
0.21604595659655
0.1541476728318
0.22842912908871
0.21803965822989
0.21132516053707
0.23078921727834
0.27848436671966
0.26435677530017
0.24509264355164    
];
results(row, column) = mean(t);
column = column + 1;

% expire: either at on the way to sink or at sink
results(row, end) = 1 - sum(results(row, 1 : end - 1));
row = row + 1;
column = 1;

%% M-LD
% catch ratio 
t = [
0
0.000478025753637
0
0
0
0
0   
];
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
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

% air loss
t = [
0.000418421713297
0.009919034387978
0.009632751354606
0.000629236621571
0.003100727596476
0.001395478649177
0.002351216831048    
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0.98733576947753
0.89112963460906
0.90633869441816
0.96261762434574
0.79968071715838
0.98735696343846
0.8651561879752    
];
results(row, column) = mean(t);
column = column + 1;

% expire: either at on the way to sink or at sink
results(row, end) = 1 - sum(results(row, 1 : end - 1));
row = row + 1;
column = 1;

%% M-MD
% catch ratio 
t = [
0.67020278036208
0.79457516611344
0.782275897583
0.78180089616363
0.63934846066075
0.73139411243854
0.70770115263407
0.80428912589526
0.78137146599782
0.84520169055954   
];
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0
0
0
0
0
0
0
0
0.000121486016959
0   
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.041664040340372
0.040683430045132
0.039955546147333
0.02997262116336
0.065582132023301
0.043809272918862
0.027361809045226
0.028712472294983
0.024904633476687
0.018739312179365    
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0.045824141191302
0.062217923920052
0.066098645215919
0.039771362697536
0.042414968725672
0.039673340358272
0.082814070351759
0.046922224461012
0.040624924071239
0.033512255367661   
];
results(row, column) = mean(t);
column = column + 1;

% expire: either at on the way to sink or at sink
results(row, end) = 1 - sum(results(row, 1 : end - 1));
row = row + 1;
column = 1;

%% M-mDQ
% catch ratio 
t = [
0.75967319094663
0.82960131073118
0.91074736745257
0.86156943360638
0.78351674750754
0.86766317067539
];
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0
0
0
0
0
0  
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.084763409205141
0.059231232840019
0.060506735717329
0.065541665306655
0.086319695342252
0.073512643369777
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0
0
0
0
0.000032548904729
0    
];
results(row, column) = mean(t);
column = column + 1;

% expire: either at on the way to sink or at sink
results(row, end) = 1 - sum(results(row, 1 : end - 1));
row = row + 1;
column = 1;

%% MDQ
% catch ratio 
t = [
0.81063332221382
0.78057863845844
0.71714929068894
0.68974420893525
0.70882915817295
0.65097757500978
0.41106879434806
];
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
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

% air loss
t = [
0.11087829579186
0.10697674418605
0.19277909738717
0.14449867805572
0.15424836601307
0.10233442986802
0.18358854860186
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
];
results(row, column) = mean(t);
column = column + 1;

% expire: either at on the way to sink or at sink
results(row, end) = 1 - sum(results(row, 1 : end - 1));
row = row + 1;
column = 1;

%% FCFS
% catch ratio 
t = [
0.92768720555058
0.91390722857822
0.83627700949272
0.89355375751529
0.95307093025906
0.82865039892446
0.92646811877043
0.96492791578733
0.95468881791181
0.86515471858757
0.96665025667275
0.79544588865153
];
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0
0
0.000849665798119
0
0
0
0
0
0
0.003854082638702
0
0
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.003762856426123
0.006173015918379
0.00699558173785
0.00373435888861
0.001665119834034
0.007338129496403
0.002337647528365
0.00153643546971
0.0029940957551
0.013115831615428
0.003443009857004
0.010576725328319
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0.031524374947738
0.035866365636878
0.068879574034213
0.052894128138673
0.018370912267293
0.062158273381295
0.023576030560465
0.013087137840211
0.017992556733917
0.022795853126587
0.008718589476607
0.08182272233158
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
0.16889714049529
0.54522398900622
0.19432097104256
0.070924769716487
0.17899439209004
0.18723154175827
];
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.17863569236425
0.067716048627009
0.20894011294313
0.358987172895
0.30329875429196
0.17410283561511
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.072227515555047
0.065420589351517
0.050540782524084
0.090844260849861
0.063104486648742
0.035496955230246
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0.001318020356844
0.00153795771458
0.015104916991854
0.00006013521239
0.000962333183806
0.002764602184284
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
0.08014548441029
0.065046935975496
0.17701471918579
0.015594718059409
0.027571491303231
0.049430852060087
];
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.29916913475058
0.32732240397902
0.31585682157346
0.37955797842501
0.45176657824324
0.43586945129664
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.094710335268909
0.083082016388022
0.071881401419925
0.1621614567353
0.13018556695924
0.089986221638914
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0.069065843858032
0.089663165069743
0.11251588180057
0.022939798148306
0.013520151780824
0.009556058935106
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
0.004339370598578
0.080279472965226
0.15262780305004
0.066542461115263
0.081688570023452
0.15028620209909
0.2422090208792
];
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.27568555535136
0.25568564958871
0.25514574315292
0.30841934128124
0.30047410256631
0.25386304313372
0.20325687315212
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.08813945276786
0.062858024760256
0.075567969257895
0.1004532948921
0.093277784191991
0.093899459719109
0.045887055069888
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0.012395766867016
0.049341186353164
0.051687252954366
0.1344069351189
0.014242555725815
0.003174354690613
0.032947556420394
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
0.76641644464115
0.50835025004343
0.90309949769496
0.61703837326583
0.84998518102457
0.8060243169155
0.94038592436787
0.86144155415761
];
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.10425940138143
0.093248541961844
0.002652876187918
0.22451154529307
0.075235641147352
0.053432231036022
0.001274395572386
0.049936416364257
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.083883346124328
0.049919272463673
0.045938412975587
0.056192475375424
0.015935444497186
0.026441399677209
0.060879697057967
0.014918892093918
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0
0.3477544564895
0.02572282480943
0.093137413208461
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

%% CTP
% catch ratio 
t = [
0.86506277403792
0.56343418509212
0.39310971996767
0.67738966040294
0.56774643629827
0.2584064431232
0.42458914940141
];
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.000166112956811
0.025423465423465
0.050514843541054
0.001058009129107
0.01306284017813
0.027334070374747
0.007988262145419
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
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

% rej
t = [
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

%% variants
figure;
% X is to set x labels apart for readability
h = bar([1:(3.7/4):4.7 5.8 6.9 8], results(1:size(variants, 1), :) * 100, 'stack');
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

set(gca, 'xtick', [1:(3.7/4):4.7 5.8 6.9 8], 'XTickLabel', variants);
set(gca, 'FontSize', 30, 'FontWeight', 'bold', 'YGrid', 'on');
set(gca, 'ytick', 0:10:100);
ylim([0 100]);
xlim([0.5 8.8]);
h_legend = legend(legends);
set(h_legend, 'FontSize', 35);
ylabel('Ratio (%)');
%%
maximize;
set(gcf, 'Color', 'white');
cd(dir);
str = ['variant_components_' traffic];
% export_fig(str, '-eps');
% export_fig(str, '-jpg', '-zbuffer');
% saveas(gcf, [str '.fig']);
%% protocols
figure;
% title([metric 'for different protocols']);
h = bar(results([1 size(variants, 1) + 1 : end], :) * 100, 'stack');
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
%%
maximize;
set(gcf, 'Color', 'white');
cd(dir);
str = ['protocol_components_' traffic];
% export_fig(str, '-eps');
% export_fig(str, '-jpg', '-zbuffer');
% saveas(gcf, [str '.fig']);