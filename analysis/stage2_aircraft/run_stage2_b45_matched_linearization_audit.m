function results = run_stage2_b45_matched_linearization_audit(outputRoot)
%RUN_STAGE2_B45_MATCHED_LINEARIZATION_AUDIT
% Branch-safe whole-aircraft 9x7 numerical linearization at B45_V035.
%
% M0 uses its canonical credible trim. M1 uses the final credible point from
% run_stage2_b45_adaptive_path_trim_extension_audit, not the stale direct
% fminsearch result. Perturbed M1 evaluations are initialized from the
% center-point left/right flap states so the Jacobian follows the same
% supported physical branch. No model equation, physical parameter, solver
% tolerance/iteration limit, trim bound, or control DOF is changed.
%
% Two fixed finite-difference scales are evaluated. Unsupported perturbed
% points are retained as evidence and make that linearization non-credible;
% they are never clipped, sign-flipped, or replaced by tuned steps.

if nargin < 1 || isempty(outputRoot)
    outputRoot = fullfile(pwd,'results','stage2_b45_matched_linearization');
end
if ~exist(outputRoot,'dir'), mkdir(outputRoot); end

P = stage2_matched_rotor_parameters();
d2r = pi/180;
condition = struct('name','B45_V035','V',35,'betaM',45*d2r,'gamma',0, ...
    'mode','conversion_longitudinal');
stateNames = {'u','v','w','p','q','r','phi','theta','psi'};
derivativeNames = {'udot','vdot','wdot','pdot','qdot','rdot','phidot','thetadot','psidot'};
inputNames = {'collective','diffCollective','cyclicLong','diffCyclicLong','aileron','elevator','rudder'};

% Fixed a-priori numerical perturbations; the second audit scale is exactly
% one half of these values. They are numerical probes only, not parameters.
baseDx = [0.05;0.05;0.05;5e-4;5e-4;5e-4;5e-4;5e-4;5e-4];
baseDu = 5e-4*ones(7,1);
stepScales = [1.0 0.5];

% M0 center: canonical primary trim is already credible.
[x0,u0,r0] = stage2_trim_longitudinal('M0_MATCHED_PRODUCTION',condition,P, ...
    struct('mode',condition.mode));
if ~r0.credible
    error('run_stage2_b45_matched_linearization_audit:M0CenterNotCredible', ...
        'B45 M0 center must be credible before matched linearization.');
end
m0 = make_center('M0_MATCHED_PRODUCTION','CANONICAL_PRIMARY_TRIM', ...
    x0,u0,r0.point,r0.residualNorm,r0.credible);

% M1 center: regenerate the independently audited second continuation segment.
m1Dir = fullfile(outputRoot,'m1_b45_trim_path');
m1Trim = run_stage2_b45_adaptive_path_trim_extension_audit(m1Dir);
m1Credible = logical(m1Trim.summary.credible(1));
if ~m1Credible
    error('run_stage2_b45_matched_linearization_audit:M1CenterNotCredible', ...
        'Final adaptive-path B45 M1 center must be credible before linearization.');
end
m1 = make_center('M1_EVIDENCE_V1_PROPAGATION','ADAPTIVE_PATH_EXTENSION_FINAL', ...
    m1Trim.finalPoint.x9,m1Trim.finalPoint.u7,m1Trim.finalPoint, ...
    norm(m1Trim.finalPoint.residual),m1Credible);

centers = [m0 m1];
centerRows = repmat(empty_center_row(),numel(centers),1);
for i = 1:numel(centers)
    c = centers(i);
    row = empty_center_row();
    row.caseName = condition.name;
    row.modelIdentity = c.modelIdentity;
    row.centerSource = c.centerSource;
    row.credible = c.credible;
    row.residualNorm = c.residualNorm;
    row.physicalConverged = logical(c.point.physicalConverged);
    row.physicalBranchSupported = logical(c.point.physicalBranchSupported);
    row.physicalStatus = char(c.point.physicalStatus);
    row.theta_deg = c.x(8)/d2r;
    row.collective_deg = c.u(1)/d2r;
    row.cyclicLong_deg = c.u(3)/d2r;
    row.elevator_deg = c.u(6)/d2r;
    centerRows(i) = row;
