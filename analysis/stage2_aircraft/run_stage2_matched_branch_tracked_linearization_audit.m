function results = run_stage2_matched_branch_tracked_linearization_audit(outputRoot,caseName)
%RUN_STAGE2_MATCHED_BRANCH_TRACKED_LINEARIZATION_AUDIT
% Shared fixed-endpoint branch-tracked two-scale A/B audit.
%
% This audit is opened only after the direct-only matched audit showed the
% same M1 flap-closure nonconvergence class in B15, B45 and B75.  Each target
% derivative endpoint remains EXACTLY the same as in the direct audit.  A
% failed M1 direct endpoint is approached from the accepted credible center
% by adaptive path continuation while carrying only the last converged
% left/right flap states.  No endpoint, physical parameter, solver tolerance,
% iteration limit, trim bound, or control DOF is changed.  Direct endpoint
% failure is retained explicitly as separate evidence.

if nargin < 1 || isempty(outputRoot)
    outputRoot = fullfile(pwd,'results','stage2_matched_branch_tracked_linearization');
end
if nargin < 2 || isempty(caseName), caseName = 'ALL'; end
if ~exist(outputRoot,'dir'), mkdir(outputRoot); end

here = fileparts(mfilename('fullpath'));
centerPath = fullfile(here,'evidence','STAGE2_ACCEPTED_MATCHED_TRIM_CENTERS.csv');
T = readtable(centerPath,'TextType','string');
if ~strcmpi(caseName,'ALL')
    T = T(T.caseName==string(caseName),:);
    assert(height(T)==2,'Stage2MatchedBranchLinearization:ExpectedMatchedPair');
else
    assert(height(T)==6,'Stage2MatchedBranchLinearization:ExpectedSixCenters');
end

P = stage2_matched_rotor_parameters();
stateNames = {'u','v','w','p','q','r','phi','theta','psi'};
derivativeNames = {'udot','vdot','wdot','pdot','qdot','rdot','phidot','thetadot','psidot'};
inputNames = {'collective','diffCollective','cyclicLong','diffCyclicLong','aileron','elevator','rudder'};
baseDx = [0.05;0.05;0.05;5e-4;5e-4;5e-4;5e-4;5e-4;5e-4];
baseDu = 5e-4*ones(7,1);
stepScales = [1.0 0.5];
minPathDt = 2^-14;
maxPathAttempts = 80;

nCenter = height(T);
centers = repmat(center_from_table(T,1),nCenter,1);
for i=2:nCenter, centers(i)=center_from_table(T,i); end

