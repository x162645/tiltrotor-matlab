function results = run_m1_stage5_wadc_holdout(outputDir)
%RUN_M1_STAGE5_WADC_HOLDOUT Post-freeze WADC cross-facility validation.
%
% Mainline research question:
%   After M0 and M1_HOLDOUT_V1 were frozen BEFORE the WADC Table A-3
%   numerical values were read, does the source-constrained M1 model retain
%   a quantitative advantage over M0 at another facility and lower tip Mach?
%
% Evidence boundary:
%   - WADC is POST_FREEZE_CROSS_FACILITY_EXTERNAL_VALIDATION.
%   - It is not called blind validation: the analyst sees the data during
%     execution, but no parameter/model selection is allowed after freeze.
%   - The report window is inherited from the predeclared M0/M1 6--11 deg
%     support window. Every available formal Run 1--3 point in that window
%     is retained; no 7 deg point is interpolated.
%
% Model boundary:
%   - M0 calls production rotor_model_bemt directly with the exact frozen
%     XV-15 low-order mapping used by run_xv15_metal_hover_validation.
%   - M1_HOLDOUT_V1 is an exact equation copy of the already-frozen
%     CORRIGAN_GENERIC_N1 branch in run_m1_stage3_corrigan_stall_delay.
%   - The copied M1 solver is fail-closed against the original Stage-3
%     implementation on the known OARF 6--11 deg points before WADC metrics
%     are accepted.
%   - No WADC-dependent tuning, offset, gain, wake selection, or parameter
%     search is performed.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'results','m1_stage5_wadc_holdout');
end
if ~exist(outputDir,'dir'), mkdir(outputDir); end

modelM0 = 'M0_PRODUCTION_LOW_ORDER';
modelM1 = 'M1_HOLDOUT_V1_GENERIC_CORRIGAN_N1';
datasetRole = 'POST_FREEZE_CROSS_FACILITY_EXTERNAL_VALIDATION';
independence = ['MODEL_FROZEN_BEFORE_WADC_VALUES_VIEWED_' ...
    'ANALYST_POSTFREEZE_DATA_VISIBLE_NO_TUNING'];
claimBoundary = ['WADC_POSTFREEZE_CROSS_FACILITY_VALIDATION_NO_RETUNING_' ...
    'NOT_BLIND_WADC_FACILITY_INTERFERENCE_CAVEAT'];
windowName = 'INHERITED_FIXED_6_TO_11_DEG_ALL_AVAILABLE_POINTS_NO_INTERPOLATION';

%% 1. Source data and predeclared point membership.
dataFile = fullfile(rootDir,'analysis','data','xv15_wadc_metal_table_a3.csv');
D = readtable(dataFile);
required = {'run','point','Vtip_fps','Mtip','collective75_deg','CT_exp','CP_exp','FM_exp'};
if ~all(ismember(required,D.Properties.VariableNames))
    error('run_m1_stage5_wadc_holdout:DataSchema','WADC source CSV schema mismatch.');
end
formalRun = ismember(D.run,[1;2;3]);
inheritedWindow = D.collective75_deg >= 6 & D.collective75_deg <= 11;
D.formalRun = formalRun;
D.inheritedReportWindow = inheritedWindow;
D.stage5Selected = formalRun & inheritedWindow;
D.selectionReason = repmat({'OUTSIDE_STAGE5'},height(D),1);
D.selectionReason(D.stage5Selected) = repmat({windowName},sum(D.stage5Selected),1);
writetable(D,fullfile(outputDir,'M1_STAGE5_WADC_SOURCE_DATA_AUDIT.csv'));

V = D(D.stage5Selected,:);
if height(V) ~= 15
    error('run_m1_stage5_wadc_holdout:UnexpectedPointCount', ...
        'Expected 15 WADC Run 1-3 points inside inherited 6-11 deg window; got %d.',height(V));
