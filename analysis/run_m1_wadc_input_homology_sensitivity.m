function results = run_m1_wadc_input_homology_sensitivity(outputDir)
%RUN_M1_WADC_INPUT_HOMOLOGY_SENSITIVITY Post-hoc environment sensitivity.
%
% This analysis MUST NOT replace or redefine the frozen Stage-5 WADC
% holdout. It asks only how sensitive the already-frozen M1_HOLDOUT_V1
% equations are to two incompletely mapped environment inputs:
%
% 1) sound speed: compare frozen a=340 m/s with the per-point value derived
%    from the reported WADC Vtip/Mtip pair;
% 2) density: because Table A-3 does not provide pointwise rho, apply a
%    transparent +/-10% sensitivity around the frozen generic rho. This is
%    a numerical sensitivity range, NOT a claim about the actual test rho.
%
% No variant is selected by validation error and no result is fed back into
% M1_HOLDOUT_V1. Sensitivity-branch failures are retained as evidence. Only
% the frozen Stage-5 reproduction branch is required to remain 15/15.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'results','m1_wadc_input_homology_sensitivity');
end
if ~exist(outputDir,'dir'), mkdir(outputDir); end

% Re-execute the immutable Stage-5 reference in the same workflow.
stage5 = run_m1_stage5_wadc_holdout(fullfile(outputDir,'frozen_stage5_recheck'));
source = stage5.validationManifest;
refRows = stage5.points(strcmp(stage5.points.modelIdentity, ...
    'M1_HOLDOUT_V1_GENERIC_CORRIGAN_N1'),:);
m0Rows = stage5.points(strcmp(stage5.points.modelIdentity, ...
    'M0_PRODUCTION_LOW_ORDER'),:);
if height(source) ~= 15 || height(refRows) ~= 15 || height(m0Rows) ~= 15
    error('run_m1_wadc_input_homology_sensitivity:Reference','Expected 15 frozen WADC points per model.');
end

Pbase = params_nominal();
R = 3.81;
rootCut = 0.0875;
Ptemplate = Pbase;
Ptemplate.rotor.R = R;
Ptemplate.rotor.Nb = 3;
Ptemplate.rotor.rootCut = rootCut;
Ptemplate.rotor.Ib = Ptemplate.rotor.bladeMass*R^2/3;
Ptemplate.rotor.Sblade = Ptemplate.rotor.bladeMass*R/2;

variantName = { ...
    'FROZEN_A340_RHO1P0'; ...
    'REPORTED_MTIP_A_RHO1P0'; ...
    'REPORTED_MTIP_A_RHO0P9'; ...
    'REPORTED_MTIP_A_RHO1P1'};
useReportedMach = [false;true;true;true];
rhoFactor = [1.0;1.0;0.9;1.1];

rows = table();
for iv = 1:numel(variantName)
    for k = 1:height(source)
        P = Ptemplate;
        Vtip_mps = source.Vtip_fps(k)*0.3048;
        P.rotor.Omega = Vtip_mps/R;
        P.env.rho = Pbase.env.rho*rhoFactor(iv);
        if useReportedMach(iv)
            P.env.aSound = Vtip_mps/source.Mtip(k);
        else
            P.env.aSound = 340.0;
        end
        out = solve_holdout_equations(P,source.collective75_deg(k));
        [CT,CP,FM] = nondim(out,P,Vtip_mps);
        one = table(variantName(iv),useReportedMach(iv),rhoFactor(iv), ...
            source.run(k),source.point(k),source.Vtip_fps(k),source.Mtip(k), ...
            Vtip_mps/source.Mtip(k),P.env.aSound,P.env.rho,source.collective75_deg(k), ...
            source.CT_exp(k),CT,100*(CT-source.CT_exp(k))/source.CT_exp(k), ...
            source.CP_exp(k),CP,100*(CP-source.CP_exp(k))/source.CP_exp(k), ...
            source.FM_exp(k),FM,100*(FM-source.FM_exp(k))/source.FM_exp(k), ...
            out.physicalConverged,out.iterations,out.flapConverged,out.flapResidualNorm, ...
            out.inducedVelocity_mps,out.closureResidualRelative, ...
            out.alphaClampCount,out.machClampCount,out.KLMinApplied,out.KLMaxApplied, ...
            'VariableNames',{'variant','useReportedMtipForSoundSpeed','rhoFactor', ...
            'run','point','Vtip_fps','Mtip_reported','aSoundDerived_mps','aSoundUsed_mps', ...
            'rhoUsed_kgm3','collective75_deg','CT_exp','CT_model','CT_relativeError_pct', ...
            'CP_exp','CP_model','CP_relativeError_pct','FM_exp','FM_model', ...
            'FM_relativeError_pct','physicalConverged','iterations','flapConverged', ...
            'flapResidualNorm','inducedVelocity_mps','closureResidualRelative', ...
            'alphaClampCount','machClampCount','KLMinApplied','KLMaxApplied'});
        rows = [rows;one]; %#ok<AGROW>
    end
