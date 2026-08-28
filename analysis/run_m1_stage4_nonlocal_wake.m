function results = run_m1_stage4_nonlocal_wake(outputDir)
%RUN_M1_STAGE4_NONLOCAL_WAKE M1-F prescribed nonlocal wake diagnostic.
%
% Primary scientific question:
%   After freezing the generic M1-E-1 Corrigan n=1 rotational-stall-delay
%   layer, does a source-constrained nonlocal prescribed wake materially
%   reduce the remaining XV-15 hover CT/CP residual without fitting OARF?
%
% Predeclared model identities:
%   M1_E1_REFERENCE
%     Existing M1-E generic n=1 result, rerun in this workflow.
%   M1_F0_UNIFORM_MOMENTUM_CONTROL
%     Same actual geometry + C81 + Corrigan n=1 aerodynamics, but removes the
%     legacy first-harmonic hover inflow shape and uses uniform momentum
%     inflow.  This isolates that bookkeeping/model-form change.
%   M1_F1_LANDGREBE_NONLOCAL
%     Same aerodynamics, with the disk-average induced velocity constrained
%     by momentum theory and the radial inflow SHAPE supplied by a discrete
%     Landgrebe-form contracted trailing-vortex wake integrated using the
%     finite-segment Biot-Savart law.
%
% No CT/CP/FM gain, collective offset, wake-strength multiplier, contraction
% multiplier, wake-age parameter fit, or MAPE optimization is permitted.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'results','m1_stage4_nonlocal_wake');
end
if ~exist(outputDir,'dir'), mkdir(outputDir); end

% Re-run M1-E in the same MATLAB workflow and use ONLY the generic n=1 branch
% as the scientific reference.  The n=1.8 XV-15-correlated branch remains a
% non-independent replication and is not promoted into M1-F.
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

% Landgrebe requires a solidity and a linear root-to-tip twist measure.
% The original XV-15 metal blade uses a 14-in rectangular main planform;
% sigma below is derived from that public geometry, not from OARF output.
referenceChord_m = 14*0.0254;
sigmaLandgrebe = Pbase.rotor.Nb*referenceChord_m/(pi*R);
thetaTwEq_deg = nasa_metal_twist_deg(1.0)-nasa_metal_twist_deg(rootCut);

primaryWakeTurns = 3.0;
primarySegmentsPerRev = 36;
modes = {'M1_F0_UNIFORM_MOMENTUM_CONTROL';'M1_F1_LANDGREBE_NONLOCAL'};
role = {'MODEL_FORM_CONTROL_NO_WAKE_FIT';'SOURCE_CONSTRAINED_NONLOCAL_WAKE_DIAGNOSTIC'};
independence = {'NOT_SELECTED_FROM_CURRENT_OARF_TARGETS';'NOT_SELECTED_FROM_CURRENT_OARF_TARGETS'};

Ptemplate = Pbase;
Ptemplate.rotor.R = R;
Ptemplate.rotor.Nb = 3;
Ptemplate.rotor.rootCut = rootCut;
Ptemplate.rotor.Ib = Ptemplate.rotor.bladeMass*R^2/3;
Ptemplate.rotor.Sblade = Ptemplate.rotor.bladeMass*R/2;
if ~isfield(Ptemplate.env,'aSound'), Ptemplate.env.aSound = 340.0; end

