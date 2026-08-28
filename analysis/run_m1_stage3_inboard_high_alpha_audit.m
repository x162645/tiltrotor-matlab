function results = run_m1_stage3_inboard_high_alpha_audit(outputDir)
%RUN_M1_STAGE3_INBOARD_HIGH_ALPHA_AUDIT
% Source-driven diagnostic for the Felker (NASA/TM-104023) mechanism.
%
% This runner DOES NOT modify the M1-B aerodynamics. It reproduces the
% actual-geometry + spanwise-C81 + global-momentum solution and records the
% local blade-section operating states.  The question is whether the
% remaining M1-B error occurs in the regime identified by Felker (1993):
% high sectional angle of attack on inboard tiltrotor blade stations, where
% limiting lift to the 2-D airfoil-table maximum produced conservative
% hover-performance predictions.
%
% OARF CT/CP/FM are attached only for point-level error context. No local
% aerodynamic parameter is inferred from those targets.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'results','m1_stage3_inboard_high_alpha_audit');
end
if ~exist(outputDir,'dir'), mkdir(outputDir); end

Pbase = params_nominal();
R = 3.81;
rootCut = 0.0875;
collective75_deg = [6;7;8;9;10;11];
Vtip_fps = [768.4;768.4;768.4;768.0;768.0;767.7];
CT_exp = [0.009208;0.010104;0.011063;0.012035;0.013089;0.013929];
CP_exp = [0.000796;0.000913;0.001044;0.001188;0.001358;0.001523];

Ptemplate = Pbase;
Ptemplate.rotor.R = R;
Ptemplate.rotor.Nb = 3;
Ptemplate.rotor.rootCut = rootCut;
Ptemplate.rotor.Ib = Ptemplate.rotor.bladeMass*R^2/3;
Ptemplate.rotor.Sblade = Ptemplate.rotor.bladeMass*R/2;
if ~isfield(Ptemplate.env,'aSound'), Ptemplate.env.aSound = 340.0; end

radialRows = table();
pointRows = table();
for k = 1:numel(collective75_deg)
    P = Ptemplate;
    Vtip_mps = Vtip_fps(k)*0.3048;
    P.rotor.Omega = Vtip_mps/R;
    out = solve_m1b_with_section_audit(P,collective75_deg(k));
    if ~out.physicalConverged
        error('run_m1_stage3_inboard_high_alpha_audit:UnsupportedPoint', ...
            'M1-B audit point %.3g deg did not physically converge.',collective75_deg(k));
    end

    A = pi*R^2;
    CT = out.thrust/(P.env.rho*A*Vtip_mps^2);
    CP = out.torque*P.rotor.Omega/(P.env.rho*A*Vtip_mps^3);
    ctErr = 100*(CT-CT_exp(k))/CT_exp(k);
    cpErr = 100*(CP-CP_exp(k))/CP_exp(k);

    nR = numel(out.rR);
    pointId = repmat(k,nR,1);
    coll = repmat(collective75_deg(k),nR,1);
    radial = table(pointId,coll,out.rR(:),out.chord_m(:), ...
        out.alphaMean_deg(:),out.alphaMin_deg(:),out.alphaMax_deg(:), ...
        out.MachMean(:),out.CLMean(:),out.CDMean(:), ...
        out.CL2DMax(:),out.alphaAtCL2DMax_deg(:),out.CLUtilization(:), ...
        out.alphaMarginTo2DPeak_deg(:),out.post2DPeak(:),out.near2DPeak(:), ...
        out.ringThrustFraction(:),out.ringTorqueFraction(:), ...
        repmat(CT,nR,1),repmat(CP,nR,1),repmat(ctErr,nR,1),repmat(cpErr,nR,1), ...
        'VariableNames',{'pointId','collective75_deg','rR','chord_m', ...
        'alphaMean_deg','alphaMin_deg','alphaMax_deg','MachMean','CLMean','CDMean', ...
        'CL2DMax','alphaAtCL2DMax_deg','CLUtilization', ...
        'alphaMarginTo2DPeak_deg','post2DPeak','near2DPeak', ...
        'ringThrustFraction','ringTorqueFraction','CT_model','CP_model', ...
        'CT_relativeError_pct','CP_relativeError_pct'});
    radialRows = [radialRows;radial]; %#ok<AGROW>

    inboard = out.rR < 0.55;
    post = out.post2DPeak;
    near = out.near2DPeak;
    highAlphaInboard = inboard & (post | near);
    one = table(collective75_deg(k),Vtip_fps(k),CT_exp(k),CT,ctErr, ...
        CP_exp(k),CP,cpErr,out.inducedVelocity_mps, ...
        max(out.alphaMean_deg(inboard)), ...
        sum(inboard),sum(inboard & post),sum(inboard & near), ...
        sum(out.ringThrustFraction(inboard)), ...
        sum(out.ringThrustFraction(highAlphaInboard)), ...
        sum(out.ringTorqueFraction(inboard)), ...
        sum(out.ringTorqueFraction(highAlphaInboard)), ...
        max(out.CLUtilization(inboard)), ...
        min(out.alphaMarginTo2DPeak_deg(inboard)), ...
        out.alphaClampCount,out.machClampCount, ...
        'VariableNames',{'collective75_deg','Vtip_fps','CT_exp','CT_model', ...
        'CT_relativeError_pct','CP_exp','CP_model','CP_relativeError_pct', ...
        'inducedVelocity_mps','maxInboardAlphaMean_deg','inboardStationCount', ...
        'inboardPost2DPeakCount','inboardNear2DPeakCount', ...
        'inboardThrustFraction','highAlphaInboardThrustFraction', ...
        'inboardTorqueFraction','highAlphaInboardTorqueFraction', ...
        'maxInboardCLUtilization','minInboardAlphaMarginTo2DPeak_deg', ...
        'alphaClampCount','machClampCount'});
    pointRows = [pointRows;one]; %#ok<AGROW>
