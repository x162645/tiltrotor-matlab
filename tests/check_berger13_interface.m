function report = check_berger13_interface()
%CHECK_BERGER13_INTERFACE Audit the isolated PR1 interface and degradation.
% Passing this check establishes only internal implementation consistency.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'model','berger13'));

d2r = pi/180;
P13 = params_berger13();
P = P13.base;
report.cases = struct('name',{},'passed',{},'message',{});

stateNamesExpected = {'u';'v';'w';'p';'q';'r';'phi';'theta';'psi'; ...
    'betaML';'betaMR';'betaMLdot';'betaMRdot'};
stateUnitsExpected = {'m/s';'m/s';'m/s';'rad/s';'rad/s';'rad/s'; ...
    'rad';'rad';'rad';'rad';'rad';'rad/s';'rad/s'};
inputNamesExpected = {'collective';'diffCollective';'cyclicLong'; ...
    'diffCyclic';'lateralCyclic';'aileron';'elevator';'rudder'; ...
    'nacelleTorqueLeft';'nacelleTorqueRight'};
inputUnitsExpected = {'rad';'rad';'rad';'rad';'rad';'rad';'rad'; ...
    'rad';'N*m';'N*m'};

add_case('frozen 13-state names and units', ...
    isequal(get_state_names_13x10(),stateNamesExpected) && ...
    isequal(get_state_units_13x10(),stateUnitsExpected), ...
    'The reviewed state order or units changed.');
add_case('frozen 10-input names and units', ...
    isequal(get_control_input_names_13x10(),inputNamesExpected) && ...
    isequal(get_control_input_units_13x10(),inputUnitsExpected), ...
    'The reviewed input order or units changed.');

sourceFields = fieldnames(P13.nacelle.parameterSources);
sourceTags = cell(size(sourceFields));
for k = 1:numel(sourceFields)
    sourceTags{k} = P13.nacelle.parameterSources.(sourceFields{k});
end
provenanceOK = all(strcmp(sourceTags,'RESEARCH_PLACEHOLDER')) && ...
    strcmp(P13.nacelle.parameterSource,'RESEARCH_PLACEHOLDER') && ...
    strcmp(P13.interface.parameterSource,'ASSUMED_MODEL_PARAMETER') && ...
    strcmp(P13.linear.parameterSource,'ASSUMED_MODEL_PARAMETER') && ...
    ~P13.nacelle.stiffnessImplemented;
add_case('placeholder provenance is explicit',provenanceOK, ...
    'PR1 placeholder or numerical/interface provenance is incomplete.');

% Equal nacelle angles and zero lateral cyclic must reduce to the unchanged
% nine-state/seven-input NUAA physical baseline.
x9 = [38;0.7;-0.3;0.01;-0.015;0.008;1*d2r;-2*d2r;3*d2r];
betaM = 37*d2r;
u7 = [9*d2r;0.4*d2r;0.6*d2r;-0.3*d2r; ...
    0.2*d2r;-1.5*d2r;0.25*d2r];
x13 = [x9;betaM;betaM;0;0];
u10 = [u7(1:4);0;u7(5:7);0;0];
[F9,M9] = total_forces_moments(x9,u7,betaM,P);
[F13,M13,info13] = total_forces_moments_13x10(x13,u10,P13);
xdot9 = tiltrotor_eom(x9,u7,betaM,P);
xdot13 = tiltrotor_eom_13x10(x13,u10,P13);
report.symmetricDegradation.forceDifference = F13-F9;
report.symmetricDegradation.momentDifference = M13-M9;
report.symmetricDegradation.firstNineDerivativeDifference = xdot13(1:9)-xdot9;
report.symmetricDegradation.forceRelative = norm(F13-F9)/max(norm(F9),1);
report.symmetricDegradation.momentRelative = norm(M13-M9)/max(norm(M9),1);
report.symmetricDegradation.derivativeRelative = ...
    norm(xdot13(1:9)-xdot9)/max(norm(xdot9),1);
degradesOK = norm(F13-F9,inf) < 1e-8 && ...
    norm(M13-M9,inf) < 1e-8 && ...
    norm(xdot13(1:9)-xdot9,inf) < 1e-10 && ...
    ~any(structfun(@(v) logical(v),info13.limitFlags));
