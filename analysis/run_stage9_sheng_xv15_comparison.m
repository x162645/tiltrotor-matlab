function results = run_stage9_sheng_xv15_comparison(outputDir)
%RUN_STAGE9_SHENG_XV15_COMPARISON Public-formula / M0 / frozen-M1 comparison.
%
% Stage-9 identity contract
% -------------------------
% S0 = NUAA_PUBLIC_FORMULA_REFERENCE evaluated with the same XV-15
%      metal-blade geometry/operating-point mapping used by M0. This is a
%      MODEL_FORM_DIAGNOSTIC, not Sheng author-code reproduction.
% M0 = frozen production low-order baseline.
% M1 = frozen M1_HOLDOUT_V1 (generic Corrigan n=1).
% S0-N = post-processing scale/shape decomposition only. It is NOT a model
%        and NOT a validation score. No fitted scale is fed back to physics.
%
% Dataset role: OARF Run 15 has already been used in development diagnostics
% and is therefore DEVELOPMENT_EXTERNAL_CORRELATION, never blind holdout.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'results','stage9_sheng_xv15_comparison');
end
if ~exist(outputDir,'dir'), mkdir(outputDir); end

fixedCollective = [6;7;8;9;10;11];
Vtip_fps = [768.4;768.4;768.4;768.0;768.0;767.7];
CT_exp = [0.009208;0.010104;0.011063;0.012035;0.013089;0.013929];
CP_exp = [0.000796;0.000913;0.001044;0.001188;0.001358;0.001523];
FM_exp = [0.7849;0.7866;0.7881;0.7858;0.7797;0.7632];

% Re-run immutable evidence paths. These functions do not tune to targets.
m0 = run_xv15_v1_baseline_correlation(fullfile(outputDir,'m0_recheck'));
m1Stage3 = run_m1_stage3_corrigan_stall_delay(fullfile(outputDir,'m1_recheck'));

% Build S0 with exactly the same reduced XV-15 geometry mapping used by M0.
[s0Rows,mappingTable] = run_s0_public_formula(fixedCollective,Vtip_fps, ...
    CT_exp,CP_exp,FM_exp);

% Extract fixed M0 and frozen M1 point rows into a common schema.
m0Rows = common_from_m0(m0.validationTable,fixedCollective);
m1Rows = common_from_m1(m1Stage3.points,fixedCollective);
pointTable = [s0Rows;m0Rows;m1Rows];
writetable(pointTable,fullfile(outputDir,'STAGE9_MODEL_POINT_COMPARISON.csv'));
writetable(mappingTable,fullfile(outputDir,'STAGE9_S0_XV15_MAPPING.csv'));

% Raw, non-fitted error/trend characterization for every physical model.
modelIds = {'S0_XV15_MAPPED_PUBLIC_FORMULA_REFERENCE'; ...
    'M0_PRODUCTION_LOW_ORDER';'M1_HOLDOUT_V1'};
rawMetrics = table();
for k = 1:numel(modelIds)
    mask = strcmp(pointTable.modelIdentity,modelIds{k});
    rawMetrics = [rawMetrics; model_metrics(pointTable(mask,:),modelIds{k})]; %#ok<AGROW>
end
writetable(rawMetrics,fullfile(outputDir,'STAGE9_RAW_MODEL_METRICS.csv'));

% S0-N amplitude/shape decomposition. These fitted scale factors are never
% interpreted as a physical correction or validation score.
s0Mask = strcmp(pointTable.modelIdentity,modelIds{1});
s0Diagnostic = scaling_diagnostic(pointTable(s0Mask,:));
writetable(s0Diagnostic,fullfile(outputDir,'STAGE9_S0_SCALE_SHAPE_DIAGNOSTIC.csv'));

metadataName = { ...
    'branch_identity'; ...
    's0_identity'; ...
    's0_role'; ...
    's0_author_code_claim'; ...
    's0n_role'; ...
    'm0_identity'; ...
    'm0_frozen_sha'; ...
    'm1_identity'; ...
    'dataset'; ...
    'dataset_role'; ...
    'report_window'; ...
    'target_parameter_fit'; ...
    'window_selected_after_results'; ...
    'failed_points_retained'; ...
    'claim_boundary'};
