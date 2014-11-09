%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Xiaohui Liu (whulxh@gmail.com)
%   Date:   9/28/2011
%   Function: prepares figures for loss causes only for MTA and other protocols
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
traffic = 'indriya_sparse';
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
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.00152846771112
0
0.001894657067071
0.003118908382066
0
0.005787037037037
0.000387747188833
0.001529051987768
0.004247104247104
0.000779423226812
0.001941119378842   
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.029805120366832
0.002457865168539
0.003789314134142
0.02261208576998
0.007843137254902
0.010416666666667
0.012020162853819
0.008792048929664
0.01003861003861
0.019485580670304
0.000970559689421 
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0.053878486816966
0.013342696629214
0.015915119363395
0.031189083820663
0.047058823529412
0.022762345679012
0.049243892981776
0.020642201834862
0.05984555984556
0.058456742010912
0.004852798447104  
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
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.58266680049633
0.50549771288606
0.502710312600692
0.48658448934772
0.339691142528337
0.222037509090776
0.333992272441369
0.365721839913885
0.189869691060633
0.344673051396246
0.3312200134462
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.217559798397835
0.154372135270122
0.166841221624327
0.223006984897395
0.1096386161848
0.040906653345773
0.122048701590439
0.192736683926742
0.118982218296806
0.16392400352318
0.156953442532775
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
0.000226435438943
0
0
0.000480715552854
0
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
0];
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.563979416809606
0.43238943684378
0.091889880952381
0.560789747142362
0.01285046728972
0.34516037468067
0.502679169457468
0.477366255144033
0.453249577192559
0.411824668705403
0.388046897340578
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.065180102915952
0.089405027044225
0.036458333333333
0.066158642189124
0.000389408099688
0
0.105157401205626
0.05982905982906
0.033824595312878
0.116207951070336
0.097512153274235
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0.361234991423671
0.478205536111995
0.871651785714286
0.373051610668514
0.986760124610592
0.65483962531933
0.387139986604153
0.462804685026907
0.495530321333655
0.471967380224261
0.512153274235059
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
0
];
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.418138041733547
0.335984727966911
0.631058823529412
0.063001145475372
0.436200999736911
0.339369341242585
0.572841384556866
0.603907039407208
0.478196049198658
0.389014722536806
0.455132343447385
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.035580524344569
0.032453070314986
0.116235294117647
0
0.060773480662983
0.015922572588199
0.116774438950171
0.119232064668238
0.119642191576593
0.099943374858437
0.105229180116204
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0.546281433921883
0.631562201718104
0.248470588235294
0.936998854524628
0.503025519600105
0.644708086169216
0.305439330543933
0.273155944762546
0.394707417070444
0.511041902604757
0.439638476436411
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
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.678186547751765
0.650740740740741
0.583817126269956
0.266050808314088
0.358823529411765
0.430688336520077
0.778994524639124
0.686046511627907
0.600079904115062
0.584848484848485
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.192121887774062
0.255555555555556
0.292815674891147
0.126558891454965
0.161085972850679
0.247609942638623
0.036834245893479
0.067614125753661
0.005193767479025
0.329292929292929
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
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.034749034749035
0.207885304659498
0.019151333082989
0
0.14812058057313
0.053618297712786
0.064343163538874
0.113610798650169
0.134460238186708
0.196866211329851
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.001287001287001
0
0
0
0
0
0
0
0.00153668843642
0.012856568903174
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