end
writetable(rows,fullfile(outputDir,'M1_WADC_INPUT_HOMOLOGY_POINTS.csv'));

% Fail closed: copied frozen environment branch must reproduce Stage 5 and
% must retain the original 15/15 physical support.
base = rows(strcmp(rows.variant,'FROZEN_A340_RHO1P0'),:);
if height(base) ~= height(refRows) || ~all(base.physicalConverged)
    error('run_m1_wadc_input_homology_sensitivity:FrozenBaseSupport', ...
        'Frozen Stage-5 reproduction must remain 15/15 physically supported.');
end
keyBase = base.run*1000+base.point;
keyRef = refRows.run*1000+refRows.point;
[tf,loc] = ismember(keyBase,keyRef);
if ~all(tf), error('run_m1_wadc_input_homology_sensitivity:Join','Reference join failed.'); end
identityDiff = max([abs(base.CT_model-refRows.CT_model(loc)); ...
    abs(base.CP_model-refRows.CP_model(loc)); abs(base.FM_model-refRows.FM_model(loc))]);
if ~(isfinite(identityDiff) && identityDiff <= 1e-10)
    error('run_m1_wadc_input_homology_sensitivity:IdentityDrift', ...
        'Copied frozen M1 equations drifted from Stage 5: %.12g.',identityDiff);
end

% Per-variant metrics retain support loss instead of aborting or deleting it.
metrics = table();
for iv = 1:numel(variantName)
    for runId = [1 2 3 0]
        candidate = strcmp(rows.variant,variantName{iv});
        expected = 15; label = 'ALL_RUNS';
        if runId ~= 0
            candidate = candidate & rows.run==runId;
            expected = 5; label = sprintf('RUN_%d',runId);
        end
        valid = candidate & rows.physicalConverged & ...
            isfinite(rows.CT_model) & rows.CT_model>0 & ...
            isfinite(rows.CP_model) & rows.CP_model>0 & isfinite(rows.FM_model);
        count = sum(valid);
        if count > 0
            ctMape = mean(abs(rows.CT_relativeError_pct(valid)));
            cpMape = mean(abs(rows.CP_relativeError_pct(valid)));
            fmMape = mean(abs(rows.FM_relativeError_pct(valid)));
            ctSigned = mean(rows.CT_relativeError_pct(valid));
            cpSigned = mean(rows.CP_relativeError_pct(valid));
            fmSigned = mean(rows.FM_relativeError_pct(valid));
            maxAlpha = max(rows.alphaClampCount(valid));
            maxMach = max(rows.machClampCount(valid));
        else
            ctMape=NaN; cpMape=NaN; fmMape=NaN;
            ctSigned=NaN; cpSigned=NaN; fmSigned=NaN;
            maxAlpha=NaN; maxMach=NaN;
        end
        one = table(variantName(iv),{label},expected,count,expected-count,count/expected, ...
            ctMape,cpMape,fmMape,ctSigned,cpSigned,fmSigned,maxAlpha,maxMach, ...
            'VariableNames',{'variant','validationGroup','expectedPointCount', ...
            'supportedPointCount','failedPointCount','supportFraction', ...
            'CT_MAPE_pct','CP_MAPE_pct','FM_MAPE_pct','CT_meanSigned_pct', ...
            'CP_meanSigned_pct','FM_meanSigned_pct','maxAlphaClampCount','maxMachClampCount'});
        metrics = [metrics;one]; %#ok<AGROW>
    end
end
for i = 1:height(metrics)
    ref = metrics(strcmp(metrics.variant,'FROZEN_A340_RHO1P0') & ...
        strcmp(metrics.validationGroup,metrics.validationGroup{i}),:);
    metrics.CT_deltaFromFrozenSameGroup_pp(i) = metrics.CT_MAPE_pct(i)-ref.CT_MAPE_pct;
    metrics.CP_deltaFromFrozenSameGroup_pp(i) = metrics.CP_MAPE_pct(i)-ref.CP_MAPE_pct;
    metrics.FM_deltaFromFrozenSameGroup_pp(i) = metrics.FM_MAPE_pct(i)-ref.FM_MAPE_pct;
