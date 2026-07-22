function linearModel = linearize_berger13_trim_point(trimReport, P13)
%LINEARIZE_BERGER13_TRIM_POINT Gate linearization on formal credibility.

if nargin < 2 || isempty(P13)
    P13 = params_berger13();
end
if ~isstruct(trimReport) || ~isfield(trimReport,'status') || ...
        ~strcmp(trimReport.status,'CREDIBLE')
    error('linearize_berger13_trim_point:NonCrediblePoint', ...
        'Only a formally classified CREDIBLE trim point may be linearized.');
end

scales = [0.1; 1; 10];
models = repmat(struct('scale',NaN,'A',[],'B',[],'report',[]),3,1);
for k = 1:3
    [models(k).A,models(k).B,models(k).report] = ...
        linearize_13x10_numeric(trimReport.x13, ...
        trimReport.u10Torque,P13,scales(k));
    models(k).scale = scales(k);
end
A = models(2).A;
B = models(2).B;
variation = zeros(2,1);
for k = [1,3]
    outputIndex = 1 + (k == 3);
    variation(outputIndex) = norm([models(k).A-A,models(k).B-B],'fro') / ...
        max(norm([A,B],'fro'),eps);
end
transform = berger13_symdiff_transform(A,B);

linearModel.A13 = A;
linearModel.B13Torque = B;
linearModel.f0 = models(2).report.f0;
linearModel.stateNames = models(2).report.stateNames;
linearModel.stateUnits = models(2).report.stateUnits;
linearModel.inputNames = models(2).report.controlNames;
linearModel.inputUnits = models(2).report.controlUnits;
linearModel.differenceSteps = struct('dx',models(2).report.dx, ...
    'du',models(2).report.du);
linearModel.differenceMethods = struct( ...
    'state',{models(2).report.stateSchemes}, ...
    'input',{models(2).report.controlSchemes});
linearModel.stepScaleModels = models;
linearModel.maximumRelativeStepVariation = max(variation);
linearModel.relativeStepVariation = variation;
finiteFlags = false(3,1);
for k = 1:3
    finiteFlags(k) = models(k).report.finite;
end
linearModel.finiteReal = all(finiteFlags);
linearModel.limitState = trimReport.activeLimits;
linearModel.appliedControls = trimReport.appliedControls;
linearModel.symdiff = transform;
linearModel.credibilityStatus = trimReport.status;
linearModel.claimBoundary = ['linearized at a CREDIBLE internal trim; ' ...
    'this is not external validation or handling-quality acceptance'];
end
