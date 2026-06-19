function report = near_normal_branch_diagnostics()
%NEAR_NORMAL_BRANCH_DIAGNOSTICS Diagnose wing near-normal switch vs trim branches.
%
% This script is diagnostic only. It does not modify model physics, trim
% thresholds, trim_symmetric, or nominal parameters.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'analysis'));

P = params_nominal();

resultDir = fullfile(rootDir, 'results');
if ~exist(resultDir, 'dir')
    mkdir(resultDir);
end

stamp = datestr(now, 'yyyymmdd_HHMMSS');
paths.log = fullfile(resultDir, ...
    ['near_normal_branch_diagnostics_run_' stamp '.log']);
paths.summary = fullfile(resultDir, ...
    ['near_normal_branch_diagnostics_' stamp '.txt']);
paths.scanCsv = fullfile(resultDir, ...
    ['near_normal_branch_scan_' stamp '.csv']);
paths.wingCsv = fullfile(resultDir, ...
    ['near_normal_branch_wing_regions_' stamp '.csv']);
paths.perturbCsv = fullfile(resultDir, ...
    ['near_normal_branch_perturb_' stamp '.csv']);
paths.mat = fullfile(resultDir, ...
    ['near_normal_branch_diagnostics_' stamp '.mat']);

lastwarn('');
diary(paths.log);
cleanupObj = onCleanup(@() diary('off')); %#ok<NASGU>

cfg = make_config(P);

fprintf('\nNear-normal wing switch / trim branch diagnostics\n');
fprintf('=================================================\n');
fprintf('Generated: %s\n', datestr(now, 31));
fprintf('Speed grid: %.2f:%.2f:%.2f m/s\n', ...
    cfg.speeds(1), cfg.speeds(2)-cfg.speeds(1), cfg.speeds(end));
fprintf('normalFlowRatio: %.12g\n', cfg.normalFlowRatio);
fprintf('formal residual threshold: %.12g\n', cfg.formalThreshold);
fprintf('high-precision residual threshold: %.12g\n', ...
    cfg.highPrecisionThreshold);
fprintf('Low theta seed deg:  [%.9f %.9f %.9f]\n', cfg.lowSeedDeg);
fprintf('High theta seed deg: [%.9f %.9f %.9f]\n', cfg.highSeedDeg);

report.generatedAt = datestr(now, 31);
report.paths = paths;
report.config = cfg;
report.scan = run_dual_seed_scan(P, cfg);
report.perturbationStudies = run_perturbation_studies(P, cfg);
report.analysis = analyze_results(report);
[warnMsg, warnId] = lastwarn;
report.lastWarning = struct('id', warnId, 'message', warnMsg);

write_summary(report, paths.summary);
write_scan_csv(report, paths.scanCsv);
write_wing_region_csv(report, paths.wingCsv);
write_perturb_csv(report, paths.perturbCsv);
save(paths.mat, 'report', '-v7');

fprintf('\nSaved summary: %s\n', paths.summary);
fprintf('Saved scan CSV: %s\n', paths.scanCsv);
fprintf('Saved wing-region CSV: %s\n', paths.wingCsv);
fprintf('Saved perturb CSV: %s\n', paths.perturbCsv);
fprintf('Saved MAT: %s\n', paths.mat);
fprintf('Saved diary log: %s\n', paths.log);
if isempty(warnMsg)
    fprintf('MATLAB lastwarn: none\n');
else
    fprintf('MATLAB lastwarn: [%s] %s\n', warnId, warnMsg);
end
end

function cfg = make_config(P)
cfg.betaM = 0;
cfg.gamma = 0;
cfg.speeds = 9.04:0.01:9.31;
cfg.formalThreshold = P.trim.residualTolerance;
cfg.highPrecisionThreshold = 1.0e-6;
cfg.normalFlowRatio = P.wing.normalFlowRatio;
cfg.thetaPerturbationsRad = [1.0e-3, 3.0e-4, 1.0e-4, 3.0e-5, 1.0e-5];

% Seeds are in trim variables [theta, collective, cyclicLong], deg.
% They are diagnostic seeds taken from existing local branch neighborhoods,
% not new physical parameters.
cfg.lowSeedDeg = [-1.266147044, 16.930183368, 0.194724099];
cfg.highSeedDeg = [6.657839472, 16.248538726, 2.350802292];
cfg.highV906SeedDeg = [6.734621267, 16.268379643, 2.392635643];
cfg.lowV930SeedDeg = [-1.294197476, 16.905025308, 0.202765362];
end

function attempts = run_dual_seed_scan(P, cfg)
nV = numel(cfg.speeds);
attempts = repmat(make_empty_attempt(), nV, 2);

fprintf('\nDual-seed local solves\n');
fprintf('----------------------\n');
fprintf(['V source theta_deg collective_deg cyclicLong_deg residualNorm ' ...
    'formal highPrecision Lratio Lnear Rratio Rnear Lwake Rwake ' ...
    'viL iterL viR iterR exit iter func\n']);

