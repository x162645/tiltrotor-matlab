function results = run_xv15_section_aero_validation(outputDir)
%RUN_XV15_SECTION_AERO_VALIDATION XV-15 C81 -> low-order section-aero test.
%
% This runner keeps the PR67 geometry/input mapping and asks one controlled
% question: what changes when the generic scalar section-aero coefficients
% are replaced by scalar values reduced from the public NASA CAMRAD II XV-15
% C81 tables, without using OARF CT/CP/FM to identify those values?
%
% Important claim boundary:
% - C81 tables are NASA reference-model inputs, not raw airfoil measurements;
% - the scalar reduction is therefore an XV-15 REFERENCE-EQUIVALENT parameter
%   set for the present generic low-order equations;
% - OARF Run 15 remains external validation data and is not used in fitting;
% - the earlier design-Cl -> alpha0L approximation is superseded here.

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

%% OARF Run 15 original-metal-blade hover data: external comparison only
collective75_deg = [0; 2; 4; 6; 7; 8; 9; 10; 11];
Vtip_fps = [769.0; 768.7; 768.4; 768.4; 768.4; 768.4; 768.0; 768.0; 767.7];
CT_exp = [0.004063; 0.005581; 0.007391; 0.009208; 0.010104; ...
          0.011063; 0.012035; 0.013089; 0.013929];
CP_exp = [0.000315; 0.000426; 0.000588; 0.000796; 0.000913; ...
          0.001044; 0.001188; 0.001358; 0.001523];
FM_exp = [0.5814; 0.6921; 0.7641; 0.7849; 0.7866; ...
          0.7881; 0.7858; 0.7797; 0.7632];

%% Same geometry/input reduction frozen from PR67
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

%% Independent section-aero parameter source: NASA XV-15 C81 reference tables
c81 = build_xv15_c81_low_order_section_aero();

variantName = {'BASELINE_GENERIC_SECTION_AERO'; 'NASA_C81_LOW_ORDER_SECTION_AERO'};
variantAlpha0 = [0; c81.alpha0L_rad];
variantLiftSlope = [Pbase.rotor.liftSlope; c81.liftSlope];
variantCLmax = [Pbase.rotor.CLmax; c81.CLmax];
variantCD0 = [Pbase.rotor.CD0; c81.CD0];
variantKCD = [Pbase.rotor.kCD; c81.kCD];

Ptemplate = Pbase;
Ptemplate.rotor.R = R;
Ptemplate.rotor.Nb = 3;
Ptemplate.rotor.rootCut = rootCut;
Ptemplate.rotor.chord = chordEq_m;
Ptemplate.rotor.twistTip = twistTipEq_deg*d2r;
% Keep the same generic uniform blade-mass closure as PR67.  This is not
% claimed to be an XV-15 mass-distribution reconstruction.
Ptemplate.rotor.Ib = Ptemplate.rotor.bladeMass*R^2/3;
Ptemplate.rotor.Sblade = Ptemplate.rotor.bladeMass*R/2;

