function result = low_collective_quick_audit(outputDir)
%LOW_COLLECTIVE_QUICK_AUDIT Read-only focused audit of low-collective hover.
% This diagnostic mirrors the committed production equations without
% changing model/rotor_model_bemt.m or params_nominal.m. It is limited to
% collective = 4, 8, 10, and 12 deg, one 11-point residual probe at 8 deg,
% and two neighbor-seed trials at 8 and 10 deg.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir, 'docs', 'low_collective_quick_audit');
end
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

logPath = fullfile(outputDir, 'LOW_COLLECTIVE_MATLAB_RUN.log');
if exist(logPath, 'file')
    delete(logPath);
end
diary(logPath);
cleanupDiary = onCleanup(@() diary('off'));

fprintf('Low-collective quick audit\n');
fprintf('==========================\n');
fprintf('Started: %s\n', datestr(now, 31));
fprintf('Root: %s\n', rootDir);
fprintf('Output: %s\n', outputDir);

P = params_nominal();
d2r = pi/180;
collectivePointsDeg = [4; 8; 10; 12];
referenceStations = [0.25, 0.50, 0.75, 0.90];

definitionTable = build_definition_table(P, referenceStations);
writetable(definitionTable, fullfile(outputDir, ...
    'LOW_COLLECTIVE_DEFINITION_MAPPING.csv'));

defaultVi = initial_induced_velocity(P);
pointResults = repmat(empty_point_result(), numel(collectivePointsDeg), 1);
productionResults = repmat(empty_production_result(), ...
    numel(collectivePointsDeg), 1);
pointRows = table();

for k = 1:numel(collectivePointsDeg)
    collectiveDeg = collectivePointsDeg(k);
    pointResults(k) = run_coupled_diagnostic(P, collectiveDeg*d2r, ...
        defaultVi);
    productionResults(k) = call_production(P, collectiveDeg*d2r);
    pointRows = [pointRows; point_result_rows(P, collectiveDeg, ...
        pointResults(k), productionResults(k), referenceStations)]; %#ok<AGROW>
    fprintf(['Point %2.0f deg: diagnostic=%s iter=%d vi=% .9g ' ...
        'T=% .9g N; production=%s\n'], collectiveDeg, ...
        pointResults(k).exitReason, pointResults(k).iterations, ...
        pointResults(k).finalVi, pointResults(k).loads.T, ...
        productionResults(k).exitReason);
end
writetable(pointRows, fullfile(outputDir, ...
    'LOW_COLLECTIVE_POINT_DIAGNOSTICS.csv'));

residualTable = build_residual_table(P, 8*d2r, defaultVi, ...
    pointResults(1).finalVi, pointResults(4).finalVi);
writetable(residualTable, fullfile(outputDir, ...
    'LOW_COLLECTIVE_RESIDUAL_AT_8DEG.csv'));
residualClassification = classify_residual(residualTable);
plot_residual(residualTable, fullfile(outputDir, ...
    'LOW_COLLECTIVE_RESIDUAL_AT_8DEG.png'));

seedTable = build_seed_table(P, pointResults(1).finalVi, ...
    pointResults(4).finalVi, residualClassification);
writetable(seedTable, fullfile(outputDir, ...
    'LOW_COLLECTIVE_SEED_TESTS.csv'));

summaryTable = build_summary_table(P, pointResults, ...
    productionResults, residualTable, residualClassification, seedTable);
writetable(summaryTable, fullfile(outputDir, ...
    'LOW_COLLECTIVE_AUDIT_SUMMARY.csv'));

write_environment_file(rootDir, outputDir, defaultVi, ...
    residualClassification);

result.rootDir = rootDir;
result.outputDir = outputDir;
result.definitionTable = definitionTable;
result.pointResults = pointResults;
result.productionResults = productionResults;
result.pointTable = pointRows;
result.residualTable = residualTable;
result.residualClassification = residualClassification;
result.seedTable = seedTable;
result.summaryTable = summaryTable;
result.defaultInitialVi = defaultVi;

fprintf('Residual classification: %s\n', residualClassification);
fprintf('Finished: %s\n', datestr(now, 31));
clear cleanupDiary;
end

function tableOut = build_definition_table(P, stations)
inputCollectiveDeg = [0; 4; 8; 10; 12];
rows = repmat(definition_row(), 0, 1);

rows(end+1) = make_definition_row('DEFINITION', ...
    'collective_reference_station', ...
    'Blade collective pitch angle at 0.75R (COLL)', ...
    'Additive pitch command referenced to zero twist at rootCut=0.18R', ...
    'CONFIRMED_MISMATCH', ...
    ['NASA-TM-86854 PDF12 printed10 Table 2; ' ...
     'model/rotor_model_bemt.m thetaBlade expression'], ...
    ['NASA Figure 25 abscissa cannot be equated degree-for-degree to the ' ...
     'current command without a radial-reference mapping.']);
rows(end+1) = make_definition_row('DEFINITION', ...
    'collective_measurement', ...
    ['Collective actuator position; control-system geometric nonlinearity ' ...
     'error estimated below +/-1 deg'], ...
    'rotorCtrl.collective in rad, used directly', ...
    'PARTIAL_MATCH', ...
    'NASA-TM-86854 PDF9 printed7 Control and Loads Plots', ...
    'Both are collective-like commands, but the measurement and station definitions differ.');
rows(end+1) = make_definition_row('DEFINITION', ...
    'collective_zero_meaning', ...
    ['Zero means 0 deg at 0.75R; the -47 deg nonlinear twist distribution ' ...
     'remains present'], ...
    ['Zero command leaves theta=twist, from 0 deg at 0.18R to -6 deg at ' ...
     'the tip'], ...
    'CONFIRMED_MISMATCH', ...
    ['NASA-TM-86854 PDF11 printed9 Table 1, PDF12 printed10 Table 2, ' ...
     'PDF21 printed19 Fig.5; params_nominal.m'], ...
    'Neither zero means that every local blade section has zero pitch.');
rows(end+1) = make_definition_row('DEFINITION', ...
    'blade_pitch_formula', ...
    'Local nonlinear ATB twist plus a 0.75R collective setting', ...
    'thetaBlade=collective+twistTip*(r-r0)/(R-r0)+theta1s*sin(psi)', ...
    'CONFIRMED_MISMATCH', ...
    ['NASA-TM-86854 PDF21 printed19 Fig.5; ' ...
     'model/rotor_model_bemt.m'], ...
    'The current hover comparison has theta1s=0.');
rows(end+1) = make_definition_row('DEFINITION', ...
    'left_right_collective_sign', ...
    'Single isolated test rotor; no left/right mapping is used', ...
    ['total_forces_moments assigns left=collective-diffCollective and ' ...
     'right=collective+diffCollective'], ...
    'NOT_USED_IN_CURRENT_COMPARISON', ...
    'model/total_forces_moments.m', ...
    'The external hover calculation calls one left rotor with cyclicLong=0.');