for k = 1:nV
    V = cfg.speeds(k);
    attempts(k, 1) = solve_once(V, cfg.lowSeedDeg, 'low_theta_seed', P, cfg);
    attempts(k, 2) = solve_once(V, cfg.highSeedDeg, 'high_theta_seed', P, cfg);
    for j = 1:2
        a = attempts(k, j);
        leftSlip = slip_region_by_side(a.diagnostics, -1);
        rightSlip = slip_region_by_side(a.diagnostics, 1);
        rL = a.diagnostics.rotorLeft;
        rR = a.diagnostics.rotorRight;
        fprintf(['%.2f %s %.9f %.9f %.9f %.12e %d %d ' ...
            '%.12e %d %.12e %d %.12e %.12e %.12e %.0f %.12e %.0f ' ...
            '%d %.0f %.0f\n'], ...
            a.V, a.source, a.solutionDeg(1), a.solutionDeg(2), ...
            a.solutionDeg(3), a.residualNorm, a.formalAccepted, ...
            a.highPrecisionRoot, leftSlip.ratio, leftSlip.nearNormal, ...
            rightSlip.ratio, rightSlip.nearNormal, leftSlip.wakeVelocity, ...
            rightSlip.wakeVelocity, rL.inducedVelocity, rL.iterations, ...
            rR.inducedVelocity, rR.iterations, a.exitflag, ...
            a.iterations, a.funcCount);
    end
end
end

function studies = run_perturbation_studies(P, cfg)
studies = repmat(make_empty_study(), 2, 1);

studies(1) = run_one_perturbation_study( ...
    'V9p06_high_theta_candidate', 9.06, cfg.highV906SeedDeg, P, cfg);
studies(2) = run_one_perturbation_study( ...
    'V9p30_low_theta_failed_point', 9.30, cfg.lowV930SeedDeg, P, cfg);
end

function study = run_one_perturbation_study(name, V, seedDeg, P, cfg)
study = make_empty_study();
study.name = name;
study.V = V;
study.seedDeg = seedDeg;
study.baseAttempt = solve_once(V, seedDeg, name, P, cfg);

baseR = study.baseAttempt.residual(:);
baseDiag = study.baseAttempt.diagnostics;
nH = numel(cfg.thetaPerturbationsRad);
records = repmat(make_empty_perturb_record(), nH, 2);
stepPairs = repmat(make_empty_step_pair(), nH, 1);

fprintf('\nTheta one-sided perturbation study: %s\n', name);
fprintf('----------------------------------------\n');
fprintf('Base solution deg: [%.9f %.9f %.9f]\n', ...
    study.baseAttempt.solutionDeg);
fprintf('Base residual norm: %.12e formal=%d highPrecision=%d\n', ...
    study.baseAttempt.residualNorm, study.baseAttempt.formalAccepted, ...
    study.baseAttempt.highPrecisionRoot);
fprintf(['h sign crossedAny changedAny residualNorm dUdot dWdot dQdot ' ...
    'Lbase Lpert Lcross Rbase Rpert Rcross\n']);

for ih = 1:nH
    h = cfg.thetaPerturbationsRad(ih);
    for idir = 1:2
        sgn = -1;
        if idir == 2
            sgn = 1;
        end
        zPert = study.baseAttempt.zRad(:);
        zPert(1) = zPert(1) + sgn*h;
        [xPert, uPert, residualPert, diagPert] = ...
            evaluate_trim_variables(V, zPert, P, cfg);

        rec = make_empty_perturb_record();
        rec.studyName = name;
        rec.V = V;
        rec.hRad = h;
        rec.direction = sgn;
        rec.thetaPerturbedDeg = zPert(1)*180/pi;
        rec.x = xPert;
        rec.uCtrl = uPert;
        rec.residual = residualPert(:);
        rec.residualNorm = norm(residualPert);
        rec.deltaResidual = rec.residual - baseR;
        rec.oneSidedDerivative = rec.deltaResidual/(sgn*h);
        rec.left = crossing_report(baseDiag, diagPert, -1);
        rec.right = crossing_report(baseDiag, diagPert, 1);
        rec.crossedAny = rec.left.crossed || rec.right.crossed;
        rec.changedAny = rec.left.changed || rec.right.changed;
        rec.diagnostics = diagPert;
        rec.finite = is_real_finite([xPert(:); uPert(:); residualPert(:)]) && ...
            diagPert.finite;
        records(ih, idir) = rec;

        fprintf(['%.1e %+d %d %d %.12e %.12e %.12e %.12e ' ...
            '%.12e %.12e %d %.12e %.12e %d\n'], ...
            h, sgn, rec.crossedAny, rec.changedAny, rec.residualNorm, ...
            rec.deltaResidual(1), rec.deltaResidual(2), ...
            rec.deltaResidual(3), rec.left.baseRatio, ...
            rec.left.perturbedRatio, rec.left.crossed, ...
            rec.right.baseRatio, rec.right.perturbedRatio, ...
            rec.right.crossed);
    end

    minusRec = records(ih, 1);
    plusRec = records(ih, 2);
    pair = make_empty_step_pair();
    pair.hRad = h;
    pair.residualPlusMinusGap = plusRec.residual - minusRec.residual;
    pair.gapNorm = norm(pair.residualPlusMinusGap);
    pair.derivativeMismatch = ...
        plusRec.oneSidedDerivative - minusRec.oneSidedDerivative;
    pair.derivativeMismatchNorm = norm(pair.derivativeMismatch);
    pair.crossedAny = plusRec.crossedAny || minusRec.crossedAny;
    pair.changedAny = plusRec.changedAny || minusRec.changedAny;
    stepPairs(ih) = pair;
