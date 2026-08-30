function results = run_m1_stage2_loaded_pitch(outputDir)
%RUN_M1_STAGE2_LOADED_PITCH M1-D quasi-static loaded-pitch diagnostic.
%
% This analysis-only runner tests whether blade torsional compliance and the
% published XV-15 reference control-system pitch stiffness are large enough,
% and of the right sign, to materially change hover CT/CP. It is not a full
% CAMRAD II elastic-blade reproduction and does not modify production code.
%
% Four cases are compared at OARF Run-15 6--11 deg theta75:
%   RIGID
%   BLADE_GJ_ONLY
%   CONTROL_COMPLIANCE_ONLY
%   COMBINED_GJ_AND_CONTROL
%
% Structural data are independent NASA reference-model inputs. OARF CT/CP
% are comparison outputs only and are never used to choose stiffness,
% pitching moment, relaxation, or any other model parameter.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'results','m1_stage2_loaded_pitch');
end
if ~exist(outputDir,'dir'); mkdir(outputDir); end

P = params_nominal();
Aero = build_xv15_c81_low_order_section_aero();
S = build_xv15_m1d_structural_reference();

R = 3.81;
Nb = 3;
rho = P.env.rho;
aSound = 340.0;
rootCut = 0.0875;
collective75_deg = [6;7;8;9;10;11];
Vtip_fps = [768.4;768.4;768.4;768.0;768.0;767.7];
CT_exp = [0.009208;0.010104;0.011063;0.012035;0.013089;0.013929];
CP_exp = [0.000796;0.000913;0.001044;0.001188;0.001358;0.001523];

caseNames = {'RIGID','BLADE_GJ_ONLY','CONTROL_COMPLIANCE_ONLY', ...
    'COMBINED_GJ_AND_CONTROL'};
useBlade = [false,true,false,true];
useControl = [false,false,true,true];

rows = table();
radialRows = table();
for k = 1:numel(collective75_deg)
    Omega = Vtip_fps(k)*0.3048/R;
    for j = 1:numel(caseNames)
        out = solve_case(collective75_deg(k),Omega,useBlade(j),useControl(j));
        one = table(collective75_deg(k),Vtip_fps(k),string(caseNames{j}), ...
            CT_exp(k),CP_exp(k),out.CT,out.CP,out.FM,out.thetaControl_deg, ...
            out.theta75Loaded_deg,out.maxAbsElasticTwist_deg,out.tipElasticTwist_deg, ...
            out.totalRootTorsion_Nm,out.iterations,out.converged, ...
            'VariableNames',{'collective75_deg','Vtip_fps','caseName','CT_exp','CP_exp', ...
            'CT','CP','FM','thetaControl_deg','theta75Loaded_deg', ...
            'maxAbsElasticTwist_deg','tipElasticTwist_deg','totalRootTorsion_Nm', ...
            'iterations','converged'});
        rows = [rows;one]; %#ok<AGROW>

        rr = table(repmat(collective75_deg(k),numel(out.x),1), ...
            repmat(string(caseNames{j}),numel(out.x),1),out.x(:), ...
            out.thetaRigid_deg(:),out.elasticTwist_deg(:),out.thetaLoaded_deg(:), ...
            out.GJ_Nm2(:),out.XQC(:),out.dTorsionPerLength_N(:), ...
            'VariableNames',{'collective75_deg','caseName','rOverR','thetaRigid_deg', ...
            'elasticTwist_deg','thetaLoaded_deg','GJ_Nm2','XQC', ...
            'aeroTorsionPerLength_N'});
        radialRows = [radialRows;rr]; %#ok<AGROW>
    end
end

metrics = table();
for j = 1:numel(caseNames)
    mask = rows.caseName == string(caseNames{j}) & rows.converged;
    CTm = mean(abs((rows.CT(mask)-rows.CT_exp(mask))./rows.CT_exp(mask)))*100;
    CPm = mean(abs((rows.CP(mask)-rows.CP_exp(mask))./rows.CP_exp(mask)))*100;
    meanShift75 = mean(rows.theta75Loaded_deg(mask)-rows.collective75_deg(mask));
    maxTwist = max(rows.maxAbsElasticTwist_deg(mask));
    one = table(string(caseNames{j}),CTm,CPm,meanShift75,maxTwist,sum(mask), ...
        'VariableNames',{'caseName','CT_MAPE_pct','CP_MAPE_pct', ...
        'meanLoadedTheta75Shift_deg','maxElasticTwist_deg','nConverged'});
    metrics = [metrics;one]; %#ok<AGROW>