rows = table();
for im = 1:numel(modes)
    for k = 1:numel(collective75_deg)
        P = Ptemplate;
        Vtip_mps = Vtip_fps(k)*0.3048;
        P.rotor.Omega = Vtip_mps/R;
        if strcmp(modes{im},'M1_F0_UNIFORM_MOMENTUM_CONTROL')
            wakeMode = 'UNIFORM_MOMENTUM';
        else
            wakeMode = 'LANDGREBE_NONLOCAL';
        end
        out = solve_hover(P,collective75_deg(k),wakeMode, ...
            sigmaLandgrebe,thetaTwEq_deg,primaryWakeTurns,primarySegmentsPerRev);
        A = pi*R^2;
        CT = out.thrust/(P.env.rho*A*Vtip_mps^2);
        CP = out.torque*P.rotor.Omega/(P.env.rho*A*Vtip_mps^3);
        if CT > 0 && CP > 0
            FM = CT^(3/2)/(sqrt(2)*CP);
        else
            FM = NaN;
        end
        one = table(modes(im),role(im),independence(im),collective75_deg(k), ...
            Vtip_fps(k),CT_exp(k),CT,100*(CT-CT_exp(k))/CT_exp(k), ...
            CP_exp(k),CP,100*(CP-CP_exp(k))/CP_exp(k), ...
            FM_exp(k),FM,100*(FM-FM_exp(k))/FM_exp(k), ...
            out.physicalConverged,out.iterations,out.viMomentum_mps, ...
            out.viAreaMean_mps,out.viMin_mps,out.viMax_mps,out.viCV, ...
            out.momentumMeanClosureRelative,out.rawWakeMean_mps, ...
            out.wakeK1,out.wakeK2,out.wakeGammaContract, ...
            out.wakeSkippedNearSingular,out.alphaClampCount,out.machClampCount, ...
            out.KLMinApplied,out.KLMaxApplied,out.stallDelayApplyCount, ...
            'VariableNames',{'mode','role','independence','collective75_deg', ...
            'Vtip_fps','CT_exp','CT_model','CT_relativeError_pct','CP_exp', ...
            'CP_model','CP_relativeError_pct','FM_exp','FM_model', ...
            'FM_relativeError_pct','physicalConverged','iterations', ...
            'viMomentum_mps','viAreaMean_mps','viMin_mps','viMax_mps','viCV', ...
            'momentumMeanClosureRelative','rawWakeMean_mps','wakeK1','wakeK2', ...
            'wakeGammaContract','wakeSkippedNearSingular','alphaClampCount', ...
            'machClampCount','KLMinApplied','KLMaxApplied','stallDelayApplyCount'});
        rows = [rows;one]; %#ok<AGROW>
    end
end
writetable(rows,fullfile(outputDir,'M1_STAGE4_NONLOCAL_WAKE_POINTS.csv'));

% Metric table begins with the freshly re-run M1-E-1 reference.
metricMode = {'M1_E1_REFERENCE'};
metricRole = {'GENERIC_CORRIGAN_N1_GLOBAL_MOMENTUM_REFERENCE'};
metricIndependence = {'NOT_SELECTED_FROM_CURRENT_OARF_TARGETS'};
metrics = table(metricMode,metricRole,metricIndependence,6, ...
    refMetric.CT_MAPE_pct,refMetric.CP_MAPE_pct,refMetric.FM_MAPE_pct, ...
    refMetric.CT_meanSigned_pct,refMetric.CP_meanSigned_pct,refMetric.FM_meanSigned_pct, ...
    'VariableNames',{'mode','role','independence','supportedPointCount', ...
    'CT_MAPE_pct','CP_MAPE_pct','FM_MAPE_pct','CT_meanSigned_pct', ...
    'CP_meanSigned_pct','FM_meanSigned_pct'});
for im = 1:numel(modes)
    mask = strcmp(rows.mode,modes{im}) & rows.physicalConverged;
    if sum(mask) ~= numel(collective75_deg)
        error('run_m1_stage4_nonlocal_wake:IncompleteVariant', ...
            '%s has only %d supported points.',modes{im},sum(mask));
    end
    one = table(modes(im),role(im),independence(im),sum(mask), ...
        mean(abs(rows.CT_relativeError_pct(mask))), ...
        mean(abs(rows.CP_relativeError_pct(mask))), ...
        mean(abs(rows.FM_relativeError_pct(mask))), ...
        mean(rows.CT_relativeError_pct(mask)), ...
        mean(rows.CP_relativeError_pct(mask)), ...
        mean(rows.FM_relativeError_pct(mask)), ...
        'VariableNames',metrics.Properties.VariableNames);
    metrics = [metrics;one]; %#ok<AGROW>
end
metrics.CT_deltaFromM1E1_pp = metrics.CT_MAPE_pct-metrics.CT_MAPE_pct(1);
metrics.CP_deltaFromM1E1_pp = metrics.CP_MAPE_pct-metrics.CP_MAPE_pct(1);
metrics.FM_deltaFromM1E1_pp = metrics.FM_MAPE_pct-metrics.FM_MAPE_pct(1);
writetable(metrics,fullfile(outputDir,'M1_STAGE4_NONLOCAL_WAKE_METRICS.csv'));

