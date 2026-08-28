function results = run_m1_stage3_corrigan_stall_delay(outputDir)
%RUN_M1_STAGE3_CORRIGAN_STALL_DELAY M1-E rotational stall-delay experiment.
%
% Compare three PREDECLARED variants on the same M1-B hover equations:
%   1) OFF                   - exact M1-B C81 baseline;
%   2) CORRIGAN_GENERIC_N1   - generic first-order Corrigan variant;
%   3) KONING_XV15_N1P8      - published XV-15/OARF-correlated n=1.8 variant.
%
% The two exponents are evidence roles, not a sweep.  This runner never
% searches n, collective offset, CT gain, CP gain, or any target-based
% parameter.  The n=1.8 branch must not be used as independent validation
% evidence because its source paper selected it in XV-15 correlation work.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'results','m1_stage3_corrigan_stall_delay');
end
if ~exist(outputDir,'dir'), mkdir(outputDir); end

Pbase = params_nominal();
R = 3.81;
rootCut = 0.0875;
collective75_deg = [6;7;8;9;10;11];
Vtip_fps = [768.4;768.4;768.4;768.0;768.0;767.7];
CT_exp = [0.009208;0.010104;0.011063;0.012035;0.013089;0.013929];
CP_exp = [0.000796;0.000913;0.001044;0.001188;0.001358;0.001523];
FM_exp = [0.7849;0.7866;0.7881;0.7858;0.7797;0.7632];

modes = {'OFF';'CORRIGAN_GENERIC_N1';'KONING_XV15_N1P8'};
role = {'M1_B_RIGID_REFERENCE';'M1_E_GENERIC_LITERATURE_VARIANT'; ...
    'M1_E_PUBLISHED_XV15_CORRELATION_REPLICATION'};
independence = {'BASELINE';'NOT_SELECTED_FROM_CURRENT_OARF_TARGETS'; ...
    'NONINDEPENDENT_XV15_OARF_CORRELATED_VARIANT'};

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
        out = solve_hover(P,collective75_deg(k),modes{im});
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
            out.physicalConverged,out.iterations,out.inducedVelocity_mps, ...
            out.KLMinApplied,out.KLMaxApplied,out.stallDelayApplyCount, ...
            out.alphaClampCount,out.machClampCount, ...
            out.inducedClosureResidualRelative, ...
            'VariableNames',{'mode','role','independence','collective75_deg', ...
            'Vtip_fps','CT_exp','CT_model','CT_relativeError_pct','CP_exp', ...
            'CP_model','CP_relativeError_pct','FM_exp','FM_model', ...
            'FM_relativeError_pct','physicalConverged','iterations', ...
            'inducedVelocity_mps','KLMinApplied','KLMaxApplied', ...
            'stallDelayApplyCount','alphaClampCount','machClampCount', ...
            'inducedClosureResidualRelative'});
        rows = [rows;one]; %#ok<AGROW>
    end
end
writetable(rows,fullfile(outputDir,'M1_STAGE3_CORRIGAN_POINTS.csv'));

metrics = table();
for im = 1:numel(modes)
    mask = strcmp(rows.mode,modes{im}) & rows.physicalConverged;
    if sum(mask) ~= numel(collective75_deg)
        error('run_m1_stage3_corrigan_stall_delay:IncompleteVariant', ...
            '%s has only %d supported points.',modes{im},sum(mask));
    end
    one = table(modes(im),role(im),independence(im),sum(mask), ...
        mean(abs(rows.CT_relativeError_pct(mask))), ...
        mean(abs(rows.CP_relativeError_pct(mask))), ...
        mean(abs(rows.FM_relativeError_pct(mask))), ...
        mean(rows.CT_relativeError_pct(mask)), ...
        mean(rows.CP_relativeError_pct(mask)), ...
        mean(rows.FM_relativeError_pct(mask)), ...
        min(rows.KLMinApplied(mask)),max(rows.KLMaxApplied(mask)), ...
        'VariableNames',{'mode','role','independence','supportedPointCount', ...
        'CT_MAPE_pct','CP_MAPE_pct','FM_MAPE_pct','CT_meanSigned_pct', ...
        'CP_meanSigned_pct','FM_meanSigned_pct','KLMin','KLMax'});
    metrics = [metrics;one]; %#ok<AGROW>
end
metrics.CT_deltaFromM1B_pp = metrics.CT_MAPE_pct-metrics.CT_MAPE_pct(1);
metrics.CP_deltaFromM1B_pp = metrics.CP_MAPE_pct-metrics.CP_MAPE_pct(1);
metrics.FM_deltaFromM1B_pp = metrics.FM_MAPE_pct-metrics.FM_MAPE_pct(1);
writetable(metrics,fullfile(outputDir,'M1_STAGE3_CORRIGAN_METRICS.csv'));