summaryRows = repmat(empty_summary_row(),nCenter*numel(stepScales),1);
pathRows = repmat(empty_path_row(),0,1);
matrixRows = repmat(empty_matrix_row(),0,1);
eigRows = repmat(empty_eig_row(),0,1);
controlRows = repmat(empty_control_row(),0,1);
linearizations = cell(nCenter,numel(stepScales));
idx=0;
for i=1:nCenter
    for s=1:numel(stepScales)
        idx=idx+1; scale=stepScales(s);
        [A,B,rep,pRows] = tracked_linearize(centers(i),P,baseDx*scale,baseDu*scale, ...
            stateNames,inputNames,minPathDt,maxPathAttempts);
        linearizations{i,s}=struct('A',A,'B',B,'report',rep);
        pathRows=[pathRows;pRows]; %#ok<AGROW>
        sr=empty_summary_row(); sr.caseName=string(centers(i).caseName); sr.modelIdentity=string(centers(i).modelIdentity);
        sr.centerSource=string(centers(i).centerSource); sr.stepScale=scale; sr.sourceCenterCredible=centers(i).sourceCredible;
        sr.baselineSupported=rep.baselineSupported; sr.supportedStateColumns=sum(rep.stateColumnSupported);
        sr.supportedInputColumns=sum(rep.inputColumnSupported); sr.fullAReady=rep.fullAReady; sr.fullBReady=rep.fullBReady;
        sr.fullABReady=rep.fullAReady&&rep.fullBReady; sr.directEndpointFailureCount=rep.directEndpointFailureCount;
        sr.finalUnsupportedEndpointCount=rep.finalUnsupportedEndpointCount; sr.totalPathAttempts=rep.totalPathAttempts;
        sr.maxEndpointPathAttempts=rep.maxEndpointPathAttempts;
        if rep.fullAReady
            lam=eig(A); sr.spectralAbscissa=max(real(lam)); sr.unstableEigenvalueCount=sum(real(lam)>1e-6);
            sr.maxAbsImagEigenvalue=max(abs(imag(lam))); sr.A_fro=norm(A,'fro');
            for k=1:numel(lam)
                er=empty_eig_row(); er.caseName=sr.caseName; er.modelIdentity=sr.modelIdentity; er.stepScale=scale;
                er.modeIndex=k; er.realPart=real(lam(k)); er.imagPart=imag(lam(k)); er.wn_radps=abs(lam(k));
                if er.wn_radps>0, er.dampingRatio=-er.realPart/er.wn_radps; end
                eigRows(end+1,1)=er; %#ok<AGROW>
            end
        end
        if rep.fullBReady, sr.B_fro=norm(B,'fro'); end
        for j=1:numel(inputNames)
            cr=empty_control_row(); cr.caseName=sr.caseName; cr.modelIdentity=sr.modelIdentity; cr.stepScale=scale;
            cr.inputIndex=j; cr.inputName=string(inputNames{j}); cr.columnSupported=rep.inputColumnSupported(j);
            if cr.columnSupported
                cr.BcolumnNorm=norm(B(:,j)); cr.udotGain=B(1,j); cr.wdotGain=B(3,j);
                cr.pdotGain=B(4,j); cr.qdotGain=B(5,j); cr.rdotGain=B(6,j);
            end
            controlRows(end+1,1)=cr; %#ok<AGROW>
        end
        matrixRows=[matrixRows;matrix_to_rows(sr.caseName,sr.modelIdentity,scale,'A',A,derivativeNames,stateNames); ...
            matrix_to_rows(sr.caseName,sr.modelIdentity,scale,'B',B,derivativeNames,inputNames)]; %#ok<AGROW>
        summaryRows(idx)=sr;
    end
end

summaryTable=struct2table(summaryRows,'AsArray',true);
pathTable=struct2table(pathRows,'AsArray',true);
matrixTable=struct2table(matrixRows,'AsArray',true);
eigenTable=struct2table(eigRows,'AsArray',true);
controlTable=struct2table(controlRows,'AsArray',true);
writetable(summaryTable,fullfile(outputRoot,'STAGE2_MATCHED_BRANCH_LINEARIZATION_SUMMARY.csv'));
writetable(pathTable,fullfile(outputRoot,'STAGE2_MATCHED_BRANCH_ENDPOINT_PATHS.csv'));
writetable(matrixTable,fullfile(outputRoot,'STAGE2_MATCHED_BRANCH_AB_MATRICES_LONG.csv'));
writetable(eigenTable,fullfile(outputRoot,'STAGE2_MATCHED_BRANCH_EIGENVALUES.csv'));
writetable(controlTable,fullfile(outputRoot,'STAGE2_MATCHED_BRANCH_CONTROL_EFFECTIVENESS.csv'));

stepRows=repmat(empty_step_row(),nCenter,1);
for i=1:nCenter
    a=linearizations{i,1}; b=linearizations{i,2}; rr=empty_step_row();
    rr.caseName=string(centers(i).caseName); rr.modelIdentity=string(centers(i).modelIdentity);
    rr.AComparable=a.report.fullAReady&&b.report.fullAReady; rr.BComparable=a.report.fullBReady&&b.report.fullBReady;
    if rr.AComparable
        rr.relativeA_FroDifference=norm(b.A-a.A,'fro')/max(norm(b.A,'fro'),eps);
        rr.spectralAbscissaDifference=max(real(eig(b.A)))-max(real(eig(a.A)));
    end
    if rr.BComparable
        rr.relativeB_FroDifference=norm(b.B-a.B,'fro')/max(norm(b.B,'fro'),eps);
    end
    stepRows(i)=rr;
