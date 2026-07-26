function results = run_external_validation_calculations(outputDir)
%RUN_EXTERNAL_VALIDATION_CALCULATIONS Frozen external-comparison calculations.
% No value in the external datasets is used to tune the model.  XV-15 hover
% data are digitized from NASA-TM-86854, PDF page 54 (original page 52),
% Figure 25.  Digitization uncertainty is recorded explicitly.

rootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'results','master_thesis_validation');
end
if ~exist(outputDir,'dir')
    mkdir(outputDir);
end
P = params_nominal();
d2r = pi/180;
collectiveDeg = (0:2:22).';
% DIGITIZED from NASA-TM-86854 Fig. 25 centerline.  The report states
% collective-position uncertainty below about +/-1 deg; the ordinate
% digitization uncertainty assigned here is +/-0.003 in CT/sigma.
externalCtSigma = [0.028;0.040;0.053;0.069;0.084;0.100; ...
    0.119;0.141;0.162;0.181;0.197;0.208];
sigma = P.rotor.Nb*P.rotor.chord/(pi*P.rotor.R);
A = pi*P.rotor.R^2;
denominator = P.env.rho*A*(P.rotor.Omega*P.rotor.R)^2;
x = zeros(9,1);
cg = zeros(3,1);

implementation = {'CURRENT_PRODUCTION'; ...
    'NUAA_PUBLIC_FORMULA_REFERENCE'};
rows = repmat(struct('collective_deg',NaN,'implementation','', ...
    'success',false,'errorIdentifier','','numericalConverged',false, ...
    'physicalConverged',false,'physicalStatus','NOT_APPLICABLE', ...
    'inducedClosureResidual_N',NaN,'CT_over_sigma',NaN, ...
    'thrust_N',NaN,'torque_Nm',NaN,'inducedVelocity_mps',NaN), ...
    numel(collectiveDeg)*numel(implementation),1);
index = 0;
for i = 1:numel(collectiveDeg)
    ctrl = struct('collective',collectiveDeg(i)*d2r,'cyclicLong',0);
    for j = 1:numel(implementation)
        index = index+1;
        rows(index).collective_deg = collectiveDeg(i);
        rows(index).implementation = implementation{j};
        try
            if j == 1
                [~,~,out] = rotor_model_bemt(x,ctrl,0,-1,cg,P);
            else
                [~,~,out] = nuaa_public_formula_rotor( ...
                    x,ctrl,0,-1,cg,P);
            end
            if j == 1
                rows(index).numericalConverged = out.numericalConverged;
                rows(index).physicalConverged = out.physicalConverged;
                rows(index).physicalStatus = out.physicalStatus;
                rows(index).inducedClosureResidual_N = ...
                    out.inducedClosureResidual;
                rows(index).success = out.physicalConverged;
                if ~out.physicalConverged
                    rows(index).errorIdentifier = out.physicalStatus;
                end
            else
                rows(index).numericalConverged = true;
                rows(index).physicalConverged = true;
                rows(index).physicalStatus = 'REFERENCE_MODEL_RETURNED';
                rows(index).success = true;
            end
            rows(index).CT_over_sigma = ...
                (out.thrust/denominator)/sigma;
            rows(index).thrust_N = out.thrust;
            rows(index).torque_Nm = out.torque;
            rows(index).inducedVelocity_mps = out.inducedVelocity;
        catch ME
            rows(index).errorIdentifier = ME.identifier;
            if j == 1
                rows(index).physicalStatus = ME.identifier;
            end
        end
    end
end
modelTable = struct2table(rows);
writetable(modelTable,fullfile(outputDir,'ROTOR_HOVER_MODEL_CURVES.csv'));

externalTable = table(collectiveDeg,externalCtSigma, ...
    ones(size(collectiveDeg)),0.003*ones(size(collectiveDeg)), ...
    repmat({'NASA-TM-86854 Fig.25 digitized'},numel(collectiveDeg),1), ...
    'VariableNames',{'collective_deg','CT_over_sigma', ...
    'collective_uncertainty_deg','CT_over_sigma_uncertainty','source'});
writetable(externalTable,fullfile(outputDir, ...
    'XV15_ATB_HOVER_DIGITIZED.csv'));

metricRows = repmat(struct('implementation','','validCount',0, ...
    'failureCount',0,'MAE_CT_over_sigma',NaN, ...
    'RMSE_CT_over_sigma',NaN,'maximumAbsoluteError',NaN, ...
    'slopeSignAgreement',NaN,'evidenceLevel','L4_CORRELATION'),2,1);
for j = 1:2
    selection = strcmp(modelTable.implementation,implementation{j});
    subset = modelTable(selection,:);
    valid = subset.success & collectiveDeg >= 4;
    errorValue = subset.CT_over_sigma(valid)-externalCtSigma(valid);
    metricRows(j).implementation = implementation{j};
    metricRows(j).validCount = sum(valid);
    metricRows(j).failureCount = sum(~subset.success);
    if ~isempty(errorValue)
        metricRows(j).MAE_CT_over_sigma = mean(abs(errorValue));
        metricRows(j).RMSE_CT_over_sigma = sqrt(mean(errorValue.^2));
        metricRows(j).maximumAbsoluteError = max(abs(errorValue));
        metricRows(j).slopeSignAgreement = mean( ...
            sign(diff(subset.CT_over_sigma(valid))) == ...
            sign(diff(externalCtSigma(valid))));
    end
end
metricTable = struct2table(metricRows);
writetable(metricTable,fullfile(outputDir, ...
    'ROTOR_HOVER_EXTERNAL_COMPARISON_METRICS.csv'));

results.claimBoundary = ['INDEPENDENT_XV15_COMPONENT_TEST_CORRELATION_' ...
    'CONFIGURATION_MISMATCH_NO_TUNING'];
results.modelTable = modelTable;
results.externalTable = externalTable;
results.metricTable = metricTable;
results.sigma = sigma;
results.tipMachApprox = P.rotor.Omega*P.rotor.R/340;
save(fullfile(outputDir,'EXTERNAL_VALIDATION_RESULTS.mat'),'results');
end
