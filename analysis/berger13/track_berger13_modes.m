function tracking = track_berger13_modes(modalModels,pointIds,pathIds)
%TRACK_BERGER13_MODES Match modes only inside continuous operating paths.
% The heading kinematic integrator is reserved before Hungarian assignment.

nPoint = numel(modalModels);
if nPoint < 1 || numel(pointIds) ~= nPoint
    error('track_berger13_modes:InvalidInput', ...
        'modalModels and pointIds must be nonempty and equally sized.');
end
if nargin < 3 || isempty(pathIds)
    pathIds = repmat({'UNSPECIFIED_CONTINUOUS_PATH'},nPoint,1);
end
if numel(pathIds) ~= nPoint
    error('track_berger13_modes:InvalidPaths', ...
        'pathIds must have one entry per modal model.');
end
pathIds = pathIds(:);
pointIds = pointIds(:);
nMode = numel(modalModels{1}.eigenvalues);
rows = cell(nPoint*nMode,13);
row = 0;
previous = [];
previousIds = [];
previousPath = '';
pathOrdinal = 0;
sequenceInPath = 0;
for kPoint = 1:nPoint
    current = modalModels{kPoint};
    newPath = ~strcmp(pathIds{kPoint},previousPath);
    if newPath
        pathOrdinal = pathOrdinal+1;
        sequenceInPath = 1;
        currentIds = (pathOrdinal*100+(1:nMode)).';
        confidence = ones(nMode,1);
        status = repmat({'PATH_START_UNMATCHED'},nMode,1);
    else
        sequenceInPath = sequenceInPath+1;
        [currentIds,confidence,status] = match_with_reserved_heading( ...
            previous,current,previousIds);
    end
    for j = 1:nMode
        row = row+1;
        lambda = current.eigenvalues(j);
        rows(row,:) = {pointIds{kPoint},pathIds{kPoint},sequenceInPath, ...
            currentIds(j),j,real(lambda),imag(lambda), ...
            current.table.dampingRatio(j),current.table.frequencyHz(j), ...
            current.table.modeName{j},current.table.headingIntegrator(j), ...
            confidence(j),status{j}};
    end
    previous = current;
    previousIds = currentIds;
    previousPath = pathIds{kPoint};
end
tracking.table = cell2table(rows,'VariableNames', ...
    {'pointId','pathId','sequenceInPath','modeId','localModeIndex', ...
    'realPartPerSecond','imagPartRadPerSecond','dampingRatio', ...
    'frequencyHz','modeName','headingIntegrator', ...
    'matchingConfidence','matchingStatus'});
tracking.method = ['independent continuous paths; heading integrator ' ...
    'reserved; remaining modes use Hungarian assignment with 0.35 ' ...
    'normalized eigenvalue distance + 0.45*(1-MAC) + 0.20 ' ...
    'participation L1 distance'];
tracking.crossGapAssignment = false;
end

function [currentIds,confidence,status] = match_with_reserved_heading( ...
        previous,current,previousIds)
n = numel(current.eigenvalues);
currentIds = zeros(n,1);
confidence = zeros(n,1);
status = repmat({'MATCHED'},n,1);
prevHeading = find(previous.table.headingIntegrator);
currHeading = find(current.table.headingIntegrator);
if numel(prevHeading) ~= 1 || numel(currHeading) ~= 1
    error('track_berger13_modes:HeadingIntegratorCount', ...
        'Every credible model must contain exactly one heading integrator.');
end
currentIds(currHeading) = previousIds(prevHeading);
confidence(currHeading) = 1;
status{currHeading} = 'RESERVED_HEADING_INTEGRATOR';
prevDynamic = setdiff((1:n).',prevHeading,'stable');
currDynamic = setdiff((1:n).',currHeading,'stable');
cost = matching_cost(previous,current,prevDynamic,currDynamic);
assignment = hungarian_assignment(cost);
for k = 1:numel(prevDynamic)
    currentIndex = currDynamic(assignment(k));
    currentIds(currentIndex) = previousIds(prevDynamic(k));
    confidence(currentIndex) = exp(-cost(k,assignment(k)));
    if confidence(currentIndex) < 0.5
        status{currentIndex} = 'AMBIGUOUS_LOW_CONFIDENCE';
    end
end
end

function cost = matching_cost(previous,current,previousIndices,currentIndices)
n = numel(previousIndices);
cost = zeros(n,n);
for ii = 1:n
    i = previousIndices(ii);
    vp = previous.rightEigenvectors(:,i);
    pp = previous.participation(:,i);
    for jj = 1:n
        j = currentIndices(jj);
        vc = current.rightEigenvectors(:,j);
        pc = current.participation(:,j);
        eigenDistance = abs(current.eigenvalues(j)- ...
            previous.eigenvalues(i))/max(1,abs(previous.eigenvalues(i)));
        mac = abs(vp'*vc)^2/(max(real(vp'*vp)*real(vc'*vc),eps));
        participationDistance = 0.5*norm(pp-pc,1);
        cost(ii,jj) = 0.35*eigenDistance+0.45*(1-min(mac,1))+ ...
            0.20*participationDistance;
    end
end
end