end
stepTable=struct2table(stepRows,'AsArray',true);
writetable(stepTable,fullfile(outputRoot,'STAGE2_MATCHED_BRANCH_STEP_SENSITIVITY.csv'));

uniqueCases=unique(T.caseName,'stable');
propRows=repmat(empty_prop_row(),numel(uniqueCases),1);
for k=1:numel(uniqueCases)
    cs=uniqueCases(k); i0=find(T.caseName==cs & T.modelIdentity=="M0_MATCHED_PRODUCTION",1);
    i1=find(T.caseName==cs & T.modelIdentity=="M1_EVIDENCE_V1_PROPAGATION",1);
    assert(~isempty(i0)&&~isempty(i1),'Stage2MatchedBranchLinearization:MissingMatchedPair');
    m0=linearizations{i0,2}; m1=linearizations{i1,2}; pr=empty_prop_row(); pr.caseName=cs; pr.stepScale=0.5;
    pr.AComparable=m0.report.fullAReady&&m1.report.fullAReady; pr.BComparable=m0.report.fullBReady&&m1.report.fullBReady;
    if pr.AComparable
        pr.relativeA_M0M1Difference=norm(m1.A-m0.A,'fro')/max(norm(m0.A,'fro'),eps);
        l0=eig(m0.A); l1=eig(m1.A); pr.M0SpectralAbscissa=max(real(l0)); pr.M1SpectralAbscissa=max(real(l1));
        pr.deltaSpectralAbscissa=pr.M1SpectralAbscissa-pr.M0SpectralAbscissa;
        pr.M0UnstableCount=sum(real(l0)>1e-6); pr.M1UnstableCount=sum(real(l1)>1e-6);
        s0=stepRows(i0).relativeA_FroDifference; s1=stepRows(i1).relativeA_FroDifference;
        if isfinite(s0)&&isfinite(s1)
            pr.relativeA_NumericalFloor=max(s0,s1);
            pr.ASignalToNumericalFloor=pr.relativeA_M0M1Difference/max(pr.relativeA_NumericalFloor,eps);
        end
    end
    if pr.BComparable
        pr.relativeB_M0M1Difference=norm(m1.B-m0.B,'fro')/max(norm(m0.B,'fro'),eps);
        s0=stepRows(i0).relativeB_FroDifference; s1=stepRows(i1).relativeB_FroDifference;
        if isfinite(s0)&&isfinite(s1)
            pr.relativeB_NumericalFloor=max(s0,s1);
            pr.BSignalToNumericalFloor=pr.relativeB_M0M1Difference/max(pr.relativeB_NumericalFloor,eps);
        end
    end
    propRows(k)=pr;
end
propTable=struct2table(propRows,'AsArray',true);
writetable(propTable,fullfile(outputRoot,'STAGE2_MATCHED_BRANCH_M0_M1_PROPAGATION_DELTA.csv'));

metadata=table(["SHARED_FLAP_CLOSURE_FAILURE_OBSERVED_IN_B15_B45_B75_DIRECT_AUDIT"; ...
    "ACCEPTED_CENTERS_ONLY_NO_RETRIM";"FIXED_ENDPOINT_CENTRAL_DIFFERENCE_TWO_SCALE"; ...
    "DIRECT_ENDPOINT_EVALUATED_FIRST_AND_RETAINED";"ADAPTIVE_PATH_ONLY_AFTER_FAILED_M1_DIRECT_ENDPOINT"; ...
    "PATH_REACHES_SAME_FIXED_ENDPOINT";"CARRY_LAST_CONVERGED_LEFT_RIGHT_FLAP_STATES_ONLY"; ...
    "NO_ENDPOINT_PHYSICS_PARAMETER_TOLERANCE_ITERATION_BOUND_OR_DOF_CHANGE"; ...
    "STATE_DX_0P05_MPS_AND_5E4_RATES_ANGLES";"CONTROL_DU_5E4_RAD"; ...
    "WHOLE_AIRCRAFT_PROPAGATION_SENSITIVITY_NOT_XV15_AIRCRAFT_VALIDATION"], ...
    'VariableNames',{'metadataValue'});