% Numerical wake discretization verification at 10 deg.  These cases are
% fixed a priori and are NOT selected by OARF error.  They test wake-age
% truncation and segment resolution around the primary 3-turn/36-seg case.
verifyTurns = [2;3;3;3;4];
verifySegs = [36;24;36;48;36];
verifyRows = table();
for iv = 1:numel(verifyTurns)
    P = Ptemplate;
    Vtip_mps = 768.0*0.3048;
    P.rotor.Omega = Vtip_mps/R;
    out = solve_hover(P,10,'LANDGREBE_NONLOCAL',sigmaLandgrebe,thetaTwEq_deg, ...
        verifyTurns(iv),verifySegs(iv));
    A = pi*R^2;
    CT = out.thrust/(P.env.rho*A*Vtip_mps^2);
    CP = out.torque*P.rotor.Omega/(P.env.rho*A*Vtip_mps^3);
    FM = CT^(3/2)/(sqrt(2)*CP);
    one = table(verifyTurns(iv),verifySegs(iv),CT,CP,FM,out.viAreaMean_mps, ...
        out.viMin_mps,out.viMax_mps,out.viCV,out.iterations,out.physicalConverged, ...
        'VariableNames',{'wakeTurns','segmentsPerRev','CT_model','CP_model','FM_model', ...
        'viAreaMean_mps','viMin_mps','viMax_mps','viCV','iterations','physicalConverged'});
    verifyRows = [verifyRows;one]; %#ok<AGROW>
end
primaryMask = verifyRows.wakeTurns == primaryWakeTurns & ...
    verifyRows.segmentsPerRev == primarySegmentsPerRev;
if sum(primaryMask) ~= 1
    error('run_m1_stage4_nonlocal_wake:MissingPrimaryVerification','Primary verification case missing.');
end
verifyRows.CT_deltaFromPrimary_pct = 100*(verifyRows.CT_model-verifyRows.CT_model(primaryMask))/verifyRows.CT_model(primaryMask);
verifyRows.CP_deltaFromPrimary_pct = 100*(verifyRows.CP_model-verifyRows.CP_model(primaryMask))/verifyRows.CP_model(primaryMask);
verifyRows.FM_deltaFromPrimary_pct = 100*(verifyRows.FM_model-verifyRows.FM_model(primaryMask))/verifyRows.FM_model(primaryMask);
writetable(verifyRows,fullfile(outputDir,'M1_STAGE4_WAKE_DISCRETIZATION.csv'));

metadataName = { ...
    'model_identity';'reference_model';'report_window';'dataset_role'; ...
    'stall_delay_mode';'wake_geometry_source';'wake_induction_method'; ...
    'wake_mean_closure';'landgrebe_solidity';'landgrebe_equivalent_twist_deg'; ...
    'primary_wake_turns';'primary_segments_per_rev'; ...
    'inboard_sheet_geometry_role';'parameter_fit_to_current_OARF_targets'; ...
    'numeric_parameter_search';'selection_rule_after_execution'};
metadataValue = { ...
    'M1_F_NONLOCAL_PRESCRIBED_WAKE'; ...
    'M1_E1_GENERIC_CORRIGAN_N1';'FIXED_6_TO_11_DEG'; ...
    'DEVELOPMENT_EXTERNAL_CORRELATION';'CORRIGAN_GENERIC_N1'; ...
    'LANDGREBE_HOVER_TIP_TRAJECTORY_Ramasamy_Gold_Bhagwat_2010'; ...
    'DISCRETE_TRAILING_VORTICES_FINITE_SEGMENT_BIOT_SAVART'; ...
    'AREA_MEAN_INFLOW_CONSTRAINED_BY_MOMENTUM_THEORY'; ...
    sprintf('%.12g',sigmaLandgrebe);sprintf('%.12g',thetaTwEq_deg); ...
    sprintf('%.12g',primaryWakeTurns);sprintf('%d',primarySegmentsPerRev); ...
    'ASSUMED_UNIFORM_NORMALIZED_CONTRACTION_EXTENSION_NOT_FULL_LANDGREBE_INBOARD_SHEET'; ...
    'NO';'NO';'REPORT_ALL_VARIANTS_DO_NOT_PICK_FROM_RUN15_MAPE'};
writetable(table(metadataName,metadataValue), ...
    fullfile(outputDir,'M1_STAGE4_NONLOCAL_WAKE_METADATA.csv'));

results = struct();
results.points = rows;
results.metrics = metrics;
results.verification = verifyRows;
results.referencePoints = refPoints;
results.claimBoundary = [ ...
    'M1_F_SOURCE_CONSTRAINED_NONLOCAL_WAKE_MODEL_FORM_DIAGNOSTIC_' ...
    'MOMENTUM_NORMALIZED_NO_OARF_WAKE_PARAMETER_FIT_' ...
    'CLASSIC_PRESCRIBED_WAKE_LIMITED_FOR_HIGHLY_TWISTED_XV15'];
