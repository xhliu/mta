%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Xiaohui Liu (whulxh@gmail.com)
%   Date:   9/28/2011
%   Function: prepares figures for loss causes only for MTA and other protocols
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
traffic = 'light';
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
0    
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.00019431310318
0.000777504211481
0.000582901554404
0.000486933939296
0.000202905608311
0.000486795667519
0.000202798620969
0.000284033272469
0.000446102684727    
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0.00226698620377
0.001684592458209
0.006930051813472
0.001339068333063
0.002231961691421
0.001216989168796
0.002433583451633
0.000852099817407
0.001378862843702   
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
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.06838133635345
0.039508853018971
0.037138963730762
0.094648152619408
0.19102473889831
0.018417799928847
0.046310382391432
0.042641851469158
0.1280540194963
0.17873836399587
0.075959212992676
0.1412002015746
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.064376665946509
0.036427926349607
0.046413039902446
0.076101780460006
0.12302617789102
0.022737265749538
0.054254248936158
0.035830258770779
0.081927597962117
0.090154374491528
0.063998537856344
0.08720781140875
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0.006499643636663
0.001782354271533
0.00164663909948
0.025161744798469
0.013012584393618
0.002084295926414
0.009249492135245
0.003565943512944
0.005754563310308
0.011688660984155
0.018238541936745
0.014755807290374
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
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.13374208858584
0.16717273163288
0.2689845674439
0.17349346214049
0.12399815723012
0.18234364357749
0.101854379957
0.20060050180833
0.13992491729454
0.13631955646957
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.090795881710275
0.11460991096718
0.22753309306692
0.12791243063634
0.094644937823898
0.16519216733126
0.081672421838404
0.15468718050689
0.10839923973284
0.11405502784923
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0.010270041225555
0.036040224615987
0.026350937269809
0.05534587738709
0.056432597872533
0.041269302764039
0.018776593455092
0.030271235172863
0.077180381417478
0.052620441751152
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
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.10417156160014
0.17290240423073
0.2016888169797
0.074291573080502
0.066299007227302
0.17269888175562
0.072874138124507
0.13699776987264
0.2125671172251
0.13224638859289
0.23639406789476
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.089546578650416
0.13123987830423
0.15240811293699
0.069880854289963
0.05003543567048
0.15685231172506
0.06298347475362
0.10854958593586
0.17325660210466
0.12982102046232
0.17795450977432
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0.029573368470824
0.063691659551031
0.008596923397967
0.080742837930721
0.033219959519312
0.051805244283999
0.034878489229533
0.025212177412651
0.037029307033142
0.03032621955736
0.02106293703894
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
0.33367343266212
0.62268088666514
0.48882485494182
0.94736234163237
0.75746890096067
0.84912610982236
0.6592171293348
];
results(row, column) = mean(t);
column = column + 1;

% overflow
t = [
0.46615538512838
0.15840968450728
0.33273056057866
0.000328030178776
0
0
0.011915554979925
];
results(row, column) = mean(t);
column = column + 1;

% air loss
t = [
0.032277425808603
0.027403507317275
0.009986848594444
0.001476135804494
0.052223371251293
0.092592592592593
0.054008548115529
];
results(row, column) = mean(t);
column = column + 1;

% rej
t = [
0.014204734911637
0.008250072550889
0.000575373993096
0.005781531900935
0.004825922095829
0.000687690342863
0.012692656391659    
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