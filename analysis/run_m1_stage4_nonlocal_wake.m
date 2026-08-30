function results = run_m1_stage4_nonlocal_wake(outputDir)
%RUN_M1_STAGE4_NONLOCAL_WAKE M1-F prescribed nonlocal wake diagnostic.
%
% This runner deliberately retains model-form failures. The first M1-F
% implementation applies the published Landgrebe tip-vortex normalized
% contraction/axial law to all discrete trailing filaments as an explicitly
% ASSUMED inboard-sheet extension. If that generalized sheet predicts a
% non-positive disk-mean downwash, the point is marked unsupported and the
% raw circulation/vortex/inflow evidence is written instead of changing
% signs, taking absolute values, or fitting a correction to OARF.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'results','m1_stage4_nonlocal_wake');
end
if ~exist(outputDir,'dir'), mkdir(outputDir); end

% Same-workflow M1-E reference. Only the generic n=1 branch is promoted.
m1e = run_m1_stage3_corrigan_stall_delay(fullfile(outputDir,'m1e_recheck'));
refMask = strcmp(m1e.metrics.mode,'CORRIGAN_GENERIC_N1');
refMetric = m1e.metrics(refMask,:);
refPointMask = strcmp(m1e.points.mode,'CORRIGAN_GENERIC_N1');
refPoints = m1e.points(refPointMask,:);
if height(refMetric) ~= 1 || height(refPoints) ~= 6
    error('run_m1_stage4_nonlocal_wake:MissingM1EReference', ...
        'Expected one M1-E generic metric row and six point rows.');
end

Pbase = params_nominal();
R = 3.81;
rootCut = 0.0875;
collective75_deg = [6;7;8;9;10;11];
Vtip_fps = [768.4;768.4;768.4;768.0;768.0;767.7];
CT_exp = [0.009208;0.010104;0.011063;0.012035;0.013089;0.013929];
CP_exp = [0.000796;0.000913;0.001044;0.001188;0.001358;0.001523];
FM_exp = [0.7849;0.7866;0.7881;0.7858;0.7797;0.7632];

referenceChord_m = 14*0.0254;
sigmaLandgrebe = Pbase.rotor.Nb*referenceChord_m/(pi*R);
thetaTwEq_deg = nasa_metal_twist_deg(1.0)-nasa_metal_twist_deg(rootCut);
primaryWakeTurns = 3.0;
primarySegmentsPerRev = 36;

Ptemplate = Pbase;
Ptemplate.rotor.R = R;
Ptemplate.rotor.Nb = 3;
Ptemplate.rotor.rootCut = rootCut;
Ptemplate.rotor.Ib = Ptemplate.rotor.bladeMass*R^2/3;
Ptemplate.rotor.Sblade = Ptemplate.rotor.bladeMass*R/2;
if ~isfield(Ptemplate.env,'aSound'), Ptemplate.env.aSound = 340.0; end

% -------------------------------------------------------------------------
% 1) M1-F0 control and raw-wake sign/model-form audit.
% -------------------------------------------------------------------------
f0 = cell(numel(collective75_deg),1);
rows = table();
auditPointRows = table();
auditRadialRows = table();
auditEdgeRows = table();