end

study.records = records;
study.stepPairs = stepPairs;
end

function attempt = solve_once(V, seedDeg, source, P, cfg)
opts.gamma = cfg.gamma;
opts.initialDeg = seedDeg;
opts.useMultiStart = false;
opts.alwaysMultiStart = false;

[xTrim, uTrim, info] = trim_symmetric(V, cfg.betaM, P, opts);
z = [xTrim(8); uTrim(1); uTrim(3)];

attempt = make_empty_attempt();
attempt.V = V;
attempt.source = source;
attempt.initialDeg = seedDeg;
attempt.solutionDeg = z(:).'*180/pi;
attempt.zRad = z(:);
attempt.xTrim = xTrim(:);
attempt.uTrim = uTrim(:);
attempt.residual = info.residual(:);
attempt.residualNorm = info.residualNorm;
attempt.exitflag = info.exitflag;
attempt.iterations = get_output_number(info.output, 'iterations');
attempt.funcCount = get_output_number(info.output, 'funcCount');
attempt.formalAccepted = info.residualNorm <= cfg.formalThreshold;
attempt.highPrecisionRoot = info.residualNorm <= cfg.highPrecisionThreshold;
attempt.solverConverged = info.solverConverged;
attempt.finiteFullStateDerivative = info.finiteFullStateDerivative;
attempt.atLimit = info.atLimit;
attempt.withinLimits = info.withinLimits;
attempt.diagnostics = point_diagnostics(xTrim, uTrim, cfg.betaM, P);
attempt.finite = is_real_finite([xTrim(:); uTrim(:); info.residual(:)]) && ...
    attempt.diagnostics.finite;
end

function [x, uCtrl, residual, diagOut] = evaluate_trim_variables(V, z, P, cfg)
theta = z(1);
collective = z(2);
cyclicLong = z(3);
alpha = theta - cfg.gamma;
u = V*cos(alpha);
w = V*sin(alpha);
x = [u; 0; w; 0; 0; 0; 0; theta; 0];
uCtrl = [collective; 0; cyclicLong; 0; 0; 0; 0];
[xdot, ~] = tiltrotor_eom(x, uCtrl, cfg.betaM, P);
residual = [xdot(1); xdot(3); xdot(5)];
diagOut = point_diagnostics(x, uCtrl, cfg.betaM, P);
end

function diagOut = point_diagnostics(x, uCtrl, betaM, P)
[~, eomOut] = tiltrotor_eom(x, uCtrl, betaM, P);
components = eomOut.components;

diagOut = make_empty_diagnostics();
diagOut.Ftotal = eomOut.Ftotal(:);
diagOut.Mtotal = eomOut.Mtotal(:);
diagOut.FaeroProp = eomOut.FaeroProp(:);
diagOut.Fgravity = eomOut.Fgravity(:);
diagOut.xdot = eomOut.xdot(:);
diagOut.rotorLeft = rotor_summary(components.rotorLeft, 'rotorLeft');
diagOut.rotorRight = rotor_summary(components.rotorRight, 'rotorRight');
diagOut.wingF = components.wing.F(:);
diagOut.wingM = components.wing.M(:);

regions = components.wing.regions;
diagOut.wingRegions = repmat(make_empty_region(), numel(regions), 1);
for i = 1:numel(regions)
    diagOut.wingRegions(i) = region_summary(regions{i}, i, P);
end

diagOut.finite = is_real_finite([diagOut.Ftotal; diagOut.Mtotal; ...
    diagOut.FaeroProp; diagOut.Fgravity; diagOut.xdot; ...
    diagOut.wingF; diagOut.wingM]) && ...
    diagOut.rotorLeft.finite && diagOut.rotorRight.finite && ...
    all([diagOut.wingRegions.finite]);
end

function rotor = rotor_summary(data, name)
rotor = make_empty_rotor();
rotor.name = name;
rotor.inducedVelocity = get_numeric_field(data, 'inducedVelocity', NaN);
rotor.iterations = get_numeric_field(data, 'iterations', NaN);
rotor.thrust = get_numeric_field(data, 'thrust', NaN);
rotor.torque = get_numeric_field(data, 'torque', NaN);
rotor.muLong = get_numeric_field(data, 'muLong', NaN);
rotor.muLat = get_numeric_field(data, 'muLat', NaN);
rotor.F = get_vector_field(data, 'F');
rotor.M = get_vector_field(data, 'M');
rotor.finite = is_real_finite([rotor.inducedVelocity; rotor.iterations; ...
    rotor.thrust; rotor.torque; rotor.muLong; rotor.muLat; ...
    rotor.F(:); rotor.M(:)]);
