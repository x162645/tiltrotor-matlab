function linearModel = linearize_berger13_command_trim_point( ...
        trimReport,P13)
%LINEARIZE_BERGER13_COMMAND_TRIM_POINT Credibility-gated command A/B model.

if nargin < 2 || isempty(P13)
    P13 = params_berger13();
end
if ~isstruct(trimReport) || ~isfield(trimReport,'credible') || ...
        ~trimReport.credible || ~strcmp(trimReport.inputContract,'ANGLE_COMMAND')
    error('linearize_berger13_command_trim_point:NonCrediblePoint', ...
        'A CREDIBLE angle-command trim report is required.');
end
scales = [0.1;1;10];
models = repmat(struct('scale',NaN,'A',[],'B',[],'report',[]),3,1);
for k = 1:3
    [models(k).A,models(k).B,models(k).report] = ...
        linearize_13x10_command_numeric(trimReport.x13, ...
        trimReport.u10Command,P13,scales(k));
    models(k).scale = scales(k);
end
A = models(2).A;
B = models(2).B;
variation = zeros(2,1);
for k = [1,3]
    index = 1+(k==3);
    variation(index) = norm([models(k).A-A,models(k).B-B],'fro') / ...
        max(norm([A,B],'fro'),eps);
end
finiteFlags = false(3,1);
for k = 1:3
    finiteFlags(k) = models(k).report.finiteReal;
end
linearModel.A13Command = A;
linearModel.B13Command = B;
linearModel.f0 = models(2).report.f0;
linearModel.stateNames = models(2).report.stateNames;
linearModel.inputNames = models(2).report.inputNames;
linearModel.stateUnits = models(2).report.stateUnits;
linearModel.inputUnits = models(2).report.inputUnits;
linearModel.stepScaleModels = models;
linearModel.relativeStepVariation = variation;
linearModel.maximumRelativeStepVariation = max(variation);
linearModel.finiteReal = all(finiteFlags);
linearModel.symdiff = berger13_symdiff_transform(A,B);
linearModel.inputContract = 'ANGLE_COMMAND';
linearModel.claimBoundary = ['finite command A/B at an internally credible ' ...
    'trim does not establish external validation'];
end