for k = 1:numel(collective75_deg)
    P = Ptemplate;
    Vtip_mps = Vtip_fps(k)*0.3048;
    P.rotor.Omega = Vtip_mps/R;
    out0 = solve_hover(P,collective75_deg(k),'UNIFORM_MOMENTUM', ...
        sigmaLandgrebe,thetaTwEq_deg,primaryWakeTurns,primarySegmentsPerRev);
    f0{k} = out0;
    rows = [rows; point_row('M1_F0_UNIFORM_MOMENTUM_CONTROL', ...
        'MODEL_FORM_CONTROL_NO_WAKE_FIT','NOT_SELECTED_FROM_CURRENT_OARF_TARGETS', ...
        k,out0,P,Vtip_mps,'SUPPORTED')]; %#ok<AGROW>

    CTstd = out0.thrust/(P.env.rho*pi*R^2*Vtip_mps^2);
    [rawWake,wm] = xv15_landgrebe_biot_savart_inflow( ...
        out0.rMid_m,out0.rEdges_m,out0.gammaMean_m2ps,CTstd, ...
        sigmaLandgrebe,thetaTwEq_deg,P.rotor.Nb,R, ...
        primaryWakeTurns,primarySegmentsPerRev);
    aw = out0.rMid_m.*diff(out0.rEdges_m);
    rawMean = sum(rawWake.*aw)/sum(aw);

    % Pure sign-convention control. A smooth positive circulation distribution
    % is never compared with OARF; it only checks filament direction/sign.
    s = (out0.rMid_m-out0.rEdges_m(1))/(out0.rEdges_m(end)-out0.rEdges_m(1));
    amp = max(abs(out0.gammaMean_m2ps));
    if ~(isfinite(amp) && amp > 0), amp = 1; end
    gammaCanonical = amp*sin(pi*s);
    [rawCanonical,cm] = xv15_landgrebe_biot_savart_inflow( ...
        out0.rMid_m,out0.rEdges_m,gammaCanonical,CTstd, ...
        sigmaLandgrebe,thetaTwEq_deg,P.rotor.Nb,R, ...
        primaryWakeTurns,primarySegmentsPerRev);
    canonicalMean = sum(rawCanonical.*aw)/sum(aw);

    byEdgeMean = (aw(:).'*wm.viDownByEdge_mps/sum(aw)).';
    rootMean = byEdgeMean(1);
    tipMean = byEdgeMean(end);
    innerMean = sum(byEdgeMean(2:end-1));

    auditPointRows = [auditPointRows; table(collective75_deg(k),CTstd, ...
        sigmaLandgrebe,thetaTwEq_deg,wm.k1,wm.k2,wm.gammaContract, ...
        rawMean,canonicalMean,rootMean,innerMean,tipMean, ...
        rawMean > 0,canonicalMean > 0,wm.skippedNearSingular,cm.skippedNearSingular, ...
        'VariableNames',{'collective75_deg','CT_M1F0_standard','sigmaLandgrebe', ...
        'thetaTwEq_deg','wakeK1','wakeK2','wakeGammaContract', ...
        'actualRawWakeAreaMean_mps','canonicalPositiveGammaAreaMean_mps', ...
        'rootFilamentMeanContribution_mps','interiorSheetMeanContribution_mps', ...
        'tipFilamentMeanContribution_mps','actualRawMeanPositive', ...
        'canonicalSignCheckPositive','actualSkippedNearSingular','canonicalSkippedNearSingular'})]; %#ok<AGROW>

    nR = numel(out0.rMid_m);
    auditRadialRows = [auditRadialRows; table( ...
        repmat(collective75_deg(k),nR,1),out0.rMid_m(:)/R, ...
        out0.gammaMean_m2ps(:),gammaCanonical(:),rawWake(:),rawCanonical(:), ...
        'VariableNames',{'collective75_deg','r_R','Gamma_actual_m2ps', ...
        'Gamma_canonical_m2ps','rawViDown_actual_mps','rawViDown_canonical_mps'})]; %#ok<AGROW>

    nE = numel(out0.rEdges_m);
    edgeClass = repmat({'INTERIOR_SHEET'},nE,1);
    edgeClass{1} = 'ROOT_CLOSURE'; edgeClass{end} = 'TIP_CLOSURE';
    auditEdgeRows = [auditEdgeRows; table( ...
        repmat(collective75_deg(k),nE,1),out0.rEdges_m(:)/R, ...
        wm.edgeStrength_m2ps(:),byEdgeMean(:),edgeClass, ...
        'VariableNames',{'collective75_deg','edge_r_R','trailingStrength_m2ps', ...
        'areaMeanViDownContribution_mps','filamentClass'})]; %#ok<AGROW>
end

writetable(auditPointRows,fullfile(outputDir,'M1_STAGE4_WAKE_SIGN_AUDIT_POINTS.csv'));
writetable(auditRadialRows,fullfile(outputDir,'M1_STAGE4_WAKE_SIGN_AUDIT_RADIAL.csv'));
writetable(auditEdgeRows,fullfile(outputDir,'M1_STAGE4_WAKE_SIGN_AUDIT_EDGES.csv'));

% -------------------------------------------------------------------------
% 2) M1-F1 only where the raw generalized-sheet mean is positive.
% -------------------------------------------------------------------------
for k = 1:numel(collective75_deg)
    P = Ptemplate;
    Vtip_mps = Vtip_fps(k)*0.3048;
    P.rotor.Omega = Vtip_mps/R;
    if ~auditPointRows.actualRawMeanPositive(k)
        outBad = f0{k};
        outBad.physicalConverged = false;
        outBad.rawWakeMean_mps = auditPointRows.actualRawWakeAreaMean_mps(k);
        outBad.wakeK1 = auditPointRows.wakeK1(k);
        outBad.wakeK2 = auditPointRows.wakeK2(k);
        outBad.wakeGammaContract = auditPointRows.wakeGammaContract(k);
        rows = [rows; point_row('M1_F1_LANDGREBE_NONLOCAL', ...
            'SOURCE_CONSTRAINED_NONLOCAL_WAKE_DIAGNOSTIC', ...
            'NOT_SELECTED_FROM_CURRENT_OARF_TARGETS',k,outBad,P,Vtip_mps, ...
            'RAW_GENERALIZED_SHEET_MEAN_NONPOSITIVE')]; %#ok<AGROW>
        continue;
    end
    out1 = solve_hover(P,collective75_deg(k),'LANDGREBE_NONLOCAL', ...
        sigmaLandgrebe,thetaTwEq_deg,primaryWakeTurns,primarySegmentsPerRev);
    rows = [rows; point_row('M1_F1_LANDGREBE_NONLOCAL', ...
        'SOURCE_CONSTRAINED_NONLOCAL_WAKE_DIAGNOSTIC', ...
        'NOT_SELECTED_FROM_CURRENT_OARF_TARGETS',k,out1,P,Vtip_mps,out1.failureCode)]; %#ok<AGROW>
