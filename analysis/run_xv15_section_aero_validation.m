function results = run_xv15_section_aero_validation(outputDir)
%RUN_XV15_SECTION_AERO_VALIDATION Independent section-aero validation update.
%
% This runner extends the PR67 XV-15 original-metal-blade hover comparison
% without fitting to OARF CT/CP. The scalar zero-lift angle is reduced from
% the published XV-15 NACA 64-series section distribution and the NACA
% design-lift-coefficient nomenclature. A second opt-in variant applies one
% bounded Prandtl-Glauert-equivalent lift-slope factor at 0.75R.
%
% Important claim boundary:
% - alpha0L_eq is a LOW-ORDER DERIVED EQUIVALENT, not a NASA-reported scalar;
% - no OARF CT/CP/FM value is used to identify alpha0L or the PG factor;
% - the PR67 +7.70 deg post-validation shift is NOT used here;
% - the unchanged production rotor_model_bemt remains the baseline.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir, 'results', 'xv15_section_aero_validation');
end
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

Pbase = params_nominal();
d2r = pi/180;
R = 3.81;
rootCut = 0.0875;

%% OARF Run 15 original-metal-blade hover data
collective75_deg = [0; 2; 4; 6; 7; 8; 9; 10; 11];
Vtip_fps = [769.0; 768.7; 768.4; 768.4; 768.4; 768.4; 768.0; 768.0; 767.7];
CT_exp = [0.004063; 0.005581; 0.007391; 0.009208; 0.010104; ...
          0.011063; 0.012035; 0.013089; 0.013929];
CP_exp = [0.000315; 0.000426; 0.000588; 0.000796; 0.000913; ...
          0.001044; 0.001188; 0.001358; 0.001523];
FM_exp = [0.5814; 0.6921; 0.7641; 0.7849; 0.7866; ...
          0.7881; 0.7858; 0.7797; 0.7632];

%% Same low-order geometry mapping frozen in PR67
xGeom = linspace(rootCut, 1, 4001).';
chord_in = 14*ones(size(xGeom));
inboard = xGeom <= 0.25;
chord_in(inboard) = -18.4615*xGeom(inboard) + 18.6154;
chord_m = chord_in*0.0254;
chordEq_m = trapz(xGeom, chord_m)/(1-rootCut);

thetaSource_deg = nasa_metal_twist_deg(xGeom);
theta75Source_deg = nasa_metal_twist_deg(0.75);
xNorm = (xGeom-rootCut)/(1-rootCut);
x75 = (0.75-rootCut)/(1-rootCut);
shapeCoordinate = xNorm-x75;
shapeTarget = thetaSource_deg-theta75Source_deg;
twistTipEq_deg = trapz(xGeom, shapeCoordinate.*shapeTarget) / ...
    trapz(xGeom, shapeCoordinate.^2);

%% Independent NACA 64-series section-aero reduction
% Published XV-15 original-metal-blade section stations:
%   0.09R NACA 64-935
%   0.17R NACA 64-528
%   0.51R NACA 64-118
%   0.80R NACA 64-(1.5)12
%   1.00R NACA 64-208
%
% In NACA 6-series nomenclature, the design lift coefficient is represented
% by the design-Cl digit/parenthesized value. This gives the independent
% design-Cl anchors below. We do NOT equate design Cl with measured Cl at
% alpha=0; instead, for a deliberately low-order linear reduction we use
% alpha0L(r) ~= -Cl_design(r)/a0 with the generic baseline lift slope a0.
airfoil_rR = [0.09; 0.17; 0.51; 0.80; 1.00];
airfoil_name = {'NACA 64-935'; 'NACA 64-528'; 'NACA 64-118'; ...
    'NACA 64-(1.5)12'; 'NACA 64-208'};
designCl = [0.90; 0.50; 0.10; 0.15; 0.20];
alpha0_station_rad = -designCl/Pbase.rotor.liftSlope;
alpha0_station_deg = alpha0_station_rad/d2r;