add_case('symmetric degradation to NUAA baseline',degradesOK, ...
    'Equal nacelles and zero lateral cyclic did not reproduce the base path.');

% Independent left/right rotor angles must be active, while diagnostics
% retain the reviewed average-angle limitation for non-rotor loads.
xAsym = [40;zeros(8,1);40*d2r;50*d2r;0;0];
uSym = [8*d2r;0;0;0;0;0;-2*d2r;0;0;0];
[Fasym,Masym,asymInfo] = total_forces_moments_13x10(xAsym,uSym,P13);
independentOK = asymInfo.usedIndependentRotorAngles && ...
    asymInfo.usedAverageNonRotorAero && ~isempty(asymInfo.warnings) && ...
    norm(asymInfo.rotorLeft.deltaFromAverage.F) > 1 && ...
    norm(asymInfo.rotorRight.deltaFromAverage.F) > 1 && ...
    all(isfinite([Fasym;Masym]));
add_case('independent rotor-angle loads are opt-in',independentOK, ...
    'Independent rotor loads or average-angle limitation was not observable.');

% Swapping left/right nacelle states at a symmetric rigid-body condition
% must mirror lateral force and roll/yaw moment without changing even axes.
xSwap = xAsym;
xSwap(10:11) = flipud(xAsym(10:11));
[Fswap,Mswap] = total_forces_moments_13x10(xSwap,uSym,P13);
evenError = [Fswap([1 3])-Fasym([1 3]); Mswap(2)-Masym(2)];
oddError = [Fswap(2)+Fasym(2); Mswap([1 3])+Masym([1 3])];
mirrorScale = max(norm([Fasym;Masym]),1);
report.leftRightExchange.evenError = evenError;
report.leftRightExchange.oddError = oddError;
mirrorOK = norm([evenError;oddError],inf) < 1e-9*mirrorScale;
add_case('left/right angle exchange mirror relation',mirrorOK, ...
    'Left/right nacelle exchange did not preserve the expected symmetry.');

% Placeholder torque channels are independent and have the reviewed sign.
xTorque = [40;zeros(8,1);45*d2r;45*d2r;0;0];
uTorque = uSym;
uTorque(9:10) = [1000;-1000];
xdotTorque = tiltrotor_eom_13x10(xTorque,uTorque,P13);
torqueOK = xdotTorque(12) > 0 && xdotTorque(13) < 0 && ...
    abs(xdotTorque(12)+xdotTorque(13)) < 1e-12;
add_case('independent torque-channel signs',torqueOK, ...
    'Left/right placeholder torque signs or independence changed.');

legacyRejectsEight = false;
try
    validate_inputs(zeros(9,1),zeros(8,1),0,P);
catch
    legacyRejectsEight = true;
end
legacyOK = numel(P.linear.du) == 7 && legacyRejectsEight && ...
    abs(P.wing.normalFlowRatio-0.35) < eps && ...
    abs(P.wing.normalFlowBlendHalfWidth-0.15) < eps && ...
    ~isfield(P.wing,'fullAngle') && ~isfield(P.wing,'useFullAngle');
add_case('legacy 9x7 and wing defaults unchanged',legacyOK, ...
    'Legacy input dimension or reviewed wing-default invariants changed.');

report.allPassed = all([report.cases.passed]);
fprintf('\nBerger13 PR1 interface checks\n');
fprintf('=============================\n');
for k = 1:numel(report.cases)
    fprintf('%-48s : %s\n',report.cases(k).name, ...
        ternary(report.cases(k).passed,'PASS','FAIL'));
    if ~report.cases(k).passed
        fprintf('  %s\n',report.cases(k).message);
    end
end
fprintf('Max |baseline F difference|: %.3e N\n', ...
    norm(report.symmetricDegradation.forceDifference,inf));
fprintf('Max |baseline M difference|: %.3e N*m\n', ...
    norm(report.symmetricDegradation.momentDifference,inf));
fprintf('Max |first-nine derivative difference|: %.3e\n', ...
    norm(report.symmetricDegradation.firstNineDerivativeDifference,inf));
fprintf('All passed: %d\n',report.allPassed);

    function add_case(name,passed,message)
        entry.name = name;
        entry.passed = logical(passed);
        entry.message = message;
        report.cases(end+1) = entry;
    end
end

function value = ternary(condition,a,b)
if condition
    value = a;
else
    value = b;
end
end
