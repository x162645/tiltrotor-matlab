function results = run_m1_stage2_loaded_torsion(outputDir)
%RUN_M1_STAGE2_LOADED_TORSION M1-D source-constrained hover torsion study.
%
% Purpose:
%   Quantify whether XV-15 reference-model blade torsional stiffness and
%   pitch-control-system compliance can explain the remaining systematic
%   hover CT/CP underprediction after restoring actual radial geometry and
%   spanwise C81 aerodynamics.
%
% Method boundary:
%   - OARF Run 15 CT/CP/FM are comparison targets only.
%   - No stiffness multiplier, collective offset, CT/CP gain or MAPE-based
%     parameter search is permitted.
%   - GJ, XQC and KPL come from NASA/TP-2004-212262 reference CAMRAD II
%     inputs; they are not claimed as record-level OARF measurements.
%   - This is a quasi-static torsion diagnostic, not a full aeroelastic
%     reproduction of CAMRAD II.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'results','m1_stage2_loaded_torsion');
end
if ~exist(outputDir,'dir'), mkdir(outputDir); end

Pbase = params_nominal();
S = build_xv15_metal_torsion_reference();
R = 3.81;
rootCut = 0.0875;
collective75_deg = [6;7;8;9;10;11];
Vtip_fps = [768.4;768.4;768.4;768.0;768.0;767.7];
CT_exp = [0.009208;0.010104;0.011063;0.012035;0.013089;0.013929];
CP_exp = [0.000796;0.000913;0.001044;0.001188;0.001358;0.001523];
FM_exp = [0.7849;0.7866;0.7881;0.7858;0.7797;0.7632];

configName = { ...
    'M1_B_RIGID_REFERENCE'; ...
    'M1_D_BLADE_GJ_ONLY'; ...
    'M1_D_PITCH_LINK_ONLY'; ...
    'M1_D_FULL_GJ_KPL'};
useBladeGJ = [false;true;false;true];
usePitchLink = [false;false;true;true];

Ptemplate = Pbase;
Ptemplate.rotor.R = R;
Ptemplate.rotor.Nb = 3;
Ptemplate.rotor.rootCut = rootCut;
Ptemplate.rotor.Ib = Ptemplate.rotor.bladeMass*R^2/3;
Ptemplate.rotor.Sblade = Ptemplate.rotor.bladeMass*R/2;
if ~isfield(Ptemplate.env,'aSound'), Ptemplate.env.aSound = 340.0; end

rows = table();
for ic = 1:numel(configName)
    for k = 1:numel(collective75_deg)
        P = Ptemplate;
        Vtip_mps = Vtip_fps(k)*0.3048;
        P.rotor.Omega = Vtip_mps/R;
        out = solve_loaded_torsion_hover(P,collective75_deg(k),S, ...
            useBladeGJ(ic),usePitchLink(ic));
        A = pi*R^2;
        CT = out.thrust/(P.env.rho*A*Vtip_mps^2);
        CP = out.torque*P.rotor.Omega/(P.env.rho*A*Vtip_mps^3);
        if CT > 0 && CP > 0
            FM = CT^(3/2)/(sqrt(2)*CP);
        else
            FM = NaN;
        end
        probeR = [0.25 0.50 0.75 0.90 1.00];
        probeTwist_deg = interp1(out.rR,out.elasticTwist_rad*180/pi, ...
            probeR,'linear','extrap');

        one = table(configName(ic),collective75_deg(k),Vtip_fps(k), ...
            CT_exp(k),CT,100*(CT-CT_exp(k))/CT_exp(k), ...
            CP_exp(k),CP,100*(CP-CP_exp(k))/CP_exp(k), ...
            FM_exp(k),FM,100*(FM-FM_exp(k))/FM_exp(k), ...
            out.physicalConverged,out.iterations,out.inducedVelocity_mps, ...
            out.rootPitchLinkTwist_rad*180/pi,out.bladeTipStructuralTwist_rad*180/pi, ...
            probeTwist_deg(1),probeTwist_deg(2),probeTwist_deg(3), ...
            probeTwist_deg(4),probeTwist_deg(5), ...
            out.totalAeroTorsion_Nm,out.totalCmTorsion_Nm, ...
            out.totalOffsetTorsion_Nm,out.alphaClampCount,out.machClampCount, ...
            out.finalTwistStep_deg,out.inducedClosureResidualRelative, ...
            'VariableNames',{'configuration','collective75_deg','Vtip_fps', ...
            'CT_exp','CT_model','CT_relativeError_pct','CP_exp','CP_model', ...
            'CP_relativeError_pct','FM_exp','FM_model','FM_relativeError_pct', ...
            'physicalConverged','iterations','inducedVelocity_mps', ...
            'rootPitchLinkTwist_deg','bladeTipStructuralTwist_deg', ...
            'twist025R_deg','twist050R_deg','twist075R_deg','twist090R_deg', ...
            'twist100R_deg','totalAeroTorsion_Nm','totalCmTorsion_Nm', ...
            'totalOffsetTorsion_Nm','alphaClampCount','machClampCount', ...
            'finalTwistStep_deg','inducedClosureResidualRelative'});
        rows = [rows;one]; %#ok<AGROW>
    end