writetable(metadata,fullfile(outputRoot,'STAGE2_MATCHED_BRANCH_LINEARIZATION_METADATA.csv'));

results=struct('centers',T,'summary',summaryTable,'endpointPaths',pathTable,'matrices',matrixTable, ...
    'eigenvalues',eigenTable,'controlEffectiveness',controlTable,'stepSensitivity',stepTable, ...
    'propagationDelta',propTable,'linearizations',{linearizations},'metadata',metadata, ...
    'claimBoundary','WHOLE_AIRCRAFT_PROPAGATION_SENSITIVITY_NOT_XV15_AIRCRAFT_VALIDATION');
save(fullfile(outputRoot,'STAGE2_MATCHED_BRANCH_TRACKED_LINEARIZATION_AUDIT.mat'),'results');
disp(summaryTable); disp(stepTable); disp(propTable);
end

function [A,B,report,rows]=tracked_linearize(center,P,dx,du,stateNames,inputNames,minPathDt,maxPathAttempts)
[~,centerOut,ok0,s0]=eval_seeded(center,center.x,center.u,P,[]);
A=NaN(9,9); B=NaN(9,7); stateOK=false(9,1); inputOK=false(7,1);
rows=repmat(empty_path_row(),0,1); totalPathAttempts=0; maxAttempts=0; directFails=0; finalFails=0;
for j=1:9
    xp=center.x; xm=center.x; xp(j)=xp(j)+dx(j); xm(j)=xm(j)-dx(j);
    [fp,~,okp,sp,ap,dp]=eval_endpoint(center,xp,center.u,P,centerOut,minPathDt,maxPathAttempts);
    [fm,~,okm,sm,am,dm]=eval_endpoint(center,xm,center.u,P,centerOut,minPathDt,maxPathAttempts);
    if okp&&okm, A(:,j)=(fp-fm)/(2*dx(j)); stateOK(j)=true; end
    directFails=directFails+(~dp)+(~dm); finalFails=finalFails+(~okp)+(~okm);
    totalPathAttempts=totalPathAttempts+ap+am; maxAttempts=max([maxAttempts ap am]);
    r=empty_path_row(); r.caseName=string(center.caseName); r.modelIdentity=string(center.modelIdentity); r.variableKind="STATE";
    r.variableIndex=j; r.variableName=string(stateNames{j}); r.stepMagnitude=dx(j); r.plusSupported=okp; r.minusSupported=okm;
    r.plusDirectSupported=dp; r.minusDirectSupported=dm; r.plusPathAttempts=ap; r.minusPathAttempts=am;
    r.plusStatus=string(sp); r.minusStatus=string(sm); rows(end+1,1)=r; %#ok<AGROW>
end
for j=1:7
    up=center.u; um=center.u; up(j)=up(j)+du(j); um(j)=um(j)-du(j);
    [fp,~,okp,sp,ap,dp]=eval_endpoint(center,center.x,up,P,centerOut,minPathDt,maxPathAttempts);
    [fm,~,okm,sm,am,dm]=eval_endpoint(center,center.x,um,P,centerOut,minPathDt,maxPathAttempts);
    if okp&&okm, B(:,j)=(fp-fm)/(2*du(j)); inputOK(j)=true; end
    directFails=directFails+(~dp)+(~dm); finalFails=finalFails+(~okp)+(~okm);
    totalPathAttempts=totalPathAttempts+ap+am; maxAttempts=max([maxAttempts ap am]);
    r=empty_path_row(); r.caseName=string(center.caseName); r.modelIdentity=string(center.modelIdentity); r.variableKind="INPUT";
    r.variableIndex=j; r.variableName=string(inputNames{j}); r.stepMagnitude=du(j); r.plusSupported=okp; r.minusSupported=okm;
    r.plusDirectSupported=dp; r.minusDirectSupported=dm; r.plusPathAttempts=ap; r.minusPathAttempts=am;
    r.plusStatus=string(sp); r.minusStatus=string(sm); rows(end+1,1)=r; %#ok<AGROW>
