function results = run_xv15_hover_inflow_cancellation_diagnostic(outputDir)
%RUN_XV15_HOVER_INFLOW_CANCELLATION_DIAGNOSTIC
% Diagnose why the NUAA Eq. (12) first-harmonic hover inflow has almost no
% net effect under the present first-harmonic flapping model.
%
% The production-equivalent diagnostic path is kept unchanged:
%   vi(r,psi) = viMean*(1 + cos(psi)*r/R)
% and the spanwise/local-Mach NASA C81 section lookup is retained.
%
% This runner does NOT replace Eq. (12) in production. Instead it evaluates
% the structural cancellation condition
%
%   beta1s + viMean/(Omega*R) ~= 0,
%
% which makes the cos(psi) inflow harmonic cancel the corresponding
% -betaDot*r contribution in the blade normal velocity during pure hover.
%
% OARF CT/CP/FM are not used to tune any model parameter.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'results','xv15_section_aero_validation');
end
if ~exist(outputDir,'dir')
    mkdir(outputDir);
end

Pbase = params_nominal();
d2r = pi/180;
R = 3.81;
rootCut = 0.0875;

collective75_deg = [6;7;8;9;10;11];
Vtip_fps = [768.4;768.4;768.4;768.0;768.0;767.7];

% Same PR67 geometry reduction used by the preceding C81 diagnostic.
xGeom = linspace(rootCut,1,4001).';
chord_in = 14*ones(size(xGeom));
inboard = xGeom <= 0.25;
chord_in(inboard) = -18.4615*xGeom(inboard)+18.6154;
chord_m = chord_in*0.0254;
chordEq_m = trapz(xGeom,chord_m)/(1-rootCut);

thetaSource_deg = nasa_metal_twist_deg(xGeom);
theta75Source_deg = nasa_metal_twist_deg(0.75);
xNorm = (xGeom-rootCut)/(1-rootCut);
x75 = (0.75-rootCut)/(1-rootCut);
shapeCoordinate = xNorm-x75;
shapeTarget = thetaSource_deg-theta75Source_deg;
twistTipEq_deg = trapz(xGeom,shapeCoordinate.*shapeTarget) / ...
    trapz(xGeom,shapeCoordinate.^2);

scalarC81 = build_xv15_c81_low_order_section_aero();

Ptemplate = Pbase;
Ptemplate.rotor.R = R;
Ptemplate.rotor.Nb = 3;
Ptemplate.rotor.rootCut = rootCut;
Ptemplate.rotor.chord = chordEq_m;
Ptemplate.rotor.twistTip = twistTipEq_deg*d2r;
Ptemplate.rotor.Ib = Ptemplate.rotor.bladeMass*R^2/3;
Ptemplate.rotor.Sblade = Ptemplate.rotor.bladeMass*R/2;

rows = table();
for k = 1:numel(collective75_deg)
    P = Ptemplate;
    Vtip_mps = Vtip_fps(k)*0.3048;
    P.rotor.Omega = Vtip_mps/R;
    modelCollective_deg = collective75_deg(k)-twistTipEq_deg*x75;

    out = xv15_hover_bemt_section_diagnostic( ...
        P,modelCollective_deg*d2r,'SPANWISE_C81_LOCAL_MACH',scalarC81);

    lambdaInduced = out.inducedVelocity/(P.rotor.Omega*R);
    beta1s = out.zFlap(3);
    cancellationResidual = beta1s + lambdaInduced;
    normalizedCancellationResidual = abs(cancellationResidual) / ...
        max(abs(lambdaInduced),eps);

    local = table(collective75_deg(k),Vtip_fps(k), ...
        P.rotor.Omega*60/(2*pi),modelCollective_deg, ...
        out.inducedVelocity,lambdaInduced,beta1s,cancellationResidual, ...
        normalizedCancellationResidual,out.physicalConverged, ...
        {out.physicalStatus}, ...
        'VariableNames',{'collective75_deg','Vtip_fps','rpm', ...
        'modelCollective_deg','inducedVelocity_mps','lambdaInduced', ...
        'beta1s','beta1sPlusLambdaInduced', ...
        'normalizedCancellationResidual','physicalConverged', ...
        'physicalStatus'});
    rows = [rows;local]; %#ok<AGROW>
end

writetable(rows,fullfile(outputDir, ...
    'XV15_HOVER_INFLOW_CANCELLATION_MATLAB_DIAGNOSTIC.csv'));

results = struct();
results.table = rows;
results.maxNormalizedCancellationResidual = ...
    max(rows.normalizedCancellationResidual);
results.chordEq_m = chordEq_m;
results.twistTipEq_deg = twistTipEq_deg;
results.claimBoundary = ['HOVER_EQ12_FLAPPING_CANCELLATION_DIAGNOSTIC_' ...
    'NO_OARF_PARAMETER_FIT'];
save(fullfile(outputDir, ...
    'XV15_HOVER_INFLOW_CANCELLATION_DIAGNOSTIC_RESULTS.mat'),'results');
end

function theta_deg = nasa_metal_twist_deg(x)
theta_deg = 289.98*x.^5-892.87*x.^4+987.06*x.^3 ...
    -438.31*x.^2+15.695*x+32.057;
end