end
writetable(rows,fullfile(outputDir,'M1_STAGE2_LOADED_TORSION_POINTS.csv'));

metrics = table();
for ic = 1:numel(configName)
    mask = strcmp(rows.configuration,configName{ic}) & rows.physicalConverged;
    if sum(mask) ~= numel(collective75_deg)
        error('run_m1_stage2_loaded_torsion:IncompleteConfiguration', ...
            '%s has only %d supported points.',configName{ic},sum(mask));
    end
    one = table(configName(ic),sum(mask), ...
        mean(abs(rows.CT_relativeError_pct(mask))), ...
        mean(abs(rows.CP_relativeError_pct(mask))), ...
        mean(abs(rows.FM_relativeError_pct(mask))), ...
        mean(rows.CT_relativeError_pct(mask)), ...
        mean(rows.CP_relativeError_pct(mask)), ...
        mean(rows.FM_relativeError_pct(mask)), ...
        'VariableNames',{'configuration','supportedPointCount','CT_MAPE_pct', ...
        'CP_MAPE_pct','FM_MAPE_pct','CT_meanSigned_pct', ...
        'CP_meanSigned_pct','FM_meanSigned_pct'});
    metrics = [metrics;one]; %#ok<AGROW>
end
rigidCT = metrics.CT_MAPE_pct(1);
rigidCP = metrics.CP_MAPE_pct(1);
rigidFM = metrics.FM_MAPE_pct(1);
metrics.CT_deltaFromRigid_pp = metrics.CT_MAPE_pct-rigidCT;
metrics.CP_deltaFromRigid_pp = metrics.CP_MAPE_pct-rigidCP;
metrics.FM_deltaFromRigid_pp = metrics.FM_MAPE_pct-rigidFM;
writetable(metrics,fullfile(outputDir,'M1_STAGE2_LOADED_TORSION_METRICS.csv'));

% Verify copied rigid equations remain numerically consistent with the
% already-executed M1-B stage-1 reference at the metric level.
stage1 = run_xv15_actual_geometry_c81_crosscheck(fullfile(outputDir,'stage1_recheck'));
ref = stage1.metrics(stage1.metrics.window == "6-11",:);
rigidMetricTolerance_pp = 1.0e-6;
rigidConsistency = [ ...
    abs(rigidCT-ref.CT_MAPE_fullC81_global_pct), ...
    abs(rigidCP-ref.CP_MAPE_fullC81_global_pct), ...
    abs(rigidFM-ref.FM_MAPE_fullC81_global_pct)];
if any(rigidConsistency > rigidMetricTolerance_pp)
    error('run_m1_stage2_loaded_torsion:RigidBaselineDrift', ...
        'Stage-2 rigid baseline drift exceeds %.3g percentage points.', ...
        rigidMetricTolerance_pp);