metadataValue = { ...
    'research/sheng-comparison-m2-nacelle-20260829'; ...
    'NUAA_PUBLIC_FORMULA_REFERENCE'; ...
    'XV15_MAPPED_PUBLIC_FORMULA_MODEL_FORM_DIAGNOSTIC'; ...
    'NO'; ...
    'DIAGNOSTIC_ONLY_NOT_MODEL_NOT_VALIDATION_SCORE'; ...
    'M0_PRODUCTION_LOW_ORDER'; ...
    '27f40883633ca14acc0e928649b62d7abb855491'; ...
    'M1_HOLDOUT_V1_GENERIC_CORRIGAN_N1'; ...
    'XV15_OARF_RUN15_ORIGINAL_METAL_BLADE'; ...
    'DEVELOPMENT_EXTERNAL_CORRELATION'; ...
    'FIXED_6_TO_11_DEG'; ...
    'NO'; ...
    'NO'; ...
    'YES'; ...
    ['S0_PUBLIC_FORMULA_REPRODUCIBLE_REFERENCE_NOT_AUTHOR_CODE_' ...
     'S0N_TARGET_DEPENDENT_DIAGNOSTIC_ONLY_M0_M1_FROZEN']};
metadataTable = table(metadataName,metadataValue);
writetable(metadataTable,fullfile(outputDir,'STAGE9_METADATA.csv'));

write_summary(fullfile(outputDir,'STAGE9_SUMMARY.md'),rawMetrics, ...
    s0Diagnostic,pointTable);

results = struct();
results.pointTable = pointTable;
results.rawMetrics = rawMetrics;
results.s0ScaleShapeDiagnostic = s0Diagnostic;
results.mappingTable = mappingTable;
results.metadataTable = metadataTable;
results.m0 = m0;
results.m1Stage3 = m1Stage3;
results.claimBoundary = metadataValue{end};
save(fullfile(outputDir,'STAGE9_SHENG_XV15_COMPARISON_RESULTS.mat'), ...
    'results','-v7');
end

function [T,mappingTable] = run_s0_public_formula(collective75_deg,Vtip_fps, ...
        CT_exp,CP_exp,FM_exp)
Pbase = params_nominal();
d2r = pi/180;
R = 3.81;
rootCut = 0.0875;
xGeom = linspace(rootCut,1,4001).';
chord_in = 14*ones(size(xGeom));
inboard = xGeom <= 0.25;
chord_in(inboard) = -18.4615*xGeom(inboard)+18.6154;
chordEq_m = trapz(xGeom,chord_in)/(1-rootCut)*0.0254;
thetaSource_deg = nasa_metal_twist_deg(xGeom);
theta75Source_deg = nasa_metal_twist_deg(0.75);
xNorm = (xGeom-rootCut)/(1-rootCut);
x75 = (0.75-rootCut)/(1-rootCut);
shapeCoordinate = xNorm-x75;
shapeTarget = thetaSource_deg-theta75Source_deg;
twistTipEq_deg = trapz(xGeom,shapeCoordinate.*shapeTarget) / ...
    trapz(xGeom,shapeCoordinate.^2);
twistFit_deg = theta75Source_deg+twistTipEq_deg*shapeCoordinate;
twistRms_deg = sqrt(trapz(xGeom,(thetaSource_deg-twistFit_deg).^2)/(1-rootCut));
twistMaxAbs_deg = max(abs(thetaSource_deg-twistFit_deg));

Ptemplate = Pbase;
Ptemplate.rotor.R = R;
Ptemplate.rotor.Nb = 3;
Ptemplate.rotor.rootCut = rootCut;
Ptemplate.rotor.chord = chordEq_m;
Ptemplate.rotor.twistTip = twistTipEq_deg*d2r;
Ptemplate.rotor.Ib = Ptemplate.rotor.bladeMass*R^2/3;
Ptemplate.rotor.Sblade = Ptemplate.rotor.bladeMass*R/2;