end
for rr = 1:3
    q = V.collective75_deg(V.run==rr);
    if numel(q) ~= 5 || ~isequal(q(:),[6;8;9;10;11])
        error('run_m1_stage5_wadc_holdout:WindowDrift', ...
            'Run %d does not contain the predeclared 6,8,9,10,11 deg point set.',rr);
    end
end
writetable(V,fullfile(outputDir,'M1_STAGE5_WADC_VALIDATION_MANIFEST.csv'));

%% 2. Fail closed on M0 production identity.
m0Audit = audit_xv15_v1_baseline_model_identity(fullfile(outputDir,'m0_identity_audit'));

%% 3. Freeze-equivalent M0 and M1 templates.
Pbase = params_nominal();
R = 3.81;
rootCut = 0.0875;
d2r = pi/180;

% Exact M0 geometry reduction used by frozen V1 validation.
xGeom = linspace(rootCut,1,4001).';
chord_in_geom = 14*ones(size(xGeom));
inboard = xGeom <= 0.25;
chord_in_geom(inboard) = -18.4615*xGeom(inboard) + 18.6154;
chordEq_m = trapz(xGeom,chord_in_geom)/(1-rootCut)*0.0254;
thetaSource_geom_deg = nasa_metal_twist_deg(xGeom);
theta75Source_deg = nasa_metal_twist_deg(0.75);
xNorm = (xGeom-rootCut)/(1-rootCut);
x75 = (0.75-rootCut)/(1-rootCut);
shapeCoordinate = xNorm-x75;
shapeTarget = thetaSource_geom_deg-theta75Source_deg;
twistTipEq_deg = trapz(xGeom,shapeCoordinate.*shapeTarget) / ...
    trapz(xGeom,shapeCoordinate.^2);

Pm0 = Pbase;
Pm0.rotor.R = R;
Pm0.rotor.Nb = 3;
Pm0.rotor.rootCut = rootCut;
Pm0.rotor.chord = chordEq_m;
Pm0.rotor.twistTip = twistTipEq_deg*d2r;
Pm0.rotor.Ib = Pm0.rotor.bladeMass*R^2/3;
Pm0.rotor.Sblade = Pm0.rotor.bladeMass*R/2;

Pm1 = Pbase;
Pm1.rotor.R = R;
Pm1.rotor.Nb = 3;
Pm1.rotor.rootCut = rootCut;
Pm1.rotor.Ib = Pm1.rotor.bladeMass*R^2/3;
Pm1.rotor.Sblade = Pm1.rotor.bladeMass*R/2;
if ~isfield(Pm1.env,'aSound'), Pm1.env.aSound = 340.0; end

%% 4. Fail-closed copied-M1 identity check against frozen Stage-3 runner.
stage3Dir = fullfile(outputDir,'m1_e1_identity_reference');
stage3 = run_m1_stage3_corrigan_stall_delay(stage3Dir);
refMask = strcmp(stage3.points.mode,'CORRIGAN_GENERIC_N1');
ref = stage3.points(refMask,:);
if height(ref) ~= 6
    error('run_m1_stage5_wadc_holdout:MissingM1Reference','Expected six M1-E-1 reference points.');
end
identityRows = table();
for k = 1:height(ref)
    P = Pm1;
    Vtip_mps = ref.Vtip_fps(k)*0.3048;
    P.rotor.Omega = Vtip_mps/R;
    out = solve_m1_holdout(P,ref.collective75_deg(k));
    [CT,CP,FM] = nondim(out,P,Vtip_mps);
    one = table(ref.collective75_deg(k),ref.CT_model(k),CT,abs(CT-ref.CT_model(k)), ...
        ref.CP_model(k),CP,abs(CP-ref.CP_model(k)),ref.FM_model(k),FM,abs(FM-ref.FM_model(k)), ...
        out.physicalConverged, ...
        'VariableNames',{'collective75_deg','CT_stage3','CT_stage5copy','CT_absDiff', ...
        'CP_stage3','CP_stage5copy','CP_absDiff','FM_stage3','FM_stage5copy','FM_absDiff', ...
        'physicalConverged'});
    identityRows = [identityRows;one]; %#ok<AGROW>
