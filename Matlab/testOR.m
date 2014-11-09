%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Author: Xiaohui Liu (whulxh@gmail.com)
%   Date:   2/11/2011 (updated)
%   Function: Analyze the existence of cases where OR gives smaller ETX
%   than unicast, namely OR capacity
%   caution: node id is not actual id, but virtual: node index in 'nodes',
%   tables use virtual id
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clear all;
%% verify Dijkstra
% link_pdrs = [ 
%         0.0 0.6 0.0 0.0 0.3 0.8;
%         0.6 0.0 0.8 0.4 0.3 0.0;
%         0.0 0.8 0.0 0.8 0.0 0.0;
%         0.0 0.4 0.8 0.0 0.5 0.3;
%         0.3 0.3 0.0 0.5 0.0 0.0;
%         0.8 0.0 0.0 0.3 0.0 0.0];
% ETX = [4.17 2.50 1.25 0.00 2.00 3.33];
% ROOT = 4;
% NODE_COUNTS = 6;
% link_etxs = zeros(NODE_COUNTS, NODE_COUNTS);
% link_etxs = 1 ./ link_pdrs;
% link_etxs(ROOT, ROOT) = 0;
% [nodeETXs, nodeParents] = Dijkstra(link_etxs, ROOT, NODE_COUNTS);    
% load('linkQualityTOSSIM5by5.mat');

%% job 439 -> 483
% load('link_pdrs.mat');
% link_pdrs = 0.95 * link_pdrs_old;
NODE_COUNTS = length(nodes);
% bi_link_pdrs = link_pdrs .* link_pdrs';
ROOT = 15;  % node 15 corresponds to, still, 5 from 'allSenders'
% variable 0
% MAX_FCS_SIZE = 5;
INVALID_RVAL = 255;
%% broadcast ETX
%bidirectional link quality
% variable 1
link_pdrs = b_link_pdrs;
ack_pdrs = link_pdrs';
bi_link_pdrs = link_pdrs .* ack_pdrs;
% bi_link_pdrs = link_pdrs;
link_etxs = zeros(NODE_COUNTS, NODE_COUNTS);
link_etxs = 1 ./ bi_link_pdrs;
link_etxs(ROOT, ROOT) = 0;
%% may need change here: b_node_ETXs is not necessarily broadcast node ETX,
%% but min{unicast ETX, OR ETX}
[b_node_ETXs, nodeParents] = Dijkstra(link_etxs, ROOT, NODE_COUNTS);
b_node_ETXs = b_node_ETXs(:, 2);

%% unicast ETX
% % variable 2
% SYNC_ACK_PDR = 1.0;     % based on LOF paper
% u_bi_link_pdrs = link_pdrs * SYNC_ACK_PDR;
% u_link_etxs = zeros(NODE_COUNTS, NODE_COUNTS);
% u_link_etxs = 1 ./ u_link_pdrs;
% u_link_etxs(ROOT, ROOT) = 0;
% [u_node_ETXs, nodeParents] = Dijkstra(u_link_etxs, ROOT, NODE_COUNTS);
% u_node_ETXs = nodeETXs(:, 2);

%% convert node ETX for ease of search thru virtual node ID
% b_tmp = zeros(NODE_COUNTS, 1);
% u_tmp = zeros(NODE_COUNTS, 1);
% for i = 1 : NODE_COUNTS
%     node = nodes(i);
%     b_tmp(i) = b_node_ETXs(find(b_node_ETXs(:, 1) == node), 2);
%     u_tmp(i) = u_node_ETXs(find(u_node_ETXs(:, 1) == node), 2);
% end
% b_node_ETXs = b_tmp;
% u_node_ETXs = u_tmp;

%% compute OR ETX
% FCS selection algorithm 3
OR_ETX = repmat(NaN, NODE_COUNTS, 1);
node_FCSs = cell(NODE_COUNTS, 1);
% each node
for k = 1 : NODE_COUNTS
    src = k;
    if src == ROOT
        OR_ETX(src) = 0;
        continue;
    end
    disp(['node ' num2str(src)]);
    % find neighbors
    neighbors = find(bi_link_pdrs(:, src) ~= 0);
    % only consider neighbors closer to root than me
