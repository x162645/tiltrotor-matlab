function results = run_m1_geometry_source_fidelity_audit(outputDir)
%RUN_M1_GEOMETRY_SOURCE_FIDELITY_AUDIT Audit public geometry mappings.
%
% Purpose
% -------
% Quantify whether the Stage-1 M1-B hover conclusions depend materially on
% the particular public-source mapping used for XV-15 original-metal-blade
% chord and twist. No variant is selected by OARF error.
%
% Chord variants
% --------------
% CURRENT_RECONSTRUCTION:
%   existing M1 path: 17 in at rootCut=0.0875R linearly to 14 in at 0.25R.
% TEXT_012_TAPER:
%   NASA/TP-2004-212262 narrative geometry: 17 in through 0.12R, tapering
%   to 14 in at 0.25R, then 14 in to the tip.
% TP_APPENDIX_CAMRAD:
%   NASA/TP-2004-212262 Appendix-A CAMRAD reference aerodynamic-property
%   input: RPROP=[0,.1,.2,.3,1], CHORD=[1.32125,1.32125,1.17375,
%   1.16625,1.16625] ft, linearly interpolated.
%
% Twist variants
% --------------
% POLYNOMIAL_CURRENT:
%   existing shared fifth-order public-source fit.
% APPENDIX_TWISTA_DIRECT:
%   direct interpolation of the published 51-point Appendix-A TWISTA table.
%
% The aerodynamic and numerical equations otherwise reproduce M1-B:
% four-region TP C81 + local Mach + global momentum + current Eq.(12)
% first-harmonic inflow + current first-harmonic flapping.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'results','m1_geometry_source_fidelity_audit');
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

chordModes = {'CURRENT_RECONSTRUCTION';'TEXT_012_TAPER';'TP_APPENDIX_CAMRAD'};
twistModes = {'POLYNOMIAL_CURRENT';'APPENDIX_TWISTA_DIRECT'};

Ptemplate = Pbase;
Ptemplate.rotor.R = R;
Ptemplate.rotor.Nb = 3;
Ptemplate.rotor.rootCut = rootCut;
Ptemplate.rotor.Ib = Ptemplate.rotor.bladeMass*R^2/3;
Ptemplate.rotor.Sblade = Ptemplate.rotor.bladeMass*R/2;
if ~isfield(Ptemplate.env,'aSound'), Ptemplate.env.aSound = 340.0; end

% Source-profile audit independent of OARF output.
xProfile = linspace(rootCut,1,201).';
profile = table(xProfile, ...
    chord_source_m(xProfile,'CURRENT_RECONSTRUCTION'), ...
    chord_source_m(xProfile,'TEXT_012_TAPER'), ...
    chord_source_m(xProfile,'TP_APPENDIX_CAMRAD'), ...
    nasa_metal_twist_deg(xProfile), ...
    nasa_metal_twist_reference_table_deg(xProfile), ...
    'VariableNames',{'r_R','chordCurrent_m','chordText012_m','chordTpAppendix_m', ...
    'twistPolynomial_deg','twistAppendixDirect_deg'});
profile.twistDirectMinusPolynomial_deg = ...
    profile.twistAppendixDirect_deg-profile.twistPolynomial_deg;
writetable(profile,fullfile(outputDir,'M1_GEOMETRY_SOURCE_PROFILES.csv'));

rows = table();
for ic = 1:numel(chordModes)
    for itw = 1:numel(twistModes)
        modelName = [chordModes{ic} '__' twistModes{itw}];
        for k = 1:numel(collective75_deg)
            P = Ptemplate;
            Vtip_mps = Vtip_fps(k)*0.3048;
            P.rotor.Omega = Vtip_mps/R;
            out = solve_global(P,collective75_deg(k),chordModes{ic},twistModes{itw});
            A = pi*R^2;
            CT = out.thrust/(P.env.rho*A*Vtip_mps^2);
            CP = out.torque*P.rotor.Omega/(P.env.rho*A*Vtip_mps^3);
            if CT > 0 && CP > 0
                FM = CT^(3/2)/(sqrt(2)*CP);
            else
                FM = NaN;
            end
            one = table({modelName},chordModes(ic),twistModes(itw), ...
                collective75_deg(k),Vtip_fps(k),CT_exp(k),CT, ...
                100*(CT-CT_exp(k))/CT_exp(k),CP_exp(k),CP, ...
                100*(CP-CP_exp(k))/CP_exp(k),FM_exp(k),FM, ...
                100*(FM-FM_exp(k))/FM_exp(k),out.physicalConverged, ...
                out.iterations,out.inducedVelocity_mps,out.alphaClampCount, ...
                out.machClampCount,out.closureResidualRelative, ...
                'VariableNames',{'modelIdentity','chordMode','twistMode', ...
                'collective75_deg','Vtip_fps','CT_exp','CT_model','CT_relativeError_pct', ...
                'CP_exp','CP_model','CP_relativeError_pct','FM_exp','FM_model', ...
                'FM_relativeError_pct','physicalConverged','iterations', ...
                'inducedVelocity_mps','alphaClampCount','machClampCount', ...
                'closureResidualRelative'});
            rows = [rows;one]; %#ok<AGROW>
        end
    end