end

function region = region_summary(data, index, P)
region = make_empty_region();
region.index = index;
region.area = get_numeric_field(data, 'area', NaN);
region.side = get_numeric_field(data, 'side', NaN);
if isfield(data, 'inSlipstream')
    region.inSlipstream = logical(data.inSlipstream);
end
region.wakeVelocity = get_numeric_field(data, 'wakeVelocity', NaN);
region.rAC = get_vector_field(data, 'rAC');
region.Vlocal = get_vector_field(data, 'Vlocal');
region.V = get_numeric_field(data, 'V', norm(region.Vlocal));
region.ratio = abs(region.Vlocal(1))/max(norm(region.Vlocal), realmin);
region.margin = region.ratio - P.wing.normalFlowRatio;
region.nearNormal = region.ratio < P.wing.normalFlowRatio;
region.alpha = get_numeric_field(data, 'alpha', NaN);
region.beta = get_numeric_field(data, 'beta', NaN);
region.CL = get_numeric_field(data, 'CL', NaN);
region.CD = get_numeric_field(data, 'CD', NaN);
region.Cm = get_numeric_field(data, 'Cm', NaN);
region.F = get_vector_field(data, 'F');
region.M = get_vector_field(data, 'M');
region.finite = is_real_finite([region.area; region.side; ...
    region.wakeVelocity; region.rAC(:); region.Vlocal(:); region.V; ...
    region.ratio; region.margin; region.alpha; region.beta; ...
    region.CL; region.CD; region.Cm; region.F(:); region.M(:)]);
end

function out = crossing_report(baseDiag, pertDiag, side)
baseRegion = slip_region_by_side(baseDiag, side);
pertRegion = slip_region_by_side(pertDiag, side);
out = make_empty_crossing();
out.side = side;
out.baseRatio = baseRegion.ratio;
out.perturbedRatio = pertRegion.ratio;
out.baseMargin = baseRegion.margin;
out.perturbedMargin = pertRegion.margin;
out.baseNearNormal = baseRegion.nearNormal;
out.perturbedNearNormal = pertRegion.nearNormal;
out.changed = xor(baseRegion.nearNormal, pertRegion.nearNormal);
if isfinite(out.baseMargin) && isfinite(out.perturbedMargin)
    out.crossed = out.changed || out.baseMargin == 0 || ...
        out.perturbedMargin == 0 || sign(out.baseMargin) ~= sign(out.perturbedMargin);
else
    out.crossed = false;
end
end

function region = slip_region_by_side(diagOut, side)
regions = diagOut.wingRegions;
region = make_empty_region();
for i = 1:numel(regions)
    if regions(i).inSlipstream && regions(i).side == side
        region = regions(i);
        return;
    end
end
end

function analysis = analyze_results(report)
analysis = struct();
attempts = report.scan;

analysis.low = branch_acceptance_summary(attempts(:, 1));
analysis.high = branch_acceptance_summary(attempts(:, 2));
analysis.nearNormalSwitches = find_near_normal_switches(attempts);
analysis.closestSlipMargin = closest_slip_margin(attempts);
analysis.anyBadNumeric = any(~[attempts(:).finite]);

studies = report.perturbationStudies;
analysis.perturbationCrossings = repmat(struct( ...
    'name', '', 'anyCrossed', false, 'anyChanged', false, ...
    'maxGapNorm', NaN, 'maxDerivativeMismatchNorm', NaN), ...
    numel(studies), 1);
for i = 1:numel(studies)
    pairs = studies(i).stepPairs;
    analysis.perturbationCrossings(i).name = studies(i).name;
    analysis.perturbationCrossings(i).anyCrossed = any([pairs.crossedAny]);
    analysis.perturbationCrossings(i).anyChanged = any([pairs.changedAny]);
    analysis.perturbationCrossings(i).maxGapNorm = max([pairs.gapNorm]);
    analysis.perturbationCrossings(i).maxDerivativeMismatchNorm = ...
        max([pairs.derivativeMismatchNorm]);
end
end

function summary = branch_acceptance_summary(attempts)
summary = struct('firstFormalV', NaN, 'lastFormalV', NaN, ...
    'firstHighPrecisionV', NaN, 'lastHighPrecisionV', NaN, ...
    'firstFormalFailureAfterAcceptanceV', NaN, ...
    'residuals', [attempts.residualNorm]);
formal = [attempts.formalAccepted];
hi = [attempts.highPrecisionRoot];
V = [attempts.V];
idx = find(formal);
if ~isempty(idx)
    summary.firstFormalV = V(idx(1));
    summary.lastFormalV = V(idx(end));
end
idx = find(hi);
if ~isempty(idx)
    summary.firstHighPrecisionV = V(idx(1));
    summary.lastHighPrecisionV = V(idx(end));
end
for i = 2:numel(formal)
    if formal(i-1) && ~formal(i)
        summary.firstFormalFailureAfterAcceptanceV = V(i);
        break;
    end
end
end