end
writetable(rows,fullfile(outputDir,'M1_STAGE4_NONLOCAL_WAKE_POINTS.csv'));

% Unsupported F1 points stay visible; no complete-window MAPE is fabricated.
metrics = metric_row('M1_E1_REFERENCE','GENERIC_CORRIGAN_N1_GLOBAL_MOMENTUM_REFERENCE', ...
    'NOT_SELECTED_FROM_CURRENT_OARF_TARGETS',6,refMetric.CT_MAPE_pct, ...
    refMetric.CP_MAPE_pct,refMetric.FM_MAPE_pct,refMetric.CT_meanSigned_pct, ...
    refMetric.CP_meanSigned_pct,refMetric.FM_meanSigned_pct,true);
modelNames = {'M1_F0_UNIFORM_MOMENTUM_CONTROL';'M1_F1_LANDGREBE_NONLOCAL'};
modelRoles = {'MODEL_FORM_CONTROL_NO_WAKE_FIT';'SOURCE_CONSTRAINED_NONLOCAL_WAKE_DIAGNOSTIC'};
for im = 1:numel(modelNames)
    mask = strcmp(rows.mode,modelNames{im}) & rows.physicalConverged;
    complete = sum(mask) == numel(collective75_deg);
    if any(mask)
        ctMape=mean(abs(rows.CT_relativeError_pct(mask))); cpMape=mean(abs(rows.CP_relativeError_pct(mask)));
        fmMape=mean(abs(rows.FM_relativeError_pct(mask))); ctSigned=mean(rows.CT_relativeError_pct(mask));
        cpSigned=mean(rows.CP_relativeError_pct(mask)); fmSigned=mean(rows.FM_relativeError_pct(mask));
    else
        ctMape=NaN; cpMape=NaN; fmMape=NaN; ctSigned=NaN; cpSigned=NaN; fmSigned=NaN;
    end
    metrics=[metrics;metric_row(modelNames{im},modelRoles{im}, ...
        'NOT_SELECTED_FROM_CURRENT_OARF_TARGETS',sum(mask),ctMape,cpMape,fmMape, ...
        ctSigned,cpSigned,fmSigned,complete)]; %#ok<AGROW>