% Re-run canonical M1-B diagnostic and require exact metric-level identity.
stage1 = run_xv15_actual_geometry_c81_crosscheck(fullfile(outputDir,'m1b_recheck'));
ref = stage1.metrics(stage1.metrics.window == "6-11",:);
consistency = [ ...
    abs(metrics.CT_MAPE_pct(1)-ref.CT_MAPE_fullC81_global_pct), ...
    abs(metrics.CP_MAPE_pct(1)-ref.CP_MAPE_fullC81_global_pct), ...
    abs(metrics.FM_MAPE_pct(1)-ref.FM_MAPE_fullC81_global_pct)];
if any(consistency > 1e-6)
    error('run_m1_stage3_corrigan_stall_delay:M1BBaselineDrift', ...
        'M1-B copied baseline drifted from stage-1 reference.');
end

metadataName = { ...
    'model_identity';'base_model';'report_window';'dataset_role'; ...
    'variant_set_frozen_before_execution';'numeric_parameter_search'; ...
    'generic_n1_source_role';'n1p8_source_role'; ...
    'drag_correction_0_to_30_deg';'parameter_fit_to_current_OARF_targets'; ...
    'selection_rule_after_execution'};
metadataValue = { ...
    'M1_E_CORRIGAN_ROTATIONAL_STALL_DELAY'; ...
    'M1_B_ACTUAL_GEOMETRY_SPANWISE_C81_GLOBAL_MOMENTUM'; ...
    'FIXED_6_TO_11_DEG';'DEVELOPMENT_EXTERNAL_CORRELATION'; ...
    'YES_OFF_N1_N1P8_ONLY';'NO'; ...
    'GENERAL_LITERATURE_FIRST_ORDER_NOT_CURRENT_OARF_SELECTED'; ...
    'NASA_CR_2016_219086_XV15_PUBLISHED_OARF_CORRELATED'; ...
    'NONE_KEEP_C81_CD';'NO'; ...
    'REPORT_ALL_VARIANTS_DO_NOT_PICK_WINNER_FROM_RUN15_MAPE'};
writetable(table(metadataName,metadataValue), ...
    fullfile(outputDir,'M1_STAGE3_CORRIGAN_METADATA.csv'));

results = struct();
results.points = rows;
results.metrics = metrics;
results.m1bConsistency_pp = consistency;
results.claimBoundary = [ ...
    'PREDECLARED_DISCRETE_CORRIGAN_VARIANTS_NO_CURRENT_OARF_PARAMETER_SEARCH_' ...
    'N1P8_EXPLICITLY_NONINDEPENDENT'];
save(fullfile(outputDir,'M1_STAGE3_CORRIGAN_RESULTS.mat'),'results');
end

function out = solve_hover(P,theta75_deg,mode)
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
out = struct('thrust',loads.T,'torque',loads.Q,'physicalConverged',physical, ...
    'iterations',iter,'inducedVelocity_mps',vi, ...
    'KLMinApplied',loads.KLMinApplied,'KLMaxApplied',loads.KLMaxApplied, ...
    'stallDelayApplyCount',loads.applyCount,'alphaClampCount',loads.alphaClampCount, ...
    'machClampCount',loads.machClampCount, ...
    'inducedClosureResidualRelative',closure);

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
                zc=z+step*dz; betaCheck=zc(1)+zc(2)*cos(psi)+zc(3)*sin(psi);
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
        viField=viNow.*(1+cos(psi).*(rMid/R));
        UP=viField-betaDotLocal.*rMid;
        W=hypot(UT,UP); phi=atan2(UP,max(abs(UT),1e-8));
        alpha=thetaBlade-phi; Mach=W/P.env.aSound;
        chordField=ones(size(alpha)).*chord_m;
        rField=ones(size(alpha)).*x;
        [CL,CD,meta]=xv15_c81_corrigan_stall_delay(alpha,Mach,rField,chordField,R,mode);
        q=0.5*rho*W.^2; dL=q.*chord_m.*CL.*dr; dD=q.*chord_m.*CD.*dr;
        dT=dL.*cos(phi)-dD.*sin(phi); dH=dD.*cos(phi)+dL.*sin(phi); dQ=dH.*rMid;
        factor=P.rotor.Nb/P.rotor.nAzimuth;
        ringT=factor*sum(dT,1); ringQ=factor*sum(dQ,1);
        ll.T=sum(ringT); ll.Q=sum(ringQ); ll.flapMomentByAzimuth=sum(dT.*rMid,2);
        ll.beta=betaLocal; ll.betaDDot=betaDDotLocal;
        ll.alphaClampCount=meta.alphaClampCount; ll.machClampCount=meta.machClampCount;
        ll.applyCount=meta.applyCount;
        ll.KLMinApplied=meta.KLMinApplied; ll.KLMaxApplied=meta.KLMaxApplied;
        if strcmp(mode,'OFF'), ll.KLMinApplied=1; ll.KLMaxApplied=1; end
    end
end

function theta_deg=nasa_metal_twist_deg(x)
theta_deg=289.98*x.^5-892.87*x.^4+987.06*x.^3-438.31*x.^2+15.695*x+32.057;
end
