%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Xiaohui Liu
%   6/30/2011
%   Function: EWMAV estimator for each column
%   samples: matrix containing the samples or row vector
%   alpha: weight of the new sample
%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [sample_mean, sample_var] = EWMAV(samples, alpha)
    sample_mean = zeros(1, size(samples, 2));
    sample_var = zeros(1, size(samples, 2));
    
    for column = 1 : size(samples, 2)
        for i = 1 : size(samples, 1)
            sample = samples(i, column);
            
            diff = sample - sample_mean(column);
            incr = alpha * diff;
            sample_mean(column) = sample_mean(column) + incr;
            sample_var(column) = (1 - alpha) * (sample_var(column) + diff * incr);
%             diff = abs(sample - sample_mean(column));
%             sample_std(column) = sample_std(column) * (1 - weight) + diff * weight;
%             sample_mean(column) = sample_mean(column) * (1 - weight) + sample * weight;
        end
    end
end