% Hover elemental lift sensitivity scales approximately with q*c*dr and
% q~(Omega*r)^2, so c(r)*(r/R)^2 is used as a transparent reduction weight.
designClField = interp1(airfoil_rR, designCl, xGeom, 'linear', 'extrap');
alpha0Field_rad = -designClField/Pbase.rotor.liftSlope;
weight = chord_m.*xGeom.^2;
alpha0Eq_rad = trapz(xGeom, alpha0Field_rad.*weight)/trapz(xGeom, weight);
alpha0Eq_deg = alpha0Eq_rad/d2r;

sourceTable = table(airfoil_rR, airfoil_name, designCl, ...
    alpha0_station_deg, ...
    'VariableNames', {'r_over_R','airfoil','design_Cl', ...
    'low_order_alpha0L_from_designCl_deg'});
writetable(sourceTable, fullfile(outputDir, 'XV15_NACA_ALPHA0_REDUCTION_INPUT.csv'));

%% Validation variants
variantName = {'BASELINE'; 'NACA_ALPHA0_EQ'; 'NACA_ALPHA0_EQ_PG075'};
variantAlpha0 = [0; alpha0Eq_rad; alpha0Eq_rad];
variantCompressibility = [false; false; true];

Ptemplate = Pbase;
Ptemplate.rotor.R = R;
Ptemplate.rotor.Nb = 3;
Ptemplate.rotor.rootCut = rootCut;
Ptemplate.rotor.chord = chordEq_m;
Ptemplate.rotor.twistTip = twistTipEq_deg*d2r;
Ptemplate.rotor.Ib = Ptemplate.rotor.bladeMass*R^2/3;
Ptemplate.rotor.Sblade = Ptemplate.rotor.bladeMass*R/2;
Ptemplate.env.aSound = 340.0;
Ptemplate.rotor.compressibilityReferenceRadius = 0.75;
Ptemplate.rotor.compressibilityMachCap = 0.75;

rows = table();
for v = 1:numel(variantName)
    for k = 1:numel(collective75_deg)
        P = Ptemplate;
        Vtip_mps = Vtip_fps(k)*0.3048;
        P.rotor.Omega = Vtip_mps/R;
        P.rotor.alpha0L = variantAlpha0(v);
        P.rotor.enableCompressibilityCorrection = variantCompressibility(v);

        modelCollective_deg = collective75_deg(k)-twistTipEq_deg*x75;
        ctrl = struct('collective', modelCollective_deg*d2r, 'cyclicLong', 0);

        returned = false;
        physicalConverged = false;
        physicalStatus = 'NOT_RUN';
        CT_model = NaN;
        CP_model = NaN;
        FM_model = NaN;
        inducedVelocity_mps = NaN;
        iterations = NaN;
        closureResidualRelative = NaN;
        referenceMach = NaN;
        liftSlopeFactor = NaN;
        errorIdentifier = '';

        try
            [~, ~, out] = rotor_model_bemt_section_aero( ...
                zeros(9,1), ctrl, 0, -1, zeros(3,1), P);
            returned = true;
            physicalConverged = out.physicalConverged;
            physicalStatus = out.physicalStatus;
            inducedVelocity_mps = out.inducedVelocity;
            iterations = out.iterations;
            closureResidualRelative = out.inducedClosureResidualRelative;
            referenceMach = out.compressibilityReferenceMachUsed;
            liftSlopeFactor = out.sectionLiftSlopeFactor;

            A = pi*R^2;
            CT_model = out.thrust/(P.env.rho*A*Vtip_mps^2);
            CP_model = out.torque*P.rotor.Omega/(P.env.rho*A*Vtip_mps^3);
            if CT_model > 0 && CP_model > 0
                FM_model = CT_model^(3/2)/(sqrt(2)*CP_model);
            end
        catch ME
            physicalStatus = ME.identifier;
            errorIdentifier = ME.identifier;
        end

        local = table(variantName(v), collective75_deg(k), Vtip_fps(k), ...
            P.rotor.Omega*60/(2*pi), modelCollective_deg, ...
            variantAlpha0(v)/d2r, variantCompressibility(v), ...
            referenceMach, liftSlopeFactor, CT_exp(k), CT_model, ...
            CP_exp(k), CP_model, FM_exp(k), FM_model, returned, ...
            physicalConverged, {physicalStatus}, inducedVelocity_mps, ...
            iterations, closureResidualRelative, {errorIdentifier}, ...
            'VariableNames', {'variant','collective75_deg','Vtip_fps','rpm', ...
            'modelCollective_deg','alpha0L_deg','compressibility_enabled', ...
            'referenceMach','liftSlopeFactor','CT_exp','CT_model','CP_exp', ...
            'CP_model','FM_exp','FM_model','returned','physicalConverged', ...
            'physicalStatus','inducedVelocity_mps','iterations', ...
            'closureResidualRelative','errorIdentifier'});
        rows = [rows; local]; %#ok<AGROW>
    end