end
writetable(metrics,fullfile(outputDir,'M1_WADC_INPUT_HOMOLOGY_METRICS.csv'));

% Common-support comparison is diagnostic only: failed points remain in the
% point table and are never silently removed from the formal Stage-5 holdout.
sourceKey = source.run*1000+source.point;
commonSupport = true(height(source),1);
for k = 1:height(source)
    key = sourceKey(k);
    q = rows(rows.run*1000+rows.point==key,:);
    commonSupport(k) = height(q)==numel(variantName) && all(q.physicalConverged) && ...
        all(isfinite(q.CT_model)) && all(q.CT_model>0) && ...
        all(isfinite(q.CP_model)) && all(q.CP_model>0) && all(isfinite(q.FM_model));
end
commonKeys = sourceKey(commonSupport);
commonMetrics = table();
for iv = 1:numel(variantName)
    mask = strcmp(rows.variant,variantName{iv}) & ismember(rows.run*1000+rows.point,commonKeys);
    one = table(variantName(iv),sum(mask), ...
        mean(abs(rows.CT_relativeError_pct(mask))), ...
        mean(abs(rows.CP_relativeError_pct(mask))), ...
        mean(abs(rows.FM_relativeError_pct(mask))), ...
        'VariableNames',{'variant','commonSupportedPointCount','CT_MAPE_pct','CP_MAPE_pct','FM_MAPE_pct'});
    commonMetrics = [commonMetrics;one]; %#ok<AGROW>
end
m0Common = ismember(m0Rows.run*1000+m0Rows.point,commonKeys) & m0Rows.physicalConverged;
m0CommonCT = mean(abs(m0Rows.CT_relativeError_pct(m0Common)));
m0CommonCP = mean(abs(m0Rows.CP_relativeError_pct(m0Common)));
m0CommonFM = mean(abs(m0Rows.FM_relativeError_pct(m0Common)));
commonMetrics.M0_common_CT_MAPE_pct = repmat(m0CommonCT,height(commonMetrics),1);
commonMetrics.M0_common_CP_MAPE_pct = repmat(m0CommonCP,height(commonMetrics),1);
commonMetrics.M0_common_FM_MAPE_pct = repmat(m0CommonFM,height(commonMetrics),1);
commonMetrics.M1minusM0_common_CT_MAPE_pp = commonMetrics.CT_MAPE_pct-m0CommonCT;
commonMetrics.M1minusM0_common_CP_MAPE_pp = commonMetrics.CP_MAPE_pct-m0CommonCP;
commonMetrics.M1minusM0_common_FM_MAPE_pp = commonMetrics.FM_MAPE_pct-m0CommonFM;
writetable(commonMetrics,fullfile(outputDir,'M1_WADC_INPUT_HOMOLOGY_COMMON_SUPPORT.csv'));

failureRows = rows(~rows.physicalConverged | ~isfinite(rows.FM_model) | rows.CP_model<=0 | rows.CT_model<=0,:);
writetable(failureRows,fullfile(outputDir,'M1_WADC_INPUT_HOMOLOGY_FAILURES.csv'));

soundAudit = unique(rows(:,{'run','point','Vtip_fps','Mtip_reported','aSoundDerived_mps'}));
soundAudit.aSoundDifferenceFrom340_pct = 100*(soundAudit.aSoundDerived_mps-340)/340;
writetable(soundAudit,fullfile(outputDir,'M1_WADC_REPORTED_MTIP_SOUND_SPEED_AUDIT.csv'));

% Evidence-level decision: no sensitivity variant is allowed to redefine the
% original 15-point holdout. Full robustness requires full support; if a
% hypothetical density branch loses support, the cross-facility advantage
% can be retained only with an explicit support caveat.
soundAll = metrics(strcmp(metrics.variant,'REPORTED_MTIP_A_RHO1P0') & strcmp(metrics.validationGroup,'ALL_RUNS'),:);
rhoLowAll = metrics(strcmp(metrics.variant,'REPORTED_MTIP_A_RHO0P9') & strcmp(metrics.validationGroup,'ALL_RUNS'),:);
rhoHighAll = metrics(strcmp(metrics.variant,'REPORTED_MTIP_A_RHO1P1') & strcmp(metrics.validationGroup,'ALL_RUNS'),:);
commonAdvantage = all(commonMetrics.M1minusM0_common_CT_MAPE_pp < 0) && ...
    all(commonMetrics.M1minusM0_common_CP_MAPE_pp < 0) && ...
    all(commonMetrics.M1minusM0_common_FM_MAPE_pp < 0);