function switches = find_near_normal_switches(attempts)
switches = repmat(struct('source', '', 'side', NaN, 'Vbefore', NaN, ...
    'Vafter', NaN, 'ratioBefore', NaN, 'ratioAfter', NaN), 0, 1);
for col = 1:size(attempts, 2)
    for side = [-1, 1]
        previous = slip_region_by_side(attempts(1, col).diagnostics, side);
        for k = 2:size(attempts, 1)
            current = slip_region_by_side(attempts(k, col).diagnostics, side);
            if previous.nearNormal ~= current.nearNormal
                item = struct('source', attempts(k, col).source, ...
                    'side', side, 'Vbefore', attempts(k-1, col).V, ...
                    'Vafter', attempts(k, col).V, ...
                    'ratioBefore', previous.ratio, ...
                    'ratioAfter', current.ratio);
                switches(end+1, 1) = item; %#ok<AGROW>
            end
            previous = current;
        end
    end
end
end

function closest = closest_slip_margin(attempts)
closest = struct('absMargin', Inf, 'margin', NaN, 'V', NaN, ...
    'source', '', 'side', NaN, 'ratio', NaN, 'nearNormal', false);
for i = 1:numel(attempts)
    regions = attempts(i).diagnostics.wingRegions;
    for j = 1:numel(regions)
        if regions(j).inSlipstream && abs(regions(j).margin) < closest.absMargin
            closest.absMargin = abs(regions(j).margin);
            closest.margin = regions(j).margin;
            closest.V = attempts(i).V;
            closest.source = attempts(i).source;
            closest.side = regions(j).side;
            closest.ratio = regions(j).ratio;
            closest.nearNormal = regions(j).nearNormal;
        end
    end
end
end

function write_summary(report, filePath)
fid = fopen(filePath, 'w');
if fid < 0
    warning('Could not open summary for writing: %s', filePath);
    return;
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

cfg = report.config;
fprintf(fid, 'Near-normal wing switch / trim branch diagnostics\n');
fprintf(fid, 'Generated: %s\n\n', report.generatedAt);
fprintf(fid, 'Scope\n');
fprintf(fid, '-----\n');
fprintf(fid, 'Speed grid: %.2f:%.2f:%.2f m/s\n', ...
    cfg.speeds(1), cfg.speeds(2)-cfg.speeds(1), cfg.speeds(end));
fprintf(fid, 'betaM=%.12g rad, gamma=%.12g rad\n', cfg.betaM, cfg.gamma);
fprintf(fid, 'normalFlowRatio=%.12g\n', cfg.normalFlowRatio);
fprintf(fid, 'formal acceptance residual <= %.12e\n', cfg.formalThreshold);
fprintf(fid, 'high-precision root residual <= %.12e\n', ...
    cfg.highPrecisionThreshold);
fprintf(fid, 'low theta seed deg=[%.9f %.9f %.9f]\n', cfg.lowSeedDeg);
fprintf(fid, 'high theta seed deg=[%.9f %.9f %.9f]\n\n', cfg.highSeedDeg);

fprintf(fid, 'Dual-seed scan summary\n');
fprintf(fid, '----------------------\n');
fprintf(fid, ['V source theta_deg collective_deg cyclicLong_deg residualNorm ' ...
    'formal highPrecision leftRatio leftNear rightRatio rightNear ' ...
    'leftWake rightWake viLeft iterLeft viRight iterRight\n']);
attempts = report.scan;
for i = 1:numel(attempts)
    a = attempts(i);
    leftSlip = slip_region_by_side(a.diagnostics, -1);
    rightSlip = slip_region_by_side(a.diagnostics, 1);
    fprintf(fid, ['%.2f %s %.9f %.9f %.9f %.12e %d %d ' ...
        '%.12e %d %.12e %d %.12e %.12e %.12e %.0f %.12e %.0f\n'], ...
        a.V, a.source, a.solutionDeg(1), a.solutionDeg(2), ...
        a.solutionDeg(3), a.residualNorm, a.formalAccepted, ...
        a.highPrecisionRoot, leftSlip.ratio, leftSlip.nearNormal, ...
        rightSlip.ratio, rightSlip.nearNormal, leftSlip.wakeVelocity, ...
        rightSlip.wakeVelocity, a.diagnostics.rotorLeft.inducedVelocity, ...
        a.diagnostics.rotorLeft.iterations, ...
        a.diagnostics.rotorRight.inducedVelocity, ...
        a.diagnostics.rotorRight.iterations);
end

fprintf(fid, '\nAcceptance ranges\n');
fprintf(fid, '-----------------\n');
fprintf(fid, ['low seed: firstFormalV=%.2f lastFormalV=%.2f ' ...
    'firstHighPrecisionV=%.2f lastHighPrecisionV=%.2f ' ...
    'firstFormalFailureAfterAcceptanceV=%.2f\n'], ...
    report.analysis.low.firstFormalV, report.analysis.low.lastFormalV, ...
    report.analysis.low.firstHighPrecisionV, ...
    report.analysis.low.lastHighPrecisionV, ...
    report.analysis.low.firstFormalFailureAfterAcceptanceV);