end
writetable(rows,fullfile(outputDir,'M1_GEOMETRY_SOURCE_FIDELITY_POINTS.csv'));

metrics = table();
modelList = unique(rows.modelIdentity,'stable');
for i = 1:numel(modelList)
    mask = strcmp(rows.modelIdentity,modelList{i}) & rows.physicalConverged;
    if sum(mask) ~= numel(collective75_deg)
        error('run_m1_geometry_source_fidelity_audit:IncompleteVariant', ...
            '%s has only %d physically supported points.',modelList{i},sum(mask));
    end
    one = table(modelList(i),rows.chordMode(find(mask,1)),rows.twistMode(find(mask,1)), ...
        mean(abs(rows.CT_relativeError_pct(mask))), ...
        mean(abs(rows.CP_relativeError_pct(mask))), ...
        mean(abs(rows.FM_relativeError_pct(mask))), ...
        mean(rows.CT_relativeError_pct(mask)), ...
        mean(rows.CP_relativeError_pct(mask)), ...
        mean(rows.FM_relativeError_pct(mask)), ...
        max(rows.alphaClampCount(mask)),max(rows.machClampCount(mask)), ...
        'VariableNames',{'modelIdentity','chordMode','twistMode','CT_MAPE_pct', ...
        'CP_MAPE_pct','FM_MAPE_pct','CT_meanSigned_pct','CP_meanSigned_pct', ...
        'FM_meanSigned_pct','maxAlphaClampCount','maxMachClampCount'});
    metrics = [metrics;one]; %#ok<AGROW>
end

baseName = 'CURRENT_RECONSTRUCTION__POLYNOMIAL_CURRENT';
baseMask = strcmp(metrics.modelIdentity,baseName);
if sum(baseMask) ~= 1
    error('run_m1_geometry_source_fidelity_audit:MissingBase','Current M1-B geometry baseline missing.');
end
metrics.CT_deltaFromCurrent_pp = metrics.CT_MAPE_pct-metrics.CT_MAPE_pct(baseMask);
metrics.CP_deltaFromCurrent_pp = metrics.CP_MAPE_pct-metrics.CP_MAPE_pct(baseMask);
metrics.FM_deltaFromCurrent_pp = metrics.FM_MAPE_pct-metrics.FM_MAPE_pct(baseMask);
writetable(metrics,fullfile(outputDir,'M1_GEOMETRY_SOURCE_FIDELITY_METRICS.csv'));

% Fail closed: copied current/current branch must reproduce canonical M1-B.
canonical = run_xv15_actual_geometry_c81_crosscheck(fullfile(outputDir,'canonical_m1b_recheck'));
ref = canonical.metrics(canonical.metrics.window=="6-11",:);
base = metrics(baseMask,:);
identityDiff_pp = [ ...
    abs(base.CT_MAPE_pct-ref.CT_MAPE_fullC81_global_pct), ...
    abs(base.CP_MAPE_pct-ref.CP_MAPE_fullC81_global_pct), ...
    abs(base.FM_MAPE_pct-ref.FM_MAPE_fullC81_global_pct)];
if any(identityDiff_pp > 1e-6)
    error('run_m1_geometry_source_fidelity_audit:BaselineDrift', ...
        'Copied current geometry branch drifted from canonical M1-B.');
end

metadataName = {'stage';'purpose';'oarf_parameter_fit';'variant_selection_by_error'; ...
    'current_chord_role';'text_chord_role';'tp_chord_role'; ...
    'polynomial_twist_role';'direct_twista_role';'canonical_identity_tolerance_pp'; ...
    'claim_boundary'};
metadataValue = {'M1_GEOMETRY_SOURCE_FIDELITY_AUDIT'; ...
    'PUBLIC_SOURCE_MAPPING_SENSITIVITY_NOT_MODEL_SELECTION';'NO';'NO'; ...
    'SOURCE_INFORMED_RECONSTRUCTION_17IN_AT_0P0875_TO_14IN_AT_0P25'; ...
    'TP_TEXT_17IN_TO_0P12_THEN_TAPER_TO_14IN_AT_0P25'; ...
    'TP_APPENDIX_A_CAMRAD_REFERENCE_AERODYNAMIC_CHORD_INPUT'; ...
    'EXISTING_PUBLIC_SOURCE_POLYNOMIAL_FIT'; ...
    'TP_APPENDIX_A_51_POINT_TWISTA_DIRECT_INTERPOLATION'; ...
    '1e-6'; ...
    'POSTHOC_SOURCE_FIDELITY_SENSITIVITY_NO_OARF_RETUNING'};