save(fullfile(outputDir,'M1_STAGE4_NONLOCAL_WAKE_RESULTS.mat'),'results');
end

function out = solve_hover(P,theta75_deg,wakeMode,sigmaLandgrebe,thetaTwEq_deg,wakeTurns,segmentsPerRev)
R = P.rotor.R;
Omega = P.rotor.Omega;
tipSpeed = Omega*R;
rho = P.env.rho;
A = pi*R^2;
r0 = P.rotor.rootCut*R;
rEdges = linspace(r0,R,P.rotor.nRadial+1);
rMid = 0.5*(rEdges(1:end-1)+rEdges(2:end));
dr = diff(rEdges);
psi = ((0:P.rotor.nAzimuth-1)*(2*pi/P.rotor.nAzimuth)).';
x = rMid/R;
chord_in = 14*ones(size(x));
inboard = x <= 0.25;
chord_in(inboard) = -18.4615*x(inboard)+18.6154;
chord_m = chord_in*0.0254;
thetaSource_deg = nasa_metal_twist_deg(x);
theta75Source_deg = nasa_metal_twist_deg(0.75);
thetaBlade = (theta75_deg+thetaSource_deg-theta75Source_deg)*pi/180;
UT = Omega*rMid;
areaWeights = rMid.*dr;

vi0 = sqrt(max(P.mass.m*P.env.g/2,1)/(2*rho*A));
viRadial = vi0*ones(size(rMid));
zFlap = P.rotor.flapInitial(:);
converged = false;
wakeMeta = empty_wake_meta();
rawWakeMean = NaN;
for iter = 1:P.rotor.inducedMaxIter
    [zFlap,flapInfo] = solve_flap(viRadial,zFlap);
    if ~flapInfo.converged, break; end
    loads = blade_loads(viRadial,zFlap);
    if ~(isfinite(loads.T) && loads.T > 0), break; end
    viMomentum = sqrt(loads.T/(2*rho*A));
    if strcmp(wakeMode,'UNIFORM_MOMENTUM')
        viTarget = viMomentum*ones(size(viRadial));
        wakeMeta = empty_wake_meta();
        rawWakeMean = viMomentum;
    elseif strcmp(wakeMode,'LANDGREBE_NONLOCAL')
        CTstd = loads.T/(rho*A*tipSpeed^2);
        [rawWake,wakeMeta] = xv15_landgrebe_biot_savart_inflow( ...
            rMid,rEdges,loads.gammaMean,CTstd,sigmaLandgrebe,thetaTwEq_deg, ...
            P.rotor.Nb,R,wakeTurns,segmentsPerRev);
        rawWakeMean = sum(rawWake.*areaWeights)/sum(areaWeights);
        if ~(isfinite(rawWakeMean) && rawWakeMean > 0)
            error('run_m1_stage4_nonlocal_wake:InvalidWakeMean', ...
                'Raw Biot-Savart wake mean is not positive at collective %.3g deg.',theta75_deg);
        end
        % Nonlocal wake supplies only radial SHAPE; momentum theory supplies
        % the disk-average magnitude.  Negative local values are retained as
        % physical local upwash if the vortex solution produces them.
        viTarget = viMomentum*(rawWake/rawWakeMean);
    else
        error('run_m1_stage4_nonlocal_wake:InvalidWakeMode','Unknown wake mode %s.',wakeMode);
    end
    viNew = (1-P.rotor.inducedRelax)*viRadial + P.rotor.inducedRelax*viTarget;
    err = max(abs(viNew-viRadial))/max(1,max(abs(viRadial)));
    viRadial = viNew;
    if err < P.rotor.inducedTol && flapInfo.residualNorm <= P.rotor.flapResidualTol
        converged = true;
        break;
    end
end

[zFlap,flapInfo] = solve_flap(viRadial,zFlap);
loads = blade_loads(viRadial,zFlap);
viMomentum = sqrt(max(loads.T,0)/(2*rho*A));
viAreaMean = sum(viRadial.*areaWeights)/sum(areaWeights);
meanClosure = abs(viAreaMean-viMomentum)/max(viMomentum,1e-12);
physical = converged && flapInfo.converged && loads.T > 0 && meanClosure <= 5e-3;