fprintf(fid, ['high seed: firstFormalV=%.2f lastFormalV=%.2f ' ...
    'firstHighPrecisionV=%.2f lastHighPrecisionV=%.2f ' ...
    'firstFormalFailureAfterAcceptanceV=%.2f\n'], ...
    report.analysis.high.firstFormalV, report.analysis.high.lastFormalV, ...
    report.analysis.high.firstHighPrecisionV, ...
    report.analysis.high.lastHighPrecisionV, ...
    report.analysis.high.firstFormalFailureAfterAcceptanceV);

fprintf(fid, '\nNear-normal switch scan events\n');
fprintf(fid, '------------------------------\n');
if isempty(report.analysis.nearNormalSwitches)
    fprintf(fid, 'none on the solved grid\n');
else
    for i = 1:numel(report.analysis.nearNormalSwitches)
        s = report.analysis.nearNormalSwitches(i);
        fprintf(fid, ['source=%s side=%+.0f Vbefore=%.2f Vafter=%.2f ' ...
            'ratioBefore=%.12e ratioAfter=%.12e\n'], ...
            s.source, s.side, s.Vbefore, s.Vafter, ...
            s.ratioBefore, s.ratioAfter);
    end
end
cm = report.analysis.closestSlipMargin;
fprintf(fid, ['closest slip margin: source=%s V=%.2f side=%+.0f ' ...
    'ratio=%.12e margin=%.12e nearNormal=%d\n'], ...
    cm.source, cm.V, cm.side, cm.ratio, cm.margin, cm.nearNormal);

fprintf(fid, '\nTheta one-sided perturbation studies\n');
fprintf(fid, '------------------------------------\n');
for i = 1:numel(report.perturbationStudies)
    study = report.perturbationStudies(i);
    base = study.baseAttempt;
    fprintf(fid, '\n%s\n', study.name);
    fprintf(fid, ['base V=%.2f seedDeg=[%.9f %.9f %.9f] ' ...
        'solutionDeg=[%.9f %.9f %.9f] residualNorm=%.12e ' ...
        'formal=%d highPrecision=%d\n'], ...
        study.V, study.seedDeg, base.solutionDeg, base.residualNorm, ...
        base.formalAccepted, base.highPrecisionRoot);
    fprintf(fid, ['h sign crossedAny changedAny residualNorm ' ...
        'dUdot dWdot dQdot dUdot_dtheta dWdot_dtheta dQdot_dtheta ' ...
        'leftBase leftPert leftCross rightBase rightPert rightCross\n']);
    records = study.records;
    for j = 1:numel(records)
        r = records(j);
        fprintf(fid, ['%.12e %+d %d %d %.12e %.12e %.12e %.12e ' ...
            '%.12e %.12e %.12e %.12e %.12e %d %.12e %.12e %d\n'], ...
            r.hRad, r.direction, r.crossedAny, r.changedAny, ...
            r.residualNorm, r.deltaResidual(1), r.deltaResidual(2), ...
            r.deltaResidual(3), r.oneSidedDerivative(1), ...
            r.oneSidedDerivative(2), r.oneSidedDerivative(3), ...
            r.left.baseRatio, r.left.perturbedRatio, r.left.crossed, ...
            r.right.baseRatio, r.right.perturbedRatio, r.right.crossed);
    end
    fprintf(fid, 'step-pair residual jump checks\n');
    fprintf(fid, ['h gapNorm dUdotGap dWdotGap dQdotGap ' ...
        'derivativeMismatchNorm crossedAny changedAny\n']);
    for j = 1:numel(study.stepPairs)
        p = study.stepPairs(j);
        fprintf(fid, ['%.12e %.12e %.12e %.12e %.12e %.12e %d %d\n'], ...
            p.hRad, p.gapNorm, p.residualPlusMinusGap(1), ...
            p.residualPlusMinusGap(2), p.residualPlusMinusGap(3), ...
            p.derivativeMismatchNorm, p.crossedAny, p.changedAny);
    end
end

fprintf(fid, '\nNumeric flags\n');
fprintf(fid, '-------------\n');
fprintf(fid, 'anyBadNumeric=%d\n', report.analysis.anyBadNumeric);
if isempty(report.lastWarning.message)
    fprintf(fid, 'lastwarn=none\n');
else
    fprintf(fid, 'lastwarn=[%s] %s\n', ...
        report.lastWarning.id, report.lastWarning.message);
end
fprintf(fid, '\nArtifact paths\n');
fprintf(fid, '--------------\n');
fprintf(fid, 'summary=%s\n', report.paths.summary);
fprintf(fid, 'scanCsv=%s\n', report.paths.scanCsv);
fprintf(fid, 'wingCsv=%s\n', report.paths.wingCsv);
fprintf(fid, 'perturbCsv=%s\n', report.paths.perturbCsv);
fprintf(fid, 'mat=%s\n', report.paths.mat);
fprintf(fid, 'log=%s\n', report.paths.log);
end