n = numel(collective75_deg);
T = empty_common_table(n);
for k = 1:n
    P = Ptemplate;
    Vtip_mps = Vtip_fps(k)*0.3048;
    P.rotor.Omega = Vtip_mps/R;
    collectiveModel_deg = collective75_deg(k)-twistTipEq_deg*x75;
    ctrl = struct('collective',collectiveModel_deg*d2r,'cyclicLong',0);
    T.modelIdentity{k} = 'S0_XV15_MAPPED_PUBLIC_FORMULA_REFERENCE';
    T.role{k} = 'MODEL_FORM_DIAGNOSTIC';
    T.collective75_deg(k) = collective75_deg(k);
    T.Vtip_fps(k) = Vtip_fps(k);
    T.CT_exp(k) = CT_exp(k); T.CP_exp(k) = CP_exp(k); T.FM_exp(k) = FM_exp(k);
    try
        [~,~,out] = nuaa_public_formula_rotor(zeros(9,1),ctrl,0,-1,zeros(3,1),P);
        A = pi*R^2;
        T.CT_model(k) = out.thrust/(P.env.rho*A*Vtip_mps^2);
        T.CP_model(k) = out.torque*P.rotor.Omega/(P.env.rho*A*Vtip_mps^3);
        if T.CT_model(k)>0 && T.CP_model(k)>0
            T.FM_model(k) = T.CT_model(k)^(3/2)/(sqrt(2)*T.CP_model(k));
        end
        T.physicalConverged(k) = out.inducedConverged && out.flap.converged && ...
            isfinite(T.CT_model(k)) && isfinite(T.CP_model(k)) && ...
            T.CT_model(k)>0 && T.CP_model(k)>0;
        if T.physicalConverged(k)
            T.status{k} = 'SUPPORTED_REFERENCE_RETURN';
        else
            T.status{k} = 'REFERENCE_RETURN_NOT_PHYSICALLY_SUPPORTED';
        end
    catch ME
        T.status{k} = ME.identifier;
        T.errorIdentifier{k} = ME.identifier;
    end
end
T = add_relative_errors(T);

mappingName = {'R_m';'rootCut';'chordEq_m';'twistTipEq_deg'; ...
    'theta75Source_deg';'twistRms_deg';'twistMaxAbs_deg'; ...
    'generic_liftSlope_1_per_rad';'generic_CLmax';'generic_CD0';'generic_kCD'};
mappingValue = [R;rootCut;chordEq_m;twistTipEq_deg;theta75Source_deg; ...
    twistRms_deg;twistMaxAbs_deg;Pbase.rotor.liftSlope;Pbase.rotor.CLmax; ...
    Pbase.rotor.CD0;Pbase.rotor.kCD];
mappingTable = table(mappingName,mappingValue);
end

function T = common_from_m0(source,collective)
mask = ismember(source.collective75_deg,collective);
S = source(mask,:);
if height(S) ~= numel(collective)
    error('run_stage9_sheng_xv15_comparison:M0Window', ...
        'M0 fixed window does not contain exactly six points.');
end
T = empty_common_table(height(S));
for k = 1:height(S)
    T.modelIdentity{k} = 'M0_PRODUCTION_LOW_ORDER';
    T.role{k} = 'FROZEN_BASELINE';
    T.collective75_deg(k) = S.collective75_deg(k);
    T.Vtip_fps(k) = S.Vtip_fps(k);
    T.CT_exp(k) = S.CT_exp(k); T.CT_model(k) = S.CT_model(k);
    T.CP_exp(k) = S.CP_exp(k); T.CP_model(k) = S.CP_model(k);
    T.FM_exp(k) = S.FM_exp(k); T.FM_model(k) = S.FM_model(k);
    T.physicalConverged(k) = S.physicalConverged(k);
    T.status{k} = char(S.physicalStatus{k});
    if ismember('errorIdentifier',S.Properties.VariableNames)
        T.errorIdentifier{k} = char(S.errorIdentifier{k});
    end
end
T = add_relative_errors(T);
end

function T = common_from_m1(source,collective)
mask = strcmp(source.mode,'CORRIGAN_GENERIC_N1') & ...
    ismember(source.collective75_deg,collective);
S = source(mask,:);
if height(S) ~= numel(collective)
    error('run_stage9_sheng_xv15_comparison:M1Window', ...
        'Frozen M1 fixed window does not contain exactly six points.');