for k = 1:numel(inputCollectiveDeg)
    pitchDeg = geometric_pitch_deg(P, inputCollectiveDeg(k), stations);
    row = make_definition_row('CURRENT_PITCH_DISTRIBUTION', ...
        sprintf('current_collective_%g_deg', inputCollectiveDeg(k)), ...
        'NOT_APPLICABLE', ...
        sprintf(['theta(0.25R)=%.9g deg; theta(0.50R)=%.9g deg; ' ...
            'theta(0.75R)=%.9g deg; theta(0.90R)=%.9g deg'], pitchDeg), ...
        'NOT_USED_IN_CURRENT_COMPARISON', ...
        'params_nominal.m; model/rotor_model_bemt.m', ...
        'Static evaluation of the committed linear-twist formula.');
    row.collective_deg = inputCollectiveDeg(k);
    row.pitch_025R_deg = pitchDeg(1);
    row.pitch_050R_deg = pitchDeg(2);
    row.pitch_075R_deg = pitchDeg(3);
    row.pitch_090R_deg = pitchDeg(4);
    rows(end+1) = row; %#ok<AGROW>
end

currentSigma = P.rotor.Nb*P.rotor.chord/(pi*P.rotor.R);
currentRpm = P.rotor.Omega*60/(2*pi);
currentTipMach = P.rotor.Omega*P.rotor.R/340;
rows(end+1) = make_definition_row('CONFIGURATION', 'blade_count', ...
    '3 blades', sprintf('%d blades', P.rotor.Nb), ...
    'CONFIRMED_MATCH', ...
    'NASA-TM-86854 PDF11 printed9 Table 1; params_nominal.m', ...
    'A numerical match does not imply that the blade designs are homologous.');
rows(end+1) = make_definition_row('CONFIGURATION', 'radius', ...
    '3.81 m from the repeatedly stated 7.62 m diameter', ...
    sprintf('%.9g m', P.rotor.R), 'CONFIRMED_MATCH', ...
    'NASA-TM-86854 PDF4 printed2 and PDF6 printed4; params_nominal.m', ...
    ['Table 1 labels 7.62 m as radius, contradicting the report narrative; ' ...
     'the diameter statement is used as the internally consistent value.']);
rows(end+1) = make_definition_row('CONFIGURATION', 'rotor_speed', ...
    'Figure 25 combines baseline data acquired over tip Mach 0.35-0.73', ...
    sprintf('%.9g rad/s = %.9g rpm; approximate tip Mach %.9g', ...
        P.rotor.Omega, currentRpm, currentTipMach), ...
    'PARTIAL_MATCH', ...
    'NASA-TM-86854 PDF3-4 printed1-2 and PDF7 printed5; params_nominal.m', ...
    'The current fixed speed lies within the test range but is not a pointwise speed match.');
rows(end+1) = make_definition_row('CONFIGURATION', 'chord_distribution', ...
    'Mean chord 0.411 m with radial taper, especially outboard of about 0.7R', ...
    sprintf('Constant chord %.9g m', P.rotor.chord), ...
    'CONFIRMED_MISMATCH', ...
    'NASA-TM-86854 PDF11 printed9 Table 1 and PDF22 printed20 Fig.7', ...
    'The current constant chord is not the ATB planform.');
rows(end+1) = make_definition_row('CONFIGURATION', 'solidity', ...
    'sigma=0.103 from the test rotor geometry', ...
    sprintf('sigma=Nb*c/(pi*R)=%.9g', currentSigma), ...
    'CONFIRMED_MISMATCH', ...
    'NASA-TM-86854 PDF11 printed9 Table 1; external-validation script', ...
    'The definition matches, but the numerical solidity and chord distribution do not.');
rows(end+1) = make_definition_row('CONFIGURATION', 'root_aerodynamic_start', ...
    'Baseline cuff/airfoil geometry begins near 0.09R and changes through 0.30R', ...
    sprintf('Blade-element integration begins at %.9gR', P.rotor.rootCut), ...
    'CONFIRMED_MISMATCH', ...
    'NASA-TM-86854 PDF7 printed5 and PDF22 printed20 Fig.8; params_nominal.m', ...
    'The test report does not define a single rootCut variable identical to the code field.');
rows(end+1) = make_definition_row('CONFIGURATION', 'blade_twist', ...
    '-47 deg nonlinear, with local zero near 0.75R in Fig.5', ...
    sprintf('Linear 0 deg at %.3gR to %.9g deg at 1R', ...
        P.rotor.rootCut, P.rotor.twistTip*180/pi), ...
    'CONFIRMED_MISMATCH', ...
    'NASA-TM-86854 PDF11 printed9 Table 1 and PDF21 printed19 Fig.5; params_nominal.m', ...
    'The current single linear field cannot represent the ATB distribution.');
rows(end+1) = make_definition_row('CONFIGURATION', 'airfoil_or_lift_model', ...
    'V43030-1.58, VR7, and VR8 by radial region', ...
    sprintf(['Single tanh-limited polar: liftSlope=%.9g 1/rad, ' ...
        'CLmax=%.9g, CD0=%.9g, kCD=%.9g'], ...
        P.rotor.liftSlope, P.rotor.CLmax, P.rotor.CD0, P.rotor.kCD), ...
    'CONFIRMED_MISMATCH', ...
    'NASA-TM-86854 PDF11 printed9 Table 1 and PDF22 printed20 Fig.8; params_nominal.m', ...
    'Public report does not provide a single lift-slope value equivalent to the code polar.');
rows(end+1) = make_definition_row('NORMALIZATION', 'CT_definition', ...
    'CT=T/(rho*A*(Omega*R)^2)', ...
    'External comparison recomputes CT=T/(rho*A*(Omega*R)^2)', ...
    'CONFIRMED_MATCH', ...
    ['NASA-TM-86854 PDF3 printed1 Nomenclature; ' ...
     'analysis/master_thesis_validation/run_external_validation_calculations.m'], ...
    'The production out.CT field uses a separate 0.5 normalization only inside NUAA Eq.13.');
rows(end+1) = make_definition_row('NORMALIZATION', 'sigma_definition', ...
    'Geometric rotor solidity; reported value 0.103', ...
    'Nb*constantChord/(pi*R)', 'CONFIRMED_MATCH', ...
    'NASA-TM-86854 PDF4 printed2 and PDF11 printed9; external-validation script', ...
    'Formula class matches; the actual geometries and numerical values do not.');

tableOut = struct2table(rows);
end

