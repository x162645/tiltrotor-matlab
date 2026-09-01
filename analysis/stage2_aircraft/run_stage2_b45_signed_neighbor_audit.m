function results = run_stage2_b45_signed_neighbor_audit(outputRoot)
%RUN_STAGE2_B45_SIGNED_NEIGHBOR_AUDIT Resolve local B45 flap-solver support.
% This numerical diagnostic samples a predeclared symmetric neighborhood of
% the frozen B45 multistart checkpoint along the exact three trim variables.
% It changes neither the M1 physics nor trim/control degrees of freedom.

if nargin < 1 || isempty(outputRoot)
    outputRoot = fullfile(pwd,'results','stage2_b45_signed_neighbor_audit');
end
if ~exist(outputRoot,'dir'), mkdir(outputRoot); end

P = stage2_matched_rotor_parameters();
d2r = pi/180;
condition = struct('name','B45_V035','V',35,'betaM',45*d2r,'gamma',0, ...
    'mode','conversion_longitudinal');
definition = make_trim_definition(condition.mode,condition,P);
z0 = [0.36961115687162627; 0.6097990356720934; 1.647599943976152];
expectedResidual = [-0.11445984591707202; -0.416173243818573; 0.07587035495863398];
base = stage2_evaluate_trim_point('M1_EVIDENCE_V1_PROPAGATION',condition,definition,z0,P);
assert(base.physicalConverged && base.physicalBranchSupported && ...
    norm(base.residual-expectedResidual) <= 1e-9, ...
    'run_stage2_b45_signed_neighbor_audit:CheckpointDrift', ...
    'Frozen B45 checkpoint no longer reproduces workflow run 33300606420.');

% Predeclared local fractions of the already-frozen production variableScale.
fractions = [1e-3 2.5e-3 5e-3 1e-2 2e-2];
sgns = [-1 1];
nRows = numel(fractions)*3*2;
rows = repmat(empty_row(),nRows,1);
idx = 0;
for f = fractions
    for j = 1:3
        for sg = sgns
            idx = idx+1;
            row = empty_row();
            row.stepFraction = f;
            row.variableIndex = j;
            row.variableName = definition.unknownNames{j};
            row.sign = sg;
            row.delta = sg*f*definition.variableScale(j);
            zn = z0; zn(j) = zn(j)+row.delta;
            row.z1 = zn(1); row.z2 = zn(2); row.z3 = zn(3);
            row.withinBounds = all(zn >= definition.bounds(:,1) & zn <= definition.bounds(:,2));
            if ~row.withinBounds
                row.status = 'OUTSIDE_TRIM_BOUNDS';
                rows(idx)=row; continue;
            end
            try
                pt = stage2_evaluate_trim_point('M1_EVIDENCE_V1_PROPAGATION',condition,definition,zn,P);
                row.evaluationReturned = true;
                row.physicalConverged = pt.physicalConverged;
                row.physicalBranchSupported = pt.physicalBranchSupported;
                row.status = pt.physicalStatus;
                row.residualNormRaw = norm(pt.residual);
                row.residual1 = pt.residual(1); row.residual2 = pt.residual(2); row.residual3 = pt.residual(3);
                if ~isempty(pt.allocation)
                    row.cyclicLong = pt.allocation.cyclicLong;
                    row.elevator = pt.allocation.elevator;
                end
            catch ME
                row.errorIdentifier = ME.identifier;
                row.errorMessage = ME.message;
                row.status = ['ERROR:' ME.identifier];
            end
            rows(idx)=row;
        end
    end
end

points = struct2table(rows);
writetable(points,fullfile(outputRoot,'STAGE2_B45_SIGNED_NEIGHBOR_POINTS.csv'));

summaryRows = repmat(empty_summary(),numel(fractions),1);
for k = 1:numel(fractions)
    mask = abs(points.stepFraction-fractions(k)) < eps;
    T = points(mask,:);
    s = empty_summary(); s.stepFraction = fractions(k);
    s.totalNeighbors = height(T);
    s.returnedCount = sum(T.evaluationReturned);
    s.physicalSupportedCount = sum(T.physicalConverged & T.physicalBranchSupported);
    s.flapNotConvergedCount = sum(contains(string(T.errorIdentifier),'FlapNotConverged'));
    s.otherErrorCount = sum(strlength(string(T.errorIdentifier))>0) - s.flapNotConvergedCount;
    s.allSixSupported = s.physicalSupportedCount==6;
    summaryRows(k)=s;
end
summary = struct2table(summaryRows);
writetable(summary,fullfile(outputRoot,'STAGE2_B45_SIGNED_NEIGHBOR_SUMMARY.csv'));

results = struct(); results.points=points; results.summary=summary;
results.baseZ=z0; results.baseResidual=base.residual; results.variableScale=definition.variableScale;
results.sourceWorkflowRun=33300606420; results.modelIdentity='M1_EVIDENCE_V1_PROPAGATION';
results.claimBoundary='NUMERICAL_LOCAL_SUPPORT_DIAGNOSTIC_NO_MODEL_OR_CONTROL_CHANGE';
save(fullfile(outputRoot,'STAGE2_B45_SIGNED_NEIGHBOR_AUDIT.mat'),'results');
disp(summary); disp(points);
end

function r=empty_row()
r=struct('stepFraction',NaN,'variableIndex',NaN,'variableName','','sign',NaN,'delta',NaN, ...
    'z1',NaN,'z2',NaN,'z3',NaN,'withinBounds',false,'evaluationReturned',false, ...
    'physicalConverged',false,'physicalBranchSupported',false,'status','NOT_RUN', ...
    'errorIdentifier','','errorMessage','','residualNormRaw',NaN,'residual1',NaN, ...
    'residual2',NaN,'residual3',NaN,'cyclicLong',NaN,'elevator',NaN);
end
function s=empty_summary()
s=struct('stepFraction',NaN,'totalNeighbors',0,'returnedCount',0, ...
    'physicalSupportedCount',0,'flapNotConvergedCount',0,'otherErrorCount',0,'allSixSupported',false);
end
