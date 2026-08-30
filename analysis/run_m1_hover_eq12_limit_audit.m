function results = run_m1_hover_eq12_limit_audit(outputDir)
%RUN_M1_HOVER_EQ12_LIMIT_AUDIT Strict-hover limit audit for NUAA Eq. (12).
%
% At strict hover there is no physically distinguished in-plane flow
% direction, while the current Eq. (12) path retains a cos(psi) first
% harmonic. This audit compares that path with uniform hover inflow under
% otherwise identical M1-A geometry/scalar-C81/global-momentum physics.
%
% The audit deliberately separates:
%   (a) integrated CT/CP/FM sensitivity;
%   (b) first-harmonic flapping-state sensitivity;
%   (c) fixed-axis in-plane H-force sensitivity;
%   (d) blade-local 1/rev thrust, in-plane load, flap-moment and normal-
%       velocity harmonics.
%
% No OARF target is used in the decision logic or in any parameter.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'results','m1_hover_eq12_limit_audit');
end
if ~exist(outputDir,'dir'), mkdir(outputDir); end

Pbase = params_nominal();
scalarC81 = build_xv15_c81_low_order_section_aero();
R = 3.81;
rootCut = 0.0875;
collective75_deg = [6;7;8;9;10;11];
Vtip_fps = [768.4;768.4;768.4;768.0;768.0;767.7];

Ptemplate = Pbase;
Ptemplate.rotor.R = R;
Ptemplate.rotor.Nb = 3;
Ptemplate.rotor.rootCut = rootCut;
Ptemplate.rotor.Ib = Ptemplate.rotor.bladeMass*R^2/3;
Ptemplate.rotor.Sblade = Ptemplate.rotor.bladeMass*R/2;
Ptemplate.rotor.nRadial = 48;
if ~isfield(Ptemplate.env,'aSound'), Ptemplate.env.aSound = 340.0; end

rows = table();
for k = 1:numel(collective75_deg)
    P = Ptemplate;
    Vtip_mps = Vtip_fps(k)*0.3048;
    P.rotor.Omega = Vtip_mps/R;
    eq12 = solve_case(P,collective75_deg(k),scalarC81,'EQ12');
    uni = solve_case(P,collective75_deg(k),scalarC81,'UNIFORM');
    A = pi*R^2;
    [CTe,CPe,FMe] = coeffs(eq12,P,A,Vtip_mps);
    [CTu,CPu,FMu] = coeffs(uni,P,A,Vtip_mps);

    one = table(collective75_deg(k),Vtip_fps(k), ...
        CTe,CPe,FMe,CTu,CPu,FMu, ...
        100*(CTe-CTu)/CTu,100*(CPe-CPu)/CPu,100*(FMe-FMu)/FMu, ...
        eq12.beta0_deg,eq12.beta1c_deg,eq12.beta1s_deg, ...
        uni.beta0_deg,uni.beta1c_deg,uni.beta1s_deg, ...
        eq12.lambdaInduced,eq12.beta1sPlusLambda,eq12.normalizedCancellationResidual, ...
        eq12.Hx_N,eq12.Hy_N,uni.Hx_N,uni.Hy_N, ...
        eq12.bladeThrust1revRatio_pct,uni.bladeThrust1revRatio_pct, ...
        eq12.bladeH1revRatio_pct,uni.bladeH1revRatio_pct, ...
        eq12.flapMoment1revRatio_pct,uni.flapMoment1revRatio_pct, ...
        eq12.maxUP1revRatio_pct,uni.maxUP1revRatio_pct, ...
        eq12.physicalConverged,uni.physicalConverged, ...
        eq12.closureResidualRelative,uni.closureResidualRelative, ...
        'VariableNames',{'collective75_deg','Vtip_fps', ...
        'CT_eq12','CP_eq12','FM_eq12','CT_uniform','CP_uniform','FM_uniform', ...
        'CT_eq12MinusUniform_pct','CP_eq12MinusUniform_pct','FM_eq12MinusUniform_pct', ...
        'beta0_eq12_deg','beta1c_eq12_deg','beta1s_eq12_deg', ...
        'beta0_uniform_deg','beta1c_uniform_deg','beta1s_uniform_deg', ...
        'lambdaInduced_eq12','beta1sPlusLambda_eq12', ...
        'normalizedCancellationResidual_eq12', ...
        'Hx_eq12_N','Hy_eq12_N','Hx_uniform_N','Hy_uniform_N', ...
        'bladeThrust1revRatio_eq12_pct','bladeThrust1revRatio_uniform_pct', ...
        'bladeH1revRatio_eq12_pct','bladeH1revRatio_uniform_pct', ...
        'flapMoment1revRatio_eq12_pct','flapMoment1revRatio_uniform_pct', ...
        'maxUP1revRatio_eq12_pct','maxUP1revRatio_uniform_pct', ...
        'physicalConverged_eq12','physicalConverged_uniform', ...
        'closureResidualRelative_eq12','closureResidualRelative_uniform'});
    rows = [rows;one]; %#ok<AGROW>
