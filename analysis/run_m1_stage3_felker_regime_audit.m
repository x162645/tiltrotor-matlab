function results = run_m1_stage3_felker_regime_audit(outputDir)
%RUN_M1_STAGE3_FELKER_REGIME_AUDIT Corrected high-alpha/stall-regime audit.
%
% The first section-state audit retained the full C81-table global maximum
% for context.  That is NOT a valid 2-D stall marker because the published
% C81 reference tables contain high-angle extrapolation beyond the first
% lift-curve turnover.  Felker (NASA/TM-104023) defines stall using the
% lowest angle where the lift-curve slope reaches zero.  This runner keeps
% the already-solved M1-B local states and applies a source-consistent
% first-turnover criterion to identify the Felker high-alpha regime.
%
% No aerodynamic load is changed and no OARF target is used in the regime
% classification.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'results','m1_stage3_felker_regime_audit');
end
if ~exist(outputDir,'dir'), mkdir(outputDir); end

rawDir = fullfile(outputDir,'raw_section_state_audit');
raw = run_m1_stage3_inboard_high_alpha_audit(rawDir);
R = raw.radial;
P = raw.points;

n = height(R);
alpha2DStallOnset_deg = NaN(n,1);
CLAt2DStallOnset = NaN(n,1);
alphaMarginTo2DStall_deg = NaN(n,1);
meanAtOrPast2DStall = false(n,1);
maxReaches2DStall = false(n,1);
CLRelativeTo2DStall = NaN(n,1);

% Dense interpolation is used only to locate the first lift-curve turnover.
% Search starts at 4 deg to avoid irrelevant low-alpha table irregularities
% and ends at 20 deg so the later post-stall C81 extrapolation cannot be
% mistaken for the first 2-D stall onset.
alphaGrid_deg = (4:0.1:20).';
for i = 1:n
    aq = alphaGrid_deg*pi/180;
    mq = R.MachMean(i)+zeros(size(aq));
    rq = R.rR(i)+zeros(size(aq));
    [clSweep,~,~] = xv15_c81_section_lookup(aq,mq,rq);
    slope = diff(clSweep)./diff(alphaGrid_deg);
    idx = find(slope <= 0,1,'first');
    if isempty(idx)
        % If no turnover occurs before 20 deg, preserve the result as an
        % unresolved/high stall angle rather than inventing a threshold.
        stallAlpha = NaN;
        clStall = NaN;
    else
        stallAlpha = alphaGrid_deg(idx);
        clStall = clSweep(idx);
    end
    alpha2DStallOnset_deg(i) = stallAlpha;
    CLAt2DStallOnset(i) = clStall;
    if isfinite(stallAlpha)
        alphaMarginTo2DStall_deg(i) = stallAlpha-R.alphaMean_deg(i);
        meanAtOrPast2DStall(i) = R.alphaMean_deg(i) >= stallAlpha;
        maxReaches2DStall(i) = R.alphaMax_deg(i) >= stallAlpha;
    end
    if isfinite(clStall) && abs(clStall) > 1e-12
        CLRelativeTo2DStall(i) = R.CLMean(i)/clStall;
    end
end

R.alpha2DStallOnset_deg = alpha2DStallOnset_deg;
R.CLAt2DStallOnset = CLAt2DStallOnset;
R.alphaMarginTo2DStall_deg = alphaMarginTo2DStall_deg;
R.meanAtOrPast2DStall = meanAtOrPast2DStall;
R.maxReaches2DStall = maxReaches2DStall;
R.CLRelativeTo2DStall = CLRelativeTo2DStall;
writetable(R,fullfile(outputDir,'M1_STAGE3_FELKER_REGIME_RADIAL.csv'));

S = table();
for k = 1:height(P)
    coll = P.collective75_deg(k);
    maskPoint = R.collective75_deg == coll;
    inboard = maskPoint & R.rR < 0.55;
    meanPost = inboard & R.meanAtOrPast2DStall;
    maxPost = inboard & R.maxReaches2DStall;
    resolved = inboard & isfinite(R.alpha2DStallOnset_deg);

    one = table(coll,P.CT_model(k),P.CT_relativeError_pct(k), ...
        P.CP_model(k),P.CP_relativeError_pct(k), ...
        sum(inboard),sum(resolved),sum(meanPost),sum(maxPost), ...
        sum(R.ringThrustFraction(inboard)), ...
        sum(R.ringThrustFraction(meanPost)), ...
        sum(R.ringThrustFraction(maxPost)), ...
        sum(R.ringTorqueFraction(inboard)), ...
        sum(R.ringTorqueFraction(meanPost)), ...
        sum(R.ringTorqueFraction(maxPost)), ...
        min(R.alphaMarginTo2DStall_deg(resolved)), ...
        max(R.CLRelativeTo2DStall(resolved)), ...
        'VariableNames',{'collective75_deg','CT_model','CT_relativeError_pct', ...
        'CP_model','CP_relativeError_pct','inboardStationCount', ...
        'stallOnsetResolvedStationCount','meanPostStallStationCount', ...
        'maxExposurePostStallStationCount','inboardThrustFraction', ...
        'meanPostStallThrustFraction','maxExposurePostStallThrustFraction', ...
        'inboardTorqueFraction','meanPostStallTorqueFraction', ...
        'maxExposurePostStallTorqueFraction','minimumMeanAlphaMarginToStall_deg', ...
        'maximumCLRelativeTo2DStall'});
    S = [S;one]; %#ok<AGROW>
end
writetable(S,fullfile(outputDir,'M1_STAGE3_FELKER_REGIME_POINTS.csv'));

metadataName = { ...
    'model_identity';'aerodynamic_model_modified';'source_hypothesis'; ...
    'stall_definition';'stall_search_window';'inboard_definition'; ...
    'dataset_role';'parameter_fit_to_OARF_targets';'interpretation_boundary'};
metadataValue = { ...
    'M1_B_FELKER_REGIME_AUDIT';'NO'; ...
    'NASA_TM_104023_INBOARD_HIGH_ALPHA_ROTATIONAL_STALL_DELAY'; ...
    'FIRST_NONPOSITIVE_LOCAL_C81_LIFT_CURVE_SLOPE'; ...
    '4_TO_20_DEG_EXCLUDES_LATER_HIGH_ALPHA_EXTRAPOLATION'; ...
    'r_R_LT_0p55';'DEVELOPMENT_EXTERNAL_CORRELATION';'NO'; ...
    'REGIME_DIAGNOSIS_ONLY_NOT_STALL_DELAY_MODEL_VALIDATION'};
writetable(table(metadataName,metadataValue), ...
    fullfile(outputDir,'M1_STAGE3_FELKER_REGIME_METADATA.csv'));

results = struct();
results.radial = R;
results.points = S;
results.claimBoundary = [ ...
    'FELKER_REGIME_AUDIT_NO_AERO_CHANGE_NO_OARF_FIT_' ...
    'FIRST_C81_LIFT_CURVE_TURNOVER_NOT_GLOBAL_TABLE_MAX'];
save(fullfile(outputDir,'M1_STAGE3_FELKER_REGIME_RESULTS.mat'),'results');
end