end
writetable(identityRows,fullfile(outputDir,'M1_STAGE5_M1_IDENTITY_EQUIVALENCE.csv'));
maxIdentityDiff = max([identityRows.CT_absDiff;identityRows.CP_absDiff;identityRows.FM_absDiff]);
if ~all(identityRows.physicalConverged) || ~(isfinite(maxIdentityDiff) && maxIdentityDiff <= 1e-10)
    error('run_m1_stage5_wadc_holdout:M1IdentityDrift', ...
        'Copied M1_HOLDOUT_V1 solver drifted from frozen Stage-3 implementation; max diff %.12g.',maxIdentityDiff);
end

%% 5. Execute frozen M0 and M1 on every predeclared WADC point.
rows = table();
for k = 1:height(V)
    % M0 direct production path.
    P = Pm0;
    Vtip_mps = V.Vtip_fps(k)*0.3048;
    P.rotor.Omega = Vtip_mps/R;
    out0 = solve_m0_direct(P,V.collective75_deg(k),twistTipEq_deg,x75);
    rows = [rows;make_point_row(modelM0,'DIRECT_PRODUCTION_ROTOR_MODEL_BEMT', ...
        V,k,out0,P,Vtip_mps,datasetRole,independence,windowName)]; %#ok<AGROW>

    % Frozen M1_HOLDOUT_V1.
    P = Pm1;
    P.rotor.Omega = Vtip_mps/R;
    out1 = solve_m1_holdout(P,V.collective75_deg(k));
    rows = [rows;make_point_row(modelM1,'FROZEN_M1_E1_EQUATION_COPY_IDENTITY_CHECKED', ...
        V,k,out1,P,Vtip_mps,datasetRole,independence,windowName)]; %#ok<AGROW>
end
writetable(rows,fullfile(outputDir,'M1_STAGE5_WADC_POINTS.csv'));

%% 6. Metrics per Run and pooled across all predeclared points.
metrics = table();
models = {modelM0;modelM1};
runIds = [1;2;3;0];
runLabels = {'RUN_1';'RUN_2';'RUN_3';'ALL_RUNS_1_TO_3'};
for im = 1:numel(models)
    for ir = 1:numel(runIds)
        if runIds(ir)==0
            candidate = strcmp(rows.modelIdentity,models{im});
            expected = 15;
        else
            candidate = strcmp(rows.modelIdentity,models{im}) & rows.run==runIds(ir);
            expected = 5;
        end
        metrics = [metrics;metric_row(rows,candidate,models{im},runLabels{ir},expected)]; %#ok<AGROW>
    end
end
writetable(metrics,fullfile(outputDir,'M1_STAGE5_WADC_METRICS.csv'));

%% 7. M1-minus-M0 comparison. No success threshold or model selection.
comparison = table();
for ir = 1:numel(runLabels)
    a = metrics(strcmp(metrics.modelIdentity,modelM0) & strcmp(metrics.validationGroup,runLabels{ir}),:);
    b = metrics(strcmp(metrics.modelIdentity,modelM1) & strcmp(metrics.validationGroup,runLabels{ir}),:);
    if height(a)~=1 || height(b)~=1
        error('run_m1_stage5_wadc_holdout:MetricJoin','Missing metric row for %s.',runLabels{ir});
    end
    completePair = a.completeFixedWindow && b.completeFixedWindow;
    one = table({runLabels{ir}},completePair, ...
        a.CT_MAPE_pct,b.CT_MAPE_pct,b.CT_MAPE_pct-a.CT_MAPE_pct, ...
        a.CP_MAPE_pct,b.CP_MAPE_pct,b.CP_MAPE_pct-a.CP_MAPE_pct, ...
        a.FM_MAPE_pct,b.FM_MAPE_pct,b.FM_MAPE_pct-a.FM_MAPE_pct, ...
        'VariableNames',{'validationGroup','completePair','M0_CT_MAPE_pct','M1_CT_MAPE_pct', ...
        'M1minusM0_CT_MAPE_pp','M0_CP_MAPE_pct','M1_CP_MAPE_pct','M1minusM0_CP_MAPE_pp', ...
        'M0_FM_MAPE_pct','M1_FM_MAPE_pct','M1minusM0_FM_MAPE_pp'});
    comparison = [comparison;one]; %#ok<AGROW>