end
writetable(rows, fullfile(outputDir, 'XV15_SECTION_AERO_MATLAB_VALIDATION.csv'));

%% Fair metrics on the six common positive-load points used in PR67
commonCollectives = [6; 7; 8; 9; 10; 11];
metricRows = table();
for v = 1:numel(variantName)
    mask = strcmp(rows.variant, variantName{v}) & ...
        ismember(rows.collective75_deg, commonCollectives) & ...
        rows.physicalConverged;
    local = rows(mask,:);
    if height(local) ~= numel(commonCollectives)
        CT_MAPE_pct = NaN;
        CP_MAPE_pct = NaN;
        FM_MAPE_pct = NaN;
        commonPointCount = height(local);
    else
        CT_MAPE_pct = 100*mean(abs(local.CT_model-local.CT_exp)./local.CT_exp);
        CP_MAPE_pct = 100*mean(abs(local.CP_model-local.CP_exp)./local.CP_exp);
        FM_MAPE_pct = 100*mean(abs(local.FM_model-local.FM_exp)./local.FM_exp);
        commonPointCount = height(local);
    end
    metricRows = [metricRows; table(variantName(v), commonPointCount, ...
        CT_MAPE_pct, CP_MAPE_pct, FM_MAPE_pct, ...
        'VariableNames', {'variant','commonPointCount','CT_MAPE_pct', ...
        'CP_MAPE_pct','FM_MAPE_pct'})]; %#ok<AGROW>
end
writetable(metricRows, fullfile(outputDir, 'XV15_SECTION_AERO_MATLAB_METRICS.csv'));

reductionName = {'alpha0L_eq_deg'; 'weight_definition_code'; ...
    'baseline_liftSlope_1_per_rad'; 'PG_reference_r_over_R'; ...
    'PG_Mach_cap'; 'sound_speed_mps'; 'twistTipEq_deg'; 'chordEq_m'};
reductionValue = {alpha0Eq_deg; 'c(r)*(r/R)^2'; Pbase.rotor.liftSlope; ...
    0.75; 0.75; Ptemplate.env.aSound; twistTipEq_deg; chordEq_m};
reductionTable = table(reductionName, reductionValue);
writetable(reductionTable, fullfile(outputDir, 'XV15_SECTION_AERO_REDUCTION_SUMMARY.csv'));

results = struct();
results.validationTable = rows;
results.metricTable = metricRows;
results.sourceTable = sourceTable;
results.reductionTable = reductionTable;
results.alpha0Eq_rad = alpha0Eq_rad;
results.alpha0Eq_deg = alpha0Eq_deg;
results.claimBoundary = ['INDEPENDENT_NACA_SECTION_AERO_REDUCTION_' ...
    'NO_OARF_PARAMETER_FIT'];
save(fullfile(outputDir, 'XV15_SECTION_AERO_VALIDATION_RESULTS.mat'), 'results');
end

function theta_deg = nasa_metal_twist_deg(x)
theta_deg = 289.98*x.^5 - 892.87*x.^4 + 987.06*x.^3 ...
    - 438.31*x.^2 + 15.695*x + 32.057;
end
