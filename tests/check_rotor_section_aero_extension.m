function report = check_rotor_section_aero_extension()
%CHECK_ROTOR_SECTION_AERO_EXTENSION Internal checks for opt-in section aero.
%
% These are model-consistency and reduction-contract checks only. They do
% not constitute XV-15 external validation.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'analysis'));

P = params_nominal();
d2r = pi/180;
x = zeros(9,1);
ctrl = struct('collective', 18*d2r, 'cyclicLong', 0);

report.cases = struct('name',{},'passed',{},'message',{});

%% 1) Legacy/no-extension path must be identical to production
[F0,M0,o0] = rotor_model_bemt(x, ctrl, 0, -1, zeros(3,1), P);
[F1,M1,o1] = rotor_model_bemt_section_aero( ...
    x, ctrl, 0, -1, zeros(3,1), P);
scale = max([norm([F0;M0]), 1]);
legacyOk = norm([F1-F0; M1-M0])/scale < 1e-12 && ...
    abs(o1.thrust-o0.thrust) <= 1e-12*max(abs(o0.thrust),1) && ...
    abs(o1.torque-o0.torque) <= 1e-12*max(abs(o0.torque),1) && ...
    o1.sectionAlpha0L == 0 && ~o1.compressibilityCorrectionEnabled && ...
    o1.sectionLiftSlopeFactor == 1;
add_case('legacy/default path is unchanged', legacyOk, ...
    'Opt-in wrapper changed the no-extension baseline.');

%% 2) Negative alpha0L must raise effective incidence and hover thrust
Pa = P;
Pa.rotor.alpha0L = -2*d2r;
Pa.rotor.enableCompressibilityCorrection = false;
[~,~,oa] = rotor_model_bemt_section_aero( ...
    x, ctrl, 0, -1, zeros(3,1), Pa);
alphaOk = oa.sectionEffectiveCollective > ctrl.collective && ...
    oa.thrust > o1.thrust && isfinite(oa.thrust) && isfinite(oa.torque);
add_case('negative alpha0L increases positive hover load', alphaOk, ...
    'Expected negative zero-lift angle to increase effective incidence/load.');

%% 3) Equivalent compressibility correction must be bounded and active
Pc = Pa;
Pc.env.aSound = 340.0;
Pc.rotor.enableCompressibilityCorrection = true;
Pc.rotor.compressibilityReferenceRadius = 0.75;
Pc.rotor.compressibilityMachCap = 0.75;
[~,~,oc] = rotor_model_bemt_section_aero( ...
    x, ctrl, 0, -1, zeros(3,1), Pc);
compOk = oc.compressibilityCorrectionEnabled && ...
    oc.compressibilityReferenceMachUsed > 0 && ...
    oc.compressibilityReferenceMachUsed <= Pc.rotor.compressibilityMachCap && ...
    oc.sectionLiftSlopeFactor > 1 && isfinite(oc.sectionLiftSlopeFactor) && ...
    isfinite(oc.thrust) && isfinite(oc.torque);
add_case('bounded equivalent compressibility factor', compOk, ...
    'Compressibility diagnostics were inactive, nonfinite, or unbounded.');

%% 4) The correction should increase load for this attached-flow case
loadOk = oc.thrust > oa.thrust;
add_case('compressibility raises representative hover lift', loadOk, ...
    'Expected the positive PG-equivalent lift-slope correction to raise thrust.');

%% 5) NASA C81 -> low-order reduction contract must be physically sane
c81 = build_xv15_c81_low_order_section_aero();
c81Finite = all(isfinite([c81.alpha0L_rad, c81.liftSlope, c81.CLmax, ...
    c81.CD0, c81.kCD, c81.clWeightedRms, c81.cdWeightedRms]));
c81Range = c81.alpha0L_rad < 0 && c81.alpha0L_rad > -3*d2r && ...
    c81.liftSlope > 6 && c81.liftSlope < 9 && ...
    c81.CLmax > 0.8 && c81.CLmax < 1.6 && ...
    c81.CD0 > 0 && c81.CD0 < 0.03 && ...
    c81.kCD > 0 && c81.kCD < 0.10;
c81Source = strcmp(c81.sourceClass,'NASA_CAMRADII_C81_REFERENCE_INPUT_REDUCTION') && ...
    ~isempty(strfind(c81.claimBoundary,'NO_OARF_FIT')); %#ok<STREMP>
add_case('NASA C81 reduction returns sane independent parameters', ...
    c81Finite && c81Range && c81Source, ...
    'C81 reduction is nonfinite, out of broad physical bounds, or lost its no-OARF-fit provenance.');

%% 6) C81 reduction must not silently reactivate the separate PG correction
P81 = P;
P81.rotor.alpha0L = c81.alpha0L_rad;
P81.rotor.liftSlope = c81.liftSlope;
P81.rotor.CLmax = c81.CLmax;
P81.rotor.CD0 = c81.CD0;
P81.rotor.kCD = c81.kCD;
P81.rotor.enableCompressibilityCorrection = false;
[~,~,o81] = rotor_model_bemt_section_aero( ...
    x, ctrl, 0, -1, zeros(3,1), P81);
noDoubleCompressibility = ~o81.compressibilityCorrectionEnabled && ...
    o81.sectionLiftSlopeFactor == 1 && isfinite(o81.thrust) && isfinite(o81.torque);
add_case('C81 parameter path does not double-count PG correction', ...
    noDoubleCompressibility, ...
    'Separate compressibility correction was unexpectedly active on the C81-reduced path.');

report.allPassed = all([report.cases.passed]);

fprintf('\nRotor section-aero extension checks\n');
fprintf('===================================\n');
for k = 1:numel(report.cases)
    if report.cases(k).passed
        status = 'PASS';
    else
        status = 'FAIL';
    end
    fprintf('%-56s : %s\n', report.cases(k).name, status);
    if ~report.cases(k).passed
        fprintf('  %s\n', report.cases(k).message);
    end
end
fprintf('All section-aero checks passed: %d\n', report.allPassed);

    function add_case(name, passed, message)
        item = struct('name',name,'passed',logical(passed),'message',message);
        report.cases(end+1) = item; %#ok<AGROW>
    end
end
