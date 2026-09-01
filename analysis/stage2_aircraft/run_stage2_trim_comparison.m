function results = run_stage2_trim_comparison(outputRoot)
%RUN_STAGE2_TRIM_COMPARISON Formal whole-aircraft M0/M1 trim propagation.
%
% Six primary solves are executed from the canonical explicit trim seeds:
%   B15_V020 x {M0_MATCHED_PRODUCTION,M1_EVIDENCE_V1_PROPAGATION}
%   B45_V035 x {M0_MATCHED_PRODUCTION,M1_EVIDENCE_V1_PROPAGATION}
%   B75_V080 x {M0_MATCHED_PRODUCTION,M1_EVIDENCE_V1_PROPAGATION}
% No failed primary solve is replaced by a tuned/continued result.  A delta
% row is scientifically comparable only when both primary solves are credible.

if nargin < 1 || isempty(outputRoot)
    outputRoot = fullfile(pwd,'results','stage2_aircraft_trim');
end
if ~exist(outputRoot,'dir'), mkdir(outputRoot); end

P = stage2_matched_rotor_parameters();
d2r = pi/180;
conditions = repmat(struct('name','','V',NaN,'betaM',NaN,'gamma',0,'mode',''),3,1);
conditions(1) = struct('name','B15_V020','V',20,'betaM',15*d2r,'gamma',0, ...
    'mode','helicopter_longitudinal');
conditions(2) = struct('name','B45_V035','V',35,'betaM',45*d2r,'gamma',0, ...
    'mode','conversion_longitudinal');
conditions(3) = struct('name','B75_V080','V',80,'betaM',75*d2r,'gamma',0, ...
    'mode','airplane_longitudinal');
models = {'M0_MATCHED_PRODUCTION','M1_EVIDENCE_V1_PROPAGATION'};

emptyRow = make_empty_row();
rows = repmat(emptyRow,numel(conditions)*numel(models),1);
reports = cell(numel(conditions),numel(models));
idx = 0;
for i = 1:numel(conditions)
    for j = 1:numel(models)
        idx = idx+1;
        row = emptyRow;
        row.caseName = conditions(i).name;
        row.modelIdentity = models{j};
        row.mode = conditions(i).mode;
        row.V_mps = conditions(i).V;
        row.betaM_deg = conditions(i).betaM/d2r;
        row.gamma_deg = conditions(i).gamma/d2r;
        opts = struct('mode',conditions(i).mode);
        try
            [xTrim,uTrim,report] = stage2_trim_longitudinal( ...
                models{j},conditions(i),P,opts);
            reports{i,j} = report;
            row = fill_row(row,xTrim,uTrim,report,conditions(i),P);
        catch ME
            if is_expected_model_domain_error(ME)
                row.solveReturned = false;
                row.status = ['MODEL_DOMAIN_ERROR:' ME.identifier];
                row.physicalStatus = ME.identifier;
                reports{i,j} = ME;
            else
                rethrow(ME);
            end
        end
        rows(idx) = row;
    end
end

points = struct2table(rows);
writetable(points,fullfile(outputRoot,'STAGE2_TRIM_POINTS.csv'));

deltaRows = repmat(make_empty_delta(),numel(conditions),1);
for i = 1:numel(conditions)
    m0 = rows((i-1)*2+1);
    m1 = rows((i-1)*2+2);
    d = make_empty_delta();
    d.caseName = conditions(i).name;
    d.M0Credible = m0.credible;
    d.M1Credible = m1.credible;
    d.comparable = m0.credible && m1.credible;
    if d.comparable
        d.status = 'COMPARABLE_PRIMARY_TRIMS';
        d.deltaTheta_deg = m1.theta_deg-m0.theta_deg;
        d.deltaAlpha_deg = m1.alpha_deg-m0.alpha_deg;
        d.deltaCollective_deg = m1.collective_deg-m0.collective_deg;
        d.deltaCyclicLong_deg = m1.cyclicLong_deg-m0.cyclicLong_deg;
        d.deltaElevator_deg = m1.elevator_deg-m0.elevator_deg;
        d.deltaMeanThrust_N = m1.meanRotorThrust_N-m0.meanRotorThrust_N;
        d.deltaMeanTorque_Nm = m1.meanRotorTorque_Nm-m0.meanRotorTorque_Nm;
        d.deltaTotalRotorPower_kW = m1.totalRotorPower_kW-m0.totalRotorPower_kW;
        d.deltaMeanInducedVelocity_mps = ...
            m1.meanInducedVelocity_mps-m0.meanInducedVelocity_mps;
        d.deltaMeanH_N = m1.meanH_N-m0.meanH_N;
        d.deltaMeanBeta0_deg = m1.meanBeta0_deg-m0.meanBeta0_deg;
        d.deltaMeanBeta1c_deg = m1.meanBeta1c_deg-m0.meanBeta1c_deg;
        d.deltaMeanBeta1s_deg = m1.meanBeta1s_deg-m0.meanBeta1s_deg;
    else
        d.status = sprintf('NOT_COMPARABLE_M0_%s__M1_%s', ...
            compact_status(m0.status),compact_status(m1.status));
    end
    deltaRows(i) = d;
