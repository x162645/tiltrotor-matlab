function report = check_nuaa_eq17_representative_trim_points()
%CHECK_NUAA_EQ17_REPRESENTATIVE_TRIM_POINTS Run the five required trim gates.
%
% This function uses the existing trim definitions and factory initial
% values only. It does not search alternate seeds, tune parameters, relax
% limits, or modify allocation.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'analysis'));

P = params_nominal();
d2r = pi/180;
cases = representative_cases();
points = repmat(empty_point(), 0, 1);

fprintf('\nNUAA Eq. (17) representative trim gates\n');
fprintf('=======================================\n');

for iCase = 1:numel(cases)
    point = run_one(cases(iCase));
    points(end+1,1) = point; %#ok<AGROW>
    print_point(point);
    if ~point.passed
        error('check_nuaa_eq17_representative_trim_points:FailedGate', ...
            'Representative trim gate failed for %s.', point.label);
    end
end

report.points = points;
report.allPassed = all([points.passed]);
fprintf('All representative trim gates passed: %d\n', report.allPassed);

assert(report.allPassed, 'Representative trim gates failed.');

    function point = run_one(caseDef)
        point = empty_point();
        point.label = caseDef.label;
        point.mode = caseDef.mode;
        point.betaM_deg = caseDef.betaM_deg;
        point.V_mps = caseDef.V_mps;
        condition = struct('V', caseDef.V_mps, ...
            'betaM', caseDef.betaM_deg*d2r, 'gamma', 0);
        try
            definition = make_trim_definition(caseDef.mode, condition, P);
            [xTrim, uTrim, trimReport] = trim_general( ...
                condition, definition, P);
            credibility = diagnose_trim_credibility( ...
                condition, definition, xTrim, uTrim, trimReport, P);
            [~,~,info] = total_forces_moments( ...
                xTrim, uTrim, condition.betaM, P);
            wing = summarize_wing(info.wing, uTrim, P);
            finite = is_real_finite(xTrim) && is_real_finite(uTrim) && ...
                is_real_finite(trimReport.fullStateDerivative) && ...
                is_real_finite([info.F; info.M]);
            symScale = max(norm([info.F; info.M]), 1);
            symmetryError = max(abs([info.F(2); info.M(1); info.M(3)])) / ...
                symScale;
            eq17Ok = info.wing.maxEq17BasisError < 1e-10 && ...
                info.wing.maxEq17ReconstructionError < 1e-10 && ...
                ~info.wing.wakeFactorUsed;
            point.converged = trimReport.converged;
            point.residualNorm = trimReport.residualNorm;
            point.credibilityStatus = credibility.status;
            point.credibilityReasons = strjoin(credibility.reasons(:).', ';');
            point.minimumMarginFraction = credibility.minimumMarginFraction;
            point.collective_deg = uTrim(1)/d2r;
            point.cyclicLong_deg = uTrim(3)/d2r;
            point.elevator_deg = uTrim(6)/d2r;
            point.theta_deg = xTrim(8)/d2r;
            point.finite = finite;
            point.symmetryError = symmetryError;
            point.eq17Ok = eq17Ok;
            point.SslipRawHalf = info.wing.SslipRawHalf;
            point.SslipHalf = info.wing.SslipHalf;
            point.SslipClampedLow = info.wing.SslipClampedLow;
            point.SslipClampedHigh = info.wing.SslipClampedHigh;
            point.VwakeSlipLeft = wing.VwakeSlipLeft;
            point.VwakeSlipRight = wing.VwakeSlipRight;
            point.VlocalSlipMean = wing.VlocalSlipMean;
            point.VlocalFreeMean = wing.VlocalFreeMean;
            point.maxEq17BasisError = info.wing.maxEq17BasisError;
            point.maxEq17ReconstructionError = ...
                info.wing.maxEq17ReconstructionError;
            point.slipForce = wing.slipForce;
            point.freeForce = wing.freeForce;
            point.slipPitchMoment_Nm = wing.slipPitchMoment_Nm;
            point.freePitchMoment_Nm = wing.freePitchMoment_Nm;
            point.maxRawCLOverCLmax = wing.maxRawCLOverCLmax;
            point.maxAbsAlpha_deg = wing.maxAbsAlpha_deg;
            point.localApplicability = wing.localApplicability;
            point.passed = trimReport.converged && ...
                strcmp(credibility.status, 'PASS') && finite && ...
                symmetryError < 1e-7 && eq17Ok;
        catch ME
            point.errorIdentifier = ME.identifier;
            point.errorMessage = ME.message;
            point.passed = false;
        end
    end

    function wing = summarize_wing(out, uTrim, P)
        slipForce = zeros(3,1);
        freeForce = zeros(3,1);
        slipMoment = zeros(3,1);
        freeMoment = zeros(3,1);
        slipVectors = NaN(3,2);
        slipLocal = [];
        freeLocal = [];
        rawCLRatio = [];
        absAlphaDeg = [];
        slipIndex = 0;
        for iRegion = 1:numel(out.regions)
            r = out.regions{iRegion};
            if r.inSlipstream
                slipIndex = slipIndex + 1;
                slipForce = slipForce + r.F;
                slipMoment = slipMoment + r.M;
                slipVectors(:, slipIndex) = r.VwakeEq17;
                slipLocal(end+1,1) = norm(r.Vlocal); %#ok<AGROW>
            else
                freeForce = freeForce + r.F;
                freeMoment = freeMoment + r.M;
                freeLocal(end+1,1) = norm(r.Vlocal); %#ok<AGROW>
            end
            if isfield(r, 'alpha')
                dCLail = -r.side*P.wing.CLaileron*uTrim(5);
                rawCL = P.wing.CL0 + P.wing.CLalpha*r.alpha + dCLail;
                rawCLRatio(end+1,1) = abs(rawCL)/P.wing.CLmax; %#ok<AGROW>
                absAlphaDeg(end+1,1) = abs(r.alpha)/d2r; %#ok<AGROW>
            end
        end
        wing.slipForce = slipForce;
        wing.freeForce = freeForce;
        wing.slipPitchMoment_Nm = slipMoment(2);
        wing.freePitchMoment_Nm = freeMoment(2);
        wing.VwakeSlipLeft = slipVectors(:,1);
        wing.VwakeSlipRight = slipVectors(:,2);
        wing.VlocalSlipMean = mean(slipLocal);
        wing.VlocalFreeMean = mean(freeLocal);
        if isempty(rawCLRatio)
            wing.maxRawCLOverCLmax = 0;
        else
            wing.maxRawCLOverCLmax = max(rawCLRatio);
        end
        if isempty(absAlphaDeg)
            wing.maxAbsAlpha_deg = 0;
        else
            wing.maxAbsAlpha_deg = max(absAlphaDeg);
        end
        if wing.maxRawCLOverCLmax <= 1
            wing.localApplicability = 'WITHIN_LINEAR_LIFT_RANGE';
        else
            wing.localApplicability = 'LIFT_SATURATION_ACTIVE';
        end
    end

    function print_point(point)
        fprintf(['%s beta=%5.1f V=%6.1f conv=%d cred=%s res=%.3e ' ...
            'theta=% .3f coll=% .3f cyc=% .3f elev=% .3f ' ...
            'marginFrac=%.3f symErr=%.3e\n'], point.label, ...
            point.betaM_deg, point.V_mps, point.converged, ...
            point.credibilityStatus, point.residualNorm, ...
            point.theta_deg, point.collective_deg, ...
            point.cyclicLong_deg, point.elevator_deg, ...
            point.minimumMarginFraction, point.symmetryError);
        fprintf(['  Eq16 SslipRawHalf=%.6f SslipHalf=%.6f ' ...
            'clampLow=%d clampHigh=%d\n'], point.SslipRawHalf, ...
            point.SslipHalf, point.SslipClampedLow, ...
            point.SslipClampedHigh);
        fprintf(['  Eq17 VwakeLeft=[%.6f %.6f %.6f] ' ...
            'VwakeRight=[%.6f %.6f %.6f]\n'], ...
            point.VwakeSlipLeft(1), point.VwakeSlipLeft(2), ...
            point.VwakeSlipLeft(3), point.VwakeSlipRight(1), ...
            point.VwakeSlipRight(2), point.VwakeSlipRight(3));
        fprintf(['  Vlocal mean slip/free=%.6f/%.6f ' ...
            'basisErr=%.3e reconErr=%.3e\n'], ...
            point.VlocalSlipMean, point.VlocalFreeMean, ...
            point.maxEq17BasisError, point.maxEq17ReconstructionError);
        fprintf(['  wing split Fslip=[%.3e %.3e %.3e] ' ...
            'Ffree=[%.3e %.3e %.3e] Myslip=%.3e Myfree=%.3e\n'], ...
            point.slipForce(1), point.slipForce(2), point.slipForce(3), ...
            point.freeForce(1), point.freeForce(2), point.freeForce(3), ...
            point.slipPitchMoment_Nm, point.freePitchMoment_Nm);
        fprintf(['  local aero: maxRawCL/CLmax=%.3f maxAbsAlpha=%.3f deg ' ...
            'applicability=%s\n'], point.maxRawCLOverCLmax, ...
            point.maxAbsAlpha_deg, point.localApplicability);
        if ~strcmp(point.credibilityReasons, 'NONE')
            fprintf('  credibility reasons: %s\n', point.credibilityReasons);
        end
    end

    function cases = representative_cases()
        cases = struct('label',{},'mode',{},'betaM_deg',{},'V_mps',{});
        cases(end+1) = make_case('helicopter_0deg_0mps', ...
            'helicopter_longitudinal', 0, 0);
        cases(end+1) = make_case('helicopter_0deg_20mps', ...
            'helicopter_longitudinal', 0, 20);
        cases(end+1) = make_case('conversion_15deg_35mps', ...
            'conversion_longitudinal', 15, 35);
        cases(end+1) = make_case('conversion_75deg_100mps', ...
            'conversion_longitudinal', 75, 100);
        cases(end+1) = make_case('airplane_90deg_100mps', ...
            'airplane_longitudinal', 90, 100);
    end

    function item = make_case(label, mode, betaM_deg, V_mps)
        item = struct('label', label, 'mode', mode, ...
            'betaM_deg', betaM_deg, 'V_mps', V_mps);
    end

    function point = empty_point()
        point = struct('label','', 'mode','', 'betaM_deg',NaN, ...
            'V_mps',NaN, 'converged',false, 'residualNorm',NaN, ...
            'credibilityStatus','NOT_RUN', 'credibilityReasons','', ...
            'minimumMarginFraction',NaN, 'collective_deg',NaN, ...
            'cyclicLong_deg',NaN, 'elevator_deg',NaN, 'theta_deg',NaN, ...
            'finite',false, 'symmetryError',Inf, 'eq17Ok',false, ...
            'SslipRawHalf',NaN, 'SslipHalf',NaN, ...
            'SslipClampedLow',false, 'SslipClampedHigh',false, ...
            'VwakeSlipLeft',NaN(3,1), 'VwakeSlipRight',NaN(3,1), ...
            'VlocalSlipMean',NaN, 'VlocalFreeMean',NaN, ...
            'maxEq17BasisError',NaN, ...
            'maxEq17ReconstructionError',NaN, 'slipForce',NaN(3,1), ...
            'freeForce',NaN(3,1), 'slipPitchMoment_Nm',NaN, ...
            'freePitchMoment_Nm',NaN, 'maxRawCLOverCLmax',NaN, ...
            'maxAbsAlpha_deg',NaN, 'localApplicability','', ...
            'passed',false, 'errorIdentifier','', 'errorMessage','');
    end

    function tf = is_real_finite(value)
        tf = isreal(value) && all(isfinite(value(:)));
    end
end