end
centerTable = struct2table(centerRows);
writetable(centerTable,fullfile(outputRoot,'STAGE2_B45_LINEARIZATION_CENTERS.csv'));

summaryRows = repmat(empty_summary(),numel(centers)*numel(stepScales),1);
perturbRows = repmat(empty_perturb(),0,1);
matrixRows = repmat(empty_matrix_row(),0,1);
eigRows = repmat(empty_eig_row(),0,1);
controlRows = repmat(empty_control_row(),0,1);
linearizations = cell(numel(centers),numel(stepScales));
idx = 0;

for i = 1:numel(centers)
    for s = 1:numel(stepScales)
        idx = idx+1;
        scale = stepScales(s);
        [A,B,rep,pRows] = branch_safe_linearize(centers(i),condition,P, ...
            baseDx*scale,baseDu*scale,stateNames,inputNames);
        linearizations{i,s} = struct('A',A,'B',B,'report',rep);
        perturbRows = [perturbRows; pRows]; %#ok<AGROW>

        sr = empty_summary();
        sr.caseName = condition.name;
        sr.modelIdentity = centers(i).modelIdentity;
        sr.centerSource = centers(i).centerSource;
        sr.stepScale = scale;
        sr.centerCredible = centers(i).credible;
        sr.baselineSupported = rep.baselineSupported;
        sr.supportedStateColumns = sum(rep.stateColumnSupported);
        sr.supportedInputColumns = sum(rep.inputColumnSupported);
        sr.allPerturbationsSupported = rep.allPerturbationsSupported;
        sr.finiteMatrices = rep.finiteMatrices;
        sr.linearizationCredible = rep.allPerturbationsSupported && rep.finiteMatrices;
        if rep.finiteMatrices
            lam = eig(A);
            sr.spectralAbscissa = max(real(lam));
            sr.unstableEigenvalueCount = sum(real(lam)>1e-6);
            sr.maxAbsImagEigenvalue = max(abs(imag(lam)));
            sr.A_fro = norm(A,'fro');
            sr.B_fro = norm(B,'fro');
            for k = 1:numel(lam)
                er = empty_eig_row();
                er.caseName = condition.name;
                er.modelIdentity = centers(i).modelIdentity;
                er.stepScale = scale;
                er.modeIndex = k;
                er.realPart = real(lam(k));
                er.imagPart = imag(lam(k));
                er.wn_radps = abs(lam(k));
                if er.wn_radps>0, er.dampingRatio = -er.realPart/er.wn_radps; end
                eigRows(end+1,1) = er; %#ok<AGROW>
            end
            for j = 1:numel(inputNames)
                cr = empty_control_row();
                cr.caseName = condition.name;
                cr.modelIdentity = centers(i).modelIdentity;
                cr.stepScale = scale;
                cr.inputIndex = j;
                cr.inputName = inputNames{j};
                cr.BcolumnNorm = norm(B(:,j));
                cr.udotGain = B(1,j); cr.wdotGain = B(3,j);
                cr.pdotGain = B(4,j); cr.qdotGain = B(5,j); cr.rdotGain = B(6,j);
                controlRows(end+1,1) = cr; %#ok<AGROW>
            end
        end
        summaryRows(idx) = sr;
        matrixRows = [matrixRows; matrix_to_rows(condition.name,centers(i).modelIdentity,scale, ...
            'A',A,derivativeNames,stateNames); ...
            matrix_to_rows(condition.name,centers(i).modelIdentity,scale, ...
            'B',B,derivativeNames,inputNames)]; %#ok<AGROW>
    end
end