end
writetable(comparison,fullfile(outputDir,'M1_STAGE5_WADC_M0_M1_COMPARISON.csv'));

%% 8. Metadata and immutable evidence semantics.
metadataName = { ...
    'stage';'dataset';'dataset_role';'dataset_independence';'source_compilation'; ...
    'original_test_report';'facility';'formal_runs';'report_window'; ...
    'points_per_run';'missing_7deg_handling';'model_freeze_before_WADC_values'; ...
    'm1_freeze_record_commit';'m1_model_identity';'m1_implementation_reference'; ...
    'm1_identity_max_abs_difference';'m0_model_identity'; ...
    'M0_parameter_fit_to_WADC';'M1_parameter_fit_to_WADC';'WADC_collective_offset_fit'; ...
    'WADC_gain_fit';'WADC_model_selection';'WADC_facility_correction'; ...
    'WADC_Mtip_used_to_retune_aSound';'failure_retention';'claim_boundary'};
metadataValue = { ...
    'STAGE_5';'XV15_ORIGINAL_METAL_BLADE_WADC';datasetRole;independence; ...
    'NASA_CR_2017_219486_APPENDIX_A_TABLE_A3';'NASA_CR_114626_BELL_300_099_010'; ...
    'WADC_RIG_3_WRIGHT_PATTERSON_AFB';'RUN_1_RUN_2_RUN_3';windowName; ...
    '5_EACH_TOTAL_15';'NO_INTERPOLATION';'YES'; ...
    'd313296a35319dc8a5e6c398adbed0d54e0f8ede';modelM1; ...
    'analysis/run_m1_stage3_corrigan_stall_delay.m:CORRIGAN_GENERIC_N1'; ...
    sprintf('%.12g',maxIdentityDiff);modelM0;'NO';'NO';'NO';'NO';'NO';'NO';'NO'; ...
    'ALL_FAILURES_AND_HIGH_ERRORS_RETAINED';claimBoundary};
writetable(table(metadataName,metadataValue),fullfile(outputDir,'M1_STAGE5_WADC_METADATA.csv'));

results = struct();
results.sourceData = D;
results.validationManifest = V;
results.points = rows;
results.metrics = metrics;
results.comparison = comparison;
results.m0Audit = m0Audit;
results.m1IdentityEquivalence = identityRows;
results.maxM1IdentityDifference = maxIdentityDiff;
results.datasetRole = datasetRole;
results.datasetIndependence = independence;
results.claimBoundary = claimBoundary;
save(fullfile(outputDir,'M1_STAGE5_WADC_RESULTS.mat'),'results');
end

function row = make_point_row(modelIdentity,computationPath,V,k,out,P,Vtip_mps,datasetRole,independence,windowName)
[CT,CP,FM] = nondim(out,P,Vtip_mps);
if isfinite(CT), ctErr = 100*(CT-V.CT_exp(k))/V.CT_exp(k); else, ctErr=NaN; end
if isfinite(CP), cpErr = 100*(CP-V.CP_exp(k))/V.CP_exp(k); else, cpErr=NaN; end
if isfinite(FM), fmErr = 100*(FM-V.FM_exp(k))/V.FM_exp(k); else, fmErr=NaN; end
row = table({modelIdentity},{computationPath},V.run(k),V.point(k),V.Vtip_fps(k),V.Mtip(k), ...
    V.collective75_deg(k),V.CT_exp(k),CT,ctErr,V.CP_exp(k),CP,cpErr,V.FM_exp(k),FM,fmErr, ...
    out.physicalConverged,out.iterations,{out.physicalStatus},out.inducedVelocity_mps, ...
    out.closureResidualRelative,out.KLMinApplied,out.KLMaxApplied,out.stallDelayApplyCount, ...
    out.alphaClampCount,out.machClampCount,{datasetRole},{independence},{windowName}, ...
    'VariableNames',{'modelIdentity','computationPath','run','point','Vtip_fps','Mtip_reported', ...
    'collective75_deg','CT_exp','CT_model','CT_relativeError_pct','CP_exp','CP_model', ...
    'CP_relativeError_pct','FM_exp','FM_model','FM_relativeError_pct','physicalConverged', ...
    'iterations','physicalStatus','inducedVelocity_mps','closureResidualRelative', ...
    'KLMinApplied','KLMaxApplied','stallDelayApplyCount','alphaClampCount','machClampCount', ...
    'datasetRole','datasetIndependence','reportWindow'});