end

writetable(rows,fullfile(outputDir,'M1_D_LOADED_PITCH_POINTS.csv'));
writetable(radialRows,fullfile(outputDir,'M1_D_LOADED_PITCH_RADIAL.csv'));
writetable(metrics,fullfile(outputDir,'M1_D_LOADED_PITCH_METRICS.csv'));

metaName = {'model_identity';'scope';'structure_source';'aero_source'; ...
    'oarf_parameter_fit';'production_model_change';'claim_boundary'};
metaValue = {'M1_D_QUASISTATIC_LOADED_PITCH_DIAGNOSTIC'; ...
    'ANALYSIS_ONLY_NOT_FULL_AEROELASTIC_ROTOR';S.source; ...
    'NASA_CAMRADII_C81_REDUCTION_PLUS_REPRESENTATIVE_MACH_CM_REDUCTION'; ...
    'NO';'NO'; ...
    'DIAGNOSTIC_OF_COMPLIANCE_MAGNITUDE_AND_DIRECTION_NOT_XV15_STRUCTURE_VALIDATION'};
metadata = table(metaName,metaValue);
writetable(metadata,fullfile(outputDir,'M1_D_METADATA.csv'));

results = struct();
results.points = rows;
results.radial = radialRows;
results.metrics = metrics;
results.metadata = metadata;
results.allFinite = all(isfinite(rows.CT)) && all(isfinite(rows.CP)) && ...
    all(isfinite(rows.theta75Loaded_deg));
