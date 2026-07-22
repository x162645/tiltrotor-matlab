function tracking = track_berger13_modes(modalModels,pointIds)
%TRACK_BERGER13_MODES Global adjacent-point mode assignment.
% Cost combines eigenvalue distance, complex-vector MAC, and participation.

nPoint = numel(modalModels);
if nPoint < 1 || numel(pointIds) ~= nPoint
    error('track_berger13_modes:InvalidInput', ...
        'modalModels and pointIds must be nonempty and equally sized.');
end
nMode = numel(modalModels{1}.eigenvalues);
modeIds = (1:nMode).';
rows = cell(nPoint*nMode,9);
row = 0;
for kPoint = 1:nPoint
    current = modalModels{kPoint};
    if kPoint == 1
        confidence = ones(nMode,1);
        currentIds = modeIds;
    else
        previous = modalModels{kPoint-1};
        cost = matching_cost(previous,current);
        assignment = hungarian_assignment(cost);
        currentIds = zeros(nMode,1);
        confidence = zeros(nMode,1);
        for i = 1:nMode
            j = assignment(i);
            currentIds(j) = modeIds(i);
            confidence(j) = exp(-cost(i,j));
        end
        modeIds = currentIds;
    end
    for j = 1:nMode
        row = row+1;
        lambda = current.eigenvalues(j);
        rows(row,:) = {pointIds{kPoint},currentIds(j),j, ...
            real(lambda),imag(lambda),current.table.dampingRatio(j), ...
            current.table.frequencyHz(j),current.table.modeName{j}, ...
            confidence(j)};
    end
end
tracking.table = cell2table(rows,'VariableNames', ...
    {'pointId','modeId','localModeIndex','realPartPerSecond', ...
    'imagPartRadPerSecond','dampingRatio','frequencyHz','modeName', ...
    'matchingConfidence'});
tracking.method = ['Hungarian global adjacent assignment; cost=0.35 ' ...
    'normalized eigenvalue distance + 0.45*(1-MAC) + 0.20 ' ...
    'participation L1 distance'];
end

function cost = matching_cost(previous,current)
n = numel(previous.eigenvalues);
cost = zeros(n,n);
for i = 1:n
    vp = previous.rightEigenvectors(:,i);
    pp = previous.participation(:,i);
    for j = 1:n
        vc = current.rightEigenvectors(:,j);
        pc = current.participation(:,j);
        eigenDistance = abs(current.eigenvalues(j)- ...
            previous.eigenvalues(i))/max(1,abs(previous.eigenvalues(i)));
        mac = abs(vp'*vc)^2/(max(real(vp'*vp)*real(vc'*vc),eps));
        participationDistance = 0.5*norm(pp-pc,1);
        cost(i,j) = 0.35*eigenDistance + 0.45*(1-min(mac,1)) + ...
            0.20*participationDistance;
    end
end
end