summaryTable = struct2table(summaryRows);
perturbTable = struct2table(perturbRows);
matrixTable = struct2table(matrixRows);
eigenTable = struct2table(eigRows);
controlTable = struct2table(controlRows);
writetable(summaryTable,fullfile(outputRoot,'STAGE2_B45_LINEARIZATION_SUMMARY.csv'));
writetable(perturbTable,fullfile(outputRoot,'STAGE2_B45_PERTURBATION_SUPPORT.csv'));
writetable(matrixTable,fullfile(outputRoot,'STAGE2_B45_AB_MATRICES_LONG.csv'));
writetable(eigenTable,fullfile(outputRoot,'STAGE2_B45_EIGENVALUES.csv'));
writetable(controlTable,fullfile(outputRoot,'STAGE2_B45_CONTROL_EFFECTIVENESS.csv'));

% Numerical step-size sensitivity within each model identity.
stepRows = repmat(empty_step_row(),numel(centers),1);
for i = 1:numel(centers)
    coarse = linearizations{i,1}; fine = linearizations{i,2};
    rr = empty_step_row();
    rr.caseName = condition.name; rr.modelIdentity = centers(i).modelIdentity;
    rr.coarseScale = stepScales(1); rr.fineScale = stepScales(2);
    rr.comparable = coarse.report.finiteMatrices && fine.report.finiteMatrices;
    if rr.comparable
        rr.relativeA_FroDifference = norm(fine.A-coarse.A,'fro')/max(norm(fine.A,'fro'),eps);
        rr.relativeB_FroDifference = norm(fine.B-coarse.B,'fro')/max(norm(fine.B,'fro'),eps);
        rr.spectralAbscissaDifference = max(real(eig(fine.A)))-max(real(eig(coarse.A)));
    end
    stepRows(i) = rr;
end
stepTable = struct2table(stepRows);
writetable(stepTable,fullfile(outputRoot,'STAGE2_B45_STEP_SENSITIVITY.csv'));

% M0 -> M1 propagation difference at the finer fixed scale. This is a model
% propagation comparison, not an external-validation error metric.
prop = empty_propagation_row(); prop.caseName = condition.name;
prop.stepScale = stepScales(2);
m0Fine = linearizations{1,2}; m1Fine = linearizations{2,2};
prop.comparable = m0Fine.report.finiteMatrices && m1Fine.report.finiteMatrices;
if prop.comparable
    prop.relativeA_FroDifference = norm(m1Fine.A-m0Fine.A,'fro')/max(norm(m0Fine.A,'fro'),eps);
    prop.relativeB_FroDifference = norm(m1Fine.B-m0Fine.B,'fro')/max(norm(m0Fine.B,'fro'),eps);
    lam0=eig(m0Fine.A); lam1=eig(m1Fine.A);
    prop.M0SpectralAbscissa=max(real(lam0)); prop.M1SpectralAbscissa=max(real(lam1));
    prop.deltaSpectralAbscissa=prop.M1SpectralAbscissa-prop.M0SpectralAbscissa;
    prop.M0UnstableCount=sum(real(lam0)>1e-6); prop.M1UnstableCount=sum(real(lam1)>1e-6);
end
propTable=struct2table(prop);
writetable(propTable,fullfile(outputRoot,'STAGE2_B45_M0_M1_PROPAGATION_DELTA.csv'));

metadata = table({'B45_V035';'9_STATE_7_CONTROL_RIGID_BODY';'CENTRAL_FIXED_STEP_TWO_SCALE'; ...
    'CENTER_FLAP_STATE_SEEDED_FOR_M1_PERTURBATIONS'; ...
    'NO_PHYSICS_PARAMETER_TOLERANCE_BOUND_OR_DOF_CHANGE'; ...
    'WHOLE_AIRCRAFT_PROPAGATION_SENSITIVITY_NOT_XV15_AIRCRAFT_VALIDATION'}, ...
    'VariableNames',{'metadataValue'});
writetable(metadata,fullfile(outputRoot,'STAGE2_B45_LINEARIZATION_METADATA.csv'));

