function results = run_stage2_b45_branch_tracked_linearization_audit(outputRoot)
%RUN_STAGE2_B45_BRANCH_TRACKED_LINEARIZATION_AUDIT
% Fixed-endpoint 9x7 numerical linearization at the credible B45 trim using
% adaptive path continuation only as a numerical branch-tracking mechanism.
%
% The derivative endpoints and finite-difference steps are fixed a priori.
% If a direct M1 endpoint evaluation fails, the evaluator walks from the
% credible center to that exact endpoint while carrying only the converged
% left/right flap states. No endpoint is moved, no derivative is fitted to
% experimental data, and no physical parameter, solver tolerance/iteration
% limit, trim bound, or control DOF is changed.

if nargin < 1 || isempty(outputRoot)
    outputRoot = fullfile(pwd,'results','stage2_b45_branch_tracked_linearization');
end
if ~exist(outputRoot,'dir'), mkdir(outputRoot); end

P = stage2_matched_rotor_parameters();
d2r = pi/180;
condition = struct('name','B45_V035','V',35,'betaM',45*d2r,'gamma',0, ...
    'mode','conversion_longitudinal');
stateNames = {'u','v','w','p','q','r','phi','theta','psi'};
derivativeNames = {'udot','vdot','wdot','pdot','qdot','rdot','phidot','thetadot','psidot'};
inputNames = {'collective','diffCollective','cyclicLong','diffCyclicLong','aileron','elevator','rudder'};
baseDx = [0.05;0.05;0.05;5e-4;5e-4;5e-4;5e-4;5e-4;5e-4];
baseDu = 5e-4*ones(7,1);
stepScales = [1.0 0.5];
minPathDt = 2^-14;
maxPathAttempts = 80;

[x0,u0,r0] = stage2_trim_longitudinal('M0_MATCHED_PRODUCTION',condition,P, ...
    struct('mode',condition.mode));
assert(r0.credible,'B45BranchLinearization:M0CenterNotCredible');
m0 = make_center('M0_MATCHED_PRODUCTION','CANONICAL_PRIMARY_TRIM',x0,u0,r0.point,r0.residualNorm,r0.credible);

m1Dir = fullfile(outputRoot,'m1_b45_trim_path');
m1Trim = run_stage2_b45_adaptive_path_trim_extension_audit(m1Dir);
assert(logical(m1Trim.summary.credible(1)),'B45BranchLinearization:M1CenterNotCredible');
m1 = make_center('M1_EVIDENCE_V1_PROPAGATION','ADAPTIVE_PATH_EXTENSION_FINAL', ...
    m1Trim.finalPoint.x9,m1Trim.finalPoint.u7,m1Trim.finalPoint, ...
    norm(m1Trim.finalPoint.residual),true);
centers=[m0 m1];

centerRows=repmat(empty_center_row(),2,1);
for i=1:2
    c=centers(i); r=empty_center_row(); r.caseName=condition.name; r.modelIdentity=c.modelIdentity;
    r.centerSource=c.centerSource; r.credible=c.credible; r.residualNorm=c.residualNorm;
    r.physicalConverged=logical(c.point.physicalConverged); r.physicalBranchSupported=logical(c.point.physicalBranchSupported);
    r.physicalStatus=char(c.point.physicalStatus); r.theta_deg=c.x(8)/d2r; r.collective_deg=c.u(1)/d2r;
    r.cyclicLong_deg=c.u(3)/d2r; r.elevator_deg=c.u(6)/d2r; centerRows(i)=r;
end
centerTable=struct2table(centerRows);
writetable(centerTable,fullfile(outputRoot,'STAGE2_B45_BRANCH_LINEARIZATION_CENTERS.csv'));

