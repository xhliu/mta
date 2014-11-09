%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Xiaohui Liu (whulxh@gmail.com)
%   Date:   9/28/2011
%   Function: prepares figures for loss causes only for MTA and other protocols
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
traffic = '99';
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
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0
0.000368677186256
0.000209044665877
0
0
0
0.000057077625571
0
0.000028835894922
0.000174337517434    
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.002670226969292
0.00324435923905
0.0018117204376
0.002392344497608
0.003181885452124
0.001906918538824
0.00148401826484
0.001282611068661
0.005103953401194
0.002556950255695 
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0
0.000294941749005
0.000278726221169
0.000362476439031
0.000221992008288
0.000059591204338
0.000456621004566
0.000027289597206
0.000201851264454
0.000261506276151   
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
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.07331095401145
0.03434456025242
0.044064204089003
0.037452567326522
0.056200924020589
0.094595449058161
0.056129463086195
0.048698512929069
0.071867879077237
0.040460569165133
0.034788456261735
0.016372216678391
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.069207728973496
0.013025749779679
0.0261421739231
0.000251106720258
0.00557581388007
0.002626414820909
0.002369813140465
0.001540232036826
0.10609725994543
0.004890347999753
0.011711928366071
0.002215835654147
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0.070529879263503
0.021666163800199
0.031539950725035
0.036360253093398
0.012578380135335
0.081530148211775
0.023478704262013
0.03205796680571
0.064980540665668
0.087223592895297
0.030481578689396
0.007165575580173
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
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.26014752305296
0.2587986104998
0.19539081559409
0.28377716267366
0.31819709720062
0.21414908134254
0.25787292694459
0.2623669339544
0.24044432255857
0.24662282725826
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.061239265103058
0.063211489749676
0.038091963418659
0.094413348338535
0.10501990338329
0.049937252094729
0.052930060625679
0.057498934707329
0.042590325087908
0.068985915644238
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0.020919437122377
0.039076929922126
0.03639693268401
0.01517854715177
0.034511257558344
0.008495103621597
0.095340635518211
0.004439020321608
0.013696301173981
0.06532536415414
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
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.36085779244913
0.29080595486277
0.26638412401111
0.28925609753762
0.22078797029636
0.3711405082142
0.23789045401718
0.30563724942749
0.28221060223603
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.095864001553724
0.077970082300459
0.098101369839142
0.094339731032383
0.036571331787822
0.12487197941288
0.06748566473401
0.074338345994789
0.069402985414974
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0.15033759052594
0.001122605896996
0.08075944805835
0.018501069474684
0.027738197158657
0.015252046412954
0.10619580455174
0.02028661586041
0.041369550542878
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
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.10745182854896
0.083193053955878
0.019200127469726
0.054311807968965
0.17797824803979
0.17214397496088
0.043786562666194
0.2494102137108
0.28418748860113
0.025570872356098
0.082668863261944
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.045222178529296
0.05058917338531
0.02899936265137
0.02610522912794
0.030182952533513
0.076975743348983
0.062116645984754
0.054468498473494
0.060915557176728
0.042337507453786
0.048237232289951
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0.00147463625639
0
0
0
0
0
0.000106364119837
0.008395781293367
0.008790807951851
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
0.99894800952328
0.87194533704511
0.75689674218591
0.98666034241484
0.91688645263507
0.70229514749475
0.89416443785704
];
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.000166103759482
0.025416355953269
0.050508089316754
0.001057977147694
0.013059824549832
0.027335112466641
0.007987220447284
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