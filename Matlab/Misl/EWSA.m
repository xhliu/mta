function EWSA(samples)
W = 1 / 16;
W_STD = 1 / 4;
W_MEAN = 1 / 8;
MAX_S = 65;
s = 20;
f = 100;
std = 20;
mean = 20;

result = [];

% load('samples.mat');
for i = 1 : length(samples)
    sample = samples(i);
    if sample <= s
        count1 = 1;
    else
        count1 = 0;
    end
    if (sample <= (s + std)) && (sample >= (s - std))
        count2 = 1;
    else
        count2 = 0;
    end

    s  = s + (900 - count1 * 1000) * W / f;
    if s > MAX_S
        s = MAX_S;
    else if s < 0
            s = 0;
        end
    end

    f = f * (1 - W) + W * count2 / (2 * std);

    %update mean and std
    std = (1 - W_STD) * std + W_STD * abs(sample - mean);
    mean = (1 - W_MEAN) * std + W_MEAN * sample;
    
    
    result = [result; s];
end
plot(result);
    
%     function y = ESMA(sample)
%     if sample <= s
%         count1 = 1000;
%     else
%         count1 = 0;
%     end
%     if (sample <= (s + std)) && (sample >= (s - std))
%         count2 = 1000;
%     else
%         count2 = 0;
%     end
% 
%     s  = s + (900 - count1) * W / f;
% 
%     f = f * (1 - W) + W * count2 / (2 * std);
% 
%     %update mean and std
%     std = (1 - W_STD) * std + W_STD * abs(sample - mean);
%     mean = (1 - W_MEAN) * std + W_MEAN * sample;
%     end
% end