if soundAll.supportedPointCount==15 && rhoLowAll.supportedPointCount==15 && ...
        rhoHighAll.supportedPointCount==15 && commonAdvantage
    decision = 'WADC_INPUT_HOMOLOGY_ROBUST_FULL_15_POINT_SUPPORT';
elseif soundAll.supportedPointCount==15 && rhoHighAll.supportedPointCount==15 && ...
        commonAdvantage && rhoLowAll.supportedPointCount>=14
    decision = 'WADC_ADVANTAGE_ROBUST_ON_COMMON_SUPPORT_WITH_LOW_DENSITY_SUPPORT_LIMITATION';
else
    decision = 'WADC_INPUT_HOMOLOGY_NOT_ROBUST_REQUIRES_EVIDENCE_DOWNGRADE';
end
summary = table(identityDiff,numel(commonKeys),height(failureRows), ...
    soundAll.supportedPointCount,rhoLowAll.supportedPointCount,rhoHighAll.supportedPointCount, ...
    commonAdvantage,{decision}, ...
    'VariableNames',{'frozenIdentityMaxAbsDifference','commonSupportedPointCount', ...
    'sensitivityFailureRowCount','reportedMtipRho1SupportedCount', ...
    'reportedMtipRho0p9SupportedCount','reportedMtipRho1p1SupportedCount', ...
    'M1BeatsM0OnAllCommonSupportVariants','decision'});
writetable(summary,fullfile(outputDir,'M1_WADC_INPUT_HOMOLOGY_SUMMARY.csv'));

metadataName = {'stage';'role';'original_holdout_modified';'model_parameter_fit'; ...
    'sound_speed_test';'density_test';'density_range_role';'variant_selection_by_error'; ...
    'sensitivity_failures_retained';'common_support_role'; ...
    'frozen_identity_max_abs_difference';'claim_boundary'};
metadataValue = {'POST_STAGE5_INPUT_HOMOLOGY_AUDIT'; ...
    'POSTHOC_INPUT_HOMOLOGY_SENSITIVITY';'NO';'NO'; ...
    'A_SOUND_EQUALS_VTIP_DIV_REPORTED_MTIP'; ...
    'FROZEN_GENERIC_RHO_TIMES_0P9_1P0_1P1'; ...
    'NUMERICAL_SENSITIVITY_NOT_ACTUAL_WADC_DENSITY_CLAIM';'NO'; ...
    'YES_NO_POINT_DELETION_NO_SOLVER_RELAXATION'; ...
    'DIAGNOSTIC_ONLY_FORMAL_STAGE5_REMAINS_ALL_15_POINTS'; ...
    sprintf('%.12g',identityDiff); ...
    'DO_NOT_REDEFINE_OR_RETUNE_FROZEN_WADC_HOLDOUT'};
metadata = table(metadataName,metadataValue);
writetable(metadata,fullfile(outputDir,'M1_WADC_INPUT_HOMOLOGY_METADATA.csv'));

results = struct();
results.points=rows; results.metrics=metrics; results.commonMetrics=commonMetrics;
results.failures=failureRows; results.summary=summary; results.soundAudit=soundAudit;
results.identityDiff=identityDiff; results.metadata=metadata;
results.claimBoundary=metadataValue{end};
save(fullfile(outputDir,'M1_WADC_INPUT_HOMOLOGY_RESULTS.mat'),'results');
end

