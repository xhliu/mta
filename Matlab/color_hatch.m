%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Xiaohui Liu
%   @date: 12/4/2011
%   Function: colored hatch
%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% color
colors = [
    128 0 0;
    0 0 143;
    100 0 0;
    0 255 0;
%     60 0 0;
];
% for i =1 : length(colors)
%     set(h(i), 'facecolor', colors(i, :)) % use color name
% end
%%
% applyhatch_pluscolor(gcf, '+/-|\', 1, [0 0 0 0 0], [], 150, 5, 10);
applyhatch_pluscolor(gcf, '+/-|\k', 1, [], [], [], 5, 10);
% applyhatch_pluscolor(gcf, '-|', 1, [], [], [], 5, 10);
%
% maximize;
set(gcf, 'Color', 'white');
% cd(dir);
% str = 'foo';
export_fig(str, '-eps');
export_fig(str, '-jpg', '-zbuffer');
saveas(gcf, [str '.fig']);