summaryRows=repmat(empty_summary(),4,1); pathRows=repmat(empty_path_row(),0,1);
matrixRows=repmat(empty_matrix_row(),0,1); eigRows=repmat(empty_eig_row(),0,1); controlRows=repmat(empty_control_row(),0,1);
linearizations=cell(2,2); idx=0;
for i=1:2
    for s=1:2
        idx=idx+1; scale=stepScales(s);
        [A,B,rep,pRows]=tracked_linearize(centers(i),condition,P,baseDx*scale,baseDu*scale, ...
            stateNames,inputNames,minPathDt,maxPathAttempts);
        linearizations{i,s}=struct('A',A,'B',B,'report',rep); pathRows=[pathRows;pRows]; %#ok<AGROW>
        sr=empty_summary(); sr.caseName=condition.name; sr.modelIdentity=centers(i).modelIdentity;
        sr.centerSource=centers(i).centerSource; sr.stepScale=scale; sr.centerCredible=centers(i).credible;
        sr.baselineSupported=rep.baselineSupported; sr.supportedStateColumns=sum(rep.stateColumnSupported);
        sr.supportedInputColumns=sum(rep.inputColumnSupported); sr.allEndpointsSupported=rep.allEndpointsSupported;
        sr.finiteMatrices=rep.finiteMatrices; sr.linearizationCredible=rep.allEndpointsSupported&&rep.finiteMatrices;
        sr.totalPathAttempts=rep.totalPathAttempts; sr.maxEndpointPathAttempts=rep.maxEndpointPathAttempts;
        sr.directEndpointFailureCount=rep.directEndpointFailureCount;
        if rep.finiteMatrices
            lam=eig(A); sr.spectralAbscissa=max(real(lam)); sr.unstableEigenvalueCount=sum(real(lam)>1e-6);
            sr.maxAbsImagEigenvalue=max(abs(imag(lam))); sr.A_fro=norm(A,'fro'); sr.B_fro=norm(B,'fro');
            for k=1:numel(lam)
                er=empty_eig_row(); er.caseName=condition.name; er.modelIdentity=centers(i).modelIdentity;
                er.stepScale=scale; er.modeIndex=k; er.realPart=real(lam(k)); er.imagPart=imag(lam(k));
                er.wn_radps=abs(lam(k)); if er.wn_radps>0, er.dampingRatio=-er.realPart/er.wn_radps; end
                eigRows(end+1,1)=er; %#ok<AGROW>
            end
            for j=1:numel(inputNames)
                cr=empty_control_row(); cr.caseName=condition.name; cr.modelIdentity=centers(i).modelIdentity;
                cr.stepScale=scale; cr.inputIndex=j; cr.inputName=inputNames{j}; cr.BcolumnNorm=norm(B(:,j));
                cr.udotGain=B(1,j); cr.wdotGain=B(3,j); cr.pdotGain=B(4,j); cr.qdotGain=B(5,j); cr.rdotGain=B(6,j);
                controlRows(end+1,1)=cr; %#ok<AGROW>
            end
        end
        summaryRows(idx)=sr;
        matrixRows=[matrixRows; matrix_to_rows(condition.name,centers(i).modelIdentity,scale,'A',A,derivativeNames,stateNames); ...
            matrix_to_rows(condition.name,centers(i).modelIdentity,scale,'B',B,derivativeNames,inputNames)]; %#ok<AGROW>
    end
end
summaryTable=struct2table(summaryRows); pathTable=struct2table(pathRows); matrixTable=struct2table(matrixRows);
eigenTable=struct2table(eigRows); controlTable=struct2table(controlRows);
writetable(summaryTable,fullfile(outputRoot,'STAGE2_B45_BRANCH_LINEARIZATION_SUMMARY.csv'));
writetable(pathTable,fullfile(outputRoot,'STAGE2_B45_BRANCH_ENDPOINT_PATHS.csv'));
writetable(matrixTable,fullfile(outputRoot,'STAGE2_B45_BRANCH_AB_MATRICES_LONG.csv'));
writetable(eigenTable,fullfile(outputRoot,'STAGE2_B45_BRANCH_EIGENVALUES.csv'));
writetable(controlTable,fullfile(outputRoot,'STAGE2_B45_BRANCH_CONTROL_EFFECTIVENESS.csv'));

stepRows=repmat(empty_step_row(),2,1);
for i=1:2
    a=linearizations{i,1}; b=linearizations{i,2}; rr=empty_step_row(); rr.caseName=condition.name;
    rr.modelIdentity=centers(i).modelIdentity; rr.coarseScale=1; rr.fineScale=.5;
    rr.comparable=a.report.finiteMatrices&&b.report.finiteMatrices;
    if rr.comparable
        rr.relativeA_FroDifference=norm(b.A-a.A,'fro')/max(norm(b.A,'fro'),eps);
        rr.relativeB_FroDifference=norm(b.B-a.B,'fro')/max(norm(b.B,'fro'),eps);
        rr.spectralAbscissaDifference=max(real(eig(b.A)))-max(real(eig(a.A)));
    end
    stepRows(i)=rr;
