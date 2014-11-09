%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Xiaohui Liu (whulxh@gmail.com)
%   Data: 6/24/2010
%   Modified: 2/22/2011 preallocate
%   Modified: 2/26/2011 use exponential interpolation for examples falling
%   in borders to deal with heavy-tailed distribution
%   Function: Use P2 algorithm proposed by Raatikainen (1987) to estimate multiple
%   quantiles simultaneously
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% observations: input samples
% p: quantiles estimated
% markers: estimated qtls
% adjusts: magnitude in each individual change
function [markers, adjusts] = ExpP2QtlEst_Ext(observations, p)
% # of quantiles
QTL_COUNTS = length(p);
% # of markers
MARKER_COUNTS = 2 * QTL_COUNTS + 3;
%marker heights & positions & desired positions & increment of desired
%positions
heights = zeros(MARKER_COUNTS, 1);
positions = zeros(MARKER_COUNTS, 1);
positions_prime = zeros(MARKER_COUNTS, 1);
delta_positions_prime = zeros(MARKER_COUNTS, 1);

%% Initilize
heights = sort(observations(1 : MARKER_COUNTS));

positions = 1 : MARKER_COUNTS;

delta_positions_prime(1) = 0;
delta_positions_prime(MARKER_COUNTS) = 1;
for i = 1 : QTL_COUNTS
    delta_positions_prime(2 * i + 1) = p(i);
end
for i = 1 : (QTL_COUNTS + 1)
    delta_positions_prime(2 * i) = (delta_positions_prime(2 * i - 1) + delta_positions_prime(2 * i + 1)) / 2;
end

for i = 1 : MARKER_COUNTS
    positions_prime(i) = 1 + 2 * (QTL_COUNTS + 1) * delta_positions_prime(i);
end


%% Update upon arrival of each new observation
% markers = cell(QTL_COUNTS, 1);
adjusts = zeros(length(observations), 1);
adjusts_cnts = 0;
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
            k = MARKER_COUNTS - 1;
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
%     for i = 1 : MARKER_COUNTS
%         if i >= (k + 1)
%             positions(i) = positions(i) + 1;
%         end
%         positions_prime(i) = positions_prime(i) + delta_positions_prime(i);
%     end
    positions(k + 1 : end) = positions(k + 1 : end) + 1;
    positions_prime = positions_prime + delta_positions_prime;

%     positions
%     disp('');
%     positions_prime
    
    % Adjust heights of markers if necessary
    for i = 2 : (MARKER_COUNTS - 1)
        d = positions_prime(i) - positions(i);
        if (((d >= 1) && ((positions(i + 1) - positions(i)) > 1))) || ...
           (((d <= -1) && ((positions(i - 1) - positions(i)) < -1)))
            d = sign(d);
            % if at borders, use exponential interpolation
%             if k == 1 || k == (MARKER_COUNTS - 1)
            if i == 2 || i == (MARKER_COUNTS - 1)
                new_height = exponent(i, d);
            else
                new_height = parabola(i, d);
            end
                adjusts_cnts = adjusts_cnts + 1;
                % if markers in order
                if (new_height > heights(i - 1)) && (new_height < heights(i + 1))
                    if i == 2 || i == (MARKER_COUNTS - 1)
                        fprintf('adjust by %f w/ exponential \n', new_height - heights(i));
                    else
                        fprintf('adjust by %f w/ parabolic\n', new_height - heights(i));
                    end
                    adjusts(adjusts_cnts, :) = new_height - heights(i);
                    heights(i) = new_height;
                else
                    fprintf('adjust by %f w/ linear\n', linear(i, d) - heights(i));
                    adjusts(adjusts_cnts, :) = linear(i, d) - heights(i);
                    heights(i) = linear(i, d);
                end
            positions(i) = positions(i) + d;
%             disp(['Maker ' num2str(i) ' adjusted  ' num2str(d) ' to height ' num2str(heights(i))]);
        end
    end
end

    % odd markers contains the current estimation of the quantiles
    markers = zeros(QTL_COUNTS, 1);
    for i = 1 : QTL_COUNTS
        markers(i) = heights(2 * i + 1);
    end
    adjusts((adjusts_cnts + 1) : end, :) = [];
    
    %% nested functions
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

    %exponential interpolation
    function y = exponent(i, d)
        if d == 1
            
                x1 = positions(i);
                x2 = positions(i + 1);
                y1 = heights(i);
                y2 = heights(i + 1);
            if i == (MARKER_COUNTS - 1)
                x2 = x2 - 1;
%             else
                % special case at right most cell
                % exponential < 1, but frequency of samples no larger than
                % max is exactly 1; hence exponential curver cannot pass it
%                 x1 = positions(i - 1);
%                 x2 = positions(i);
%                 y1 = heights(i - 1);
%                 y2 = heights(i);
            end
        else....
            if d == -1
                x1 = positions(i - 1);
                x2 = positions(i);
                y1 = heights(i - 1);
                y2 = heights(i);
            else
                disp('error: expected 1 or -1');
                return;
            end
        end
        x = positions(i) + d;
        
        % exponential 1
%         y = y1 * (y2 / y1) ^ ((x - x1) / (x2 - x1));
        % exponential 2
        % sanity check
        if (x1 >= j)  ||  (x2 >= j) || (x >= j)
            disp('error: should not exceed total # of observations so far');
            return;
        end
        % convert to CDF form
        x_1 = y1;
        f_1 = x1 / j;
        x_2 = y2;
        f_2 = x2 / j;
        % compute two parameters
        theta = (x_2 - x_1)  / (log(1 - f_1) - log(1 - f_2));
        alpha = theta * log(1 - f_1) + x_1;
        
        % plug in CDF obtained
        y = - theta * log(1 - x / j) + alpha;
    end
end
    
    
    
    
    