function result = run_coupled_diagnostic(P, collective, initialVi)
result = empty_point_result();
result.initialVi = initialVi;
result.finalVi = initialVi;
result.exitReason = 'NOT_STARTED';
result.history = repmat(struct('iteration',NaN,'viOld',NaN, ...
    'viTarget',NaN,'viNew',NaN,'viError',NaN,'thrust',NaN, ...
    'momentumThrust',NaN,'closureResidual',NaN, ...
    'positiveThrustGuardActive',false,'denominator',NaN, ...
    'denominatorFloorActive',false,'flapResidualNorm',NaN, ...
    'flapExitReason',''), P.rotor.inducedMaxIter, 1);

vi = initialVi;
zFlap = P.rotor.flapInitial(:);
flapInfo = empty_flap_info();
lastLoads = empty_loads(P);
tipSpeed = P.rotor.Omega*P.rotor.R;
A = pi*P.rotor.R^2;

for iter = 1:P.rotor.inducedMaxIter
    [zFlap, flapInfo] = solve_flap_diagnostic(P, collective, vi, zFlap);
    if ~flapInfo.converged
        result.exitReason = ['FLAP_' upper(flapInfo.exitStatus)];
        result.iterations = iter;
        result.flap = flapInfo;
        result.zFlap = zFlap;
        result.finalVi = vi;
        result.loads = blade_loads_diagnostic(P, collective, vi, zFlap);
        result.history = result.history(1:iter);
        return;
    end

    loads = blade_loads_diagnostic(P, collective, vi, zFlap);
    lambda1 = -vi/max(tipSpeed, eps);
    denominator = abs(lambda1);
    denominatorUsed = max(denominator, 1.0e-12);
    CTinternal = max(loads.T, 0)/(0.5*P.env.rho*A*tipSpeed^2);
    viTarget = tipSpeed*CTinternal/(4*denominatorUsed);
    viNew = 0.5*(vi + viTarget);
    viError = abs(viNew-vi)/max(1, abs(vi));
    momentumThrust = 2*P.env.rho*A*tipSpeed*vi*denominator;

    result.history(iter).iteration = iter;
    result.history(iter).viOld = vi;
    result.history(iter).viTarget = viTarget;
    result.history(iter).viNew = viNew;
    result.history(iter).viError = viError;
    result.history(iter).thrust = loads.T;
    result.history(iter).momentumThrust = momentumThrust;
    result.history(iter).closureResidual = loads.T-momentumThrust;
    result.history(iter).positiveThrustGuardActive = loads.T < 0;
    result.history(iter).denominator = denominator;
    result.history(iter).denominatorFloorActive = ...
        denominator < denominatorUsed;
    result.history(iter).flapResidualNorm = flapInfo.residualNorm;
    result.history(iter).flapExitReason = flapInfo.exitStatus;

    vi = viNew;
    lastLoads = loads;
    if viError < P.rotor.inducedTol && ...
            flapInfo.residualNorm <= P.rotor.flapResidualTol
        result.converged = true;
        result.exitReason = 'CONVERGED';
        break;
    end
end

if ~result.converged
    result.exitReason = 'COUPLED_MAX_ITER';
end
result.iterations = iter;
result.finalVi = vi;
result.zFlap = zFlap;
result.flap = flapInfo;
result.loads = blade_loads_diagnostic(P, collective, vi, zFlap);
result.history = result.history(1:iter);
if isempty(result.loads.rMid)
    result.loads = lastLoads;
end
result.viError = result.history(end).viError;
result.momentumThrust = 2*P.env.rho*A*tipSpeed*result.finalVi* ...
    abs(result.finalVi/tipSpeed);
result.closureResidual = result.loads.T-result.momentumThrust;
result.signJump = any(diff(sign_nonzero([result.history.thrust])) ~= 0);
result.branchSwitch = any(diff([result.history.positiveThrustGuardActive]) ~= 0);
result.denominatorNearZero = any([result.history.denominator] < 1.0e-10);
result.hasNaN = numeric_has_nan(result);
result.hasInf = numeric_has_inf(result);
result.hasUnexpectedComplex = numeric_has_complex(result);
end

function production = call_production(P, collective)
production = empty_production_result();
x = zeros(9,1);
ctrl = struct('collective', collective, 'cyclicLong', 0);
try
    [~, ~, out] = rotor_model_bemt(x, ctrl, 0, -1, zeros(3,1), P);
    production.success = true;
    production.exitReason = 'CONVERGED';
    production.thrust = out.thrust;
    production.torque = out.torque;
    production.inducedVelocity = out.inducedVelocity;
    production.iterations = out.iterations;
    production.viError = out.inducedVelocityError;
    production.flapResidualNorm = out.flap.residualNorm;
catch ME
    production.errorIdentifier = ME.identifier;
    production.errorMessage = ME.message;
    production.exitReason = ME.identifier;
end
end

function rows = point_result_rows(P, collectiveDeg, diagnostic, ...
        production, stations)
loads = diagnostic.loads;
count = numel(loads.rMid);
sigma = P.rotor.Nb*P.rotor.chord/(pi*P.rotor.R);
A = pi*P.rotor.R^2;
tipSpeed = P.rotor.Omega*P.rotor.R;
ctSigma = (loads.T/(P.env.rho*A*tipSpeed^2))/sigma;
referencePitch = geometric_pitch_deg(P, collectiveDeg, stations);
referenceAlpha = interp1(loads.rMid/P.rotor.R, ...
    loads.alphaMean*180/pi, stations, 'linear', 'extrap');
region = classify_thrust_region(loads.T, P);

rows = table();
for j = 1:count
    row = table(collectiveDeg, j, loads.rMid(j)/P.rotor.R, ...
        loads.thetaMean(j)*180/pi, loads.alphaMean(j)*180/pi, ...
        loads.alphaMin(j)*180/pi, loads.alphaMax(j)*180/pi, ...
        loads.radialThrust(j), loads.T, ctSigma, loads.Q, ...
        diagnostic.initialVi, diagnostic.finalVi, loads.T, ...
        diagnostic.momentumThrust, diagnostic.closureResidual, ...
        diagnostic.iterations, {diagnostic.exitReason}, ...
        diagnostic.converged, diagnostic.flap.converged, ...
        {diagnostic.flap.exitStatus}, diagnostic.hasNaN, ...
        diagnostic.hasInf, diagnostic.hasUnexpectedComplex, ...
        diagnostic.denominatorNearZero, diagnostic.signJump, ...
        diagnostic.branchSwitch, {region}, production.success, ...
        {production.errorIdentifier}, production.thrust, ...
        production.torque, production.inducedVelocity, ...
        referencePitch(1), referencePitch(2), referencePitch(3), ...
        referencePitch(4), referenceAlpha(1), referenceAlpha(2), ...
        referenceAlpha(3), referenceAlpha(4), ...
        'VariableNames', {'collective_deg','radial_index','r_over_R', ...
        'geometric_pitch_deg','alpha_mean_deg','alpha_min_deg', ...
        'alpha_max_deg','radial_thrust_contribution_N','total_thrust_N', ...
        'CT_over_sigma','total_torque_Nm','induced_initial_mps', ...
        'induced_final_mps','BEMT_thrust_N','momentum_thrust_N', ...
        'closure_residual_N','outer_iterations','exit_reason', ...
        'diagnostic_converged','flap_converged','flap_exit_reason', ...
        'has_NaN','has_Inf','has_unexpected_complex', ...
        'denominator_near_zero','thrust_sign_jump','branch_switch', ...
        'region_class','production_success','production_error_identifier', ...
        'production_thrust_N','production_torque_Nm', ...
        'production_induced_velocity_mps','pitch_025R_deg', ...
        'pitch_050R_deg','pitch_075R_deg','pitch_090R_deg', ...
        'alpha_mean_025R_deg','alpha_mean_050R_deg', ...
        'alpha_mean_075R_deg','alpha_mean_090R_deg'});
    rows = [rows; row]; %#ok<AGROW>