end
stepTable=struct2table(stepRows); writetable(stepTable,fullfile(outputRoot,'STAGE2_B45_BRANCH_STEP_SENSITIVITY.csv'));

prop=empty_propagation_row(); prop.caseName=condition.name; prop.stepScale=.5;
a=linearizations{1,2}; b=linearizations{2,2}; prop.comparable=a.report.finiteMatrices&&b.report.finiteMatrices;
if prop.comparable
    prop.relativeA_FroDifference=norm(b.A-a.A,'fro')/max(norm(a.A,'fro'),eps);
    prop.relativeB_FroDifference=norm(b.B-a.B,'fro')/max(norm(a.B,'fro'),eps);
    l0=eig(a.A); l1=eig(b.A); prop.M0SpectralAbscissa=max(real(l0)); prop.M1SpectralAbscissa=max(real(l1));
    prop.deltaSpectralAbscissa=prop.M1SpectralAbscissa-prop.M0SpectralAbscissa;
    prop.M0UnstableCount=sum(real(l0)>1e-6); prop.M1UnstableCount=sum(real(l1)>1e-6);
end
propTable=struct2table(prop); writetable(propTable,fullfile(outputRoot,'STAGE2_B45_BRANCH_M0_M1_PROPAGATION_DELTA.csv'));

metadata=table({'B45_V035';'9_STATE_7_CONTROL_RIGID_BODY';'FIXED_ENDPOINT_CENTRAL_DIFFERENCE_TWO_SCALE'; ...
    'ADAPTIVE_PATH_ONLY_FOR_NUMERICAL_BRANCH_TRACKING';'CARRY_LEFT_RIGHT_CONVERGED_FLAP_STATES_ONLY'; ...
    'NO_ENDPOINT_PHYSICS_PARAMETER_TOLERANCE_BOUND_OR_DOF_CHANGE'; ...
    'DIRECT_LINEARIZATION_FAILURE_RETAINED_AS_SEPARATE_EVIDENCE'; ...
    'WHOLE_AIRCRAFT_PROPAGATION_SENSITIVITY_NOT_XV15_AIRCRAFT_VALIDATION'},'VariableNames',{'metadataValue'});
writetable(metadata,fullfile(outputRoot,'STAGE2_B45_BRANCH_LINEARIZATION_METADATA.csv'));
results=struct('condition',condition,'centers',centers,'centerTable',centerTable,'summary',summaryTable, ...
    'endpointPaths',pathTable,'matrices',matrixTable,'eigenvalues',eigenTable,'controlEffectiveness',controlTable, ...
    'stepSensitivity',stepTable,'propagationDelta',propTable,'linearizations',{linearizations},'m1Trim',m1Trim, ...
    'claimBoundary','WHOLE_AIRCRAFT_PROPAGATION_SENSITIVITY_NOT_XV15_AIRCRAFT_VALIDATION');
save(fullfile(outputRoot,'STAGE2_B45_BRANCH_TRACKED_LINEARIZATION_AUDIT.mat'),'results');
disp(centerTable); disp(summaryTable); disp(stepTable); disp(propTable);
end

function [A,B,report,rows]=tracked_linearize(center,condition,P,dx,du,stateNames,inputNames,minPathDt,maxPathAttempts)
[f0,o0,ok0,s0]=eval_direct(center.modelIdentity,center.x,center.u,condition.betaM,seedP(P,center.point.eomOut,center.modelIdentity));
A=NaN(9,9); B=NaN(9,7); stateOK=false(9,1); inputOK=false(7,1); rows=repmat(empty_path_row(),0,1);
totalAttempts=0; maxAttempts=0; directFails=0;
for j=1:9
    xp=center.x; xm=center.x; xp(j)=xp(j)+dx(j); xm(j)=xm(j)-dx(j);
    [fp,~,okp,sp,ap,dp]=eval_endpoint(center,xp,center.u,condition.betaM,P,minPathDt,maxPathAttempts);
    [fm,~,okm,sm,am,dm]=eval_endpoint(center,xm,center.u,condition.betaM,P,minPathDt,maxPathAttempts);
    if okp&&okm, A(:,j)=(fp-fm)/(2*dx(j)); stateOK(j)=true; end
    totalAttempts=totalAttempts+ap+am; maxAttempts=max([maxAttempts ap am]); directFails=directFails+(~dp)+(~dm);
    r=empty_path_row(); r.caseName=condition.name; r.modelIdentity=center.modelIdentity; r.variableKind='STATE';
    r.variableIndex=j; r.variableName=stateNames{j}; r.stepMagnitude=dx(j); r.plusSupported=okp; r.minusSupported=okm;
    r.plusDirectSupported=dp; r.minusDirectSupported=dm; r.plusPathAttempts=ap; r.minusPathAttempts=am;
    r.plusStatus=sp; r.minusStatus=sm; rows(end+1,1)=r; %#ok<AGROW>