end

deltas = struct2table(deltaRows);
writetable(deltas,fullfile(outputRoot,'STAGE2_M0_M1_TRIM_DELTAS.csv'));

summary = table(sum(points.credible & strcmp(points.modelIdentity,'M0_MATCHED_PRODUCTION')), ...
    sum(points.credible & strcmp(points.modelIdentity,'M1_EVIDENCE_V1_PROPAGATION')), ...
    sum(deltas.comparable), sum(points.solveReturned), ...
    'VariableNames',{'M0CredibleCount','M1CredibleCount', ...
    'ComparableCaseCount','ReturnedSolveCount'});
writetable(summary,fullfile(outputRoot,'STAGE2_TRIM_SUMMARY.csv'));

results = struct();
results.conditions = conditions;
results.points = points;
results.deltas = deltas;
results.summary = summary;
results.reports = reports;
results.parameterRole = P.stage2RotorMapping;
results.claimBoundary = ...
    'WHOLE_AIRCRAFT_PROPAGATION_SENSITIVITY_NOT_XV15_AIRCRAFT_VALIDATION';
save(fullfile(outputRoot,'STAGE2_TRIM_COMPARISON.mat'),'results');

disp(points);
disp(deltas);
disp(summary);
end

function row = fill_row(row,xTrim,uTrim,report,condition,P)
row.solveReturned = true;
row.credible = logical(report.credible);
row.solverConverged = logical(report.solverConverged);
row.physicalConverged = logical(report.physicalConverged);
row.physicalBranchSupported = logical(report.physicalBranchSupported);
row.residualNorm = report.residualNorm;
row.physicalStatus = report.physicalStatus;
row.status = classify_report(report,P);
row.theta_deg = xTrim(8)*180/pi;
row.alpha_deg = (xTrim(8)-condition.gamma)*180/pi;
row.collective_deg = uTrim(1)*180/pi;
row.cyclicLong_deg = uTrim(3)*180/pi;
row.elevator_deg = uTrim(6)*180/pi;
row.pitchCommand = NaN;
if isfield(report.trimVariables,'pitchCommand')
    row.pitchCommand = report.trimVariables.pitchCommand;
end
row.atLimit = logical(report.atLimit);
row.withinLimits = logical(report.withinLimits);
row.invalidEvaluationCount = report.invalidEvaluationCount;

comp = report.point.eomOut.components;
left = comp.rotorLeft;
right = comp.rotorRight;
row.leftThrust_N = left.thrust;
row.rightThrust_N = right.thrust;
row.meanRotorThrust_N = 0.5*(left.thrust+right.thrust);
row.leftTorque_Nm = left.torque;
row.rightTorque_Nm = right.torque;
row.meanRotorTorque_Nm = 0.5*(left.torque+right.torque);
row.totalRotorPower_kW = (left.torque+right.torque)*P.rotor.Omega/1000;
row.leftInducedVelocity_mps = left.inducedVelocity;
row.rightInducedVelocity_mps = right.inducedVelocity;
row.meanInducedVelocity_mps = 0.5*(left.inducedVelocity+right.inducedVelocity);
row.leftH_N = hypot(left.Hlong,left.Hlat);
row.rightH_N = hypot(right.Hlong,right.Hlat);
row.meanH_N = 0.5*(row.leftH_N+row.rightH_N);
row.meanBeta0_deg = 0.5*(left.beta0+right.beta0)*180/pi;
row.meanBeta1c_deg = 0.5*(left.beta1c+right.beta1c)*180/pi;
row.meanBeta1s_deg = 0.5*(left.beta1s+right.beta1s)*180/pi;
row.leftClosureRelative = left.inducedClosureResidualRelative;
row.rightClosureRelative = right.inducedClosureResidualRelative;
row.leftPropagationBranch = get_char_field(left,'propagationBranch','PRODUCTION_M0');
row.rightPropagationBranch = get_char_field(right,'propagationBranch','PRODUCTION_M0');
end