end
end

function residualTable = build_residual_table(P, collective, defaultVi, ...
        negativeNeighborVi, positiveNeighborVi)
upper = max([1.25*defaultVi, 1.5*positiveNeighborVi, 2]);
vi = linspace(0, upper, 11).';
count = numel(vi);
T_BEMT = NaN(count,1);
T_momentum = NaN(count,1);
residual_N = NaN(count,1);
valid = false(count,1);
invalid_reason = repmat({''}, count, 1);
flap_residual_norm = NaN(count,1);
flap_iterations = NaN(count,1);
denominator = NaN(count,1);
denominator_floor_active = false(count,1);
tipSpeed = P.rotor.Omega*P.rotor.R;
A = pi*P.rotor.R^2;

for k = 1:count
    [zFlap, flapInfo] = solve_flap_diagnostic(P, collective, vi(k), ...
        P.rotor.flapInitial(:));
    flap_residual_norm(k) = flapInfo.residualNorm;
    flap_iterations(k) = flapInfo.iterations;
    if ~flapInfo.converged
        invalid_reason{k} = ['FLAP_' upper(flapInfo.exitStatus)];
        continue;
    end
    loads = blade_loads_diagnostic(P, collective, vi(k), zFlap);
    denominator(k) = abs(vi(k)/tipSpeed);
    denominator_floor_active(k) = denominator(k) < 1.0e-12;
    T_BEMT(k) = loads.T;
    T_momentum(k) = 2*P.env.rho*A*tipSpeed*vi(k)*denominator(k);
    residual_N(k) = T_BEMT(k)-T_momentum(k);
    valid(k) = isreal([T_BEMT(k), T_momentum(k), residual_N(k)]) && ...
        all(isfinite([T_BEMT(k), T_momentum(k), residual_N(k)]));
    if ~valid(k)
        invalid_reason{k} = 'NONFINITE_OR_COMPLEX';
    end
end

collective_deg = repmat(collective*180/pi, count, 1);
interval_basis = repmat({sprintf([ ...
    'vi in [0, %.9g] m/s: zero/4deg neighbor %.9g, ' ...
    '12deg positive neighbor %.9g, default hover scale %.9g'], ...
    upper, negativeNeighborVi, positiveNeighborVi, defaultVi)}, count, 1);
residualTable = table(collective_deg, vi, T_BEMT, T_momentum, ...
    residual_N, valid, invalid_reason, flap_residual_norm, ...
    flap_iterations, denominator, denominator_floor_active, interval_basis);
end

function classification = classify_residual(T)
valid = T.valid & isfinite(T.residual_N);
indices = find(valid);
signChanges = 0;
for k = 1:numel(indices)-1
    if indices(k+1) == indices(k)+1 && ...
            T.residual_N(indices(k))*T.residual_N(indices(k+1)) <= 0
        signChanges = signChanges+1;
    end
end
if any(~T.valid)
    if signChanges == 0
        classification = 'DISCONTINUOUS_OR_UNDEFINED';
    else
        classification = 'CLEAR_SINGLE_ROOT_WITH_INVALID_SAMPLES';
    end
elseif signChanges == 1
    classification = 'CLEAR_SINGLE_ROOT';
elseif signChanges > 1
    classification = 'MULTIPLE_ROOTS_OR_BRANCHES';
else
    classification = 'NO_ROOT_IN_SAMPLED_PHYSICAL_INTERVAL';
end
end

function plot_residual(T, pngPath)
fig = figure('Visible','off','Color','w','Position',[100 100 900 650]);
cleanupFigure = onCleanup(@() close(fig));
subplot(2,1,1);
plot(T.vi, T.T_BEMT, '-o', 'LineWidth', 1.4, ...
    'DisplayName', 'T_{BEMT}');
hold on;
plot(T.vi, T.T_momentum, '-s', 'LineWidth', 1.4, ...
    'DisplayName', 'T_{momentum}');
yline(0, ':k', 'HandleVisibility', 'off');
grid on;
xlabel('Induced velocity v_i (m/s)');
ylabel('Thrust (N)');
title('8 deg low-collective closure components');
legend('Location','best');

subplot(2,1,2);
plot(T.vi, T.residual_N, '-o', 'LineWidth', 1.4);
hold on;
yline(0, ':k', 'HandleVisibility', 'off');
grid on;
xlabel('Induced velocity v_i (m/s)');
ylabel('R(v_i) = T_{BEMT} - T_{momentum} (N)');
title('Committed positive-thrust momentum closure residual');
print(fig, pngPath, '-dpng', '-r160');
clear cleanupFigure;
end

function seedTable = build_seed_table(P, negativeSeedVi, positiveSeedVi, ...
        residualClassification)
collectiveValues = [8; 10];
seedNames = {'4DEG_NEGATIVE_NEIGHBOR'; '12DEG_POSITIVE_NEIGHBOR'};
seedValues = [negativeSeedVi; positiveSeedVi];
rows = table();
for i = 1:numel(collectiveValues)
    local = repmat(empty_point_result(), 2, 1);
    for j = 1:2
        local(j) = run_coupled_diagnostic(P, ...
            collectiveValues(i)*pi/180, seedValues(j));
    end
    if collectiveValues(i) == 8
        localResidualClassification = residualClassification;
    else
        localResidualClassification = ...
            'INCONCLUSIVE_WITH_CURRENT_PUBLIC_MODEL';
    end
    category = classify_seed_pair(local, localResidualClassification);
    for j = 1:2
        if local(j).converged
            rootSign = thrust_sign_name(local(j).loads.T);
        else
            rootSign = 'NOT_CONVERGED';
        end
        differentRoots = local(1).converged && local(2).converged && ...
            (abs(local(1).finalVi-local(2).finalVi) > 1e-3 || ...
             sign(local(1).loads.T) ~= sign(local(2).loads.T));
        row = table(collectiveValues(i), seedNames(j), seedValues(j), ...
            local(j).converged, {rootSign}, local(j).finalVi, ...
            local(j).loads.T, local(j).closureResidual, ...
            local(j).iterations, {local(j).exitReason}, ...
            differentRoots, {category}, ...
            'VariableNames', {'collective_deg','seed_source', ...
            'seed_induced_velocity_mps','converged','converged_root_sign', ...
            'final_induced_velocity_mps','final_thrust_N', ...
            'final_residual_N','iterations','exit_reason', ...
            'different_roots_for_seed_pair','pair_classification'});
        rows = [rows; row]; %#ok<AGROW>
    end