end
T = empty_common_table(height(S));
for k = 1:height(S)
    T.modelIdentity{k} = 'M1_HOLDOUT_V1';
    T.role{k} = 'FROZEN_PHYSICS_ENHANCED_HOLDOUT_IDENTITY';
    T.collective75_deg(k) = S.collective75_deg(k);
    T.Vtip_fps(k) = S.Vtip_fps(k);
    T.CT_exp(k) = S.CT_exp(k); T.CT_model(k) = S.CT_model(k);
    T.CP_exp(k) = S.CP_exp(k); T.CP_model(k) = S.CP_model(k);
    T.FM_exp(k) = S.FM_exp(k); T.FM_model(k) = S.FM_model(k);
    T.physicalConverged(k) = S.physicalConverged(k);
    if T.physicalConverged(k), T.status{k} = 'SUPPORTED'; else, T.status{k} = 'UNSUPPORTED'; end
end
T = add_relative_errors(T);
end

function T = empty_common_table(n)
modelIdentity = repmat({''},n,1);
role = repmat({''},n,1);
collective75_deg = NaN(n,1); Vtip_fps = NaN(n,1);
CT_exp = NaN(n,1); CT_model = NaN(n,1); CT_relativeError_pct = NaN(n,1);
CP_exp = NaN(n,1); CP_model = NaN(n,1); CP_relativeError_pct = NaN(n,1);
FM_exp = NaN(n,1); FM_model = NaN(n,1); FM_relativeError_pct = NaN(n,1);
physicalConverged = false(n,1);
status = repmat({''},n,1); errorIdentifier = repmat({''},n,1);
T = table(modelIdentity,role,collective75_deg,Vtip_fps, ...
    CT_exp,CT_model,CT_relativeError_pct,CP_exp,CP_model,CP_relativeError_pct, ...
    FM_exp,FM_model,FM_relativeError_pct,physicalConverged,status,errorIdentifier);
end

function T = add_relative_errors(T)
validCT = isfinite(T.CT_model) & isfinite(T.CT_exp) & T.CT_exp~=0;
validCP = isfinite(T.CP_model) & isfinite(T.CP_exp) & T.CP_exp~=0;
validFM = isfinite(T.FM_model) & isfinite(T.FM_exp) & T.FM_exp~=0;
T.CT_relativeError_pct(validCT) = 100*(T.CT_model(validCT)-T.CT_exp(validCT))./abs(T.CT_exp(validCT));
T.CP_relativeError_pct(validCP) = 100*(T.CP_model(validCP)-T.CP_exp(validCP))./abs(T.CP_exp(validCP));
T.FM_relativeError_pct(validFM) = 100*(T.FM_model(validFM)-T.FM_exp(validFM))./abs(T.FM_exp(validFM));
end

function M = model_metrics(T,modelId)
quantities = {'CT';'CP';'FM'};
M = table();
for k = 1:numel(quantities)
    q = quantities{k};
    mf = [q '_model']; ef = [q '_exp']; rf = [q '_relativeError_pct'];
    model = T.(mf); experiment = T.(ef);
    valid = T.physicalConverged & isfinite(model) & isfinite(experiment) & experiment~=0;
    expected = height(T); supported = sum(valid);
    mae=NaN; rmse=NaN; mape=NaN; signed=NaN; pearson=NaN; spearman=NaN;
    if any(valid)
        err = model(valid)-experiment(valid);
        mae = mean(abs(err)); rmse = sqrt(mean(err.^2));
        mape = mean(abs(T.(rf)(valid))); signed = mean(T.(rf)(valid));
        pearson = pearson_corr(model(valid),experiment(valid));
        spearman = pearson_corr(simple_ranks(model(valid)),simple_ranks(experiment(valid)));
    end
    one = table({modelId},{q},expected,supported,supported==expected,mae,rmse,mape, ...
        signed,pearson,spearman,'VariableNames',{'modelIdentity','quantity', ...
        'expectedPointCount','supportedPointCount','completeFixedWindow','MAE','RMSE', ...
        'MAPE_pct','meanSignedError_pct','pearsonR','spearmanR'});
    M = [M;one]; %#ok<AGROW>
end
end