%     tmp_neighbors = find(u_node_ETXs(:, 1) < u_node_ETXs(src, 1));
    tmp_neighbors = find(b_node_ETXs(:, 1) < b_node_ETXs(src, 1));
    neighbors = intersect(neighbors, tmp_neighbors);
    if isempty(neighbors)
        disp('no candidate');
    end
    % variable 3
    % sort neighbors according to their ETXs
    % include local link
    nbETXs = [neighbors b_node_ETXs(neighbors) + (link_etxs(src, neighbors))'];
    % exclude local link
%     nbETXs = [neighbors b_node_ETXs(neighbors)];
    [tmp, IX] = sort(nbETXs(:, 2));
    neighbors = nbETXs(IX, 1);
    
    % initialize FCS
    fcs_etx = b_node_ETXs(neighbors(1));
    fcs_p = bi_link_pdrs(src, neighbors(1));
    fcs_u_p = link_pdrs(src, neighbors(1));
    fcs = neighbors(1);

    % each rest neighbor
    for i = 2 : size(neighbors, 1)
        nb = neighbors(i);
        
        % neighbor info
        etx = b_node_ETXs(nb);
        p = bi_link_pdrs(src, nb);
        u_p = link_pdrs(src, nb);
        
        % suppression PDR: outgoing only, from all current FC to it
        % variable 4
%         tmp_a = 0;
        % ack success prob.
        a = 0;
        for j = 1 : size(fcs, 1)
            a = 1 - (1 - a) * (1 - link_pdrs(fcs(j), nb));
        end
        
        tmp_p = 1 - (1 - fcs_p) * (1 - p * (1 - fcs_u_p * a));
        tmp_u_p = 1 - (1 - fcs_u_p) * (1 - u_p);
        tmp_etx = fcs_u_p * fcs_etx + u_p * (1 - fcs_u_p * a) * etx;
        tmp_etx = tmp_etx / tmp_u_p;
        
        % include it reduces ETX?
        if (1 / fcs_p + fcs_etx) > (1 / tmp_p + tmp_etx)
            fcs_etx = tmp_etx;
            fcs_p = tmp_p;
            fcs_u_p = tmp_u_p;
            fcs = [fcs; nb];
            if length(fcs) >= MAX_FCS_SIZE
                break;
            end
        end
    end
    
    OR_ETX(k) = 1 / fcs_p + fcs_etx;
    node_FCSs{k} = fcs;
end

% FCS selection algorithm 4: each round add FC reduces ETX most till no FC
% can be added to further reduce ETX
OR_ETX_2 = repmat(NaN, NODE_COUNTS, 1);
node_FCSs_2 = cell(NODE_COUNTS, 1);
% each node
for k = 1 : NODE_COUNTS
    src = k;
    if src == ROOT
        OR_ETX_2(src) = 0;
        continue;
    end
    disp(['node ' num2str(src)]);
    % find neighbors
    neighbors = find(bi_link_pdrs(:, src) ~= 0);
    % only consider neighbors closer to root than me
%     tmp_neighbors = find(u_node_ETXs(:, 1) < u_node_ETXs(src, 1));
    tmp_neighbors = find(b_node_ETXs(:, 1) < b_node_ETXs(src, 1));
    neighbors = intersect(neighbors, tmp_neighbors);
    if isempty(neighbors)
        disp('no candidate');
    end
    % initialize FCS
    node_etx = inf;
    fcs_p = 0;
    fcs_u_p = 0;
    fcs = zeros(MAX_FCS_SIZE, 1);

    % try to add new FC
    for fc_idx = 1 : MAX_FCS_SIZE
        min_fcs_etx = 1 / fcs_p + node_etx;
        min_fc_idx = INVALID_RVAL;
        % each remaing neighbor
        for i = 1 : length(neighbors)
            nb = neighbors(i);
            if 0 == nb
                fprintf('already included \n');
                continue;
            end
            % neighbor info
            etx = b_node_ETXs(nb);
            p = bi_link_pdrs(src, nb);
            u_p = link_pdrs(src, nb);

            % ack success prob.
            a = 0;
            for j = 1 : (fc_idx - 1)
                a = 1 - (1 - a) * (1 - link_pdrs(fcs(j), nb));
            end

            tmp_p = 1 - (1 - fcs_p) * (1 - p * (1 - fcs_u_p * a));
            tmp_u_p = 1 - (1 - fcs_u_p) * (1 - u_p);
            tmp_etx = fcs_u_p * fcs_etx + u_p * (1 - fcs_u_p * a) * etx;
            tmp_etx = tmp_etx / tmp_u_p;

            % include it reduces ETX?
            tmp_fcs_etx = 1 / tmp_p + tmp_etx;
            if min_fcs_etx > tmp_fcs_etx
                min_fcs_etx = tmp_fcs_etx;
                min_fc_idx = i;
                
                min_node_etx = tmp_etx;
                min_fcs_p = tmp_p;
                min_fcs_u_p = tmp_u_p;
            end
        end
        % no reduction
        if min_fc_idx == INVALID_RVAL
            % current idx entry not valid
            fc_idx = fc_idx - 1;
            break;
        end
        % add FC
        fcs(fc_idx) = neighbors(min_fc_idx);
        % invalidate
        neighbors(min_fc_idx) = 0;
        % update
        node_etx = min_node_etx;
        fcs_p = min_fcs_p;
        fcs_u_p = min_fcs_u_p;
    end
    
    OR_ETX_2(k) = 1 / fcs_p + node_etx;
    node_FCSs_2{k} = fcs(1 : fc_idx);
end
%% presentation
% diff = OR_ETX - u_node_ETXs;
% OR_win_ratio = size(find(diff < 0), 1) / size(diff, 1);
% diff
%% FCS selection algorithm 1
% for i = 1 : NODE_COUNTS
%     % each node
%     src = i;
%     if src == ROOT
%         OR_ETX(src) = 0;
%         continue;
%     end
%     disp(['node ' num2str(src)]);
%     neighbors = find(bi_link_pdrs(:, src) ~= 0);
%     nbETXs = [neighbors nodeETXs(neighbors) + 1 ./ bi_link_pdrs(neighbors, src)];
%     % sort neighbors according to their ETXs
%     [tmp, IX] = sort(nbETXs(:, 2));
%     neighbors = nbETXs(IX, 1);
%     min_nb = neighbors(1);
% 
%     % each neighbor excluding the min ETX one
%     neighbors(find(neighbors == min_nb)) = [];
%     p = bi_link_pdrs(src, min_nb);
%     for i = 1 : size(neighbors, 1)
%         nb = neighbors(i);
%         % outgoing only
%         a = link_pdrs(min_nb, nb);
%     %     RHS = (1 - p) * (1 + nodeETXs(min_nb + 1) * p ) / (p * (1 - p * a));
%     %     LHS = nodeETXs(nb + 1);
%         expr = (p - 1) + nodeETXs(min_nb) * p * (p - 1) + nodeETXs(nb) * p * ( 1 - p * a);
%     %     if (LHS < RHS)
%         if expr < 0
%             disp('OR ++');
%         else
%             disp('OR --');
%         end
%     end
% end

%% FCS selection algorithm 2
% for k = 1 : NODE_COUNTS
%     src = k;
%     if src == ROOT
%         OR_ETX(src) = 0;
%         continue;
%     end
%     disp(['node ' num2str(src)]);
%     neighbors = find(bi_link_pdrs(:, src) ~= 0);
%     % only consider neighbors closer to root than me
%     tmp_neighbors = find(b_node_ETXs(:, 1) < b_node_ETXs(src, 1));
%     neighbors = intersect(neighbors, tmp_neighbors);
%     
%     % variable 3
%     % sort neighbors according to their ETXs, exclusing local link
%     nbETXs = [neighbors b_node_ETXs(neighbors) + (link_etxs(src, neighbors))'];
% %     nbETXs = [neighbors b_node_ETXs(neighbors)];
%     [tmp, IX] = sort(nbETXs(:, 2));
%     neighbors = nbETXs(IX, 1);
%     
%     % initialize FCS
%     fcs_p = 0;
% %     fcs_a = 0;
%     fcs_etx = 0;
%     fcs = [];
% 
%     % each neighbor
%     for i = 1 : size(neighbors, 1)
%         nb = neighbors(i);
%         
%         % local link PDR
%         p = bi_link_pdrs(src, nb);
%         tmp_p = 1 - (1 - fcs_p) * (1 - p);
%         
%         % suppression PDR: outgoing only, from all current FC to it
%         % variable 4
% %         tmp_a = 0;
%         a = 1;
%         for j = 1 : size(fcs, 1)
%             a = a * (1 - link_pdrs(fcs(j), nb));
%         end
%         tmp_a = 1 - a;
%         
%         tmp_etx = fcs_p * fcs_etx + p * (1 - fcs_p * tmp_a) * b_node_ETXs(nb);
%         tmp_etx = tmp_etx / tmp_p;
%         
%         % add it reduces ETX?
%         if (1 / fcs_p + fcs_etx) > (1 / tmp_p + tmp_etx)
%             fcs_p = tmp_p;
%             fcs_etx = tmp_etx;
%             fcs = [fcs; nb];
%             
%             if length(fcs) >= MAX_FCS_SIZE
%                 break;
%             end
%         end
%     end
%     
%     OR_ETX(k) = 1 / fcs_p + fcs_etx;
%     node_FCSs{k} = fcs;
% end