%% Run unchanged low-order rotor equations with only section parameters varied
rows = table();
for v = 1:numel(variantName)
    for k = 1:numel(collective75_deg)
        P = Ptemplate;
        Vtip_mps = Vtip_fps(k)*0.3048;
        P.rotor.Omega = Vtip_mps/R;
        P.rotor.alpha0L = variantAlpha0(v);
        P.rotor.liftSlope = variantLiftSlope(v);
        P.rotor.CLmax = variantCLmax(v);
        P.rotor.CD0 = variantCD0(v);
        P.rotor.kCD = variantKCD(v);
        % C81 reduction already represents spanwise Mach-dependent reference
        % tables at the nominal hover tip speed. Do not stack the separate PG
        % wrapper correction on top of it.
        P.rotor.enableCompressibilityCorrection = false;

        modelCollective_deg = collective75_deg(k)-twistTipEq_deg*x75;
        ctrl = struct('collective', modelCollective_deg*d2r, 'cyclicLong', 0);

        returned = false;
        physicalConverged = false;
        physicalStatus = 'NOT_RUN';
        CT_model = NaN; CP_model = NaN; FM_model = NaN;
        inducedVelocity_mps = NaN; iterations = NaN;
        closureResidualRelative = NaN; errorIdentifier = '';

        try
            [~, ~, out] = rotor_model_bemt_section_aero( ...
                zeros(9,1), ctrl, 0, -1, zeros(3,1), P);
            returned = true;
            physicalConverged = out.physicalConverged;
            physicalStatus = out.physicalStatus;
            inducedVelocity_mps = out.inducedVelocity;
            iterations = out.iterations;
            closureResidualRelative = out.inducedClosureResidualRelative;

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
            P.rotor.alpha0L/d2r, P.rotor.liftSlope, P.rotor.CLmax, ...
            P.rotor.CD0, P.rotor.kCD, CT_exp(k), CT_model, ...
            CP_exp(k), CP_model, FM_exp(k), FM_model, returned, ...
            physicalConverged, {physicalStatus}, inducedVelocity_mps, ...
            iterations, closureResidualRelative, {errorIdentifier}, ...
            'VariableNames', {'variant','collective75_deg','Vtip_fps','rpm', ...
            'modelCollective_deg','alpha0L_deg','liftSlope','CLmax','CD0','kCD', ...
            'CT_exp','CT_model','CP_exp','CP_model','FM_exp','FM_model', ...
            'returned','physicalConverged','physicalStatus', ...
            'inducedVelocity_mps','iterations','closureResidualRelative', ...
            'errorIdentifier'});
        rows = [rows; local]; %#ok<AGROW>
    end
end
writetable(rows, fullfile(outputDir, 'XV15_SECTION_AERO_MATLAB_VALIDATION.csv'));

%% Fair comparison on the same common converged range used in PR67
commonCollectives = [6; 7; 8; 9; 10; 11];
metricRows = table();
for v = 1:numel(variantName)
    mask = strcmp(rows.variant, variantName{v}) & ...
        ismember(rows.collective75_deg, commonCollectives) & ...
        rows.physicalConverged;
    local = rows(mask,:);
    if height(local) ~= numel(commonCollectives)
        CT_MAPE_pct = NaN; CP_MAPE_pct = NaN; FM_MAPE_pct = NaN;
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

%% Reduction audit
reductionName = {'source_class'; 'source'; 'nominal_Vtip_fps'; ...
    'Mtip'; 'alpha0L_eq_deg'; 'liftSlope_eq_1_per_rad'; 'CLmax_eq'; ...
    'CD0_eq'; 'kCD_eq'; 'CL_fit_weighted_RMS'; 'CD_fit_weighted_RMS'; ...
    'twistTipEq_deg'; 'chordEq_m'};
reductionValue = {c81.sourceClass; c81.source; c81.nominalVtip_fps; ...
    c81.Mtip; c81.alpha0L_deg; c81.liftSlope; c81.CLmax; c81.CD0; ...
    c81.kCD; c81.clWeightedRms; c81.cdWeightedRms; twistTipEq_deg; chordEq_m};
reductionTable = table(reductionName, reductionValue);
writetable(reductionTable, fullfile(outputDir, 'XV15_SECTION_AERO_REDUCTION_SUMMARY.csv'));

results = struct();
results.validationTable = rows;
results.metricTable = metricRows;
results.reductionTable = reductionTable;
results.c81 = c81;
results.claimBoundary = ['NASA_C81_REFERENCE_AERO_REDUCTION_TO_GENERIC_' ...
    'LOW_ORDER_FIELDS_NO_OARF_PARAMETER_FIT'];
save(fullfile(outputDir, 'XV15_SECTION_AERO_VALIDATION_RESULTS.mat'), 'results');
end

function theta_deg = nasa_metal_twist_deg(x)
theta_deg = 289.98*x.^5 - 892.87*x.^4 + 987.06*x.^3 ...
    - 438.31*x.^2 + 15.695*x + 32.057;
end