end
writetable(rows,fullfile(outputDir,'M1_HOVER_EQ12_LIMIT_POINTS.csv'));

if ~all(rows.physicalConverged_eq12) || ~all(rows.physicalConverged_uniform)
    error('run_m1_hover_eq12_limit_audit:PhysicalClosure', ...
        'Eq12 or uniform strict-hover branch failed physical closure.');
end

% Fail-closed identity against the already existing factorial diagnostic.
legacy = run_xv15_flap_inflow_interaction_diagnostic( ...
    fullfile(outputDir,'legacy_interaction_recheck'));
identityDiff = [ ...
    max(abs(rows.CT_eq12-legacy.table.CT_eq12_full)), ...
    max(abs(rows.CP_eq12-legacy.table.CP_eq12_full)), ...
    max(abs(rows.FM_eq12-legacy.table.FM_eq12_full)), ...
    max(abs(rows.CT_uniform-legacy.table.CT_uniform_full)), ...
    max(abs(rows.CP_uniform-legacy.table.CP_uniform_full)), ...
    max(abs(rows.FM_uniform-legacy.table.FM_uniform_full))];
if any(identityDiff > 1e-12)
    error('run_m1_hover_eq12_limit_audit:IdentityDrift', ...
        'Strict-hover audit drifted from existing factorial diagnostic.');
end

maxAbsCTdiff_pct = max(abs(rows.CT_eq12MinusUniform_pct));
maxAbsCPdiff_pct = max(abs(rows.CP_eq12MinusUniform_pct));
maxAbsFMdiff_pct = max(abs(rows.FM_eq12MinusUniform_pct));
maxEq12Beta1_deg = max(hypot(rows.beta1c_eq12_deg,rows.beta1s_eq12_deg));
maxUniformBeta1_deg = max(hypot(rows.beta1c_uniform_deg,rows.beta1s_uniform_deg));
maxCancellationResidual = max(rows.normalizedCancellationResidual_eq12);
maxEq12UP1rev_pct = max(rows.maxUP1revRatio_eq12_pct);
maxUniformUP1rev_pct = max(rows.maxUP1revRatio_uniform_pct);
maxEq12Thrust1rev_pct = max(rows.bladeThrust1revRatio_eq12_pct);
maxUniformThrust1rev_pct = max(rows.bladeThrust1revRatio_uniform_pct);
maxEq12H_N = max(hypot(rows.Hx_eq12_N,rows.Hy_eq12_N));
maxUniformH_N = max(hypot(rows.Hx_uniform_N,rows.Hy_uniform_N));

% These are model-audit thresholds, fixed independently of OARF error.
% They distinguish a negligible integrated-performance perturbation from a
% material strict-hover first-harmonic state/load artifact.
integralNegligibleThreshold_pct = 0.5;
cancellationThreshold = 0.05;
localOneRevSmallThreshold_pct = 1.0;

integralRobust = maxAbsCTdiff_pct < integralNegligibleThreshold_pct && ...
    maxAbsCPdiff_pct < integralNegligibleThreshold_pct;
cancellationEffective = maxCancellationResidual < cancellationThreshold;
localNormalFlowNearlyAxisymmetric = maxEq12UP1rev_pct < localOneRevSmallThreshold_pct;
localThrustNearlyAxisymmetric = maxEq12Thrust1rev_pct < localOneRevSmallThreshold_pct;
flapStateNonobjective = maxEq12Beta1_deg > max(0.1,10*maxUniformBeta1_deg);

