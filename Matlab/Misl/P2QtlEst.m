%%  Author: Xiaohui Liu (whulxh@gmail.com)
%   Data: 6/24/2010
%   Use P2 algorithm proposed by Raj Jain (1985) to estimate a single
%   quantile
%%%
% observations: input samples
% p: quantile estimated
function markers = P2QtlEst(observations, p)
% # of markers
MARKER_COUNTS = 5;
%marker heights & positions & desired positions & increment of desired
%positions
heights = zeros(MARKER_COUNTS, 1);
positions = zeros(MARKER_COUNTS, 1);
positions_prime = zeros(MARKER_COUNTS, 1);
delta_positions_prime = zeros(MARKER_COUNTS, 1);

%% Initilize
heights = sort(observations(1 : MARKER_COUNTS));
positions = 1 : MARKER_COUNTS;
positions_prime(1) = 1;
positions_prime(2) = 1 + 2 * p;
positions_prime(3) = 1 + 4 * p;
positions_prime(4) = 3 + 2 * p;
positions_prime(5) = 5;

delta_positions_prime(1) = 0;
delta_positions_prime(2) = p / 2;
delta_positions_prime(3) = p;
delta_positions_prime(4) = (1 + p) / 2;
delta_positions_prime(5) = 1;

%% Update upon arrival of each new observation
markers = [];
for j = (MARKER_COUNTS + 1) : length(observations)
    x = observations(j);
%     disp(['Round ' num2str(j) ' with sample ' num2str(x)]);
    % Find the cell x falls in
    if x < heights(1)   % min
        heights(1) = x;
        k = 1;
    else
        if x >= heights(MARKER_COUNTS) % max
            heights(MARKER_COUNTS) = x;
            k = 4;
        else
            for k = 1 : (MARKER_COUNTS - 1)
                if x < heights(k + 1)
                    break;
                end
            end
        end
    end

    % Increment positions of markers k + 1 through MARKER_COUNTS
    % and desired positions for all markers
    for i = 1 : MARKER_COUNTS
        if i >= (k + 1)
            positions(i) = positions(i) + 1;
        end
        positions_prime(i) = positions_prime(i) + delta_positions_prime(i);
    end

%     positions
%     disp('');
%     positions_prime
    
    % Adjust heights of markers if necessary
    for i = 2 : (MARKER_COUNTS - 1)
        d = positions_prime(i) - positions(i);
        if (((d >= 1) && ((positions(i + 1) - positions(i)) > 1))) || ...
                (((d <= -1) && ((positions(i - 1) - positions(i)) < -1)))
            d = sign(d);
            new_height = parabola(i, d);
            % if markers in order
            if (new_height > heights(i - 1)) && (new_height < heights(i + 1))
                heights(i) = new_height;
            else
                heights(i) = linear(i, d);
            end
            positions(i) = positions(i) + d;
%             disp(['Maker ' num2str(i) ' adjusted  ' num2str(d) ' to height ' num2str(heights(i))]);
        end
    end
    
    % marker 3 contains the current estimation of the p-quantile
    markers = [markers; positions(3), positions_prime(3), heights(3)];
end
    %parabolic interpolation
    function y = parabola(i, d)
        y = heights(i) + d * ((positions(i) - positions(i - 1) + d) * (heights(i + 1) - heights(i)) / (positions(i + 1) - positions(i)) ...
                            + (positions(i + 1) - positions(i) - d) * (heights(i) - heights(i - 1)) / (positions(i) - positions(i - 1)))...
                            / (positions(i + 1) - positions(i - 1));
    end
    %linear interpolation
    function y = linear(i, d)
        y = heights(i) + d * (heights(i + d) - heights(i)) / (positions(i + d) - positions(i));
    end
end    
    
    
    
    
    