end

metadataName = { ...
    'model_identity';'base_model';'dataset_role';'report_window'; ...
    'GJ_source';'XQC_source';'KPL_source';'C81_CM_source'; ...
    'positive_torsion_definition';'XQC_sign_definition'; ...
    'offset_moment_sign_rule';'parameter_fit_to_OARF_targets'; ...
    'aeroelastic_scope';'source_truth_boundary'};
metadataValue = { ...
    'M1_D_QUASISTATIC_LOADED_TORSION'; ...
    'M1_B_ACTUAL_GEOMETRY_SPANWISE_C81_GLOBAL_MOMENTUM'; ...
    'DEVELOPMENT_EXTERNAL_CORRELATION';'FIXED_6_TO_11_DEG'; ...
    S.source;S.source;S.source; ...
    'NASA_TP_2004_212262_C81_CLCD3015_TO_CLCD3018'; ...
    'POSITIVE_ELASTIC_TWIST_INCREASES_LOCAL_GEOMETRIC_PITCH'; ...
    'XQC_POSITIVE_AFT_OF_ELASTIC_AXIS'; ...
    'POSITIVE_NORMAL_FORCE_AT_POSITIVE_AFT_XQC_IS_NOSE_DOWN_NEGATIVE_TORSION'; ...
    'NO'; ...
    'QUASISTATIC_TORSION_NOT_FULL_CAMRADII_AEROELASTICITY'; ...
    S.claimBoundary};
writetable(table(metadataName,metadataValue), ...
    fullfile(outputDir,'M1_STAGE2_METADATA.csv'));

results = struct();
results.points = rows;
results.metrics = metrics;
results.structureReference = S;
results.rigidConsistency_pp = rigidConsistency;
results.claimBoundary = [ ...
    'SOURCE_CONSTRAINED_QUASISTATIC_LOADED_TORSION_' ...
    'NO_OARF_PARAMETER_FIT_NOT_FULL_AEROELASTIC_REPRODUCTION'];
save(fullfile(outputDir,'M1_STAGE2_LOADED_TORSION_RESULTS.mat'),'results');
end

function out = solve_loaded_torsion_hover(P,theta75_deg,S,useBladeGJ,usePitchLink)
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
thetaBase = (theta75_deg + thetaSource_deg-theta75Source_deg)*pi/180;
UT = Omega*rMid;
GJ = interp1(S.rR,S.GJ_Nm2,x,'linear','extrap');
xqc_m = interp1(S.rR,S.XQC_m,x,'linear','extrap');

vi = sqrt(max(P.mass.m*P.env.g/2,1)/(2*rho*A));
zFlap = P.rotor.flapInitial(:);
elasticTwist = zeros(size(rMid));
twistRelax = 0.35;
twistTol = 1.0e-7;
maxIter = max(120,6*P.rotor.inducedMaxIter);
converged = false;
finalTwistStep = Inf;

for iter = 1:maxIter
    [zFlap,flapInfo] = solve_flap(vi,zFlap,elasticTwist);
    if ~flapInfo.converged, break; end
    loads = blade_loads(vi,zFlap,elasticTwist);

    lambda1 = -vi/max(tipSpeed,eps);
    CTiter = max(loads.T,0)/(0.5*rho*A*tipSpeed^2);
    viTarget = tipSpeed*CTiter/(4*max(abs(lambda1),1e-12));
    viNew = 0.5*(vi+viTarget);
    viErr = abs(viNew-vi)/max(1,abs(vi));

    [twistTarget,~,~] = torsion_target(loads);
    twistNew = (1-twistRelax)*elasticTwist+twistRelax*twistTarget;
    finalTwistStep = max(abs(twistNew-elasticTwist));
    vi = viNew;
    elasticTwist = twistNew;

    if viErr < P.rotor.inducedTol && finalTwistStep < twistTol && ...
            flapInfo.residualNorm <= P.rotor.flapResidualTol
        converged = true;
        break;
    end
