function assignment = hungarian_assignment(cost)
%HUNGARIAN_ASSIGNMENT Minimum-cost square assignment, row to column.
% O(n^3) potential-based implementation compatible with MATLAB R2021a.

[n,m] = size(cost);
if n ~= m || any(~isfinite(cost(:))) || ~isreal(cost)
    error('hungarian_assignment:InvalidCost', ...
        'cost must be a finite real square matrix.');
end
u = zeros(n+1,1);
v = zeros(m+1,1);
p = zeros(m+1,1);
way = zeros(m+1,1);
for i = 1:n
    p(1) = i;
    j0 = 1;
    minv = inf(m+1,1);
    used = false(m+1,1);
    while true
        used(j0) = true;
        i0 = p(j0);
        delta = inf;
        j1 = 0;
        for j = 2:m+1
            if ~used(j)
                cur = cost(i0,j-1)-u(i0+1)-v(j);
                if cur < minv(j)
                    minv(j) = cur;
                    way(j) = j0;
                end
                if minv(j) < delta
                    delta = minv(j);
                    j1 = j;
                end
            end
        end
        for j = 1:m+1
            if used(j)
                u(p(j)+1) = u(p(j)+1)+delta;
                v(j) = v(j)-delta;
            else
                minv(j) = minv(j)-delta;
            end
        end
        j0 = j1;
        if p(j0) == 0
            break;
        end
    end
    while true
        j1 = way(j0);
        p(j0) = p(j1);
        j0 = j1;
        if j0 == 1
            break;
        end
    end
end
assignment = zeros(n,1);
for j = 2:m+1
    assignment(p(j)) = j-1;
end
end