if integralRobust && cancellationEffective && localNormalFlowNearlyAxisymmetric && ...
        localThrustNearlyAxisymmetric && flapStateNonobjective
    decision = ['INTEGRAL_HOVER_PERFORMANCE_ROBUST_BUT_EQ12_FIRST_HARMONIC_' ...
        'FLAP_STATE_IS_STRICT_HOVER_NONOBJECTIVE'];
else
    decision = 'EQ12_STRICT_HOVER_LIMIT_REQUIRES_MODEL_IDENTITY_REPAIR';
end

summary = table(maxAbsCTdiff_pct,maxAbsCPdiff_pct,maxAbsFMdiff_pct, ...
    maxEq12Beta1_deg,maxUniformBeta1_deg,maxCancellationResidual, ...
    maxEq12UP1rev_pct,maxUniformUP1rev_pct,maxEq12Thrust1rev_pct, ...
    maxUniformThrust1rev_pct,maxEq12H_N,maxUniformH_N, ...
    integralRobust,cancellationEffective,localNormalFlowNearlyAxisymmetric, ...
    localThrustNearlyAxisymmetric,flapStateNonobjective,{decision}, ...
    max(identityDiff), ...
    'VariableNames',{'maxAbsCT_eq12MinusUniform_pct', ...
    'maxAbsCP_eq12MinusUniform_pct','maxAbsFM_eq12MinusUniform_pct', ...
    'maxEq12Beta1_deg','maxUniformBeta1_deg','maxNormalizedCancellationResidual', ...
    'maxEq12UP1revRatio_pct','maxUniformUP1revRatio_pct', ...
    'maxEq12BladeThrust1revRatio_pct','maxUniformBladeThrust1revRatio_pct', ...
    'maxEq12FixedAxisH_N','maxUniformFixedAxisH_N', ...
    'integralPerformanceRobust','cancellationEffective', ...
    'localNormalFlowNearlyAxisymmetric','localThrustNearlyAxisymmetric', ...
    'eq12FlapStateNonobjective','decision','legacyIdentityMaxAbsDiff'});
writetable(summary,fullfile(outputDir,'M1_HOVER_EQ12_LIMIT_SUMMARY.csv'));

metadataName = {'audit';'physics_change';'oarf_parameter_fit'; ...
    'eq12_definition';'uniform_definition';'H_projection_convention'; ...
    'integral_negligible_threshold_pct';'cancellation_threshold'; ...
    'local_1rev_small_threshold_pct';'claim_boundary'};
metadataValue = {'STRICT_HOVER_EQ12_LIMIT';'NONE_ANALYSIS_ONLY';'NO'; ...
    'vi_mean_times_1_plus_r_over_R_cos_psi'; ...
    'vi_mean_axisymmetric'; ...
    'diagnostic_tangential_H_projected_as_x_minus_sinpsi_y_plus_cospsi'; ...
    num2str(integralNegligibleThreshold_pct,'%.6g'); ...
    num2str(cancellationThreshold,'%.6g'); ...
    num2str(localOneRevSmallThreshold_pct,'%.6g'); ...
    'STRICT_HOVER_LIMIT_AUDIT_NOT_FORWARD_FLIGHT_EQ12_INVALIDATION'};
metadata = table(metadataName,metadataValue);
writetable(metadata,fullfile(outputDir,'M1_HOVER_EQ12_LIMIT_METADATA.csv'));

results = struct();
results.table = rows;
results.summary = summary;
results.metadata = metadata;
results.identityDiff = identityDiff;
results.claimBoundary = metadataValue{end};
save(fullfile(outputDir,'M1_HOVER_EQ12_LIMIT_RESULTS.mat'),'results');
end

