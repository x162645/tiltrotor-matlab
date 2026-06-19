function continuityReport = check_trim_continuity()
%CHECK_TRIM_CONTINUITY Formal low-speed helicopter trim continuity check.
%
% This test uses the current code definition betaM = 0 rad for helicopter
% mode and records failures instead of changing any physical model item.
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'analysis'));

P = params_nominal();
opts = struct();
opts.speeds = 0:1:20;
opts.betaM = 0;
opts.gamma = 0;
opts.initialDeg = [0, 18, 0];
opts.useContinuation = true;
opts.useTrimMultiStart = false;
opts.allowRescueInitials = true;
opts.failOnRescueInitial = true;
opts.maxDeltaThetaDeg = 2.5;
opts.maxDeltaControlDeg = 1.25;
opts.signFlipThresholdDeg = 0.25;
opts.jacobianStepRad = 1.0e-4;
opts.rescueInitialDegs = [
     0, 18,  0;
    -4, 18, -1;
     4, 16,  2;
     8, 15,  4;
    -8, 20, -4;
    12, 14,  6];

% Threshold basis:
% - Residual tolerance remains P.trim.residualTolerance; this test does not
%   relax force/moment balance to pass continuity.
% - Speeds are spaced by 1 m/s, so a continuous low-speed branch should not
%   require more than 2.5 deg pitch change or 1.25 deg change in any control
%   component between adjacent samples. Larger changes are treated as a
%   possible branch switch or under-sampling symptom requiring diagnosis.
% - Any rescue initial means strict continuation from the previous
%   successful point failed, so this formal test fails and reports the point.

continuityReport = trim_sweep_helicopter(P, opts);

fprintf('\nHelicopter trim continuity test summary\n');
fprintf('=======================================\n');
fprintf('Successful speeds [m/s]:');
fprintf(' %.6g', continuityReport.summary.successSpeeds);
fprintf('\n');
fprintf('Failed speeds [m/s]:');
fprintf(' %.6g', continuityReport.summary.failedSpeeds);
fprintf('\n');
fprintf(['Thresholds: residual <= %.3e, |dTheta| <= %.3f deg, ' ...
    '|dControl| <= %.3f deg per 1 m/s, rescue initials allowed for ' ...
    'diagnosis but fail this test.\n'], P.trim.residualTolerance, ...
    opts.maxDeltaThetaDeg, opts.maxDeltaControlDeg);

print_formal_failure_reasons(continuityReport);

fprintf('\nPer-speed trim table\n');
fprintf(['V[m/s] exit trimNorm fullNorm theta[deg] collective[deg] ' ...
    'cyclicLong[deg] elevator[deg] udot wdot qdot rescue atLimit ' ...
    'jacRank jacCond linFinite\n']);
for k = 1:numel(continuityReport.points)
    p = continuityReport.points(k);
    fprintf(['%5.1f %4d % .3e % .3e % .6f % .6f % .6f % .6f ' ...
        '% .3e % .3e % .3e %d %d %d % .3e %d\n'], ...
        p.V, p.exitflag, p.trimResidualNorm, p.fullResidualNorm, ...
        p.xTrim(8)*180/pi, p.uTrim(1)*180/pi, p.uTrim(3)*180/pi, ...
        p.uTrim(6)*180/pi, p.trimResidual(1), p.trimResidual(2), ...
        p.trimResidual(3), p.usedRescueInitial, p.anyLimit, ...
        p.residualJacobian.rank, p.residualJacobian.conditionNumber, ...
        p.linearization.finite);
end

if ~continuityReport.allPassed
    print_failure_details(continuityReport);
end

assert(continuityReport.allPassed, ...
    'Helicopter trim continuity check failed; see printed failed speeds, residuals, and diagnostics.');
end

function print_failure_details(report)
fprintf('\nContinuity failure details\n');
fprintf('--------------------------\n');
print_rescue_details(report);
for k = 1:numel(report.points)
    p = report.points(k);
    if ~p.status.success
        fprintf('V=%.6g m/s status=%s: %s\n', ...
            p.V, p.status.label, p.status.message);
        fprintf('  trim residual [udot wdot qdot]:');
        fprintf(' % .12e', p.trimResidual);
        fprintf('\n');
        fprintf('  full residual [udot vdot wdot pdot qdot rdot phidot thetadot psidot]:');
        fprintf(' % .12e', p.fullResidual);
        fprintf('\n');
    end
end
for k = 1:numel(report.adjacent)
    a = report.adjacent(k);
    if ~a.passed
        fprintf('Pair %.6g -> %.6g m/s: %s\n', a.V0, a.V1, a.message);
    end
end
end

function print_formal_failure_reasons(report)
fprintf('\nFormal failure reasons\n');
fprintf('----------------------\n');
hasReason = false;
for k = 1:numel(report.points)
    p = report.points(k);
    if p.usedRescueInitial
        hasReason = true;
        fprintf(['Rescue initial used at V=%.6g m/s: selected source=%s, ' ...
            'rescueIndex=%d, theta=%.6f deg, collective=%.6f deg, ' ...
            'cyclicLong=%.6f deg.\n'], p.V, p.initialSource, ...
            p.rescueIndex, p.solutionDeg(1), p.solutionDeg(2), ...
            p.solutionDeg(3));
    end
end
for k = 1:numel(report.adjacent)
    a = report.adjacent(k);
    if ~a.passed
        hasReason = true;
        fprintf(['Continuity failure %.6g -> %.6g m/s: %s; ' ...
            'dTheta=%.6f deg, dCollective=%.6f deg, ' ...
            'dCyclicLong=%.6f deg.\n'], a.V0, a.V1, a.message, ...
            a.deltaThetaDeg, a.deltaControlDeg(1), ...
            a.deltaControlDeg(3));
    end
end
if ~hasReason
    fprintf('None.\n');
end
end

function print_rescue_details(report)
fprintf('\nRescue initial details\n');
fprintf('----------------------\n');
hasRescue = false;
for k = 1:numel(report.points)
    p = report.points(k);
    if ~isfield(p, 'attempts') || isempty(p.attempts)
        continue;
    end
    for j = 1:numel(p.attempts)
        a = p.attempts(j);
        if isfield(a, 'usedRescue') && a.usedRescue
            hasRescue = true;
            fprintf(['V=%.6g m/s rescue attempt %d: source=%s, ' ...
                'initial=[%.6f %.6f %.6f] deg, final=[%.6f %.6f %.6f] deg, ' ...
                'residualNorm=%.12e, exitflag=%d, success=%d.\n'], ...
                p.V, j, a.source, a.initialDeg(1), a.initialDeg(2), ...
                a.initialDeg(3), a.solutionDeg(1), a.solutionDeg(2), ...
                a.solutionDeg(3), a.residualNorm, a.exitflag, a.success);
        end
    end
end
if ~hasRescue
    fprintf('None.\n');
end
end