end
for j=1:7
    up=center.u; um=center.u; up(j)=up(j)+du(j); um(j)=um(j)-du(j);
    [fp,~,okp,sp,ap,dp]=eval_endpoint(center,center.x,up,condition.betaM,P,minPathDt,maxPathAttempts);
    [fm,~,okm,sm,am,dm]=eval_endpoint(center,center.x,um,condition.betaM,P,minPathDt,maxPathAttempts);
    if okp&&okm, B(:,j)=(fp-fm)/(2*du(j)); inputOK(j)=true; end
    totalAttempts=totalAttempts+ap+am; maxAttempts=max([maxAttempts ap am]); directFails=directFails+(~dp)+(~dm);
    r=empty_path_row(); r.caseName=condition.name; r.modelIdentity=center.modelIdentity; r.variableKind='INPUT';
    r.variableIndex=j; r.variableName=inputNames{j}; r.stepMagnitude=du(j); r.plusSupported=okp; r.minusSupported=okm;
    r.plusDirectSupported=dp; r.minusDirectSupported=dm; r.plusPathAttempts=ap; r.minusPathAttempts=am;
    r.plusStatus=sp; r.minusStatus=sm; rows(end+1,1)=r; %#ok<AGROW>
end
report=struct('f0',f0,'centerOut',o0,'baselineSupported',ok0,'baselineStatus',s0, ...
    'stateColumnSupported',stateOK,'inputColumnSupported',inputOK, ...
    'allEndpointsSupported',ok0&&all(stateOK)&&all(inputOK), ...
    'finiteMatrices',ok0&&all(stateOK)&&all(inputOK)&&all(isfinite(A(:)))&&all(isfinite(B(:)))&&isreal(A)&&isreal(B), ...
    'totalPathAttempts',totalAttempts,'maxEndpointPathAttempts',maxAttempts,'directEndpointFailureCount',directFails,'dx',dx,'du',du);
end

function [xdot,out,ok,status,attempts,directSupported]=eval_endpoint(center,xt,ut,betaM,P,minPathDt,maxPathAttempts)
P0=seedP(P,center.point.eomOut,center.modelIdentity);
[xd,out,ok,status]=eval_direct(center.modelIdentity,xt,ut,betaM,P0);
attempts=1; directSupported=ok;
if ok || strcmp(center.modelIdentity,'M0_MATCHED_PRODUCTION')
    xdot=xd; return;
end
% Direct target failed for M1. Walk to the same fixed endpoint.
t=0; dt=1; curOut=center.point.eomOut; xdot=NaN(9,1); out=struct(); ok=false; status='PATH_NOT_REACHED'; attempts=0;
while t<1-1e-14 && attempts<maxPathAttempts
    ttry=min(1,t+dt); xtry=center.x+ttry*(xt-center.x); utry=center.u+ttry*(ut-center.u);
    Pk=seedP(P,curOut,center.modelIdentity); attempts=attempts+1;
    [ft,ot,good,st]=eval_direct(center.modelIdentity,xtry,utry,betaM,Pk);
    if good
        curOut=ot; t=ttry; xdot=ft; out=ot; status=st;
        if t>=1-1e-14, ok=true; return; end
        dt=min(2*dt,1-t);
    else
        dt=.5*dt;
        if dt<minPathDt, status=['PATH_FAILED:' st]; ok=false; return; end
    end
end
end

function Pk=seedP(P,out,modelIdentity)
Pk=P;
if strcmp(modelIdentity,'M1_EVIDENCE_V1_PROPAGATION')
    Pk.stage2Numerics.flapInitialLeft=out.components.rotorLeft.zFlap(:);
    Pk.stage2Numerics.flapInitialRight=out.components.rotorRight.zFlap(:);
