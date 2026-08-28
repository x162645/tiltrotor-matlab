function results = run_xv15_rotational_augmentation_screen(outputDir)
%RUN_XV15_ROTATIONAL_AUGMENTATION_SCREEN
% Screen whether first-order rotational lift augmentation can plausibly close
% the remaining XV-15 hover thrust gap without tuning the validation data.
%
% This is a diagnostic envelope, not a production rotor model.
%
% Baseline physics retained from the preceding validation chain:
%   - PR67 XV-15 metal-blade geometry reduction;
%   - scalar NASA-C81 low-order section fit from PR68;
%   - hover momentum closure;
%   - OARF Run 15 CT/CP/FM used only for external comparison.
%
% The added 3-D rotational effect uses the Snel-type algebraic correction
%
%   CL_3D = CL_2D + g * 3.1*(c/r)^2 * (CL_pot - CL_2D)
%
% where g=1 is the published nominal Snel coefficient and g is varied only
% as a post-hoc sensitivity multiplier. Drag is intentionally kept at the
% original 2-D low-order value so that this screen isolates lift augmentation.
%
% The inverse gain that matches the 10-deg OARF CT is reported only as an
% error-attribution diagnostic. It must NOT be reused as a calibrated model
% parameter or counted as independent validation evidence.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'results','xv15_section_aero_validation');
end
if ~exist(outputDir,'dir')
    mkdir(outputDir);
end

Pbase = params_nominal();
d2r = pi/180;
R = 3.81;
rootCut = 0.0875;
Nb = 3;

collective75_deg = [6;7;8;9;10;11];
Vtip_fps = [768.4;768.4;768.4;768.0;768.0;767.7];
CT_exp = [0.009208;0.010104;0.011063;0.012035;0.013089;0.013929];
CP_exp = [0.000796;0.000913;0.001044;0.001188;0.001358;0.001523];
FM_exp = [0.7849;0.7866;0.7881;0.7858;0.7797;0.7632];

% Same PR67 geometry reduction used in the earlier C81 diagnostics.
xGeom = linspace(rootCut,1,4001).';
chord_in = 14*ones(size(xGeom));
inboard = xGeom <= 0.25;
chord_in(inboard) = -18.4615*xGeom(inboard)+18.6154;
chord_m = chord_in*0.0254;
chordEq_m = trapz(xGeom,chord_m)/(1-rootCut);

thetaSource_deg = nasa_metal_twist_deg(xGeom);
theta75Source_deg = nasa_metal_twist_deg(0.75);
xNorm = (xGeom-rootCut)/(1-rootCut);
x75 = (0.75-rootCut)/(1-rootCut);
shapeCoordinate = xNorm-x75;
shapeTarget = thetaSource_deg-theta75Source_deg;
twistTipEq_deg = trapz(xGeom,shapeCoordinate.*shapeTarget) / ...
    trapz(xGeom,shapeCoordinate.^2);

scalarC81 = build_xv15_c81_low_order_section_aero();

Ptemplate = Pbase;
Ptemplate.rotor.R = R;
Ptemplate.rotor.Nb = Nb;
Ptemplate.rotor.rootCut = rootCut;
Ptemplate.rotor.chord = chordEq_m;
Ptemplate.rotor.twistTip = twistTipEq_deg*d2r;
Ptemplate.rotor.Ib = Ptemplate.rotor.bladeMass*R^2/3;
Ptemplate.rotor.Sblade = Ptemplate.rotor.bladeMass*R/2;

% g=1 is the nominal published Snel strength. Larger values are not model
% recommendations; they are only used to quantify how much extra lift would
% be required to close the measured thrust gap.
gainList = [0;0.5;1;2;5;10;15;20];

pointRows = table();
metricRows = table();
baselineConsistency = table();