end
metrics.CT_deltaFromM1E1_pp=metrics.CT_MAPE_pct-metrics.CT_MAPE_pct(1);
metrics.CP_deltaFromM1E1_pp=metrics.CP_MAPE_pct-metrics.CP_MAPE_pct(1);
metrics.FM_deltaFromM1E1_pp=metrics.FM_MAPE_pct-metrics.FM_MAPE_pct(1);
writetable(metrics,fullfile(outputDir,'M1_STAGE4_NONLOCAL_WAKE_METRICS.csv'));

% 10 deg discretization is not executed if the primary raw wake is invalid.
verifyTurns=[2;3;3;3;4]; verifySegs=[36;24;36;48;36]; verifyRows=table();
k10=find(collective75_deg==10,1);
if auditPointRows.actualRawMeanPositive(k10)
    for iv=1:numel(verifyTurns)
        P=Ptemplate; Vtip_mps=768.0*0.3048; P.rotor.Omega=Vtip_mps/R;
        out=solve_hover(P,10,'LANDGREBE_NONLOCAL',sigmaLandgrebe,thetaTwEq_deg,verifyTurns(iv),verifySegs(iv));
        [CT,CP,FM]=nondim(out,P,Vtip_mps);
        verifyRows=[verifyRows;table(verifyTurns(iv),verifySegs(iv),CT,CP,FM, ...
            out.viAreaMean_mps,out.viMin_mps,out.viMax_mps,out.viCV,out.iterations, ...
            out.physicalConverged,{out.failureCode},'VariableNames',{'wakeTurns','segmentsPerRev', ...
            'CT_model','CP_model','FM_model','viAreaMean_mps','viMin_mps','viMax_mps', ...
            'viCV','iterations','physicalConverged','failureCode'})]; %#ok<AGROW>
    end
    primaryMask=verifyRows.wakeTurns==primaryWakeTurns & verifyRows.segmentsPerRev==primarySegmentsPerRev;
    verifyRows.CT_deltaFromPrimary_pct=100*(verifyRows.CT_model-verifyRows.CT_model(primaryMask))/verifyRows.CT_model(primaryMask);
    verifyRows.CP_deltaFromPrimary_pct=100*(verifyRows.CP_model-verifyRows.CP_model(primaryMask))/verifyRows.CP_model(primaryMask);
    verifyRows.FM_deltaFromPrimary_pct=100*(verifyRows.FM_model-verifyRows.FM_model(primaryMask))/verifyRows.FM_model(primaryMask);
else
    verifyRows=table(verifyTurns,verifySegs,NaN(size(verifyTurns)),NaN(size(verifyTurns)), ...
        NaN(size(verifyTurns)),false(size(verifyTurns)), ...
        repmat({'NOT_RUN_PRIMARY_10DEG_RAW_WAKE_MEAN_NONPOSITIVE'},numel(verifyTurns),1), ...
        'VariableNames',{'wakeTurns','segmentsPerRev','CT_model','CP_model','FM_model', ...
        'physicalConverged','failureCode'});
end
writetable(verifyRows,fullfile(outputDir,'M1_STAGE4_WAKE_DISCRETIZATION.csv'));

metadataName={'model_identity';'reference_model';'report_window';'dataset_role'; ...
    'stall_delay_mode';'wake_geometry_source';'wake_induction_method';'wake_mean_closure'; ...
    'landgrebe_solidity';'landgrebe_equivalent_twist_deg';'primary_wake_turns'; ...
    'primary_segments_per_rev';'inboard_sheet_geometry_role';'failure_retention_rule'; ...
    'parameter_fit_to_current_OARF_targets';'numeric_parameter_search';'selection_rule_after_execution'};
