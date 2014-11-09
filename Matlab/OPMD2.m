%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Xiaohui Liu
%   6/7/2011
%   Function: impirically measure the tightness of new OPMD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% extract trace data
% 23 -> 55 -> 15
t = node_seqno_timestamp;
seqnos = t(t(:, 1) == 15, 2);
seqnos = unique(seqnos);
len = length(seqnos);

% 23 -> 55
X = zeros(len, 1);
% 55 -> 15
Y = zeros(len, 1);
for i = 1 : len
    seqno = seqnos(i);
    
    tx_time = t(t(:, 1) == 23 & t(:, 2) == seqno, 3);
    rx_time = t(t(:, 1) == 55 & t(:, 2) == seqno, 3);
    if isempty(tx_time) || isempty(rx_time)
        fprintf('log err for pkt %d\n', seqno);
        continue;
    end
    X(i) = rx_time(1) - tx_time(1);

    tx_time = rx_time;
    rx_time = t(t(:, 1) == 15 & t(:, 2) == seqno, 3);
    if isempty(tx_time) || isempty(rx_time)
        fprintf('log err for pkt %d\n', seqno);
        continue;
    end
    Y(i) = rx_time(1) - tx_time(1);    
end
%%
X = X(1 : 3500);
Y = Y(1 : 3500);
save('X.mat', 'X');
save('Y.mat', 'Y');
%% Z = X + Y
X_QTL = .9;
Y_QTL = .9;
fprintf('quantile %f\n', X_QTL);
a = quantile(X, X_QTL);
b = quantile(Y, Y_QTL);
% ensure b >= a
if a > b
    t = a;
    a = b;
    b = t;
    
    T = X;
    X = Y;
    Y = T;
end
Z = X + Y;
len = length(Z);

% compute P & q
% v1: p = P{X <= a, Y <= b}
cnts = 0;
for i = 1 : len
    if X(i) <= a && Y(i) <= b
        cnts = cnts + 1;
    end
end
p = cnts / len;
% v2: p = min{P{X <= a}, P{Y <= b}}
% p = min(X_QTL, Y_QTL);

% v1: q = P{Z <= a + b}
q = length(find(Z <= (a + b))) / len;
% v2: q = P{X <= (a + b)} * P{Y <= (a + b)} / 2
% q = (length(find(X <= (a + b))) / len) * (length(find(Y <= (a + b))) / len) / 2;
% v3: q = 1;
% q = 1;
% ensure q >= p
if q < p
    q = p;
end
fprintf('a %f, b %f, p %f, q %f\n', a, b, p, q);

% solve the equation
% case 1: z >= b && z <= (a + b)
A = p * (a ^ 2 + b ^ 2) - 4 * a * b * (q - p);
B = 4 * a * b * (a + b) * (q - p) - 2 * p * (a + b) * (a ^ 2 + b ^ 2);
C = p * (a ^ 2 + b ^ 2) * ((a + b) ^ 2) - 2 * a * b * (q - p) * (a ^ 2 + b ^ 2);
delta = B ^ 2 - 4 * A * C;
z1 = (- B - sqrt(delta)) / (2 * A);
z2 = (- B + sqrt(delta)) / (2 * A);
fprintf('z = %f, %f, range [%f, %f]\n', z1, z2, b, a + b);
if z1 >= b && z1 <= (a + b)
    z = z1;
end
if z2 >= b && z2 <= (a + b)
    z = z2;
end

fprintf('actual quantile vs estimated quantile\n');
fprintf('%f vs %f\n\n\n', p, length(find(Z <= z)) / len);