function out = solve_holdout_equations(P,theta75_deg)
% Exact numerical equation copy of the frozen M1_HOLDOUT_V1 solver; only P.env
% inputs are varied by the audit caller.
mode='CORRIGAN_GENERIC_N1';
R=P.rotor.R; Omega=P.rotor.Omega; tipSpeed=Omega*R; rho=P.env.rho; A=pi*R^2;
r0=P.rotor.rootCut*R; rEdges=linspace(r0,R,P.rotor.nRadial+1);
rMid=0.5*(rEdges(1:end-1)+rEdges(2:end)); dr=diff(rEdges);
psi=((0:P.rotor.nAzimuth-1)*(2*pi/P.rotor.nAzimuth)).'; x=rMid/R;
chord_in=14*ones(size(x)); inboard=x<=0.25; chord_in(inboard)=-18.4615*x(inboard)+18.6154;
chord_m=chord_in*0.0254; thetaSource_deg=nasa_metal_twist_deg(x);
theta75Source_deg=nasa_metal_twist_deg(0.75);
thetaBlade=(theta75_deg+thetaSource_deg-theta75Source_deg)*pi/180; UT=Omega*rMid;
vi=sqrt(max(P.mass.m*P.env.g/2,1)/(2*rho*A)); zFlap=P.rotor.flapInitial(:); converged=false;
flapInfo=struct('converged',false,'iterations',0,'residualNorm',Inf); err=Inf;
for iter=1:P.rotor.inducedMaxIter
    [zFlap,flapInfo]=solve_flap(vi,zFlap); if ~flapInfo.converged, break; end
    loads=blade_loads(vi,zFlap); lambda1=-vi/max(tipSpeed,eps);
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
out=struct('thrust',loads.T,'torque',loads.Q,'physicalConverged',physical, ...
    'iterations',iter,'flapConverged',flapInfo.converged,'flapResidualNorm',flapInfo.residualNorm, ...
    'inducedVelocity_mps',vi,'closureResidualRelative',closure, ...
    'alphaClampCount',loads.alphaClampCount,'machClampCount',loads.machClampCount, ...
    'KLMinApplied',loads.KLMinApplied,'KLMaxApplied',loads.KLMaxApplied);

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
        [res,scale]=flap_residual(z,viNow); info.iterations=P.rotor.flapMaxIter;
        info.residualNorm=norm(res/scale);
    end

    function [res,scale]=flap_residual(z,viNow)
        ll=blade_loads(viNow,z); gravityMoment=-P.rotor.Sblade*P.env.g*cos(ll.beta);
        inertialRestoring=P.rotor.Ib*ll.betaDDot+P.rotor.Ib*Omega^2*ll.beta;
        byAz=inertialRestoring-ll.flapMomentByAzimuth-gravityMoment;
        res=[mean(byAz);2*mean(byAz.*cos(psi));2*mean(byAz.*sin(psi))];
        scale=max([max(abs(ll.flapMomentByAzimuth)),max(abs(gravityMoment)), ...
            P.rotor.Ib*Omega^2*0.05,1]);
    end

    function ll=blade_loads(viNow,z)
        beta=z(1)+z(2)*cos(psi)+z(3)*sin(psi);
        betaDot=-Omega*(-z(2)*sin(psi)+z(3)*cos(psi));
        betaDDot=-Omega^2*(z(2)*cos(psi)+z(3)*sin(psi));
        viField=viNow.*(1+cos(psi).*(rMid/R));
        UP=viField-betaDot.*rMid; W=hypot(UT,UP); phi=atan2(UP,max(abs(UT),1e-8));
        alpha=thetaBlade-phi; Mach=W/P.env.aSound;
        chordField=ones(size(alpha)).*chord_m; rField=ones(size(alpha)).*x;
        [CL,CD,meta]=xv15_c81_corrigan_stall_delay(alpha,Mach,rField,chordField,R,mode);
        q=0.5*rho*W.^2; dL=q.*chord_m.*CL.*dr; dD=q.*chord_m.*CD.*dr;
        dT=dL.*cos(phi)-dD.*sin(phi); dH=dD.*cos(phi)+dL.*sin(phi); dQ=dH.*rMid;
        factor=P.rotor.Nb/P.rotor.nAzimuth;
        ll.T=factor*sum(dT(:)); ll.Q=factor*sum(dQ(:));
        ll.flapMomentByAzimuth=sum(dT.*rMid,2); ll.beta=beta; ll.betaDDot=betaDDot;
        ll.alphaClampCount=meta.alphaClampCount; ll.machClampCount=meta.machClampCount;
        ll.KLMinApplied=meta.KLMinApplied; ll.KLMaxApplied=meta.KLMaxApplied;
    end
end

function [CT,CP,FM]=nondim(out,P,Vtip)
A=pi*P.rotor.R^2; CT=out.thrust/(P.env.rho*A*Vtip^2);
CP=out.torque*P.rotor.Omega/(P.env.rho*A*Vtip^3);
if CT>0 && CP>0, FM=CT^(3/2)/(sqrt(2)*CP); else, FM=NaN; end
end