metadataValue={'M1_F_NONLOCAL_PRESCRIBED_WAKE';'M1_E1_GENERIC_CORRIGAN_N1'; ...
    'FIXED_6_TO_11_DEG';'DEVELOPMENT_EXTERNAL_CORRELATION';'CORRIGAN_GENERIC_N1'; ...
    'LANDGREBE_TIP_TRAJECTORY_WITH_EXPLICIT_ASSUMED_INBOARD_EXTENSION'; ...
    'DISCRETE_TRAILING_VORTICES_FINITE_SEGMENT_BIOT_SAVART'; ...
    'AREA_MEAN_MOMENTUM_NORMALIZATION_ONLY_IF_RAW_MEAN_POSITIVE'; ...
    sprintf('%.12g',sigmaLandgrebe);sprintf('%.12g',thetaTwEq_deg);sprintf('%.12g',primaryWakeTurns); ...
    sprintf('%d',primarySegmentsPerRev); ...
    'ASSUMED_UNIFORM_NORMALIZED_CONTRACTION_EXTENSION_NOT_FULL_LANDGREBE_INBOARD_SHEET'; ...
    'NONPOSITIVE_RAW_MEAN_MARK_UNSUPPORTED_NO_ABS_NO_SIGN_FLIP';'NO';'NO'; ...
    'REPORT_ALL_VARIANTS_DO_NOT_PICK_FROM_RUN15_MAPE'};
writetable(table(metadataName,metadataValue),fullfile(outputDir,'M1_STAGE4_NONLOCAL_WAKE_METADATA.csv'));

results=struct(); results.points=rows; results.metrics=metrics; results.verification=verifyRows;
results.wakeSignAuditPoints=auditPointRows; results.wakeSignAuditRadial=auditRadialRows;
results.wakeSignAuditEdges=auditEdgeRows; results.referencePoints=refPoints;
results.claimBoundary=['M1_F_FAILURE_RETAINING_NONLOCAL_WAKE_MODEL_FORM_DIAGNOSTIC_' ...
    'NO_ABS_NO_SIGN_FLIP_NO_OARF_WAKE_FIT'];
save(fullfile(outputDir,'M1_STAGE4_NONLOCAL_WAKE_RESULTS.mat'),'results');

    function one=point_row(modeName,roleName,indName,k,out,P,Vtip_mps,failureCode)
        [CT,CP,FM]=nondim(out,P,Vtip_mps);
        one=table({modeName},{roleName},{indName},collective75_deg(k),Vtip_fps(k),CT_exp(k),CT, ...
            100*(CT-CT_exp(k))/CT_exp(k),CP_exp(k),CP,100*(CP-CP_exp(k))/CP_exp(k), ...
            FM_exp(k),FM,100*(FM-FM_exp(k))/FM_exp(k),out.physicalConverged,out.iterations, ...
            out.viMomentum_mps,out.viAreaMean_mps,out.viMin_mps,out.viMax_mps,out.viCV, ...
            out.momentumMeanClosureRelative,out.rawWakeMean_mps,out.wakeK1,out.wakeK2, ...
            out.wakeGammaContract,out.wakeSkippedNearSingular,out.alphaClampCount,out.machClampCount, ...
            out.KLMinApplied,out.KLMaxApplied,out.stallDelayApplyCount,{failureCode}, ...
            'VariableNames',{'mode','role','independence','collective75_deg','Vtip_fps','CT_exp', ...
            'CT_model','CT_relativeError_pct','CP_exp','CP_model','CP_relativeError_pct','FM_exp', ...
            'FM_model','FM_relativeError_pct','physicalConverged','iterations','viMomentum_mps', ...
            'viAreaMean_mps','viMin_mps','viMax_mps','viCV','momentumMeanClosureRelative', ...
            'rawWakeMean_mps','wakeK1','wakeK2','wakeGammaContract','wakeSkippedNearSingular', ...
            'alphaClampCount','machClampCount','KLMinApplied','KLMaxApplied','stallDelayApplyCount','failureCode'});
    end
end

function row=metric_row(mode,role,independence,n,ct,cp,fm,cts,cps,fms,complete)
row=table({mode},{role},{independence},n,ct,cp,fm,cts,cps,fms,complete, ...
    'VariableNames',{'mode','role','independence','supportedPointCount','CT_MAPE_pct', ...
    'CP_MAPE_pct','FM_MAPE_pct','CT_meanSigned_pct','CP_meanSigned_pct', ...
    'FM_meanSigned_pct','completeFixedWindow'});