end
fullA=ok0&&all(stateOK)&&all(isfinite(A(:)))&&isreal(A);
fullB=ok0&&all(inputOK)&&all(isfinite(B(:)))&&isreal(B);
report=struct('baselineSupported',ok0,'baselineStatus',s0,'stateColumnSupported',stateOK, ...
    'inputColumnSupported',inputOK,'fullAReady',fullA,'fullBReady',fullB, ...
    'directEndpointFailureCount',directFails,'finalUnsupportedEndpointCount',finalFails, ...
    'totalPathAttempts',totalPathAttempts,'maxEndpointPathAttempts',maxAttempts,'dx',dx,'du',du);
end

function [xdot,out,ok,status,pathAttempts,directSupported]=eval_endpoint(center,xt,ut,P,centerOut,minPathDt,maxPathAttempts)
[xdot,out,ok,status]=eval_seeded(center,xt,ut,P,[]);
directSupported=ok; pathAttempts=0;
if ok || strcmp(center.modelIdentity,'M0_MATCHED_PRODUCTION')
    return;
end
% Direct target failed for M1. Walk from the accepted center to the SAME endpoint.
t=0; dt=1; curOut=centerOut; xdot=NaN(9,1); out=struct(); ok=false; status="PATH_NOT_REACHED";
while t<1-1e-14 && pathAttempts<maxPathAttempts
    ttry=min(1,t+dt); xtry=center.x+ttry*(xt-center.x); utry=center.u+ttry*(ut-center.u);
    pathAttempts=pathAttempts+1;
    [ft,ot,good,st]=eval_seeded(center,xtry,utry,P,curOut);
    if good
        curOut=ot; t=ttry; xdot=ft; out=ot; status=string(st);
        if t>=1-1e-14, ok=true; return; end
        dt=min(2*dt,1-t);
    else
        dt=0.5*dt;
        if dt<minPathDt, status="PATH_FAILED:"+string(st); ok=false; return; end
    end
end
if ~ok && pathAttempts>=maxPathAttempts, status="PATH_MAX_ATTEMPTS"; end
end

function [xdot,out,ok,status]=eval_seeded(center,x,u,P,seedOut)
Pk=P;
if strcmp(center.modelIdentity,'M1_EVIDENCE_V1_PROPAGATION')
    if isempty(seedOut)
        Pk.stage2Numerics.flapInitialLeft=center.flapLeft(:);
        Pk.stage2Numerics.flapInitialRight=center.flapRight(:);
    else
        Pk.stage2Numerics.flapInitialLeft=seedOut.components.rotorLeft.zFlap(:);
        Pk.stage2Numerics.flapInitialRight=seedOut.components.rotorRight.zFlap(:);
    end
end
try
    [xdot,out]=stage2_tiltrotor_eom(center.modelIdentity,x,u,center.betaM,Pk);
    ok=isreal(xdot)&&all(isfinite(xdot))&&logical(out.physicalConverged)&&logical(out.physicalBranchSupported);
    status=char(out.physicalStatus);
catch ME
    if is_expected_model_domain_error(ME)
        xdot=NaN(9,1); out=struct(); ok=false; status=['ERROR:' ME.identifier];
    else
        rethrow(ME);
    end
end
end

function tf=is_expected_model_domain_error(ME)
tf=startsWith(ME.identifier,'m1_evidence_v1_forward_rotor:') || ...
    startsWith(ME.identifier,'rotor_model_bemt:') || strcmp(ME.identifier,'pitch_allocation_schedule:InvalidPitchCommand');
end

function c=center_from_table(T,i)
c=struct(); c.caseName=char(T.caseName(i)); c.modelIdentity=char(T.modelIdentity(i)); c.centerSource=char(T.centerSource(i));
c.sourceCredible=logical(T.credible(i));
c.x=[T.x1_u_mps(i);T.x2_v_mps(i);T.x3_w_mps(i);T.x4_p_rps(i);T.x5_q_rps(i);T.x6_r_rps(i);T.x7_phi_rad(i);T.x8_theta_rad(i);T.x9_psi_rad(i)];
c.u=[T.u1_collective_rad(i);T.u2_diffCollective_rad(i);T.u3_cyclicLong_rad(i);T.u4_diffCyclicLong_rad(i);T.u5_aileron_rad(i);T.u6_elevator_rad(i);T.u7_rudder_rad(i)];
c.flapLeft=[T.leftBeta0_rad(i);T.leftBeta1c_rad(i);T.leftBeta1s_rad(i)]; c.flapRight=[T.rightBeta0_rad(i);T.rightBeta1c_rad(i);T.rightBeta1s_rad(i)];
switch c.caseName
    case 'B15_V020', c.betaM=15*pi/180;
    case 'B45_V035', c.betaM=45*pi/180;
    case 'B75_V080', c.betaM=75*pi/180;
    otherwise, error('Stage2MatchedBranchLinearization:UnknownCase','Unknown case %s',c.caseName);