results.allConverged = all(rows.converged);
results.claimBoundary = metaValue{end};
save(fullfile(outputDir,'M1_D_RESULTS.mat'),'results');

    function out = solve_case(theta75,Omega,useBladeFlex,useControlFlex)
        n = 64;
        rEdges = linspace(rootCut*R,R,n+1);
        r = 0.5*(rEdges(1:end-1)+rEdges(2:end));
        dr = diff(rEdges);
        x = r/R;
        dA = pi*(rEdges(2:end).^2-rEdges(1:end-1).^2);
        chord = 14*ones(size(x));
        inb = x <= 0.25;
        chord(inb) = -18.4615*x(inb)+18.6154;
        chord = chord*0.0254;

        twist = interp1(S.rOverR,S.twist_deg,x,'linear','extrap');
        twist75 = interp1(S.rOverR,S.twist_deg,0.75,'linear');
        thetaRigid = theta75 + twist-twist75;
        GJ = interp1(S.rOverR,S.GJ_Nm2,x,'linear','extrap');
        XQC = interp1(S.rOverR,S.XQC,x,'linear','extrap');

        elastic = zeros(size(x));
        ctrl = 0;
        vi = sqrt(max(P.mass.m*P.env.g/2,1)/(2*rho*pi*R^2))*ones(size(x));
        converged = false;
        maxIter = 160;
        relax = 0.25;
        for it = 1:maxIter
            theta = (thetaRigid + elastic + ctrl)*pi/180;
            UT = Omega*r;
            W = hypot(UT,vi);
            phi = atan2(vi,max(UT,1e-9));
            alpha = theta-phi;
            CL = Aero.CLmax*tanh(Aero.liftSlope*(alpha-Aero.alpha0L_rad)/Aero.CLmax);
            CD = Aero.CD0 + Aero.kCD*CL.^2;
            q = 0.5*rho*W.^2;
            dL = q.*chord.*CL.*dr;
            dD = q.*chord.*CD.*dr;
            dTblade = dL.*cos(phi)-dD.*sin(phi);
            dQblade = (dL.*sin(phi)+dD.*cos(phi)).*r;

            % Compact C81 pitching-moment reduction at hover-relevant Mach.
            % Values are independent of OARF targets; they preserve the
            % published order/sign of the four span-region C81 Cm tables.
            cm = hover_cm_reduction(alpha*180/pi,x,W/aSound);
            mCm = q.*chord.^2.*cm;                 % N m per m = N
            mOffset = (dL./dr).*(XQC.*chord);     % N m per m = N
            mAero = mCm + mOffset;

            % Tip-to-root internal torsion resultant.
            Tint = fliplr(cumsum(fliplr(mAero.*dr)));
            newElastic = zeros(size(x));
            if useBladeFlex
                grad = Tint./max(GJ,1); % rad/m
                newElastic = cumtrapz(r,grad)*180/pi;
                newElastic = newElastic-newElastic(1);
            end
            newCtrl = 0;
            if useControlFlex
                rootMoment = sum(mAero.*dr);
                newCtrl = rootMoment/S.Kpl_Nm_per_rad*180/pi;
            end

            viTarget = sqrt(max(Nb*dTblade,0)./(2*rho*dA));
            newVi = (1-relax)*vi + relax*viTarget;
            err = max([max(abs(newVi-vi)./max(1,abs(vi))), ...
                max(abs(newElastic-elastic))/max(1,max(abs(elastic))), ...
                abs(newCtrl-ctrl)/max(1,abs(ctrl))]);
            vi = newVi;
            elastic = (1-relax)*elastic + relax*newElastic;
            ctrl = (1-relax)*ctrl + relax*newCtrl;
            if err < 1e-6
                converged = true;
                break;
            end
        end

        theta = (thetaRigid + elastic + ctrl)*pi/180;
        UT = Omega*r; W = hypot(UT,vi); phi = atan2(vi,max(UT,1e-9));
        alpha = theta-phi;
        CL = Aero.CLmax*tanh(Aero.liftSlope*(alpha-Aero.alpha0L_rad)/Aero.CLmax);
        CD = Aero.CD0 + Aero.kCD*CL.^2;
        q = 0.5*rho*W.^2;
        dL = q.*chord.*CL.*dr; dD = q.*chord.*CD.*dr;
        dTblade = dL.*cos(phi)-dD.*sin(phi);
        dQblade = (dL.*sin(phi)+dD.*cos(phi)).*r;
        T = Nb*sum(dTblade); Q = Nb*sum(dQblade);
        A = pi*R^2; tip = Omega*R;
        CT = T/(rho*A*tip^2); CP = Q*Omega/(rho*A*tip^3);
        if T > 0 && Q > 0
            FM = T^(3/2)/(sqrt(2*rho*A)*Q*Omega);
        else
            FM = NaN;
        end
        cm = hover_cm_reduction(alpha*180/pi,x,W/aSound);
        mAero = q.*chord.^2.*cm + (dL./dr).*(XQC.*chord);

        out = struct(); out.CT=CT; out.CP=CP; out.FM=FM;
        out.thetaControl_deg=ctrl;
        out.theta75Loaded_deg=interp1(x,thetaRigid+elastic+ctrl,0.75,'linear','extrap');
        out.maxAbsElasticTwist_deg=max(abs(elastic));
        out.tipElasticTwist_deg=elastic(end);
        out.totalRootTorsion_Nm=sum(mAero.*dr);
        out.iterations=it; out.converged=converged;
        out.x=x; out.thetaRigid_deg=thetaRigid;
        out.elasticTwist_deg=elastic; out.thetaLoaded_deg=thetaRigid+elastic+ctrl;
        out.GJ_Nm2=GJ; out.XQC=XQC; out.dTorsionPerLength_N=mAero;
    end
end

function cm = hover_cm_reduction(alphaDeg,x,Mach)
%HOVER_CM_REDUCTION Compact representative-Mach reduction of Appendix-A C81 Cm.
% The reduction is deliberately low order and is used only to estimate the
% sign and scale of static torsional loading. No OARF performance target is
% involved. Mild Mach scaling is bounded to avoid extrapolating C81 tables.
alphaGrid = [-4 -2 0 2 4 6 8 10];
cm1 = [-.075 -.075 -.075 -.075 -.075 -.075 -.075 -.075];
cm2 = [-.008 -.008 -.008 -.010 -.010 -.013 -.008 -.011];
cm3 = [-.018 -.019 -.019 -.021 -.021 -.019 -.011 -.006];
cm4 = [-.024 -.022 -.022 -.023 -.022 -.017 -.013 -.064];
cm = zeros(size(x));
for i = 1:numel(x)
    if x(i) < 0.55; tab=cm1;
    elseif x(i) < 0.80; tab=cm2;
    elseif x(i) < 0.95; tab=cm3;
    else; tab=cm4;
    end
    a = min(max(alphaDeg(i),alphaGrid(1)),alphaGrid(end));
    cmi = interp1(alphaGrid,tab,a,'linear');
    machFactor = 1 + 0.10*max(0,min(Mach(i),0.85)-0.5);
    cm(i) = cmi*machFactor;
end
end