function out = solve_case(P,theta75_deg,scalarC81,inflowMode)
R=P.rotor.R; Omega=P.rotor.Omega; Vtip=Omega*R; rho=P.env.rho; A=pi*R^2;
r0=P.rotor.rootCut*R; edges=linspace(r0,R,P.rotor.nRadial+1);
r=0.5*(edges(1:end-1)+edges(2:end)); dr=diff(edges); x=r/R;
psi=((0:P.rotor.nAzimuth-1)*(2*pi/P.rotor.nAzimuth)).';
chord=xv15_metal_chord_m(x);
theta75Source_deg=nasa_metal_twist_deg(0.75);
theta=(theta75_deg+nasa_metal_twist_deg(x)-theta75Source_deg)*pi/180;
UT=Omega*r;

vi=sqrt(max(P.mass.m*P.env.g/2,1)/(2*rho*A));
z=P.rotor.flapInitial(:); converged=false; flapOK=false; flapNorm=Inf;
for iter=1:max(100,5*P.rotor.inducedMaxIter)
    [z,flapOK,flapNorm]=solve_flap(vi,z);
    if ~flapOK, break; end
    loads=blade_loads(vi,z);
    lambda1=-vi/max(Vtip,eps);
    CTiter=max(loads.T,0)/(0.5*rho*A*Vtip^2);
    viTarget=Vtip*CTiter/(4*max(abs(lambda1),1e-12));
    viNew=0.5*(vi+viTarget);
    viError=abs(viNew-vi)/max(1,abs(vi));
    vi=viNew;
    if viError<1e-6 && flapNorm<=P.rotor.flapResidualTol
        converged=true; break;
    end
end
loads=blade_loads(vi,z);
lambdaInduced=vi/(Omega*R);
momentumThrust=2*rho*A*Vtip*vi*abs(-lambdaInduced);
closure=abs(loads.T-momentumThrust)/max([abs(loads.T),abs(momentumThrust),1]);
physical=converged && flapOK && loads.T>0 && closure<=2e-4;

beta1sPlusLambda=z(3)+lambdaInduced;
normalizedCancellationResidual=abs(beta1sPlusLambda)/max(abs(lambdaInduced),eps);