end

function [CT,CP,FM]=nondim(out,P,Vtip_mps)
A=pi*P.rotor.R^2; CT=out.thrust/(P.env.rho*A*Vtip_mps^2);
CP=out.torque*P.rotor.Omega/(P.env.rho*A*Vtip_mps^3);
if CT>0 && CP>0, FM=CT^(3/2)/(sqrt(2)*CP); else, FM=NaN; end
end

function out=solve_hover(P,theta75_deg,wakeMode,sigmaLandgrebe,thetaTwEq_deg,wakeTurns,segmentsPerRev)
R=P.rotor.R; Omega=P.rotor.Omega; tipSpeed=Omega*R; rho=P.env.rho; A=pi*R^2;
r0=P.rotor.rootCut*R; rEdges=linspace(r0,R,P.rotor.nRadial+1);
rMid=0.5*(rEdges(1:end-1)+rEdges(2:end)); dr=diff(rEdges);
psi=((0:P.rotor.nAzimuth-1)*(2*pi/P.rotor.nAzimuth)).'; x=rMid/R;
chord_in=14*ones(size(x)); qin=x<=0.25; chord_in(qin)=-18.4615*x(qin)+18.6154;
chord_m=chord_in*0.0254; thetaSource_deg=nasa_metal_twist_deg(x);
theta75Source_deg=nasa_metal_twist_deg(0.75); thetaBlade=(theta75_deg+thetaSource_deg-theta75Source_deg)*pi/180;
UT=Omega*rMid; areaWeights=rMid.*dr;
vi0=sqrt(max(P.mass.m*P.env.g/2,1)/(2*rho*A)); viRadial=vi0*ones(size(rMid));
zFlap=P.rotor.flapInitial(:); converged=false; wakeMeta=empty_wake_meta(); rawWakeMean=NaN;
failureCode='NOT_CONVERGED';
for iter=1:P.rotor.inducedMaxIter
    [zFlap,flapInfo]=solve_flap(viRadial,zFlap);
    if ~flapInfo.converged, failureCode='FLAP_NOT_CONVERGED'; break; end
    loads=blade_loads(viRadial,zFlap);
    if ~(isfinite(loads.T) && loads.T>0), failureCode='NONPOSITIVE_THRUST'; break; end
    viMomentum=sqrt(loads.T/(2*rho*A));
    if strcmp(wakeMode,'UNIFORM_MOMENTUM')
        viTarget=viMomentum*ones(size(viRadial)); wakeMeta=empty_wake_meta(); rawWakeMean=viMomentum;
    elseif strcmp(wakeMode,'LANDGREBE_NONLOCAL')
        CTstd=loads.T/(rho*A*tipSpeed^2);
        [rawWake,wakeMeta]=xv15_landgrebe_biot_savart_inflow(rMid,rEdges,loads.gammaMean, ...
            CTstd,sigmaLandgrebe,thetaTwEq_deg,P.rotor.Nb,R,wakeTurns,segmentsPerRev);
        rawWakeMean=sum(rawWake.*areaWeights)/sum(areaWeights);
        if ~(isfinite(rawWakeMean) && rawWakeMean>0)
            failureCode='RAW_WAKE_MEAN_NONPOSITIVE_DURING_ITERATION'; break;
        end
        viTarget=viMomentum*(rawWake/rawWakeMean);
    else
        error('run_m1_stage4_nonlocal_wake:InvalidWakeMode','Unknown wake mode %s.',wakeMode);
    end
    viNew=(1-P.rotor.inducedRelax)*viRadial+P.rotor.inducedRelax*viTarget;
    err=max(abs(viNew-viRadial))/max(1,max(abs(viRadial))); viRadial=viNew;
    if err<P.rotor.inducedTol && flapInfo.residualNorm<=P.rotor.flapResidualTol
        converged=true; failureCode='SUPPORTED'; break;
    end