for g = gainList.'
    localRows = table();
    for k = 1:numel(collective75_deg)
        P = Ptemplate;
        Vtip_mps = Vtip_fps(k)*0.3048;
        P.rotor.Omega = Vtip_mps/R;
        modelCollective_deg = collective75_deg(k)-twistTipEq_deg*x75;

        ax = axisymmetric_case(modelCollective_deg*d2r,g);

        local = table(g,collective75_deg(k),Vtip_fps(k), ...
            CT_exp(k),ax.CT,CP_exp(k),ax.CP,FM_exp(k),ax.FM, ...
            ax.lambda,ax.alphaMin_deg,ax.alphaMax_deg, ...
            'VariableNames',{'snelGain','collective75_deg','Vtip_fps', ...
            'CT_exp','CT_model','CP_exp','CP_model','FM_exp','FM_model', ...
            'lambdaInduced','alphaMin_deg','alphaMax_deg'});
        localRows = [localRows;local]; %#ok<AGROW>
        pointRows = [pointRows;local]; %#ok<AGROW>

        if g == 0
            out = xv15_hover_bemt_section_diagnostic(P, ...
                modelCollective_deg*d2r,'SCALAR_C81_LOW_ORDER',scalarC81);
            A = pi*R^2;
            CTmirror = out.thrust/(P.env.rho*A*Vtip_mps^2);
            CPmirror = out.torque*P.rotor.Omega/(P.env.rho*A*Vtip_mps^3);
            relCT = abs(ax.CT-CTmirror)/max([abs(ax.CT),abs(CTmirror),eps]);
            relCP = abs(ax.CP-CPmirror)/max([abs(ax.CP),abs(CPmirror),eps]);
            bRow = table(collective75_deg(k),ax.CT,CTmirror,relCT, ...
                ax.CP,CPmirror,relCP,out.physicalConverged, ...
                'VariableNames',{'collective75_deg','axisymCT','mirrorCT', ...
                'relativeCTDifference','axisymCP','mirrorCP', ...
                'relativeCPDifference','mirrorPhysicalConverged'});
            baselineConsistency = [baselineConsistency;bRow]; %#ok<AGROW>
        end
    end

    CT_MAPE_pct = 100*mean(abs(localRows.CT_model-localRows.CT_exp)./localRows.CT_exp);
    CP_MAPE_pct = 100*mean(abs(localRows.CP_model-localRows.CP_exp)./localRows.CP_exp);
    FM_MAPE_pct = 100*mean(abs(localRows.FM_model-localRows.FM_exp)./localRows.FM_exp);
    row10 = localRows(localRows.collective75_deg == 10,:);
    mRow = table(g,CT_MAPE_pct,CP_MAPE_pct,FM_MAPE_pct, ...
        row10.CT_model,row10.CP_model,row10.FM_model, ...
        'VariableNames',{'snelGain','CT_MAPE_pct','CP_MAPE_pct', ...
        'FM_MAPE_pct','CT_10deg','CP_10deg','FM_10deg'});
    metricRows = [metricRows;mRow]; %#ok<AGROW>
end

% Post-hoc inverse diagnostic only: find the gain required to hit the 10-deg
% measured CT. Never feed this number back into a validation parameter set.
targetCT10 = CT_exp(collective75_deg == 10);
modelCollective10_deg = 10-twistTipEq_deg*x75;
lo = 0; hi = 40;
for iter = 1:80
    mid = 0.5*(lo+hi);
    test = axisymmetric_case(modelCollective10_deg*d2r,mid);
    if test.CT < targetCT10
        lo = mid;
    else
        hi = mid;
    end
end
gainToMatchCT10 = 0.5*(lo+hi);
matched10 = axisymmetric_case(modelCollective10_deg*d2r,gainToMatchCT10);

inverseDiagnostic = table(gainToMatchCT10,targetCT10,matched10.CT, ...
    CP_exp(collective75_deg == 10),matched10.CP, ...
    FM_exp(collective75_deg == 10),matched10.FM, ...
    'VariableNames',{'gainToMatchCT10','CT_exp_10deg','CT_model_10deg', ...
    'CP_exp_10deg','CP_model_10deg','FM_exp_10deg','FM_model_10deg'});

writetable(pointRows,fullfile(outputDir, ...
    'XV15_ROTATIONAL_AUGMENTATION_MATLAB_POINTS.csv'));
writetable(metricRows,fullfile(outputDir, ...
    'XV15_ROTATIONAL_AUGMENTATION_MATLAB_METRICS.csv'));