function write_scan_csv(report, filePath)
fid = fopen(filePath, 'w');
if fid < 0
    warning('Could not open scan CSV for writing: %s', filePath);
    return;
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, ['V,source,initialThetaDeg,initialCollectiveDeg,' ...
    'initialCyclicLongDeg,thetaDeg,collectiveDeg,cyclicLongDeg,' ...
    'residualNorm,formalAccepted,highPrecisionRoot,exitflag,' ...
    'iterations,funcCount,finite,solverConverged,atLimit,withinLimits,' ...
    'leftSlipRatio,leftSlipNearNormal,leftSlipWakeVelocity,' ...
    'rightSlipRatio,rightSlipNearNormal,rightSlipWakeVelocity,' ...
    'rotorLeftInducedVelocity,rotorLeftIterations,' ...
    'rotorRightInducedVelocity,rotorRightIterations\n']);
attempts = report.scan;
for i = 1:numel(attempts)
    a = attempts(i);
    leftSlip = slip_region_by_side(a.diagnostics, -1);
    rightSlip = slip_region_by_side(a.diagnostics, 1);
    fprintf(fid, ['%.12g,%s,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,' ...
        '%.12e,%d,%d,%d,%.0f,%.0f,%d,%d,%d,%d,' ...
        '%.12e,%d,%.12e,%.12e,%d,%.12e,%.12e,%.0f,%.12e,%.0f\n'], ...
        a.V, a.source, a.initialDeg(1), a.initialDeg(2), ...
        a.initialDeg(3), a.solutionDeg(1), a.solutionDeg(2), ...
        a.solutionDeg(3), a.residualNorm, a.formalAccepted, ...
        a.highPrecisionRoot, a.exitflag, a.iterations, a.funcCount, ...
        a.finite, a.solverConverged, a.atLimit, a.withinLimits, ...
        leftSlip.ratio, leftSlip.nearNormal, leftSlip.wakeVelocity, ...
        rightSlip.ratio, rightSlip.nearNormal, rightSlip.wakeVelocity, ...
        a.diagnostics.rotorLeft.inducedVelocity, ...
        a.diagnostics.rotorLeft.iterations, ...
        a.diagnostics.rotorRight.inducedVelocity, ...
        a.diagnostics.rotorRight.iterations);
end
end

function write_wing_region_csv(report, filePath)
fid = fopen(filePath, 'w');
if fid < 0
    warning('Could not open wing-region CSV for writing: %s', filePath);
    return;
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, ['V,source,regionIndex,side,inSlipstream,area,ratio,' ...
    'nearNormal,margin,wakeVelocity,V,VlocalX,VlocalY,VlocalZ,' ...
    'Fx,Fy,Fz,Mx,My,Mz,alpha,beta,CL,CD,Cm\n']);
attempts = report.scan;
for i = 1:numel(attempts)
    a = attempts(i);
    regions = a.diagnostics.wingRegions;
    for j = 1:numel(regions)
        r = regions(j);
        fprintf(fid, ['%.12g,%s,%d,%.0f,%d,%.12e,%.12e,%d,' ...
            '%.12e,%.12e,%.12e,%.12e,%.12e,%.12e,' ...
            '%.12e,%.12e,%.12e,%.12e,%.12e,%.12e,' ...
            '%.12e,%.12e,%.12e,%.12e,%.12e\n'], ...
            a.V, a.source, r.index, r.side, r.inSlipstream, ...
            r.area, r.ratio, r.nearNormal, r.margin, ...
            r.wakeVelocity, r.V, r.Vlocal(1), r.Vlocal(2), ...
            r.Vlocal(3), r.F(1), r.F(2), r.F(3), ...
            r.M(1), r.M(2), r.M(3), r.alpha, r.beta, ...
            r.CL, r.CD, r.Cm);
    end
end
end

function write_perturb_csv(report, filePath)
fid = fopen(filePath, 'w');
if fid < 0
    warning('Could not open perturb CSV for writing: %s', filePath);
    return;
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, ['studyName,V,hRad,direction,thetaPerturbedDeg,' ...
    'residualNorm,dUdot,dWdot,dQdot,dUdot_dtheta,dWdot_dtheta,' ...
    'dQdot_dtheta,leftBaseRatio,leftPerturbedRatio,leftCrossed,' ...
    'leftChanged,rightBaseRatio,rightPerturbedRatio,rightCrossed,' ...
    'rightChanged,crossedAny,changedAny,finite\n']);
studies = report.perturbationStudies;
for i = 1:numel(studies)
    records = studies(i).records;
    for j = 1:numel(records)
        r = records(j);
        fprintf(fid, ['%s,%.12g,%.12e,%+d,%.12g,%.12e,' ...
            '%.12e,%.12e,%.12e,%.12e,%.12e,%.12e,' ...
            '%.12e,%.12e,%d,%d,%.12e,%.12e,%d,%d,%d,%d,%d\n'], ...
            r.studyName, r.V, r.hRad, r.direction, ...
            r.thetaPerturbedDeg, r.residualNorm, ...
            r.deltaResidual(1), r.deltaResidual(2), ...
            r.deltaResidual(3), r.oneSidedDerivative(1), ...
            r.oneSidedDerivative(2), r.oneSidedDerivative(3), ...
            r.left.baseRatio, r.left.perturbedRatio, r.left.crossed, ...
            r.left.changed, r.right.baseRatio, r.right.perturbedRatio, ...
            r.right.crossed, r.right.changed, r.crossedAny, ...
            r.changedAny, r.finite);
    end