out = struct();
out.thrust = loads.T;
out.torque = loads.Q;
out.physicalConverged = physical;
out.iterations = iter;
out.viMomentum_mps = viMomentum;
out.viAreaMean_mps = viAreaMean;
out.viMin_mps = min(viRadial);
out.viMax_mps = max(viRadial);
out.viCV = std(viRadial)/max(abs(mean(viRadial)),1e-12);
out.momentumMeanClosureRelative = meanClosure;
out.rawWakeMean_mps = rawWakeMean;
out.wakeK1 = wakeMeta.k1;
out.wakeK2 = wakeMeta.k2;
out.wakeGammaContract = wakeMeta.gammaContract;
out.wakeSkippedNearSingular = wakeMeta.skippedNearSingular;
out.alphaClampCount = loads.alphaClampCount;
out.machClampCount = loads.machClampCount;
out.KLMinApplied = loads.KLMinApplied;
out.KLMaxApplied = loads.KLMaxApplied;
out.stallDelayApplyCount = loads.applyCount;

    function [z,info] = solve_flap(viNow,z0)
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
                zc=z+step*dz;
                betaCheck=zc(1)+zc(2)*cos(psi)+zc(3)*sin(psi);
                if all(isfinite(zc)) && max(abs(betaCheck))<P.rotor.flapDivergenceAngle
                    [rc,sc]=flap_residual(zc,viNow);
                    if norm(rc/sc)<norm(rn), z=zc; accepted=true; break; end
                end
                step=step*P.rotor.flapNewtonDamping;
            end
            if ~accepted, return; end
        end
        [res,scale]=flap_residual(z,viNow);
        info.iterations=P.rotor.flapMaxIter; info.residualNorm=norm(res/scale);
    end

    function [res,scale]=flap_residual(z,viNow)
        ll=blade_loads(viNow,z);
        gravityMoment=-P.rotor.Sblade*P.env.g*cos(ll.beta);
        inertialRestoring=P.rotor.Ib*ll.betaDDot+P.rotor.Ib*Omega^2*ll.beta;
        byAz=inertialRestoring-ll.flapMomentByAzimuth-gravityMoment;
        res=[mean(byAz);2*mean(byAz.*cos(psi));2*mean(byAz.*sin(psi))];
        scale=max([max(abs(ll.flapMomentByAzimuth)),max(abs(gravityMoment)),P.rotor.Ib*Omega^2*0.05,1]);
    end

    function ll=blade_loads(viNow,z)
        betaLocal=z(1)+z(2)*cos(psi)+z(3)*sin(psi);
        betaDotLocal=-Omega*(-z(2)*sin(psi)+z(3)*cos(psi));
        betaDDotLocal=-Omega^2*(z(2)*cos(psi)+z(3)*sin(psi));
        viField=ones(P.rotor.nAzimuth,1)*viNow;
        UP=viField-betaDotLocal.*rMid;
        W=hypot(UT,UP);
        phi=atan2(UP,max(abs(UT),1e-8));
        alpha=thetaBlade-phi;
        Mach=W/P.env.aSound;
        chordField=ones(size(alpha)).*chord_m;
        rField=ones(size(alpha)).*x;
        [CL,CD,meta]=xv15_c81_corrigan_stall_delay(alpha,Mach,rField,chordField,R,'CORRIGAN_GENERIC_N1');
        q=0.5*rho*W.^2;
        dL=q.*chord_m.*CL.*dr;
        dD=q.*chord_m.*CD.*dr;
        dT=dL.*cos(phi)-dD.*sin(phi);
        dH=dD.*cos(phi)+dL.*sin(phi);
        dQ=dH.*rMid;
        factor=P.rotor.Nb/P.rotor.nAzimuth;
        ringT=factor*sum(dT,1);
        ringQ=factor*sum(dQ,1);
        ll.T=sum(ringT);
        ll.Q=sum(ringQ);
        ll.flapMomentByAzimuth=sum(dT.*rMid,2);
        ll.beta=betaLocal;
        ll.betaDDot=betaDDotLocal;
        ll.gammaMean=mean(0.5*W.*chord_m.*CL,1);
        ll.alphaClampCount=meta.alphaClampCount;
        ll.machClampCount=meta.machClampCount;
        ll.applyCount=meta.applyCount;
        ll.KLMinApplied=meta.KLMinApplied;
        ll.KLMaxApplied=meta.KLMaxApplied;
    end
end

function m = empty_wake_meta()
m = struct('k1',NaN,'k2',NaN,'gammaContract',NaN,'skippedNearSingular',0);
end