end

[zFlap,flapInfo] = solve_flap(vi,zFlap,elasticTwist);
loads = blade_loads(vi,zFlap,elasticTwist);
[twistTarget,rootLinkTwist,bladeStructuralTwist] = torsion_target(loads);
if useBladeGJ || usePitchLink
    targetResidual = max(abs(elasticTwist-twistTarget));
else
    targetResidual = 0;
end
lambda1 = -vi/max(tipSpeed,eps);
momentumThrust = 2*rho*A*tipSpeed*vi*abs(lambda1);
closureResidualRelative = abs(loads.T-momentumThrust)/ ...
    max([abs(loads.T),abs(momentumThrust),1]);
physical = converged && flapInfo.converged && loads.T > 0 && ...
    closureResidualRelative <= 2.0e-4 && targetResidual <= 5*twistTol;

out = struct();
out.thrust = loads.T;
out.torque = loads.Q;
out.inducedVelocity_mps = vi;
out.physicalConverged = physical;
out.iterations = iter;
out.rR = x;
out.elasticTwist_rad = elasticTwist;
out.rootPitchLinkTwist_rad = rootLinkTwist;
out.bladeTipStructuralTwist_rad = bladeStructuralTwist(end);
out.totalAeroTorsion_Nm = sum(loads.meanAeroTorsionByRadial_Nm);
out.totalCmTorsion_Nm = sum(loads.meanCmTorsionByRadial_Nm);
out.totalOffsetTorsion_Nm = sum(loads.meanOffsetTorsionByRadial_Nm);
out.alphaClampCount = loads.alphaClampCount;
out.machClampCount = loads.machClampCount;
out.finalTwistStep_deg = finalTwistStep*180/pi;
out.inducedClosureResidualRelative = closureResidualRelative;

    function [target,rootAngle,bladeAngle] = torsion_target(ll)
        aeroMoment = ll.meanAeroTorsionByRadial_Nm;
        internalTorque = fliplr(cumsum(fliplr(aeroMoment)));
        if useBladeGJ
            twistIncrement = internalTorque./GJ.*dr;
            bladeAngle = cumsum(twistIncrement)-0.5*twistIncrement;
        else
            bladeAngle = zeros(size(rMid));
        end
        if usePitchLink
            rootAngle = sum(aeroMoment)/S.KPL_Nm_per_rad;
        else
            rootAngle = 0;
        end
        target = rootAngle+bladeAngle;
    end

    function [z,info] = solve_flap(viNow,z0,twistNow)
        z = z0(:);
        info = struct('converged',false,'iterations',0,'residualNorm',Inf);
        for kk = 1:P.rotor.flapMaxIter
            [res,scale] = flap_residual(z,viNow,twistNow);
            rn = res/scale;
            if norm(rn) <= P.rotor.flapResidualTol
                info.converged = true;
                info.iterations = kk;
                info.residualNorm = norm(rn);
                return;
            end
            J = zeros(3,3);
            for jj = 1:3
                h = P.rotor.flapJacobianStep*max(1,abs(z(jj)));
                zp = z; zm = z;
                zp(jj) = zp(jj)+h; zm(jj) = zm(jj)-h;
                [rp,~] = flap_residual(zp,viNow,twistNow);
                [rm,~] = flap_residual(zm,viNow,twistNow);
                J(:,jj) = (rp-rm)/(2*h*scale);
            end
            if ~all(isfinite(J(:))) || rcond(J.'*J) < 1e-14, return; end
            reg = P.rotor.flapNewtonRegularization;
            dz = -(J.'*J+reg*eye(3))\(J.'*rn);
            step = 1;
            accepted = false;
            for trial = 1:P.rotor.flapLineSearchMaxIter
                zc = z+step*dz;
                betaCheck = zc(1)+zc(2)*cos(psi)+zc(3)*sin(psi);
                if all(isfinite(zc)) && max(abs(betaCheck)) < P.rotor.flapDivergenceAngle
                    [rc,sc] = flap_residual(zc,viNow,twistNow);
                    if norm(rc/sc) < norm(rn)
                        z = zc; accepted = true; break;
                    end
                end
                step = step*P.rotor.flapNewtonDamping;
            end
            if ~accepted, return; end
        end
        [res,scale] = flap_residual(z,viNow,twistNow);
        info.iterations = P.rotor.flapMaxIter;
        info.residualNorm = norm(res/scale);
    end

    function [res,scale] = flap_residual(z,viNow,twistNow)
        ll = blade_loads(viNow,z,twistNow);
        gravityMoment = -P.rotor.Sblade*P.env.g*cos(ll.beta);
        inertialRestoring = P.rotor.Ib*ll.betaDDot+P.rotor.Ib*Omega^2*ll.beta;
        byAz = inertialRestoring-ll.flapMomentByAzimuth-gravityMoment;
        res = [mean(byAz);2*mean(byAz.*cos(psi));2*mean(byAz.*sin(psi))];
        scale = max([max(abs(ll.flapMomentByAzimuth)),max(abs(gravityMoment)), ...
            P.rotor.Ib*Omega^2*0.05,1]);
    end

    function ll = blade_loads(viNow,z,twistNow)
        betaLocal = z(1)+z(2)*cos(psi)+z(3)*sin(psi);
        betaDotLocal = -Omega*(-z(2)*sin(psi)+z(3)*cos(psi));
        betaDDotLocal = -Omega^2*(z(2)*cos(psi)+z(3)*sin(psi));
        viField = viNow.*(1+cos(psi).*(rMid/R));
        UP = viField-betaDotLocal.*rMid;
        W = hypot(UT,UP);
        phi = atan2(UP,max(abs(UT),1e-8));
        theta = thetaBase+twistNow;
        alpha = theta-phi;
        Mach = W/P.env.aSound;
        [CL,CD,aeroMeta] = xv15_c81_section_lookup(alpha,Mach,rMid/R);
        [CM,momentMeta] = xv15_c81_moment_lookup(alpha,Mach,rMid/R);

        q = 0.5*rho*W.^2;
        dL = q.*chord_m.*CL.*dr;
        dD = q.*chord_m.*CD.*dr;
        dT = dL.*cos(phi)-dD.*sin(phi);
        dH = dD.*cos(phi)+dL.*sin(phi);
        dQ = dH.*rMid;

        % C81 CM uses the conventional positive nose-up sectional moment.
        dMcm = q.*chord_m.^2.*CM.*dr;
        % XQC is positive aft of the elastic axis.  A positive normal force
        % acting aft of the axis produces a nose-down (negative-pitch) moment.
        dNormal = dL.*cos(alpha)+dD.*sin(alpha);
        dMoffset = -dNormal.*xqc_m;
        dMaero = dMcm+dMoffset;

        factor = P.rotor.Nb/P.rotor.nAzimuth;
        ringThrust = factor*sum(dT,1);
        ringTorque = factor*sum(dQ,1);
        ll.T = sum(ringThrust);
        ll.Q = sum(ringTorque);
        ll.flapMomentByAzimuth = sum(dT.*rMid,2);
        ll.beta = betaLocal;
        ll.betaDDot = betaDDotLocal;
        ll.meanAeroTorsionByRadial_Nm = mean(dMaero,1);
        ll.meanCmTorsionByRadial_Nm = mean(dMcm,1);
        ll.meanOffsetTorsionByRadial_Nm = mean(dMoffset,1);
        ll.alphaClampCount = aeroMeta.alphaClampCount+momentMeta.alphaClampCount;
        ll.machClampCount = aeroMeta.machClampCount+momentMeta.machClampCount;
    end
end

function theta_deg = nasa_metal_twist_deg(x)
theta_deg = 289.98*x.^5-892.87*x.^4+987.06*x.^3 ...
    -438.31*x.^2+15.695*x+32.057;
end