metadata = table(metadataName,metadataValue);
writetable(metadata,fullfile(outputDir,'M1_GEOMETRY_SOURCE_FIDELITY_METADATA.csv'));

results = struct();
results.points = rows;
results.metrics = metrics;
results.profile = profile;
results.identityDiff_pp = identityDiff_pp;
results.metadata = metadata;
results.claimBoundary = metadataValue{end};
save(fullfile(outputDir,'M1_GEOMETRY_SOURCE_FIDELITY_RESULTS.mat'),'results');
end

function out = solve_global(P,theta75_deg,chordMode,twistMode)
R=P.rotor.R; Omega=P.rotor.Omega; tipSpeed=Omega*R; rho=P.env.rho; A=pi*R^2;
r0=P.rotor.rootCut*R; rEdges=linspace(r0,R,P.rotor.nRadial+1);
rMid=0.5*(rEdges(1:end-1)+rEdges(2:end)); dr=diff(rEdges);
psi=((0:P.rotor.nAzimuth-1)*(2*pi/P.rotor.nAzimuth)).'; x=rMid/R;
chord_m=chord_source_m(x,chordMode);
if strcmp(twistMode,'POLYNOMIAL_CURRENT')
    thetaSource_deg=nasa_metal_twist_deg(x);
    theta75Source_deg=nasa_metal_twist_deg(0.75);
elseif strcmp(twistMode,'APPENDIX_TWISTA_DIRECT')
    thetaSource_deg=nasa_metal_twist_reference_table_deg(x);
    theta75Source_deg=nasa_metal_twist_reference_table_deg(0.75);
else
    error('run_m1_geometry_source_fidelity_audit:TwistMode','Unknown twist mode.');
end
thetaBlade=(theta75_deg+thetaSource_deg-theta75Source_deg)*pi/180;
UT=Omega*rMid;
vi=sqrt(max(P.mass.m*P.env.g/2,1)/(2*rho*A));
zFlap=P.rotor.flapInitial(:); converged=false; err=Inf;
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
out=struct('thrust',loads.T,'torque',loads.Q,'physicalConverged',physical, ...
    'iterations',iter,'inducedVelocity_mps',vi,'alphaClampCount',loads.alphaClampCount, ...
    'machClampCount',loads.machClampCount,'closureResidualRelative',closure);

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
        ll=blade_loads(viNow,z);
        gravityMoment=-P.rotor.Sblade*P.env.g*cos(ll.beta);
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
        [CL,CD,meta]=xv15_c81_section_lookup(alpha,Mach,rMid/R);
        q=0.5*rho*W.^2; dL=q.*chord_m.*CL.*dr; dD=q.*chord_m.*CD.*dr;
        dT=dL.*cos(phi)-dD.*sin(phi); dH=dD.*cos(phi)+dL.*sin(phi); dQ=dH.*rMid;
        factor=P.rotor.Nb/P.rotor.nAzimuth;
        ll.T=factor*sum(dT(:)); ll.Q=factor*sum(dQ(:));
        ll.flapMomentByAzimuth=sum(dT.*rMid,2); ll.beta=beta; ll.betaDDot=betaDDot;
        ll.alphaClampCount=meta.alphaClampCount; ll.machClampCount=meta.machClampCount;
    end
end

function c = chord_source_m(x,mode)
mode=upper(char(mode)); x=x(:);
switch mode
    case 'CURRENT_RECONSTRUCTION'
        cin=14*ones(size(x)); q=x<=0.25;
        cin(q)=-18.4615*x(q)+18.6154;
        c=cin*0.0254;
    case 'TEXT_012_TAPER'
        cin=14*ones(size(x));
        q0=x<=0.12; cin(q0)=17;
        q1=x>0.12 & x<0.25;
        cin(q1)=17+(14-17)*(x(q1)-0.12)/(0.25-0.12);
        c=cin*0.0254;
    case 'TP_APPENDIX_CAMRAD'
        r=[0;0.1;0.2;0.3;1.0];
        cft=[1.32125;1.32125;1.17375;1.16625;1.16625];
        c=interp1(r,cft,x,'linear')*0.3048;
    otherwise
        error('run_m1_geometry_source_fidelity_audit:ChordMode','Unknown chord mode.');
end
end