end

function one = metric_row(rows,candidate,modelIdentity,groupLabel,expected)
valid = candidate & rows.physicalConverged & isfinite(rows.CT_model) & rows.CT_model>0 & ...
    isfinite(rows.CP_model) & rows.CP_model>0 & isfinite(rows.FM_model);
count = sum(valid);
complete = count==expected;
if count>0
    ct = rows.CT_relativeError_pct(valid); cp = rows.CP_relativeError_pct(valid); fm = rows.FM_relativeError_pct(valid);
    ctMape=mean(abs(ct)); cpMape=mean(abs(cp)); fmMape=mean(abs(fm));
    ctSigned=mean(ct); cpSigned=mean(cp); fmSigned=mean(fm);
    ctMax=max(abs(ct)); cpMax=max(abs(cp)); fmMax=max(abs(fm));
else
    ctMape=NaN; cpMape=NaN; fmMape=NaN; ctSigned=NaN; cpSigned=NaN; fmSigned=NaN;
    ctMax=NaN; cpMax=NaN; fmMax=NaN;
end
one = table({modelIdentity},{groupLabel},expected,count,complete,ctMape,cpMape,fmMape, ...
    ctSigned,cpSigned,fmSigned,ctMax,cpMax,fmMax, ...
    'VariableNames',{'modelIdentity','validationGroup','expectedPointCount','validPointCount', ...
    'completeFixedWindow','CT_MAPE_pct','CP_MAPE_pct','FM_MAPE_pct','CT_meanSigned_pct', ...
    'CP_meanSigned_pct','FM_meanSigned_pct','CT_maxAbs_pct','CP_maxAbs_pct','FM_maxAbs_pct'});
end

function out = solve_m0_direct(P,collective75_deg,twistTipEq_deg,x75)
modelCollective_deg = collective75_deg-twistTipEq_deg*x75;
ctrl = struct('collective',modelCollective_deg*pi/180,'cyclicLong',0);
out = empty_out();
try
    [~,~,r] = rotor_model_bemt(zeros(9,1),ctrl,0,-1,zeros(3,1),P);
    out.thrust = r.thrust;
    out.torque = r.torque;
    out.physicalConverged = r.physicalConverged;
    out.iterations = r.iterations;
    out.physicalStatus = r.physicalStatus;
    out.inducedVelocity_mps = r.inducedVelocity;
    out.closureResidualRelative = r.inducedClosureResidualRelative;
catch ME
    out.physicalStatus = ME.identifier;
end
end

