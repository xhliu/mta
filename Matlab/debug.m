clc;
for i = 0 : 29
    fprintf('%d, ', round(1280 * log10(1 + 10 ^ (-i / 10))));
end

y = 10 ^ (-69 / 10) - 10 ^ (-71 / 10);
10 * log10(y)