end
seedTable = rows;
end

function category = classify_seed_pair(local, residualClassification)
if all([local.converged])
    different = abs(local(1).finalVi-local(2).finalVi) > 1e-3 || ...
        sign(local(1).loads.T) ~= sign(local(2).loads.T);
    if different
        category = 'MULTIBRANCH_CONFIRMED';
    else
        category = 'SAME_ROOT_FROM_BOTH_SEEDS';
    end
elseif ~local(1).converged && local(2).converged && ...
        local(2).loads.T > 0
    category = 'CONTINUATION_OR_INITIALIZATION_SENSITIVE';
elseif ~any([local.converged]) && ...
        ~isempty(strfind(residualClassification, 'ROOT')) %#ok<STREMP>
    category = 'SOLVER_ALGORITHM_LIMITATION';
elseif ~any([local.converged]) && ...
        ~isempty(strfind(residualClassification, 'NO_ROOT')) %#ok<STREMP>
    category = 'CLOSURE_OR_DEFINITION_LIMITATION';
else
    category = 'INCONCLUSIVE';
end
end

function summary = build_summary_table(P, points, production, ~, ...
        residualClassification, seedTable)
questions = {
    'NASA_FIG25_COLLECTIVE_DIRECTLY_COMPARABLE'
    'CURRENT_ZERO_COLLECTIVE_NEGATIVE_PITCH_RANGE'
    'ZERO_TO_FOUR_NEGATIVE_THRUST_EXPLAINED_BY_LOCAL_PITCH'
    'OTHER_POSSIBLE_CAUSES'
    'SIX_TO_TEN_FAILURE_LOCATION'
    'EIGHT_DEG_RESIDUAL_ROOT'
    'MULTIPLE_ROOTS_OR_BRANCHES'
    'INITIALIZATION_DEPENDENCE'
    'PRIMARY_ROOT_CAUSE_CLASS'
    'MODIFY_PRODUCTION_PHYSICS_NOW'
    'SOLVER_ONLY_FIX_SUFFICIENT'
    'SEPARATE_XV15_HOMOLOGOUS_OVERRIDE'
    'TWELVE_TO_TWENTYTWO_TREND_RETAINED'
    'THESIS_CLAIM_ACTION'
    'AIRCRAFT_REPRESENTATIVE_CASE_IMPACT'
    'AFFECTED_AIRCRAFT_CONCLUSIONS'};
answers = cell(size(questions));
classifications = cell(size(questions));
confidence = cell(size(questions));
uncertainty = cell(size(questions));
action = cell(size(questions));
evidence = cell(size(questions));
field = cell(size(questions));

negativeEnd = P.rotor.rootCut + ...
    (0/P.rotor.twistTip)*(1-P.rotor.rootCut); %#ok<NASGU>
answers{1} = ['No. NASA COLL is the blade pitch at 0.75R inferred from ' ...
    'actuator position; the current command is referenced to zero twist ' ...
    'at rootCut and gives a different 0.75R pitch.'];
classifications{1} = 'A_CONFIRMED_DEFINITION_MAPPING_MISMATCH';
confidence{1} = 'HIGH';
uncertainty{1} = 'NASA actuator calibration law beyond the stated +/-1 deg is not published here.';
action{1} = 'Map both datasets to a common radial pitch definition before quantitative offset claims.';
evidence{1} = 'LOW_COLLECTIVE_DEFINITION_MAPPING.csv';
field{1} = 'collective_reference_station';

answers{2} = sprintf(['At input 0 deg, theta is zero only at %.3gR and ' ...
    'negative for every modeled blade element outboard of that station.'], ...
    P.rotor.rootCut);
classifications{2} = 'CODE_DIRECT_EVIDENCE';
confidence{2} = 'HIGH';
uncertainty{2} = 'The first blade-element midpoint is outboard of rootCut.';
action{2} = 'Do not reinterpret current 0 deg as 0.75R pitch.';
evidence{2} = 'LOW_COLLECTIVE_DEFINITION_MAPPING.csv';
field{2} = 'current_collective_0_deg';

answers{3} = ['The local negative pitch distribution is a direct, sufficient ' ...
    'mechanism for negative sectional loading, but the audit does not prove ' ...
    'it is the only contributor to total negative thrust.'];
classifications{3} = 'HIGH_PROBABILITY_INFERENCE';
confidence{3} = 'MEDIUM_HIGH';
uncertainty{3} = 'Airfoil simplification and the nonuniform inflow/flapping closure also affect integrated thrust.';
action{3} = 'Retain the negative points; do not add an empirical collective offset.';
evidence{3} = 'LOW_COLLECTIVE_POINT_DIAGNOSTICS.csv';
field{3} = 'geometric_pitch_deg;radial_thrust_contribution_N';

answers{4} = ['Yes: ATB/current geometry and airfoil mismatches, the current ' ...
    'first-harmonic inflow choice, and a positive-thrust-only momentum closure.'];
classifications{4} = 'B_AND_D_CONFIRMED';
confidence{4} = 'HIGH';
uncertainty{4} = 'No model-form sensitivity sweep is authorized in this audit.';
action{4} = 'Separate configuration mapping from any later solver/physics task.';
evidence{4} = 'LOW_COLLECTIVE_DEFINITION_MAPPING.csv';
field{4} = 'CONFIGURATION rows';

flapAllConverged = all(arrayfun(@(p) p.flap.converged, points(2:3)));
if flapAllConverged && all(~[production(2:3).success])
    answers{5} = ['Blade-element and inner steady-flap evaluations remain finite ' ...
        'and converge; failure occurs in the outer induced-velocity/flapping ' ...
        'fixed-point closure reaching its iteration limit.'];
    classifications{5} = 'OUTER_COUPLED_INDUCED_CLOSURE';
else
    answers{5} = 'Multiple diagnostic stages failed; quick audit cannot isolate one stage.';
    classifications{5} = 'QUICK_AUDIT_INCONCLUSIVE';
end
confidence{5} = 'HIGH';
uncertainty{5} = 'This does not validate the underlying blade-element or flap equations.';
action{5} = 'Do not modify blade geometry to address an outer-loop failure.';
evidence{5} = 'LOW_COLLECTIVE_POINT_DIAGNOSTICS.csv';
field{5} = 'flap_converged;exit_reason;outer_iterations';