end

writetable(radialRows,fullfile(outputDir,'M1_STAGE3_INBOARD_HIGH_ALPHA_RADIAL.csv'));
writetable(pointRows,fullfile(outputDir,'M1_STAGE3_INBOARD_HIGH_ALPHA_POINTS.csv'));

summaryName = { ...
    'model_identity';'source_hypothesis';'aerodynamic_model_modified'; ...
    'report_window';'dataset_role';'parameter_fit_to_OARF_targets'; ...
    'inboard_definition';'post_2D_peak_definition';'near_2D_peak_definition'};
summaryValue = { ...
    'M1_B_SECTION_STATE_AUDIT'; ...
    'NASA_TM_104023_FELKER_1993_INBOARD_HIGH_ALPHA_EFFECT'; ...
    'NO';'6_TO_11_DEG';'DEVELOPMENT_EXTERNAL_CORRELATION';'NO'; ...
    'r_R_LT_0p55_MATCHES_C81_REGION1_BOUNDARY'; ...
    'MEAN_ALPHA_GE_ALPHA_OF_LOCAL_C81_CL_MAX'; ...
    'MEAN_ALPHA_WITHIN_2_DEG_BELOW_LOCAL_C81_CL_MAX'};
writetable(table(summaryName,summaryValue), ...
    fullfile(outputDir,'M1_STAGE3_INBOARD_HIGH_ALPHA_METADATA.csv'));

results = struct();
results.radial = radialRows;
results.points = pointRows;
results.claimBoundary = [ ...
    'M1_B_LOCAL_STATE_AUDIT_NO_AERO_CHANGE_NO_OARF_FIT_' ...
    'TEST_FELKER_1993_HIGH_ALPHA_INBOARD_HYPOTHESIS'];
save(fullfile(outputDir,'M1_STAGE3_INBOARD_HIGH_ALPHA_RESULTS.mat'),'results');
end

function out = solve_m1b_with_section_audit(P,theta75_deg)
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

vi = sqrt(max(P.mass.m*P.env.g/2,1)/(2*rho*A));
zFlap = P.rotor.flapInitial(:);
converged = false;
for iter = 1:P.rotor.inducedMaxIter
    [zFlap,flapInfo] = solve_flap(vi,zFlap);
    if ~flapInfo.converged, break; end
    loads = blade_loads(vi,zFlap);
    lambda1 = -vi/max(tipSpeed,eps);
    CTiter = max(loads.T,0)/(0.5*rho*A*tipSpeed^2);
    viTarget = tipSpeed*CTiter/(4*max(abs(lambda1),1e-12));
    viNew = 0.5*(vi+viTarget);
    err = abs(viNew-vi)/max(1,abs(vi));
    vi = viNew;
    if err < P.rotor.inducedTol && flapInfo.residualNorm <= P.rotor.flapResidualTol
        converged = true;
        break;
    end
end
loads = blade_loads(vi,zFlap);
lambda1 = -vi/max(tipSpeed,eps);
momentumThrust = 2*rho*A*tipSpeed*vi*abs(lambda1);
closure = abs(loads.T-momentumThrust)/max([abs(loads.T),abs(momentumThrust),1]);
physical = converged && flapInfo.converged && loads.T > 0 && closure <= 2e-4;

% Determine the local 2-D C81 maximum at the point's local mean Mach using
% the same lookup, without changing the solved operating state.
alphaGrid_deg = (-10:0.1:30).';
CL2DMax = NaN(size(x));
alphaAtMax = NaN(size(x));
for ir = 1:numel(x)
    aq = alphaGrid_deg*pi/180;
    mq = loads.MachMean(ir)+zeros(size(aq));
    rq = x(ir)+zeros(size(aq));
    [clSweep,~,~] = xv15_c81_section_lookup(aq,mq,rq);
    [CL2DMax(ir),idx] = max(clSweep);
    alphaAtMax(ir) = alphaGrid_deg(idx);
end
alphaMean_deg = loads.alphaMean*180/pi;
alphaMargin = alphaAtMax-alphaMean_deg;
post2DPeak = alphaMean_deg >= alphaAtMax;
near2DPeak = ~post2DPeak & alphaMargin <= 2.0;