function out = solve_m1_holdout(P,theta75_deg)
% Exact equation copy of frozen Stage-3 CORRIGAN_GENERIC_N1 branch.
mode = 'CORRIGAN_GENERIC_N1';
R=P.rotor.R; Omega=P.rotor.Omega; tipSpeed=Omega*R; rho=P.env.rho; A=pi*R^2;
r0=P.rotor.rootCut*R; rEdges=linspace(r0,R,P.rotor.nRadial+1);
rMid=0.5*(rEdges(1:end-1)+rEdges(2:end)); dr=diff(rEdges);
psi=((0:P.rotor.nAzimuth-1)*(2*pi/P.rotor.nAzimuth)).'; x=rMid/R;
chord_in=14*ones(size(x)); inboard=x<=0.25; chord_in(inboard)=-18.4615*x(inboard)+18.6154;
chord_m=chord_in*0.0254; thetaSource_deg=nasa_metal_twist_deg(x);
theta75Source_deg=nasa_metal_twist_deg(0.75);
thetaBlade=(theta75_deg+thetaSource_deg-theta75Source_deg)*pi/180; UT=Omega*rMid;

vi=sqrt(max(P.mass.m*P.env.g/2,1)/(2*rho*A)); zFlap=P.rotor.flapInitial(:); converged=false;
flapInfo=struct('converged',false,'iterations',0,'residualNorm',Inf);
for iter=1:P.rotor.inducedMaxIter
    [zFlap,flapInfo]=solve_flap(vi,zFlap);
    if ~flapInfo.converged, break; end
    loads=blade_loads(vi,zFlap);
    lambda1=-vi/max(tipSpeed,eps);
    CTiter=max(loads.T,0)/(0.5*rho*A*tipSpeed^2);
    viTarget=tipSpeed*CTiter/(4*max(abs(lambda1),1e-12));
    viNew=0.5*(vi+viTarget); err=abs(viNew-vi)/max(1,abs(vi)); vi=viNew;
    if err<P.rotor.inducedTol && flapInfo.residualNorm<=P.rotor.flapResidualTol
        converged=true; break;
    end
