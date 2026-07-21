function report = check_berger13_linearization()
%CHECK_BERGER13_LINEARIZATION Internal PR1 finite-difference evidence.
% Matrix finiteness and consistency are not trim, mode, handling-quality,
% aircraft-type, or external-validation evidence.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'model','berger13'));
addpath(fullfile(rootDir,'analysis','berger13'));

d2r = pi/180;
P13 = params_berger13();
x0 = [40;0.4;-0.2;0.006;-0.009;0.004; ...
    0.5*d2r;-1*d2r;0;40*d2r;50*d2r;0.5*d2r;-0.4*d2r];
u0 = [8*d2r;0.2*d2r;0.3*d2r;-0.15*d2r;0.25*d2r; ...
    0.1*d2r;-2*d2r;0.2*d2r;800;-600];
scales = [0.1,1,10];
Aset = cell(3,1);
Bset = cell(3,1);
linset = cell(3,1);
for k = 1:3
    [Aset{k},Bset{k},linset{k}] = ...
        linearize_13x10_numeric(x0,u0,P13,scales(k));
end

dimensionsOK = true;
for k = 1:3
    dimensionsOK = dimensionsOK && isequal(size(Aset{k}),[13 13]) && ...
        isequal(size(Bset{k}),[13 10]) && linset{k}.finite && ...
        all(strcmp(linset{k}.stateSchemes,'central')) && ...
        all(strcmp(linset{k}.controlSchemes,'central'));
end

% Compare only columns introduced or structurally extended in PR1.
keyA = [10,11,12,13];
keyB = [5,9,10];
reference = [Aset{2}(:,keyA),Bset{2}(:,keyB)];
variationSmall = norm([Aset{1}(:,keyA),Bset{1}(:,keyB)]-reference,'fro') / ...
    max(norm(reference,'fro'),1);
variationLarge = norm([Aset{3}(:,keyA),Bset{3}(:,keyB)]-reference,'fro') / ...
    max(norm(reference,'fro'),1);
stepStable = variationSmall < 5e-3 && variationLarge < 5e-3;

% Explicit endpoint calls demonstrate that the finite-difference stencil
% stays inside reviewed angle limits instead of crossing a clamp boundary.
xEdge = x0;
xEdge(10) = P13.nacelle.betaMin;
xEdge(11) = P13.nacelle.betaMax;
[Aedge,Bedge,edge] = linearize_13x10_numeric(xEdge,u0,P13,1);
boundaryOK = strcmp(edge.stateSchemes{10},'forward') && ...
    strcmp(edge.stateSchemes{11},'backward') && edge.finite && ...
    all(isfinite([Aedge(:);Bedge(:)]));

% For sufficiently small perturbations, nonlinear-minus-linear error must
% decrease as the perturbation is reduced. The operating point need not be
% a trim because this is an increment test about f(x0,u0).
deltaX = zeros(13,1);
deltaX([1,2,4,8,10,11,12,13]) = ...
    [0.03;-0.02;2e-4;-1e-4;2e-4;-1.5e-4;1e-4;-0.8e-4];
deltaU = zeros(10,1);
deltaU([1,3,5,6,9,10]) = [1e-4;-8e-5;7e-5;5e-5;2;-1.5];
f0 = tiltrotor_eom_13x10(x0,u0,P13);
localScales = [1,0.5,0.25];
localErrors = zeros(size(localScales));
for k = 1:numel(localScales)
    alpha = localScales(k);
    fnl = tiltrotor_eom_13x10( ...
        x0+alpha*deltaX,u0+alpha*deltaU,P13);
    flin = f0 + alpha*(Aset{2}*deltaX+Bset{2}*deltaU);
    localErrors(k) = norm(fnl-flin,2);
end
decreasingOK = localErrors(2) < 0.7*localErrors(1) && ...
    localErrors(3) < 0.7*localErrors(2);

report.scales = scales;
report.A = Aset;
report.B = Bset;
report.linearization = linset;
report.keyColumnRelativeVariation = [variationSmall,variationLarge];
report.endpointSchemes = edge.stateSchemes(10:11);
report.localPerturbationScales = localScales;
report.localApproximationErrors = localErrors;
report.cases = struct( ...
    'name',{'dimensions, finite values, and interior central stencil', ...
            'h/10, h, 10h key-column stability', ...
            'boundary-aware nacelle-angle stencils', ...
            'local nonlinear/linear error decreases'}, ...
    'passed',{dimensionsOK,stepStable,boundaryOK,decreasingOK}, ...
    'message',{'A/B size, finiteness, or interior stencil failed.', ...
               'PR1 key columns changed materially with step scale.', ...
               'Endpoint stencil crossed or failed at a beta limit.', ...
               'Local increment error did not decrease with scale.'});
report.allPassed = all([report.cases.passed]);

fprintf('\nBerger13 PR1 linearization checks\n');
fprintf('==================================\n');
for k = 1:numel(report.cases)
    fprintf('%-48s : %s\n',report.cases(k).name, ...
        ternary(report.cases(k).passed,'PASS','FAIL'));
    if ~report.cases(k).passed
        fprintf('  %s\n',report.cases(k).message);
    end
end
fprintf('Key-column relative variation [h/10,10h]: %.3e %.3e\n', ...
    variationSmall,variationLarge);
fprintf('Local approximation errors [1,1/2,1/4]: %.3e %.3e %.3e\n', ...
    localErrors(1),localErrors(2),localErrors(3));
fprintf('All passed: %d\n',report.allPassed);
end

function value = ternary(condition,a,b)
if condition
    value = a;
else
    value = b;
end
end