hasRoot = ~isempty(strfind(residualClassification, 'ROOT')) && ...
    isempty(strfind(residualClassification, 'NO_ROOT')); %#ok<STREMP>
answers{6} = ternary(hasRoot, ...
    'Yes, one sampled sign-changing bracket is present in the finite physical interval.', ...
    'No sign-changing bracket was resolved by the focused samples.');
classifications{6} = residualClassification;
confidence{6} = ternary(hasRoot, 'HIGH', 'MEDIUM');
uncertainty{6} = 'Only the authorized finite interval and focused samples were examined.';
action{6} = 'Use a bracketed solve in a separate repair task only if authorized.';
evidence{6} = 'LOW_COLLECTIVE_RESIDUAL_AT_8DEG.csv';
field{6} = 'residual_N;valid';

answers{7} = ternary(strcmp(residualClassification, ...
    'MULTIPLE_ROOTS_OR_BRANCHES'), ...
    'Multiple sampled roots/branches are indicated.', ...
    'No multiple root is demonstrated by the focused residual probe.');
classifications{7} = ternary(strcmp(residualClassification, ...
    'MULTIPLE_ROOTS_OR_BRANCHES'), ...
    'MULTIPLE_ROOTS_OR_BRANCHES', 'NOT_CONFIRMED');
confidence{7} = 'MEDIUM_HIGH';
uncertainty{7} = 'Unsampled or unsupported negative-thrust/windmill branches remain possible.';
action{7} = 'Do not claim global uniqueness.';
evidence{7} = 'LOW_COLLECTIVE_RESIDUAL_AT_8DEG.csv';
field{7} = 'residual_N';

pairClasses = unique(seedTable.pair_classification);
answers{8} = strjoin(pairClasses, ';');
classifications{8} = 'COMPUTED_SEED_TEST';
confidence{8} = 'HIGH';
uncertainty{8} = 'Only the mandated 4 deg and 12 deg neighboring seeds were used.';
action{8} = 'Treat continuation only as a diagnosis, not a model repair.';
evidence{8} = 'LOW_COLLECTIVE_SEED_TESTS.csv';
field{8} = 'pair_classification';

answers{9} = ['Combination E: A definition mapping mismatch, B configuration ' ...
    'mismatch, C fixed-point/initialization behavior, and D missing ' ...
    'negative/zero-thrust momentum branches all contribute.'];
classifications{9} = 'E_COMBINATION';
confidence{9} = 'HIGH';
uncertainty{9} = 'Relative contribution magnitudes were not fitted or optimized.';
action{9} = 'Split later work into definition/configuration and numerical/branch tasks.';
evidence{9} = 'LOW_COLLECTIVE_AUDIT_SUMMARY.csv';
field{9} = 'supporting evidence files';

answers{10} = 'No change is justified inside this quick audit.';
classifications{10} = 'NO_CHANGE_IN_CURRENT_TASK';
confidence{10} = 'HIGH';
uncertainty{10} = 'A later negative-thrust/windmill scope may require new physics.';
action{10} = 'Open a separate scoped repair/design task after review.';
evidence{10} = 'analysis/low_collective_quick_audit.m';
field{10} = 'read-only diagnostic boundary';

answers{11} = ['No. A bracketed solver may recover a positive root, but it cannot ' ...
    'resolve the collective-reference/configuration mismatch or add the missing ' ...
    'negative-thrust branch.'];
classifications{11} = 'SOLVER_ONLY_INSUFFICIENT';
confidence{11} = 'HIGH';
uncertainty{11} = 'The exact later branch model is not selected.';
action{11} = 'Do not label a solver-only change as full resolution.';
evidence{11} = 'LOW_COLLECTIVE_RESIDUAL_AT_8DEG.csv';
field{11} = 'residual root plus definition mapping';

answers{12} = 'Yes, if XV-15 quantitative reproduction is pursued.';
classifications{12} = 'RECOMMENDED_SEPARATE_DATASET';
confidence{12} = 'HIGH';
uncertainty{12} = 'A complete source-controlled ATB geometry/polar dataset is not yet assembled.';
action{12} = 'Create an opt-in homologous XV-15/ATB override; preserve generic defaults.';
evidence{12} = 'LOW_COLLECTIVE_DEFINITION_MAPPING.csv';
field{12} = 'CONFIGURATION rows';

answers{13} = ['Yes, retain the limited 12-22 deg slope-direction observation, ' ...
    'but explicitly state the pitch-reference and configuration mismatch.'];
classifications{13} = 'RETAIN_WITH_DOWNGRADED_SCOPE';
confidence{13} = 'HIGH';
uncertainty{13} = 'Absolute offset is not attributable to one cause.';
action{13} = 'Keep correlation language; prohibit validation or homologous-comparison wording.';
evidence{13} = 'PR58 frozen external-correlation evidence';
field{13} = '12-22 deg common valid interval';

answers{14} = ['Keep: slope direction agrees while magnitude bias is significant. ' ...
    'Rewrite: the comparison is not at a demonstrated common 0.75R pitch ' ...
    'definition. Delete no frozen failure point.'];
classifications{14} = 'REWRITE_QUALIFIER_ONLY';
confidence{14} = 'HIGH';
uncertainty{14} = 'Exact thesis sentence locations are documented in the Markdown report.';
action{14} = 'Apply wording changes only in a separate thesis revision if requested.';
evidence{14} = 'LOW_COLLECTIVE_QUICK_AUDIT.md';
field{14} = 'Thesis claim disposition';

answers{15} = ['Representative aircraft cases use converged positive-thrust rotor ' ...
    'states, so this audit does not invalidate their internal incremental results; ' ...
    'absolute rotor-load baselines remain configuration-sensitive.'];
classifications{15} = 'LIMITED_IMPACT_NOT_INVALIDATION';
confidence{15} = 'MEDIUM';
uncertainty{15} = 'No aircraft cases were recomputed in this quick audit.';
action{15} = 'Retain internal-study scope and avoid XV-15 absolute claims.';
evidence{15} = 'PR58 frozen representative-case evidence';
field{15} = 'positive-thrust converged cases';

answers{16} = ['Directly sensitive: collective trim, power, control margin, and trim ' ...
    'boundaries. Potentially sensitive through operating-point shifts: dynamic ' ...
    'increments and stability derivatives; local signs/internal consistency are ' ...
    'not automatically invalidated.'];
classifications{16} = 'IMPACT_PATH_ASSESSMENT';
confidence{16} = 'MEDIUM_HIGH';
uncertainty{16} = 'No homologous rotor replacement or aircraft re-trim was run.';
action{16} = 'Quantify only after a reviewed homologous rotor dataset exists.';
evidence{16} = 'LOW_COLLECTIVE_QUICK_AUDIT.md';
field{16} = 'Aircraft-level implications';