out=struct();
out.thrust=loads.T; out.torque=loads.Q; out.physicalConverged=physical;
out.closureResidualRelative=closure; out.inducedVelocity=vi; out.zFlap=z;
out.beta0_deg=z(1)*180/pi; out.beta1c_deg=z(2)*180/pi; out.beta1s_deg=z(3)*180/pi;
out.lambdaInduced=lambdaInduced; out.beta1sPlusLambda=beta1sPlusLambda;
out.normalizedCancellationResidual=normalizedCancellationResidual;
out.Hx_N=loads.Hx_N; out.Hy_N=loads.Hy_N;
out.bladeThrust1revRatio_pct=harmonic_ratio(loads.bladeThrustByAzimuth);
out.bladeH1revRatio_pct=harmonic_ratio(loads.bladeHByAzimuth);
out.flapMoment1revRatio_pct=harmonic_ratio(loads.flapMomentByAzimuth);
out.maxUP1revRatio_pct=max_up_harmonic_ratio(loads.UP);

    function [zNow,ok,rn] = solve_flap(viNow,z0)
        zNow=z0(:); ok=false; rn=Inf;
        for kk=1:P.rotor.flapMaxIter
            [res,scale]=flap_residual(zNow,viNow); rn=norm(res/scale);
            if rn<=P.rotor.flapResidualTol, ok=true; return; end
            J=zeros(3,3);
            for jj=1:3
                h=P.rotor.flapJacobianStep*max(1,abs(zNow(jj)));
                zp=zNow; zm=zNow; zp(jj)=zp(jj)+h; zm(jj)=zm(jj)-h;
                [rp,~]=flap_residual(zp,viNow); [rm,~]=flap_residual(zm,viNow);
                J(:,jj)=(rp-rm)/(2*h*scale);
            end
            if ~all(isfinite(J(:))) || rcond(J.'*J)<1e-14, return; end
            dz=-(J.'*J+P.rotor.flapNewtonRegularization*eye(3))\(J.'*(res/scale));
            step=1; accepted=false;
            for trial=1:P.rotor.flapLineSearchMaxIter
                zc=zNow+step*dz; beta=zc(1)+zc(2)*cos(psi)+zc(3)*sin(psi);
                if all(isfinite(zc)) && max(abs(beta))<P.rotor.flapDivergenceAngle
                    [rc,sc]=flap_residual(zc,viNow);
                    if norm(rc/sc)<rn, zNow=zc; accepted=true; break; end
                end
                step=step*P.rotor.flapNewtonDamping;
            end
            if ~accepted, return; end
        end
    end

    function [res,scale] = flap_residual(zNow,viNow)
        L=blade_loads(viNow,zNow);
        gravity=-P.rotor.Sblade*P.env.g*cos(L.beta);
        inertial=P.rotor.Ib*L.betaDDot+P.rotor.Ib*Omega^2*L.beta;
        by=inertial-L.flapMomentByAzimuth-gravity;
        res=[mean(by);2*mean(by.*cos(psi));2*mean(by.*sin(psi))];
        scale=max([max(abs(L.flapMomentByAzimuth)),max(abs(gravity)), ...
            P.rotor.Ib*Omega^2*0.05,1]);
    end

    function L = blade_loads(viNow,zNow)
        beta=zNow(1)+zNow(2)*cos(psi)+zNow(3)*sin(psi);
        betaDot=-Omega*(-zNow(2)*sin(psi)+zNow(3)*cos(psi));
        betaDDot=-Omega^2*(zNow(2)*cos(psi)+zNow(3)*sin(psi));
        if strcmp(inflowMode,'EQ12')
            viField=viNow.*(1+cos(psi).*(r/R));
        elseif strcmp(inflowMode,'UNIFORM')
            viField=viNow+zeros(numel(psi),numel(r));
        else
            error('run_m1_hover_eq12_limit_audit:InflowMode','Unknown inflow mode.');
        end
        UP=viField-betaDot.*r;
        W=hypot(UT,UP); phi=atan2(UP,max(abs(UT),1e-8)); alpha=theta-phi;
        CL=scalarC81.CLmax*tanh( ...
            scalarC81.liftSlope*(alpha-scalarC81.alpha0L_rad)/scalarC81.CLmax);
        CD=scalarC81.CD0+scalarC81.kCD*CL.^2;
        q=0.5*rho*W.^2; dL=q.*chord.*CL.*dr; dD=q.*chord.*CD.*dr;
        dT=dL.*cos(phi)-dD.*sin(phi); dH=dD.*cos(phi)+dL.*sin(phi);
        dQ=dH.*r; factor=P.rotor.Nb/P.rotor.nAzimuth;
        Tb=sum(dT,2); Hb=sum(dH,2); Mb=sum(dT.*r,2);
        L.T=factor*sum(dT(:)); L.Q=factor*sum(dQ(:));
        L.Hx_N=factor*sum(-Hb.*sin(psi));
        L.Hy_N=factor*sum(Hb.*cos(psi));
        L.flapMomentByAzimuth=Mb; L.bladeThrustByAzimuth=Tb;
        L.bladeHByAzimuth=Hb; L.UP=UP; L.beta=beta; L.betaDDot=betaDDot;
    end

    function ratioPct = harmonic_ratio(y)
        y0=mean(y); y1c=2*mean(y.*cos(psi)); y1s=2*mean(y.*sin(psi));
        ratioPct=100*hypot(y1c,y1s)/max(abs(y0),1e-12);
    end

    function ratioPct = max_up_harmonic_ratio(UP)
        u0=mean(UP,1); u1c=2*mean(UP.*cos(psi),1); u1s=2*mean(UP.*sin(psi),1);
        ratioPct=100*max(hypot(u1c,u1s)./max(abs(u0),1e-12));
    end
end

function [CT,CP,FM]=coeffs(out,P,A,Vtip)
CT=out.thrust/(P.env.rho*A*Vtip^2);
CP=out.torque*P.rotor.Omega/(P.env.rho*A*Vtip^3);
if CT>0 && CP>0, FM=CT^(3/2)/(sqrt(2)*CP); else, FM=NaN; end
end
function c=xv15_metal_chord_m(x)
cIn=14*ones(size(x)); mask=x<=0.25; cIn(mask)=-18.4615*x(mask)+18.6154; c=cIn*0.0254;
end
function theta=nasa_metal_twist_deg(x)
theta=289.98*x.^5-892.87*x.^4+987.06*x.^3-438.31*x.^2+15.695*x+32.057;
end
