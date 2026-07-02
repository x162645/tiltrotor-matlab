function report = check_wing_legacy_identity()
%CHECK_WING_LEGACY_IDENTITY Default wing_model dispatch must preserve legacy output.

rootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'model','wing'));

P = params_nominal();
P.wing.fullAngleModelEnabled = 0;
rotor = struct('muLong',0.05,'muLat',-0.02,'inducedVelocity',12.0, ...
    'eT',[0;0;-1]);
cases = make_cases();
maxForceError = 0;
maxMomentError = 0;
for k = 1:numel(cases)
    c = cases(k);
    [F0,M0,out0] = wing_model_legacy(c.x, c.u, c.betaM, c.cgShift, rotor, rotor, P);
    [F1,M1,out1] = wing_model(c.x, c.u, c.betaM, c.cgShift, rotor, rotor, P);
    maxForceError = max(maxForceError, norm(F1 - F0));
    maxMomentError = max(maxMomentError, norm(M1 - M0));
    assert(norm(F1 - F0) <= 1e-12*max(norm(F0),1));
    assert(norm(M1 - M0) <= 1e-12*max(norm(M0),1));
    assert(strcmp(out1.slipstreamAreaModel, out0.slipstreamAreaModel));
end
report.maxForceError = maxForceError;
report.maxMomentError = maxMomentError;
report.allPassed = true;
fprintf('\nWing legacy identity\n');
fprintf('====================\n');
fprintf('maxForceError=%.12e maxMomentError=%.12e\n', maxForceError, maxMomentError);
end

function cases = make_cases()
baseU = [10;0.1;-0.2;0.05;0.03;-0.02;0]*(pi/180);
baseX = [35;0;2;0.01;-0.02;0.005;0.01;0.04;0];
for k = 1:4
    cases(k).x = baseX + (k-2)*[3;0.2;-0.5;0.002;0.001;0;0;0.01;0]; %#ok<AGROW>
    cases(k).u = baseU;
    betaList = [0, pi/6, pi/3, pi/2];
    cases(k).betaM = betaList(k);
    cases(k).cgShift = [0.02;-0.01;0.03]*(k-1);
end
end