summary = table(questions, answers, classifications, evidence, field, ...
    confidence, uncertainty, action, ...
    'VariableNames', {'question','answer','classification','evidence_file', ...
    'evidence_field_or_line','confidence','remaining_uncertainty', ...
    'recommended_action'});
end

function [z, info] = solve_flap_diagnostic(P, collective, viMean, z0)
z = z0(:);
info = empty_flap_info();
for k = 1:P.rotor.flapMaxIter
    [residual, aux] = flap_residual_diagnostic(P, collective, z, viMean);
    scaled = residual/aux.scale;
    residualNorm = norm(scaled);
    info.iterations = k;
    info.residual = residual;
    info.residualNorm = residualNorm;
    info.scale = aux.scale;
    if residualNorm <= P.rotor.flapResidualTol
        info.converged = true;
        info.exitStatus = 'converged';
        return;
    end

    J = zeros(3,3);
    for j = 1:3
        h = P.rotor.flapJacobianStep*max(1, abs(z(j)));
        zp = z;
        zm = z;
        zp(j) = zp(j)+h;
        zm(j) = zm(j)-h;
        rp = flap_residual_diagnostic(P, collective, zp, viMean);
        rm = flap_residual_diagnostic(P, collective, zm, viMean);
        J(:,j) = (rp/aux.scale-rm/aux.scale)/(2*h);
    end
    if ~all(isfinite(J(:))) || rcond(J.'*J) < 1e-14
        info.exitStatus = 'singular_jacobian';
        return;
    end
    dz = -(J.'*J+P.rotor.flapNewtonRegularization*eye(3)) \ ...
        (J.'*scaled);
    alpha = 1;
    accepted = false;
    for trial = 1:P.rotor.flapLineSearchMaxIter
        candidate = z+alpha*dz;
        if valid_flap_state(P, candidate)
            [candidateResidual, candidateAux] = ...
                flap_residual_diagnostic(P, collective, candidate, viMean);
            if norm(candidateResidual/candidateAux.scale) < residualNorm
                z = candidate;
                accepted = true;
                break;
            end
        end
        alpha = alpha*P.rotor.flapNewtonDamping;
    end
    if ~accepted
        info.exitStatus = 'line_search_failed';
        return;
    end
end
[residual, aux] = flap_residual_diagnostic(P, collective, z, viMean);
info.iterations = P.rotor.flapMaxIter;
info.residual = residual;
info.residualNorm = norm(residual/aux.scale);
info.scale = aux.scale;
info.exitStatus = 'max_iter';
end

function [residual, aux] = flap_residual_diagnostic(P, collective, z, viMean)
loads = blade_loads_diagnostic(P, collective, viMean, z);
gT = -P.env.g;
gravityMoment = P.rotor.Sblade*cos(loads.beta)*gT;
inertialRestoring = P.rotor.Ib*loads.betaDDot + ...
    P.rotor.Ib*P.rotor.Omega^2*loads.beta;
residualByAzimuth = inertialRestoring-loads.flapMomentByAzimuth- ...
    gravityMoment;
residual = [mean(residualByAzimuth); ...
    2*mean(residualByAzimuth.*cos(loads.psi)); ...
    2*mean(residualByAzimuth.*sin(loads.psi))];
aux.scale = max([max(abs(loads.flapMomentByAzimuth)), ...
    max(abs(gravityMoment)), P.rotor.Ib*P.rotor.Omega^2*0.05, 1]);
end

function loads = blade_loads_diagnostic(P, collective, viMean, zFlap)
r0 = P.rotor.rootCut*P.rotor.R;
rEdges = linspace(r0, P.rotor.R, P.rotor.nRadial+1);
rMid = 0.5*(rEdges(1:end-1)+rEdges(2:end));
dr = diff(rEdges);
psi = ((0:P.rotor.nAzimuth-1)*(2*pi/P.rotor.nAzimuth)).';
beta = zFlap(1)+zFlap(2)*cos(psi)+zFlap(3)*sin(psi);
betaDot = -P.rotor.Omega*(-zFlap(2)*sin(psi)+zFlap(3)*cos(psi));
betaDDot = -P.rotor.Omega^2*(zFlap(2)*cos(psi)+zFlap(3)*sin(psi));
twist = P.rotor.twistTip*(rMid-r0)/max(P.rotor.R-r0, eps);
thetaBlade = collective+twist;
UT = P.rotor.Omega*rMid+zeros(size(psi));
viField = viMean.*(1+cos(psi).*(rMid/P.rotor.R));
UP = viField-betaDot.*rMid;
W = hypot(UT, UP);
phiInflow = atan2(UP, max(abs(UT), 1e-8));
alphaBlade = thetaBlade-phiInflow;
CL = P.rotor.CLmax*tanh(P.rotor.liftSlope*alphaBlade/P.rotor.CLmax);
CD = P.rotor.CD0+P.rotor.kCD*CL.^2;
qElem = 0.5*P.env.rho*W.^2;
dL = qElem*P.rotor.chord.*CL.*dr;
dD = qElem*P.rotor.chord.*CD.*dr;
dT = dL.*cos(phiInflow)-dD.*sin(phiInflow);
dH = dD.*cos(phiInflow)+dL.*sin(phiInflow);
dQ = dH.*rMid;
factor = P.rotor.Nb/P.rotor.nAzimuth;

loads.T = factor*sum(dT(:));
loads.Q = factor*sum(dQ(:));
loads.psi = psi;
loads.rMid = rMid;
loads.dr = dr;
loads.beta = beta;
loads.betaDot = betaDot;
loads.betaDDot = betaDDot;
loads.flapMomentByAzimuth = sum(dT.*rMid, 2);
loads.thetaMean = mean(thetaBlade+zeros(size(psi)), 1);
loads.alphaMean = mean(alphaBlade, 1);
loads.alphaMin = min(alphaBlade, [], 1);
loads.alphaMax = max(alphaBlade, [], 1);
loads.radialThrust = factor*sum(dT, 1);
loads.dT = dT;
loads.UT = UT;
loads.UP = UP;
loads.minUT = min(UT(:));
loads.maxUT = max(UT(:));
end

function tf = valid_flap_state(P, z)
psi = (0:P.rotor.nAzimuth-1)*(2*pi/P.rotor.nAzimuth);
beta = z(1)+z(2)*cos(psi)+z(3)*sin(psi);
tf = all(isfinite(z)) && max(abs(beta)) < P.rotor.flapDivergenceAngle;
end

function pitchDeg = geometric_pitch_deg(P, collectiveDeg, stations)
r0Ratio = P.rotor.rootCut;
pitchDeg = collectiveDeg + P.rotor.twistTip*180/pi * ...
    (stations-r0Ratio)/(1-r0Ratio);
end

function value = initial_induced_velocity(P)
A = pi*P.rotor.R^2;
value = sqrt(max(P.mass.m*P.env.g/2, 1)/(2*P.env.rho*A));
end

function region = classify_thrust_region(thrust, P)
scale = P.mass.m*P.env.g/2;
if thrust < -0.01*scale
    region = 'NEGATIVE_THRUST_REGION';
elseif thrust > 0.01*scale
    region = 'NORMAL_POSITIVE_THRUST_REGION';
elseif isfinite(thrust)
    region = 'NEAR_ZERO_THRUST_REGION';
else
    region = 'UNCLASSIFIABLE_BY_CURRENT_MODEL';
end
end

function name = thrust_sign_name(thrust)
if thrust > 0
    name = 'POSITIVE_THRUST_ROOT';
elseif thrust < 0
    name = 'NEGATIVE_THRUST_ROOT';
else
    name = 'ZERO_THRUST_ROOT';
end
end

function write_environment_file(rootDir, outputDir, defaultVi, residualClass)
[statusHead, head] = system(sprintf('git -C "%s" rev-parse HEAD', rootDir));
[statusBranch, branch] = system(sprintf( ...
    'git -C "%s" branch --show-current', rootDir));
fid = fopen(fullfile(outputDir, 'LOW_COLLECTIVE_RUN_ENVIRONMENT.txt'), 'w');
if fid < 0
    error('low_collective_quick_audit:EnvironmentFileOpenFailed', ...
        'Could not create environment file.');
end
cleanupFile = onCleanup(@() fclose(fid));
fprintf(fid, 'timestamp=%s\n', datestr(now, 31));
fprintf(fid, 'matlab_version=%s\n', version);
fprintf(fid, 'computer=%s\n', computer);
fprintf(fid, 'operating_system=%s\n', getenv('OS'));
fprintf(fid, 'root=%s\n', rootDir);
fprintf(fid, 'output=%s\n', outputDir);
fprintf(fid, 'head_status=%d\n', statusHead);
fprintf(fid, 'head_sha=%s', head);
fprintf(fid, 'branch_status=%d\n', statusBranch);
fprintf(fid, 'branch=%s', branch);
fprintf(fid, 'default_initial_vi_mps=%.16g\n', defaultVi);
fprintf(fid, 'residual_classification=%s\n', residualClass);
fprintf(fid, ['scope=4,8,10,12 deg points; 11 residual samples at 8 deg; ' ...
    'two seeds at 8 and 10 deg\n']);
fprintf(fid, ['audit_command=MATLAB R2021a -batch "cd(worktree); ' ...
    'run(''startup.m''); result=low_collective_quick_audit;"\n']);
fprintf(fid, ['validation_command=MATLAB R2021a -batch "cd(worktree); ' ...
    'run(''startup.m''); check_low_collective_quick_audit; ' ...
    'check_rotor_force_moment_chain; check_flapping_model; ' ...
    'check_nuaa_public_formula_reference;"\n']);
fprintf(fid, ['complete_regression=NOT_RUN; PR58 recorded runtime is about ' ...
    '500 s and exceeds the several-minute confirmation threshold\n']);
fprintf(fid, 'production_model_modified=false\n');
fprintf(fid, 'default_parameters_modified=false\n');
clear cleanupFile;
end

function row = definition_row()
row = struct('category','','item','','nasa_definition','', ...
    'current_definition','','classification','','evidence','', ...
    'notes','','collective_deg',NaN,'pitch_025R_deg',NaN, ...
    'pitch_050R_deg',NaN,'pitch_075R_deg',NaN,'pitch_090R_deg',NaN);
end

function row = make_definition_row(category, item, nasaDefinition, ...
        currentDefinition, classification, evidence, notes)
row = definition_row();
row.category = category;
row.item = item;
row.nasa_definition = nasaDefinition;
row.current_definition = currentDefinition;
row.classification = classification;
row.evidence = evidence;
row.notes = notes;
end

function point = empty_point_result()
point = struct('initialVi',NaN,'finalVi',NaN,'converged',false, ...
    'exitReason','','iterations',0,'viError',Inf,'zFlap',NaN(3,1), ...
    'flap',empty_flap_info(),'loads',struct(),'history',struct([]), ...
    'momentumThrust',NaN,'closureResidual',NaN,'signJump',false, ...
    'branchSwitch',false,'denominatorNearZero',false,'hasNaN',false, ...
    'hasInf',false,'hasUnexpectedComplex',false);
end

function production = empty_production_result()
production = struct('success',false,'exitReason','NOT_RUN', ...
    'errorIdentifier','','errorMessage','','thrust',NaN,'torque',NaN, ...
    'inducedVelocity',NaN,'iterations',NaN,'viError',NaN, ...
    'flapResidualNorm',NaN);
end

function info = empty_flap_info()
info = struct('converged',false,'iterations',0,'residual',NaN(3,1), ...
    'residualNorm',Inf,'scale',NaN,'exitStatus','not_started');
end

function loads = empty_loads(P)
loads = struct('T',NaN,'Q',NaN,'psi',[],'rMid',[], ...
    'dr',[],'beta',[],'betaDot',[],'betaDDot',[], ...
    'flapMomentByAzimuth',[],'thetaMean',NaN(1,P.rotor.nRadial), ...
    'alphaMean',NaN(1,P.rotor.nRadial), ...
    'alphaMin',NaN(1,P.rotor.nRadial), ...
    'alphaMax',NaN(1,P.rotor.nRadial), ...
    'radialThrust',NaN(1,P.rotor.nRadial),'dT',[],'UT',[],'UP',[], ...
    'minUT',NaN,'maxUT',NaN);
end

function values = sign_nonzero(values)
values = sign(values);
for k = 2:numel(values)
    if values(k) == 0
        values(k) = values(k-1);
    end
end
end

function tf = numeric_has_nan(point)
values = [point.finalVi, point.loads.T, point.loads.Q, ...
    point.flap.residualNorm, [point.history.viOld], ...
    [point.history.viTarget], [point.history.viNew], ...
    [point.history.thrust]];
tf = any(isnan(values));
end

function tf = numeric_has_inf(point)
values = [point.finalVi, point.loads.T, point.loads.Q, ...
    point.flap.residualNorm, [point.history.viOld], ...
    [point.history.viTarget], [point.history.viNew], ...
    [point.history.thrust]];
tf = any(isinf(values));
end

function tf = numeric_has_complex(point)
values = [point.finalVi, point.loads.T, point.loads.Q, ...
    point.flap.residualNorm, [point.history.viOld], ...
    [point.history.viTarget], [point.history.viNew], ...
    [point.history.thrust]];
tf = ~isreal(values);
end

function value = ternary(condition, a, b)
if condition
    value = a;
else
    value = b;
end
end