end
[zFlap,flapInfo]=solve_flap(viRadial,zFlap); loads=blade_loads(viRadial,zFlap);
viMomentum=sqrt(max(loads.T,0)/(2*rho*A)); viAreaMean=sum(viRadial.*areaWeights)/sum(areaWeights);
meanClosure=abs(viAreaMean-viMomentum)/max(viMomentum,1e-12);
physical=converged && flapInfo.converged && loads.T>0 && meanClosure<=5e-3;
if ~physical && strcmp(failureCode,'SUPPORTED'), failureCode='FINAL_CLOSURE_OR_PHYSICAL_CHECK_FAILED'; end
out=struct('thrust',loads.T,'torque',loads.Q,'physicalConverged',physical,'iterations',iter, ...
    'viMomentum_mps',viMomentum,'viAreaMean_mps',viAreaMean,'viMin_mps',min(viRadial), ...
    'viMax_mps',max(viRadial),'viCV',std(viRadial)/max(abs(mean(viRadial)),1e-12), ...
    'momentumMeanClosureRelative',meanClosure,'rawWakeMean_mps',rawWakeMean, ...
    'wakeK1',wakeMeta.k1,'wakeK2',wakeMeta.k2,'wakeGammaContract',wakeMeta.gammaContract, ...
    'wakeSkippedNearSingular',wakeMeta.skippedNearSingular,'alphaClampCount',loads.alphaClampCount, ...
    'machClampCount',loads.machClampCount,'KLMinApplied',loads.KLMinApplied, ...
    'KLMaxApplied',loads.KLMaxApplied,'stallDelayApplyCount',loads.applyCount, ...
    'failureCode',failureCode,'rMid_m',rMid,'rEdges_m',rEdges,'gammaMean_m2ps',loads.gammaMean);

    function [z,info]=solve_flap(viNow,z0)
        z=z0(:); info=struct('converged',false,'iterations',0,'residualNorm',Inf);
        for kk=1:P.rotor.flapMaxIter
            [res,scale]=flap_residual(z,viNow); rn=res/scale;
            if norm(rn)<=P.rotor.flapResidualTol
                info.converged=true; info.iterations=kk; info.residualNorm=norm(rn); return;
            end
            J=zeros(3,3);
            for jj=1:3
                h=P.rotor.flapJacobianStep*max(1,abs(z(jj))); zp=z; zm=z;
                zp(jj)=zp(jj)+h; zm(jj)=zm(jj)-h;
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
        viField=ones(P.rotor.nAzimuth,1)*viNow; UP=viField-betaDotLocal.*rMid;
        W=hypot(UT,UP); phi=atan2(UP,max(abs(UT),1e-8)); alpha=thetaBlade-phi;
        Mach=W/P.env.aSound; chordField=ones(size(alpha)).*chord_m; rField=ones(size(alpha)).*x;
        [CL,CD,meta]=xv15_c81_corrigan_stall_delay(alpha,Mach,rField,chordField,R,'CORRIGAN_GENERIC_N1');
        q=0.5*rho*W.^2; dL=q.*chord_m.*CL.*dr; dD=q.*chord_m.*CD.*dr;
        dT=dL.*cos(phi)-dD.*sin(phi); dH=dD.*cos(phi)+dL.*sin(phi); dQ=dH.*rMid;
        factor=P.rotor.Nb/P.rotor.nAzimuth; ringT=factor*sum(dT,1); ringQ=factor*sum(dQ,1);
        ll.T=sum(ringT); ll.Q=sum(ringQ); ll.flapMomentByAzimuth=sum(dT.*rMid,2);
        ll.beta=betaLocal; ll.betaDDot=betaDDotLocal; ll.gammaMean=mean(0.5*W.*chord_m.*CL,1);
        ll.alphaClampCount=meta.alphaClampCount; ll.machClampCount=meta.machClampCount;
        ll.applyCount=meta.applyCount; ll.KLMinApplied=meta.KLMinApplied; ll.KLMaxApplied=meta.KLMaxApplied;
    end
end

function m=empty_wake_meta()
m=struct('k1',NaN,'k2',NaN,'gammaContract',NaN,'skippedNearSingular',0);
end
