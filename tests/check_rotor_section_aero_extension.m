function report = check_rotor_section_aero_extension()
%CHECK_ROTOR_SECTION_AERO_EXTENSION Internal checks for opt-in section aero.
%
% These are model-consistency checks only. They do not constitute XV-15
% external validation.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));

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

report.allPassed = all([report.cases.passed]);

fprintf('\nRotor section-aero extension checks\n');
fprintf('===================================\n');
for k = 1:numel(report.cases)
    if report.cases(k).passed
        status = 'PASS';
    else
        status = 'FAIL';
    end
    fprintf('%-48s : %s\n', report.cases(k).name, status);
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