end
end
function [xdot,out,ok,status]=eval_direct(modelIdentity,x,u,betaM,P)
xdot=NaN(9,1); out=struct(); ok=false; status='NOT_EVALUATED';
try
    [xdot,out]=stage2_tiltrotor_eom(modelIdentity,x,u,betaM,P);
    finiteReal=isreal(xdot)&&all(isfinite(xdot)); ok=finiteReal&&logical(out.physicalConverged)&&logical(out.physicalBranchSupported);
    if ok, status='SUPPORTED'; elseif ~finiteReal, status='NONFINITE_OR_COMPLEX'; else, status=char(out.physicalStatus); end
catch ME, status=['ERROR:' ME.identifier];
end
end
function center=make_center(modelIdentity,source,x,u,point,residualNorm,credible)
center=struct('modelIdentity',modelIdentity,'centerSource',source,'x',x(:),'u',u(:),'point',point, ...
    'residualNorm',residualNorm,'credible',logical(credible));
end
function rows=matrix_to_rows(caseName,modelIdentity,scale,matrixName,M,rowNames,colNames)
rows=repmat(empty_matrix_row(),numel(M),1); k=0;
for i=1:size(M,1), for j=1:size(M,2), k=k+1; rows(k).caseName=caseName; rows(k).modelIdentity=modelIdentity; rows(k).stepScale=scale;
    rows(k).matrixName=matrixName; rows(k).rowIndex=i; rows(k).rowName=rowNames{i}; rows(k).colIndex=j; rows(k).colName=colNames{j}; rows(k).value=M(i,j); end, end
end
function r=empty_center_row(), r=struct('caseName','','modelIdentity','','centerSource','','credible',false,'residualNorm',NaN,'physicalConverged',false,'physicalBranchSupported',false,'physicalStatus','','theta_deg',NaN,'collective_deg',NaN,'cyclicLong_deg',NaN,'elevator_deg',NaN); end
function r=empty_summary(), r=struct('caseName','','modelIdentity','','centerSource','','stepScale',NaN,'centerCredible',false,'baselineSupported',false,'supportedStateColumns',0,'supportedInputColumns',0,'allEndpointsSupported',false,'finiteMatrices',false,'linearizationCredible',false,'totalPathAttempts',0,'maxEndpointPathAttempts',0,'directEndpointFailureCount',0,'spectralAbscissa',NaN,'unstableEigenvalueCount',NaN,'maxAbsImagEigenvalue',NaN,'A_fro',NaN,'B_fro',NaN); end
function r=empty_path_row(), r=struct('caseName','','modelIdentity','','variableKind','','variableIndex',NaN,'variableName','','stepMagnitude',NaN,'plusSupported',false,'minusSupported',false,'plusDirectSupported',false,'minusDirectSupported',false,'plusPathAttempts',0,'minusPathAttempts',0,'plusStatus','','minusStatus',''); end
function r=empty_matrix_row(), r=struct('caseName','','modelIdentity','','stepScale',NaN,'matrixName','','rowIndex',NaN,'rowName','','colIndex',NaN,'colName','','value',NaN); end
function r=empty_eig_row(), r=struct('caseName','','modelIdentity','','stepScale',NaN,'modeIndex',NaN,'realPart',NaN,'imagPart',NaN,'wn_radps',NaN,'dampingRatio',NaN); end
function r=empty_control_row(), r=struct('caseName','','modelIdentity','','stepScale',NaN,'inputIndex',NaN,'inputName','','BcolumnNorm',NaN,'udotGain',NaN,'wdotGain',NaN,'pdotGain',NaN,'qdotGain',NaN,'rdotGain',NaN); end
function r=empty_step_row(), r=struct('caseName','','modelIdentity','','coarseScale',NaN,'fineScale',NaN,'comparable',false,'relativeA_FroDifference',NaN,'relativeB_FroDifference',NaN,'spectralAbscissaDifference',NaN); end
function r=empty_propagation_row(), r=struct('caseName','','stepScale',NaN,'comparable',false,'relativeA_FroDifference',NaN,'relativeB_FroDifference',NaN,'M0SpectralAbscissa',NaN,'M1SpectralAbscissa',NaN,'deltaSpectralAbscissa',NaN,'M0UnstableCount',NaN,'M1UnstableCount',NaN); end
