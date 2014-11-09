%% Given link costs, compute the shortest path to the source
% ETXDist: [node, SP distance from this node to source]
% Parent: the resulting parent in the tree
function [ETXDist, Parent] = Dijkstra(linkMatrix, BASESTATION, TOTAL_NODES)
        S = zeros(0); 
        Q = 1 : TOTAL_NODES;
        Q = Q';
        initDist = repmat(inf, TOTAL_NODES, 1);
        initDist(BASESTATION) = 0;
        Q = [Q initDist];
%         Q = [Q linkMatrix(:, BASESTATION)];
        
        Parent = repmat(NaN, TOTAL_NODES, 1);
        
        while ~isempty(Q)
            % extract min element in Q
            [minQ, minIndex] = min(Q(:,2));
            currentNode = Q(minIndex, 1);
            Q(minIndex, :) = [];

            S = [S; currentNode minQ];
            
            %find all inbound neighbors
            neighbors = find(linkMatrix(:, currentNode) ~= inf);
            for i = 1 : size(neighbors)
                relax(neighbors(i), currentNode);
            end
        end
        
        %sort node ETX pair according to their ETX distance to destination
        [tmp, IX] = sort(S(:,1));
        ETXDist = S(IX, :);
%         ETXDist = S;
            
        %% i reach base station via j
        function f = relax(i , j)
            indexI = find(Q(:, 1) == i);
            indexJ = find(S(:, 1) == j);
            if isempty(indexI)
%                 disp('cannot find the element in remaining set Q');
                return 
            end
            if isempty(indexJ)
%                 disp('element already placed in known set S');
                return
            end
            
            distI = Q(indexI, 2);
            distJ = S(indexJ, 2);
            if distI > (distJ + linkMatrix(i, j))
                Q(indexI, 2) = distJ + linkMatrix(i, j);
                %update parent
                Parent(i) = j;
                fprintf('update parent of %d to %d\n', i, j);
            end
        end
    end