function status = classify_report(report,P)
if report.credible
    status = 'CREDIBLE';
elseif ~report.solverConverged
    status = 'SOLVER_NOT_CONVERGED';
elseif ~report.physicalConverged
    status = ['PHYSICAL:' report.physicalStatus];
elseif report.atLimit || ~report.withinLimits
    status = 'BOUNDARY_LIMITED';
elseif report.residualNorm >= P.trim.residualTolerance
    status = 'RESIDUAL_FAILED';
else
    status = 'NONCREDIBLE_UNCLASSIFIED';
end
end

function tf = is_expected_model_domain_error(ME)
tf = startsWith(ME.identifier,'m1_evidence_v1_forward_rotor:') || ...
    startsWith(ME.identifier,'rotor_model_bemt:') || ...
    strcmp(ME.identifier,'pitch_allocation_schedule:InvalidPitchCommand');
end

function value = get_char_field(S,name,defaultValue)
if isfield(S,name), value = char(S.(name)); else, value = defaultValue; end
end

function s = compact_status(s)
s = strrep(s,':','_');
s = strrep(s,' ','_');
end

function row = make_empty_row()
row = struct('caseName','','modelIdentity','','mode','','V_mps',NaN, ...
    'betaM_deg',NaN,'gamma_deg',NaN,'solveReturned',false,'credible',false, ...
    'solverConverged',false,'physicalConverged',false, ...
    'physicalBranchSupported',false,'residualNorm',NaN,'status','NOT_RUN', ...
    'physicalStatus','NOT_RUN','theta_deg',NaN,'alpha_deg',NaN, ...
    'collective_deg',NaN,'cyclicLong_deg',NaN,'elevator_deg',NaN, ...
    'pitchCommand',NaN,'atLimit',false,'withinLimits',false, ...
    'invalidEvaluationCount',NaN,'leftThrust_N',NaN,'rightThrust_N',NaN, ...
    'meanRotorThrust_N',NaN,'leftTorque_Nm',NaN,'rightTorque_Nm',NaN, ...
    'meanRotorTorque_Nm',NaN,'totalRotorPower_kW',NaN, ...
    'leftInducedVelocity_mps',NaN,'rightInducedVelocity_mps',NaN, ...
    'meanInducedVelocity_mps',NaN,'leftH_N',NaN,'rightH_N',NaN, ...
    'meanH_N',NaN,'meanBeta0_deg',NaN,'meanBeta1c_deg',NaN, ...
    'meanBeta1s_deg',NaN,'leftClosureRelative',NaN,'rightClosureRelative',NaN, ...
    'leftPropagationBranch','','rightPropagationBranch','');
end

function d = make_empty_delta()
d = struct('caseName','','M0Credible',false,'M1Credible',false, ...
    'comparable',false,'status','NOT_RUN','deltaTheta_deg',NaN, ...
    'deltaAlpha_deg',NaN,'deltaCollective_deg',NaN, ...
    'deltaCyclicLong_deg',NaN,'deltaElevator_deg',NaN, ...
    'deltaMeanThrust_N',NaN,'deltaMeanTorque_Nm',NaN, ...
    'deltaTotalRotorPower_kW',NaN,'deltaMeanInducedVelocity_mps',NaN, ...
    'deltaMeanH_N',NaN,'deltaMeanBeta0_deg',NaN, ...
    'deltaMeanBeta1c_deg',NaN,'deltaMeanBeta1s_deg',NaN);
end