writetable(baselineConsistency,fullfile(outputDir, ...
    'XV15_ROTATIONAL_AUGMENTATION_BASELINE_CONSISTENCY.csv'));
writetable(inverseDiagnostic,fullfile(outputDir, ...
    'XV15_ROTATIONAL_AUGMENTATION_INVERSE_DIAGNOSTIC.csv'));

results = struct();
results.pointTable = pointRows;
results.metricTable = metricRows;
results.baselineConsistency = baselineConsistency;
results.inverseDiagnostic = inverseDiagnostic;
results.chordEq_m = chordEq_m;
results.twistTipEq_deg = twistTipEq_deg;
results.snelNominalGain = 1;
results.claimBoundary = ['ROTATIONAL_AUGMENTATION_SCREEN_ONLY_' ...
    'SNEL_NOMINAL_PLUS_SENSITIVITY_NO_OARF_PARAMETER_FIT'];
save(fullfile(outputDir,'XV15_ROTATIONAL_AUGMENTATION_SCREEN_RESULTS.mat'),'results');

    function out = axisymmetric_case(collectiveRad,snelGain)
        % Reduced pure-hover mirror justified by the preceding Eq.12/flapping
        % cancellation diagnostic. This is used only for the augmentation
        % sensitivity envelope and is checked against the scalar-C81 mirror at
        % snelGain=0.
        n = 4000;
        x = linspace(rootCut,1,n).';
        r = x*R;
        theta = collectiveRad + twistTipEq_deg*d2r*(x-rootCut)/(1-rootCut);

        lambda = 0.06;
        for it = 1:300
            phi = atan2(lambda,x);
            alpha = theta-phi;

            CL2D = scalarC81.CLmax*tanh( ...
                scalarC81.liftSlope*(alpha-scalarC81.alpha0L_rad) / ...
                scalarC81.CLmax);
            CD2D = scalarC81.CD0 + scalarC81.kCD*CL2D.^2;
            CLpot = scalarC81.liftSlope*(alpha-scalarC81.alpha0L_rad);
            fSnel = 3.1*(chordEq_m./r).^2;
            CL = CL2D + snelGain*fSnel.*(CLpot-CL2D);
            CD = CD2D;

            W2 = x.^2 + lambda^2;
            dT = 0.5*W2*(chordEq_m/R).*(CL.*cos(phi)-CD.*sin(phi));
            CT = Nb/pi*trapz(x,dT);
            lambdaTarget = sqrt(max(CT,0)/2);
            if abs(lambdaTarget-lambda) < 1e-12
                lambda = lambdaTarget;
                break;
            end
            lambda = 0.5*(lambda+lambdaTarget);
        end

        phi = atan2(lambda,x);
        alpha = theta-phi;
        CL2D = scalarC81.CLmax*tanh( ...
            scalarC81.liftSlope*(alpha-scalarC81.alpha0L_rad) / ...
            scalarC81.CLmax);
        CD2D = scalarC81.CD0 + scalarC81.kCD*CL2D.^2;
        CLpot = scalarC81.liftSlope*(alpha-scalarC81.alpha0L_rad);
        fSnel = 3.1*(chordEq_m./r).^2;
        CL = CL2D + snelGain*fSnel.*(CLpot-CL2D);
        CD = CD2D;
        W2 = x.^2 + lambda^2;
        dT = 0.5*W2*(chordEq_m/R).*(CL.*cos(phi)-CD.*sin(phi));
        dH = 0.5*W2*(chordEq_m/R).*(CD.*cos(phi)+CL.*sin(phi));
        CT = Nb/pi*trapz(x,dT);
        CP = Nb/pi*trapz(x,dH.*x);
        FM = CT^(3/2)/(sqrt(2)*CP);

        out = struct('CT',CT,'CP',CP,'FM',FM,'lambda',lambda, ...
            'alphaMin_deg',min(alpha)*180/pi, ...
            'alphaMax_deg',max(alpha)*180/pi, ...
            'maxSnelFactor',max(fSnel));
    end
end

function theta_deg = nasa_metal_twist_deg(x)
theta_deg = 289.98*x.^5-892.87*x.^4+987.06*x.^3 ...
    -438.31*x.^2+15.695*x+32.057;
end