out = struct();
out.thrust = loads.T;
out.torque = loads.Q;
out.physicalConverged = physical;
out.inducedVelocity_mps = vi;
out.rR = x(:);
out.chord_m = chord_m(:);
out.alphaMean_deg = alphaMean_deg(:);
out.alphaMin_deg = loads.alphaMin(:)*180/pi;
out.alphaMax_deg = loads.alphaMax(:)*180/pi;
out.MachMean = loads.MachMean(:);
out.CLMean = loads.CLMean(:);
out.CDMean = loads.CDMean(:);
out.CL2DMax = CL2DMax(:);
out.alphaAtCL2DMax_deg = alphaAtMax(:);
out.CLUtilization = loads.CLMean(:)./CL2DMax(:);
out.alphaMarginTo2DPeak_deg = alphaMargin(:);
out.post2DPeak = post2DPeak(:);
out.near2DPeak = near2DPeak(:);
out.ringThrustFraction = loads.ringThrust(:)/loads.T;
out.ringTorqueFraction = loads.ringTorque(:)/loads.Q;
out.alphaClampCount = loads.alphaClampCount;
out.machClampCount = loads.machClampCount;

    function [z,info] = solve_flap(viNow,z0)
        z = z0(:);
        info = struct('converged',false,'iterations',0,'residualNorm',Inf);
        for kk = 1:P.rotor.flapMaxIter
            [res,scale] = flap_residual(z,viNow);
            rn = res/scale;
            if norm(rn) <= P.rotor.flapResidualTol
                info.converged = true; info.iterations = kk; info.residualNorm = norm(rn); return;
            end
            J = zeros(3,3);
            for jj = 1:3
                h = P.rotor.flapJacobianStep*max(1,abs(z(jj)));
                zp = z; zm = z; zp(jj)=zp(jj)+h; zm(jj)=zm(jj)-h;
                [rp,~]=flap_residual(zp,viNow); [rm,~]=flap_residual(zm,viNow);
                J(:,jj)=(rp-rm)/(2*h*scale);
            end
            if ~all(isfinite(J(:))) || rcond(J.'*J)<1e-14, return; end
            reg=P.rotor.flapNewtonRegularization;
            dz=-(J.'*J+reg*eye(3))\(J.'*rn);
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

    function [res,scale] = flap_residual(z,viNow)
        ll=blade_loads(viNow,z);
        gravityMoment=-P.rotor.Sblade*P.env.g*cos(ll.beta);
        inertialRestoring=P.rotor.Ib*ll.betaDDot+P.rotor.Ib*Omega^2*ll.beta;
        byAz=inertialRestoring-ll.flapMomentByAzimuth-gravityMoment;
        res=[mean(byAz);2*mean(byAz.*cos(psi));2*mean(byAz.*sin(psi))];
        scale=max([max(abs(ll.flapMomentByAzimuth)),max(abs(gravityMoment)),P.rotor.Ib*Omega^2*0.05,1]);
    end

    function ll = blade_loads(viNow,z)
        betaLocal=z(1)+z(2)*cos(psi)+z(3)*sin(psi);
        betaDotLocal=-Omega*(-z(2)*sin(psi)+z(3)*cos(psi));
        betaDDotLocal=-Omega^2*(z(2)*cos(psi)+z(3)*sin(psi));
        viField=viNow.*(1+cos(psi).*(rMid/R));
        UP=viField-betaDotLocal.*rMid;
        W=hypot(UT,UP);
        phi=atan2(UP,max(abs(UT),1e-8));
        alpha=thetaBlade-phi;
        Mach=W/P.env.aSound;
        [CL,CD,meta]=xv15_c81_section_lookup(alpha,Mach,rMid/R);
        q=0.5*rho*W.^2;
        dL=q.*chord_m.*CL.*dr;
        dD=q.*chord_m.*CD.*dr;
        dT=dL.*cos(phi)-dD.*sin(phi);
        dH=dD.*cos(phi)+dL.*sin(phi);
        dQ=dH.*rMid;
        factor=P.rotor.Nb/P.rotor.nAzimuth;
        ll.ringThrust=factor*sum(dT,1);
        ll.ringTorque=factor*sum(dQ,1);
        ll.T=sum(ll.ringThrust); ll.Q=sum(ll.ringTorque);
        ll.flapMomentByAzimuth=sum(dT.*rMid,2);
        ll.beta=betaLocal; ll.betaDDot=betaDDotLocal;
        ll.alphaMean=mean(alpha,1); ll.alphaMin=min(alpha,[],1); ll.alphaMax=max(alpha,[],1);
        ll.MachMean=mean(Mach,1); ll.CLMean=mean(CL,1); ll.CDMean=mean(CD,1);
        ll.alphaClampCount=meta.alphaClampCount; ll.machClampCount=meta.machClampCount;
    end
end

function theta_deg = nasa_metal_twist_deg(x)
theta_deg=289.98*x.^5-892.87*x.^4+987.06*x.^3-438.31*x.^2+15.695*x+32.057;
end