end
end

function attempt = make_empty_attempt()
attempt = struct('V', NaN, 'source', '', ...
    'initialDeg', [NaN, NaN, NaN], ...
    'solutionDeg', [NaN, NaN, NaN], 'zRad', [NaN; NaN; NaN], ...
    'xTrim', NaN(9, 1), 'uTrim', NaN(7, 1), ...
    'residual', NaN(3, 1), 'residualNorm', NaN, ...
    'exitflag', NaN, 'iterations', NaN, 'funcCount', NaN, ...
    'formalAccepted', false, 'highPrecisionRoot', false, ...
    'solverConverged', false, 'finiteFullStateDerivative', false, ...
    'atLimit', false, 'withinLimits', false, ...
    'finite', false, 'diagnostics', make_empty_diagnostics());
end

function diagOut = make_empty_diagnostics()
diagOut = struct('Ftotal', NaN(3, 1), 'Mtotal', NaN(3, 1), ...
    'FaeroProp', NaN(3, 1), 'Fgravity', NaN(3, 1), ...
    'xdot', NaN(9, 1), 'rotorLeft', make_empty_rotor(), ...
    'rotorRight', make_empty_rotor(), 'wingF', NaN(3, 1), ...
    'wingM', NaN(3, 1), ...
    'wingRegions', repmat(make_empty_region(), 0, 1), ...
    'finite', false);
end

function rotor = make_empty_rotor()
rotor = struct('name', '', 'inducedVelocity', NaN, ...
    'iterations', NaN, 'thrust', NaN, 'torque', NaN, ...
    'muLong', NaN, 'muLat', NaN, 'F', NaN(3, 1), ...
    'M', NaN(3, 1), 'finite', false);
end

function region = make_empty_region()
region = struct('index', NaN, 'area', NaN, 'side', NaN, ...
    'inSlipstream', false, 'wakeVelocity', NaN, ...
    'rAC', NaN(3, 1), 'Vlocal', NaN(3, 1), 'V', NaN, ...
    'ratio', NaN, 'margin', NaN, 'nearNormal', false, ...
    'alpha', NaN, 'beta', NaN, 'CL', NaN, 'CD', NaN, ...
    'Cm', NaN, 'F', NaN(3, 1), 'M', NaN(3, 1), ...
    'finite', false);
end

function study = make_empty_study()
study = struct('name', '', 'V', NaN, ...
    'seedDeg', [NaN, NaN, NaN], 'baseAttempt', make_empty_attempt(), ...
    'records', repmat(make_empty_perturb_record(), 0, 2), ...
    'stepPairs', repmat(make_empty_step_pair(), 0, 1));
end

function rec = make_empty_perturb_record()
rec = struct('studyName', '', 'V', NaN, 'hRad', NaN, ...
    'direction', NaN, 'thetaPerturbedDeg', NaN, ...
    'x', NaN(9, 1), 'uCtrl', NaN(7, 1), ...
    'residual', NaN(3, 1), 'residualNorm', NaN, ...
    'deltaResidual', NaN(3, 1), ...
    'oneSidedDerivative', NaN(3, 1), ...
    'left', make_empty_crossing(), 'right', make_empty_crossing(), ...
    'crossedAny', false, 'changedAny', false, ...
    'diagnostics', make_empty_diagnostics(), 'finite', false);
end

function cross = make_empty_crossing()
cross = struct('side', NaN, 'baseRatio', NaN, ...
    'perturbedRatio', NaN, 'baseMargin', NaN, ...
    'perturbedMargin', NaN, 'baseNearNormal', false, ...
    'perturbedNearNormal', false, 'crossed', false, ...
    'changed', false);
end

function pair = make_empty_step_pair()
pair = struct('hRad', NaN, 'residualPlusMinusGap', NaN(3, 1), ...
    'gapNorm', NaN, 'derivativeMismatch', NaN(3, 1), ...
    'derivativeMismatchNorm', NaN, ...
    'crossedAny', false, 'changedAny', false);
end

function value = get_output_number(output, fieldName)
value = NaN;
if isstruct(output) && isfield(output, fieldName)
    value = output.(fieldName);
end
end

function value = get_numeric_field(data, fieldName, defaultValue)
value = defaultValue;
if isstruct(data) && isfield(data, fieldName)
    raw = data.(fieldName);
    if isnumeric(raw) && isscalar(raw)
        value = raw;
    end
end
end

function value = get_vector_field(data, fieldName)
value = NaN(3, 1);
if isstruct(data) && isfield(data, fieldName)
    raw = data.(fieldName);
    if isnumeric(raw) && numel(raw) == 3
        value = raw(:);
    end
end
end

function tf = is_real_finite(value)
tf = isnumeric(value) && isreal(value) && all(isfinite(value(:)));
end