function D = scaling_diagnostic(T)
quantities = {'CT';'CP';'FM'};
D = table();
for k = 1:numel(quantities)
    q=quantities{k}; model=T.([q '_model']); experiment=T.([q '_exp']);
    valid=T.physicalConverged & isfinite(model) & isfinite(experiment) & model~=0 & experiment~=0;
    n=sum(valid); scale=NaN; rawRMSE=NaN; scaledRMSE=NaN; rawMAPE=NaN; scaledMAPE=NaN;
    pearson=NaN; spearman=NaN; ratioMean=NaN; ratioStd=NaN; ratioCV=NaN;
    if n>0
        m=model(valid); e=experiment(valid);
        denom=sum(m.^2);
        if denom>0
            scale=sum(m.*e)/denom;
            scaled=scale*m;
            rawRMSE=sqrt(mean((m-e).^2));
            scaledRMSE=sqrt(mean((scaled-e).^2));
            rawMAPE=100*mean(abs((m-e)./e));
            scaledMAPE=100*mean(abs((scaled-e)./e));
        end
        pearson=pearson_corr(m,e);
        spearman=pearson_corr(simple_ranks(m),simple_ranks(e));
        ratio=e./m; ratioMean=mean(ratio); ratioStd=std(ratio,0);
        ratioCV=ratioStd/max(abs(ratioMean),eps);
    end
    one=table({q},height(T),n,n==height(T),scale,rawRMSE,scaledRMSE,rawMAPE, ...
        scaledMAPE,rawRMSE-scaledRMSE,rawMAPE-scaledMAPE,pearson,spearman, ...
        ratioMean,ratioStd,ratioCV,{'DIAGNOSTIC_ONLY_NOT_MODEL_NOT_VALIDATION_SCORE'}, ...
        'VariableNames',{'quantity','expectedPointCount','supportedPointCount', ...
        'completeFixedWindow','leastSquaresScale_k','rawRMSE','scaledRMSE', ...
        'rawMAPE_pct','scaledMAPE_pct','RMSE_reduction','MAPE_reduction_pp', ...
        'pearsonR','spearmanR','localRatioMean','localRatioStd','localRatioCV', ...
        'diagnosticRole'});
    D=[D;one]; %#ok<AGROW>
end
end

function r = pearson_corr(a,b)
a=a(:); b=b(:);
if numel(a)<2 || numel(a)~=numel(b), r=NaN; return; end
ac=a-mean(a); bc=b-mean(b); den=sqrt(sum(ac.^2)*sum(bc.^2));
if den<=eps, r=NaN; else, r=sum(ac.*bc)/den; end
end

function ranks = simple_ranks(x)
x=x(:); [~,order]=sort(x); ranks=zeros(size(x)); ranks(order)=(1:numel(x)).';
end

function write_summary(path,rawMetrics,D,points)
fid=fopen(path,'w');
if fid<0, error('run_stage9_sheng_xv15_comparison:SummaryOpen','Cannot create summary.'); end
cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'# Stage 9 Sheng public-formula / XV-15 comparison\n\n');
fprintf(fid,'Fixed window: OARF Run 15, 0.75R collective 6--11 deg.\n\n');
fprintf(fid,'S0 is a public-formula reproducible reference with documented closures, not Sheng author code.\n\n');
fprintf(fid,'S0-N scale factors are target-dependent diagnostics only and are not physical-model corrections or validation scores.\n\n');
for i=1:height(rawMetrics)
    fprintf(fid,'- %s %s: supported %d/%d, MAPE %.6g%%, Pearson %.6g, Spearman %.6g.\n', ...
        rawMetrics.modelIdentity{i},rawMetrics.quantity{i}, ...
        rawMetrics.supportedPointCount(i),rawMetrics.expectedPointCount(i), ...
        rawMetrics.MAPE_pct(i),rawMetrics.pearsonR(i),rawMetrics.spearmanR(i));
end
fprintf(fid,'\n## S0-N scale/shape diagnostic\n\n');
for i=1:height(D)
    fprintf(fid,'- %s: k*=%.8g, raw MAPE %.6g%% -> scaled diagnostic MAPE %.6g%%, local-ratio CV %.6g, Pearson %.6g.\n', ...
        D.quantity{i},D.leastSquaresScale_k(i),D.rawMAPE_pct(i), ...
        D.scaledMAPE_pct(i),D.localRatioCV(i),D.pearsonR(i));
end
fprintf(fid,'\nFailed/unsupported point rows retained: %d.\n',sum(~points.physicalConverged));
end