results=struct('condition',condition,'centers',centers,'centerTable',centerTable, ...
    'summary',summaryTable,'perturbations',perturbTable,'matrices',matrixTable, ...
    'eigenvalues',eigenTable,'controlEffectiveness',controlTable, ...
    'stepSensitivity',stepTable,'propagationDelta',propTable, ...
    'linearizations',{linearizations},'m1Trim',m1Trim, ...
    'claimBoundary','WHOLE_AIRCRAFT_PROPAGATION_SENSITIVITY_NOT_XV15_AIRCRAFT_VALIDATION');
save(fullfile(outputRoot,'STAGE2_B45_MATCHED_LINEARIZATION_AUDIT.mat'),'results');

disp(centerTable); disp(summaryTable); disp(stepTable); disp(propTable);
end

function center=make_center(modelIdentity,source,x,u,point,residualNorm,credible)
center=struct('modelIdentity',modelIdentity,'centerSource',source,'x',x(:),'u',u(:), ...
    'point',point,'residualNorm',residualNorm,'credible',logical(credible));
end

function [A,B,report,rows] = branch_safe_linearize(center,condition,P,dx,du,stateNames,inputNames)
Pnum=P;
if strcmp(center.modelIdentity,'M1_EVIDENCE_V1_PROPAGATION')
    Pnum.stage2Numerics.flapInitialLeft=center.point.eomOut.components.rotorLeft.zFlap(:);
    Pnum.stage2Numerics.flapInitialRight=center.point.eomOut.components.rotorRight.zFlap(:);
end
[f0,~,ok0,status0]=eval_safe(center.modelIdentity,center.x,center.u,condition.betaM,Pnum);
A=NaN(9,9); B=NaN(9,7); stateOK=false(9,1); inputOK=false(7,1);
rows=repmat(empty_perturb(),0,1);
for j=1:9
    xp=center.x; xm=center.x; xp(j)=xp(j)+dx(j); xm(j)=xm(j)-dx(j);
    [fp,~,okp,sp]=eval_safe(center.modelIdentity,xp,center.u,condition.betaM,Pnum);
    [fm,~,okm,sm]=eval_safe(center.modelIdentity,xm,center.u,condition.betaM,Pnum);
    if okp&&okm, A(:,j)=(fp-fm)/(2*dx(j)); stateOK(j)=true; end
    r=empty_perturb(); r.caseName=condition.name; r.modelIdentity=center.modelIdentity;
    r.stepScale=dx(j); r.variableKind='STATE'; r.variableIndex=j; r.variableName=stateNames{j};
    r.plusSupported=okp; r.minusSupported=okm; r.plusStatus=sp; r.minusStatus=sm; rows(end+1,1)=r; %#ok<AGROW>
end
for j=1:7
    up=center.u; um=center.u; up(j)=up(j)+du(j); um(j)=um(j)-du(j);
    [fp,~,okp,sp]=eval_safe(center.modelIdentity,center.x,up,condition.betaM,Pnum);
    [fm,~,okm,sm]=eval_safe(center.modelIdentity,center.x,um,condition.betaM,Pnum);
    if okp&&okm, B(:,j)=(fp-fm)/(2*du(j)); inputOK(j)=true; end
    r=empty_perturb(); r.caseName=condition.name; r.modelIdentity=center.modelIdentity;
    r.stepScale=du(j); r.variableKind='INPUT'; r.variableIndex=j; r.variableName=inputNames{j};
    r.plusSupported=okp; r.minusSupported=okm; r.plusStatus=sp; r.minusStatus=sm; rows(end+1,1)=r; %#ok<AGROW>
end
report=struct(); report.f0=f0; report.baselineSupported=ok0; report.baselineStatus=status0;
report.stateColumnSupported=stateOK; report.inputColumnSupported=inputOK;
report.allPerturbationsSupported=ok0&&all(stateOK)&&all(inputOK);
report.finiteMatrices=report.allPerturbationsSupported && all(isfinite(A(:))) && all(isfinite(B(:))) && isreal(A) && isreal(B);
report.dx=dx; report.du=du;
end

