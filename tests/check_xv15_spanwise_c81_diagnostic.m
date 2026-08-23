function report = check_xv15_spanwise_c81_diagnostic()
%CHECK_XV15_SPANWISE_C81_DIAGNOSTIC Checks for the spanwise C81 diagnostic.
%
% These are internal consistency checks only; they do not constitute XV-15
% validation by themselves.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'analysis'));

d2r = pi/180;
report.cases = struct('name',{},'passed',{},'message',{});

%% 1) Published C81 table nodes must reproduce exactly.
[cl1,cd1,m1] = xv15_c81_section_lookup(0*d2r,0.60,0.97);
node1 = abs(cl1-0.111) < 1e-12 && abs(cd1-0.006) < 1e-12 && ...
    m1.alphaClampCount == 0 && m1.machClampCount == 0;
add_case('outer C81 node alpha=0 M=0.60',node1, ...
    'Expected CL=0.111 and CD=0.006 at the published outer-section node.');

[cl2,cd2] = xv15_c81_section_lookup(8*d2r,0.66,0.85);
node2 = abs(cl2-1.017) < 1e-12 && abs(cd2-0.044) < 1e-12;
add_case('third-region C81 node alpha=8 M=0.66',node2, ...
    'Expected CL=1.017 and CD=0.044 at the published third-region node.');

[cl3,cd3] = xv15_c81_section_lookup(0*d2r,0.60,0.70);
node3 = abs(cl3-0.025) < 1e-12 && abs(cd3-0.007) < 1e-12;
add_case('second-region C81 node alpha=0 M=0.60',node3, ...
    'Expected CL=0.025 and CD=0.007 at the published second-region node.');

%% 2) Build the same 10-deg XV-15 validation instance as PR67/PR68.
P = params_nominal();
R = 3.81;
rootCut = 0.0875;
xGeom = linspace(rootCut,1,4001).';
chord_in = 14*ones(size(xGeom));
inboard = xGeom <= 0.25;
chord_in(inboard) = -18.4615*xGeom(inboard)+18.6154;
P.rotor.R = R;
P.rotor.Nb = 3;
P.rotor.rootCut = rootCut;
P.rotor.chord = trapz(xGeom,chord_in*0.0254)/(1-rootCut);

thetaSource_deg = nasa_metal_twist_deg(xGeom);
theta75Source_deg = nasa_metal_twist_deg(0.75);
xNorm = (xGeom-rootCut)/(1-rootCut);
x75 = (0.75-rootCut)/(1-rootCut);
shapeCoordinate = xNorm-x75;
shapeTarget = thetaSource_deg-theta75Source_deg;
twistTipEq_deg = trapz(xGeom,shapeCoordinate.*shapeTarget) / ...
    trapz(xGeom,shapeCoordinate.^2);
P.rotor.twistTip = twistTipEq_deg*d2r;
P.rotor.Ib = P.rotor.bladeMass*R^2/3;
P.rotor.Sblade = P.rotor.bladeMass*R/2;
Vtip_mps = 768.0*0.3048;
P.rotor.Omega = Vtip_mps/R;
modelCollective_deg = 10.0-twistTipEq_deg*x75;
ctrl = struct('collective',modelCollective_deg*d2r,'cyclicLong',0);
A = pi*R^2;

%% 3) Generic mirror must reproduce production.
mirror0 = xv15_hover_bemt_section_diagnostic( ...
    P,ctrl.collective,'GENERIC_LOW_ORDER',[]);
[~,~,prod0] = rotor_model_bemt_section_aero( ...
    zeros(9,1),ctrl,0,-1,zeros(3,1),P);
ctMirror0 = mirror0.thrust/(P.env.rho*A*Vtip_mps^2);
ctProd0 = prod0.thrust/(P.env.rho*A*Vtip_mps^2);
cpMirror0 = mirror0.torque*P.rotor.Omega/(P.env.rho*A*Vtip_mps^3);
cpProd0 = prod0.torque*P.rotor.Omega/(P.env.rho*A*Vtip_mps^3);
mirrorGeneric = relerr(ctMirror0,ctProd0) < 1e-9 && ...
    relerr(cpMirror0,cpProd0) < 1e-9;
add_case('generic hover mirror matches production',mirrorGeneric, ...
    'Diagnostic mirror drifted from production generic BEMT.');

%% 4) Scalar-C81 mirror must reproduce the PR68 production wrapper path.
c81 = build_xv15_c81_low_order_section_aero();
Ps = P;
Ps.rotor.alpha0L = c81.alpha0L_rad;
Ps.rotor.liftSlope = c81.liftSlope;
Ps.rotor.CLmax = c81.CLmax;
Ps.rotor.CD0 = c81.CD0;
Ps.rotor.kCD = c81.kCD;
Ps.rotor.enableCompressibilityCorrection = false;
mirrorS = xv15_hover_bemt_section_diagnostic( ...
    P,ctrl.collective,'SCALAR_C81_LOW_ORDER',c81);
[~,~,prodS] = rotor_model_bemt_section_aero( ...
    zeros(9,1),ctrl,0,-1,zeros(3,1),Ps);
ctMirrorS = mirrorS.thrust/(P.env.rho*A*Vtip_mps^2);
ctProdS = prodS.thrust/(P.env.rho*A*Vtip_mps^2);
cpMirrorS = mirrorS.torque*P.rotor.Omega/(P.env.rho*A*Vtip_mps^3);
cpProdS = prodS.torque*P.rotor.Omega/(P.env.rho*A*Vtip_mps^3);
mirrorScalar = relerr(ctMirrorS,ctProdS) < 1e-9 && ...
    relerr(cpMirrorS,cpProdS) < 1e-9;
add_case('scalar C81 hover mirror matches production',mirrorScalar, ...
    'Diagnostic mirror drifted from the scalar-C81 production wrapper path.');

%% 5) Full spanwise/local-Mach C81 path must remain finite and unclamped at 10 deg.
span = xv15_hover_bemt_section_diagnostic( ...
    P,ctrl.collective,'SPANWISE_C81_LOCAL_MACH',c81);
spanOk = span.physicalConverged && isfinite(span.thrust) && ...
    isfinite(span.torque) && span.c81AlphaClampCount == 0 && ...
    span.c81MachClampCount == 0 && span.alphaMin_deg > -10 && ...
    span.alphaMax_deg < 30;
add_case('spanwise C81 10-deg diagnostic is physical/unclamped',spanOk, ...
    'Spanwise C81 diagnostic failed, clamped, or left the published lookup window.');

report.allPassed = all([report.cases.passed]);
fprintf('\nXV-15 spanwise C81 diagnostic checks\n');
fprintf('===================================\n');
for k = 1:numel(report.cases)
    if report.cases(k).passed
        status = 'PASS';
    else
        status = 'FAIL';
    end
    fprintf('%-55s : %s\n',report.cases(k).name,status);
    if ~report.cases(k).passed
        fprintf('  %s\n',report.cases(k).message);
    end
end
fprintf('All spanwise C81 checks passed: %d\n',report.allPassed);

    function add_case(name,passed,message)
        item = struct('name',name,'passed',logical(passed),'message',message);
        report.cases(end+1) = item; %#ok<AGROW>
    end
end

function e = relerr(a,b)
e = abs(a-b)/max([abs(a),abs(b),1e-12]);
end

function theta_deg = nasa_metal_twist_deg(x)
theta_deg = 289.98*x.^5-892.87*x.^4+987.06*x.^3 ...
    -438.31*x.^2+15.695*x+32.057;
end