end
end

function rows=matrix_to_rows(caseName,modelIdentity,scale,matrixName,M,rowNames,colNames)
rows=repmat(empty_matrix_row(),numel(M),1); n=0;
for i=1:size(M,1)
    for j=1:size(M,2)
        n=n+1; r=empty_matrix_row(); r.caseName=caseName; r.modelIdentity=modelIdentity; r.stepScale=scale;
        r.matrixName=string(matrixName); r.rowIndex=i; r.rowName=string(rowNames{i}); r.columnIndex=j; r.columnName=string(colNames{j}); r.value=M(i,j); rows(n)=r;
    end
end
end
function r=empty_summary_row()
r=struct('caseName',"",'modelIdentity',"",'centerSource',"",'stepScale',NaN,'sourceCenterCredible',false, ...
    'baselineSupported',false,'supportedStateColumns',0,'supportedInputColumns',0,'fullAReady',false,'fullBReady',false, ...
    'fullABReady',false,'directEndpointFailureCount',0,'finalUnsupportedEndpointCount',0,'totalPathAttempts',0, ...
    'maxEndpointPathAttempts',0,'spectralAbscissa',NaN,'unstableEigenvalueCount',NaN,'maxAbsImagEigenvalue',NaN,'A_fro',NaN,'B_fro',NaN);
end
function r=empty_path_row()
r=struct('caseName',"",'modelIdentity',"",'variableKind',"",'variableIndex',NaN,'variableName',"",'stepMagnitude',NaN, ...
    'plusSupported',false,'minusSupported',false,'plusDirectSupported',false,'minusDirectSupported',false, ...
    'plusPathAttempts',0,'minusPathAttempts',0,'plusStatus',"",'minusStatus',"");
end
function r=empty_matrix_row()
r=struct('caseName',"",'modelIdentity',"",'stepScale',NaN,'matrixName',"",'rowIndex',NaN,'rowName',"",'columnIndex',NaN,'columnName',"",'value',NaN);
end
function r=empty_eig_row()
r=struct('caseName',"",'modelIdentity',"",'stepScale',NaN,'modeIndex',NaN,'realPart',NaN,'imagPart',NaN,'wn_radps',NaN,'dampingRatio',NaN);
end
function r=empty_control_row()
r=struct('caseName',"",'modelIdentity',"",'stepScale',NaN,'inputIndex',NaN,'inputName',"",'columnSupported',false, ...
    'BcolumnNorm',NaN,'udotGain',NaN,'wdotGain',NaN,'pdotGain',NaN,'qdotGain',NaN,'rdotGain',NaN);
end
function r=empty_step_row()
r=struct('caseName',"",'modelIdentity',"",'AComparable',false,'BComparable',false,'relativeA_FroDifference',NaN,'relativeB_FroDifference',NaN,'spectralAbscissaDifference',NaN);
end
function r=empty_prop_row()
r=struct('caseName',"",'stepScale',NaN,'AComparable',false,'BComparable',false,'relativeA_M0M1Difference',NaN,'relativeB_M0M1Difference',NaN, ...
    'relativeA_NumericalFloor',NaN,'relativeB_NumericalFloor',NaN,'ASignalToNumericalFloor',NaN,'BSignalToNumericalFloor',NaN, ...
    'M0SpectralAbscissa',NaN,'M1SpectralAbscissa',NaN,'deltaSpectralAbscissa',NaN,'M0UnstableCount',NaN,'M1UnstableCount',NaN);
end
