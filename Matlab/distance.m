%% compute the distance of two node with id m and n
function dist = distance(m, n, columns)
    COLUMNS = columns;
    m = m - 1;
    m_x = mod(m, COLUMNS);
    m_y = floor(m / COLUMNS);

    n = n - 1;    
    n_x = mod(n, COLUMNS);
    n_y = floor(n / COLUMNS);
    
    fprintf('(%d, %d) & (%d, %d) \n', m_x, m_y, n_x, n_y);
    dist = sqrt((m_x - n_x) ^ 2 + (m_y - n_y) ^ 2);
end