end
loads=blade_loads(vi,zFlap); lambda1=-vi/max(tipSpeed,eps);
momentumThrust=2*rho*A*tipSpeed*vi*abs(lambda1);
closure=abs(loads.T-momentumThrust)/max([abs(loads.T),abs(momentumThrust),1]);
physical=converged && flapInfo.converged && loads.T>0 && closure<=2e-4;
out=empty_out(); out.thrust=loads.T; out.torque=loads.Q; out.physicalConverged=physical;
out.iterations=iter; out.inducedVelocity_mps=vi; out.closureResidualRelative=closure;
out.KLMinApplied=loads.KLMinApplied; out.KLMaxApplied=loads.KLMaxApplied;
out.stallDelayApplyCount=loads.applyCount; out.alphaClampCount=loads.alphaClampCount;
out.machClampCount=loads.machClampCount;
if physical, out.physicalStatus='SUPPORTED'; else, out.physicalStatus='M1_E1_NOT_PHYSICALLY_CONVERGED'; end

    function [z,info]=solve_flap(viNow,z0)
        z=z0(:); info=struct('converged',false,'iterations',0,'residualNorm',Inf);
        for kk=1:P.rotor.flapMaxIter
            [res,scale]=flap_residual(z,viNow); rn=res/scale;
            if norm(rn)<=P.rotor.flapResidualTol
                info.converged=true; info.iterations=kk; info.residualNorm=norm(rn); return;
            end
            J=zeros(3,3);
            for jj=1:3
                h=P.rotor.flapJacobianStep*max(1,abs(z(jj)));
                zp=z; zm=z; zp(jj)=zp(jj)+h; zm(jj)=zm(jj)-h;
                [rp,~]=flap_residual(zp,viNow); [rm,~]=flap_residual(zm,viNow);
                J(:,jj)=(rp-rm)/(2*h*scale);
            end
            if ~all(isfinite(J(:))) || rcond(J.'*J)<1e-14, return; end
            dz=-(J.'*J+P.rotor.flapNewtonRegularization*eye(3))\(J.'*rn);
            step=1; accepted=false;
            for trial=1:P.rotor.flapLineSearchMaxIter
                zc=z+step*dz; betaCheck=zc(1)+zc(2)*cos(psi)+zc(3)*sin(psi);
                if all(isfinite(zc)) && max(abs(betaCheck))<P.rotor.flapDivergenceAngle
                    [rc,sc]=flap_residual(zc,viNow);
                    if norm(rc/sc)<norm(rn), z=zc; accepted=true; break; end
                end
                step=step*P.rotor.flapNewtonDamping;
            end
            if ~accepted, return; end
        end
        [res,scale]=flap_residual(z,viNow); info.iterations=P.rotor.flapMaxIter; info.residualNorm=norm(res/scale);
    end

    function [res,scale]=flap_residual(z,viNow)
        ll=blade_loads(viNow,z); gravityMoment=-P.rotor.Sblade*P.env.g*cos(ll.beta);
        inertialRestoring=P.rotor.Ib*ll.betaDDot+P.rotor.Ib*Omega^2*ll.beta;
        byAz=inertialRestoring-ll.flapMomentByAzimuth-gravityMoment;
        res=[mean(byAz);2*mean(byAz.*cos(psi));2*mean(byAz.*sin(psi))];
        scale=max([max(abs(ll.flapMomentByAzimuth)),max(abs(gravityMoment)),P.rotor.Ib*Omega^2*0.05,1]);
    end

    function ll=blade_loads(viNow,z)
        betaLocal=z(1)+z(2)*cos(psi)+z(3)*sin(psi);
        betaDotLocal=-Omega*(-z(2)*sin(psi)+z(3)*cos(psi));
        betaDDotLocal=-Omega^2*(z(2)*cos(psi)+z(3)*sin(psi));
        viField=viNow.*(1+cos(psi).*(rMid/R));
        UP=viField-betaDotLocal.*rMid; W=hypot(UT,UP); phi=atan2(UP,max(abs(UT),1e-8));
        alpha=thetaBlade-phi; Mach=W/P.env.aSound; chordField=ones(size(alpha)).*chord_m;
        rField=ones(size(alpha)).*x;
        [CL,CD,meta]=xv15_c81_corrigan_stall_delay(alpha,Mach,rField,chordField,R,mode);
        q=0.5*rho*W.^2; dL=q.*chord_m.*CL.*dr; dD=q.*chord_m.*CD.*dr;
        dT=dL.*cos(phi)-dD.*sin(phi); dH=dD.*cos(phi)+dL.*sin(phi); dQ=dH.*rMid;
        factor=P.rotor.Nb/P.rotor.nAzimuth; ringT=factor*sum(dT,1); ringQ=factor*sum(dQ,1);
        ll.T=sum(ringT); ll.Q=sum(ringQ); ll.flapMomentByAzimuth=sum(dT.*rMid,2);
        ll.beta=betaLocal; ll.betaDDot=betaDDotLocal; ll.alphaClampCount=meta.alphaClampCount;
        ll.machClampCount=meta.machClampCount; ll.applyCount=meta.applyCount;
        ll.KLMinApplied=meta.KLMinApplied; ll.KLMaxApplied=meta.KLMaxApplied;
    end
end

function [CT,CP,FM] = nondim(out,P,Vtip_mps)
A=pi*P.rotor.R^2;
CT=out.thrust/(P.env.rho*A*Vtip_mps^2);
CP=out.torque*P.rotor.Omega/(P.env.rho*A*Vtip_mps^3);
if isfinite(CT) && isfinite(CP) && CT>0 && CP>0
    FM=CT^(3/2)/(sqrt(2)*CP);
else
    FM=NaN;
end
end

function theta_deg = nasa_metal_twist_deg(x)
theta_deg=289.98*x.^5-892.87*x.^4+987.06*x.^3-438.31*x.^2+15.695*x+32.057;
end

function out = empty_out()
out=struct('thrust',NaN,'torque',NaN,'physicalConverged',false,'iterations',NaN, ...
    'physicalStatus','NOT_RUN','inducedVelocity_mps',NaN,'closureResidualRelative',NaN, ...
    'KLMinApplied',NaN,'KLMaxApplied',NaN,'stallDelayApplyCount',NaN, ...
    'alphaClampCount',NaN,'machClampCount',NaN);
end