function [xdot,out,ok,status]=eval_safe(modelIdentity,x,u,betaM,P)
xdot=NaN(9,1); out=struct(); ok=false; status='NOT_EVALUATED';
try
    [xdot,out]=stage2_tiltrotor_eom(modelIdentity,x,u,betaM,P);
    finiteReal=isreal(xdot)&&all(isfinite(xdot));
    ok=finiteReal && logical(out.physicalConverged) && logical(out.physicalBranchSupported);
    if ok, status='SUPPORTED';
    elseif ~finiteReal, status='NONFINITE_OR_COMPLEX';
    else, status=char(out.physicalStatus); end
catch ME
    status=['ERROR:' ME.identifier];
end
end

function rows=matrix_to_rows(caseName,modelIdentity,scale,matrixName,M,rowNames,colNames)
rows=repmat(empty_matrix_row(),numel(M),1); k=0;
for i=1:size(M,1)
    for j=1:size(M,2)
        k=k+1; rows(k).caseName=caseName; rows(k).modelIdentity=modelIdentity;
        rows(k).stepScale=scale; rows(k).matrixName=matrixName; rows(k).rowIndex=i;
        rows(k).rowName=rowNames{i}; rows(k).colIndex=j; rows(k).colName=colNames{j}; rows(k).value=M(i,j);
    end
end
end

function r=empty_center_row()
r=struct('caseName','','modelIdentity','','centerSource','','credible',false,'residualNorm',NaN, ...
    'physicalConverged',false,'physicalBranchSupported',false,'physicalStatus','', ...
    'theta_deg',NaN,'collective_deg',NaN,'cyclicLong_deg',NaN,'elevator_deg',NaN);
end
function r=empty_summary()
r=struct('caseName','','modelIdentity','','centerSource','','stepScale',NaN,'centerCredible',false, ...
    'baselineSupported',false,'supportedStateColumns',0,'supportedInputColumns',0, ...
    'allPerturbationsSupported',false,'finiteMatrices',false,'linearizationCredible',false, ...
    'spectralAbscissa',NaN,'unstableEigenvalueCount',NaN,'maxAbsImagEigenvalue',NaN,'A_fro',NaN,'B_fro',NaN);
end
function r=empty_perturb()
r=struct('caseName','','modelIdentity','','stepScale',NaN,'variableKind','','variableIndex',NaN, ...
    'variableName','','plusSupported',false,'minusSupported',false,'plusStatus','','minusStatus','');
end
function r=empty_matrix_row()
r=struct('caseName','','modelIdentity','','stepScale',NaN,'matrixName','','rowIndex',NaN,'rowName','', ...
    'colIndex',NaN,'colName','','value',NaN);
end
function r=empty_eig_row()
r=struct('caseName','','modelIdentity','','stepScale',NaN,'modeIndex',NaN,'realPart',NaN,'imagPart',NaN, ...
    'wn_radps',NaN,'dampingRatio',NaN);
end
function r=empty_control_row()
r=struct('caseName','','modelIdentity','','stepScale',NaN,'inputIndex',NaN,'inputName','', ...
    'BcolumnNorm',NaN,'udotGain',NaN,'wdotGain',NaN,'pdotGain',NaN,'qdotGain',NaN,'rdotGain',NaN);
end
function r=empty_step_row()
r=struct('caseName','','modelIdentity','','coarseScale',NaN,'fineScale',NaN,'comparable',false, ...
    'relativeA_FroDifference',NaN,'relativeB_FroDifference',NaN,'spectralAbscissaDifference',NaN);
end
function r=empty_propagation_row()
r=struct('caseName','','stepScale',NaN,'comparable',false,'relativeA_FroDifference',NaN, ...
    'relativeB_FroDifference',NaN,'M0SpectralAbscissa',NaN,'M1SpectralAbscissa',NaN, ...
    'deltaSpectralAbscissa',NaN,'M0UnstableCount',NaN,'M1UnstableCount',NaN);
end
