function results = run_stage10_sheng_comparison_definition(outputDir)
%RUN_STAGE10_SHENG_COMPARISON_DEFINITION Isolate NUAA comparison definitions.
%
% This experiment does NOT alter production control allocation and does NOT
% fit any external target. It quantifies the effect of a previously audited
% comparison-definition mismatch:
%   - NUAA 15 deg nacelle case: production conversion definition versus
%     paper-comparison strict helicopter manipulation.
%   - NUAA 75 deg nacelle case: production conversion definition versus
%     paper-comparison fixed-wing manipulation.
%
% Important: these labels refer only to the paper-comparison contract. They
% are not claims that the production conversion allocation is physically
% incorrect for the generic aircraft model.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'results','stage10_sheng_comparison_definition');
end
if ~exist(outputDir,'dir'), mkdir(outputDir); end

P = params_nominal();
d2r = pi/180;

cases = struct([]);
cases(1).caseName = 'FIG6A_NUAA15';
cases(1).nuaaNacelle_deg = 15;
cases(1).betaM_deg = 75;
cases(1).speeds = 10:10:60;
cases(1).productionMode = 'conversion_longitudinal';
cases(1).paperMode = 'helicopter_longitudinal';
cases(1).paperRole = 'STRICT_HELICOPTER_MANIPULATION_COMPARISON';

cases(2).caseName = 'FIG6B_NUAA75';
cases(2).nuaaNacelle_deg = 75;
cases(2).betaM_deg = 15;
cases(2).speeds = [70,85,100,115,130,145];
cases(2).productionMode = 'conversion_longitudinal';
cases(2).paperMode = 'airplane_longitudinal';
cases(2).paperRole = 'FIXED_WING_MANIPULATION_COMPARISON';

rows = table();
for ic = 1:numel(cases)
    c = cases(ic);
    definitions = {c.productionMode,c.paperMode};
    roles = {'PRODUCTION_COMPARISON_DEFINITION',c.paperRole};
    for id = 1:2
        modeName = definitions{id};
        seed = [];
        for iv = 1:numel(c.speeds)
            condition = struct('V',c.speeds(iv), ...
                'betaM',c.betaM_deg*d2r,'gamma',0);
            definition = make_trim_definition(modeName,condition,P);
            if ~isempty(seed) && numel(seed)==numel(definition.initialValues)
                definition.initialValues = seed;
            end
            one = solve_one(condition,definition,P,c,roles{id});
            rows = [rows;one]; %#ok<AGROW>
            if one.trimConverged
                seed = one.solutionVector_rad{1};
            else
                seed = [];
            end
        end
    end
end
writetable(removevars(rows,{'solutionVector_rad'}), ...
    fullfile(outputDir,'STAGE10_POINT_COMPARISON.csv'));

paired = build_paired_delta(rows,cases);
writetable(paired,fullfile(outputDir,'STAGE10_PAPER_DEFINITION_DELTAS.csv'));

summary = build_summary(rows,paired,cases);
writetable(summary,fullfile(outputDir,'STAGE10_CASE_SUMMARY.csv'));

metadataName = { ...
    'experiment_identity'; ...
    'physics_change'; ...
    'production_allocation_modified'; ...
    'external_target_fit'; ...
    'external_error_score'; ...
    'fig6a_comparison'; ...
    'fig6b_comparison'; ...
    'speed_grids'; ...
    'claim_boundary'};
metadataValue = { ...
    'S1_COMPARISON_DEFINITION_ISOLATION'; ...
    'NO'; ...
    'NO'; ...
    'NO'; ...
    'NOT_COMPUTED_NO_MACHINE_READABLE_EXTERNAL_TARGET_IN_THIS_EXPERIMENT'; ...
    'CONVERSION_VS_STRICT_HELICOPTER_AT_NUAA15'; ...
    'CONVERSION_VS_FIXED_WING_AT_NUAA75'; ...
    'INHERITED_FROM_EXISTING_NUAA_FIG6_BASELINE'; ...
    ['ANALYSIS_ONLY_CONTROL_DEFINITION_EFFECT_' ...
     'NOT_PRODUCTION_FIX_NOT_EXTERNAL_VALIDATION']};
metadata = table(metadataName,metadataValue);
writetable(metadata,fullfile(outputDir,'STAGE10_METADATA.csv'));
write_summary(fullfile(outputDir,'STAGE10_SUMMARY.md'),summary,paired);

results = struct();
results.points = rows;
results.pairedDelta = paired;
results.summary = summary;
results.metadata = metadata;
results.claimBoundary = metadataValue{end};
save(fullfile(outputDir,'STAGE10_SHENG_COMPARISON_DEFINITION_RESULTS.mat'), ...
    'results','-v7');
end

function one = solve_one(condition,definition,P,c,role)
modelDefinition = {definition.mode};
comparisonRole = {role};
caseName = {c.caseName};
nuaaNacelle_deg = c.nuaaNacelle_deg;
betaM_deg = c.betaM_deg;
velocity_mps = condition.V;
trimConverged = false;
solverConverged = false;
physicalConverged = false;
residualNorm = NaN;
theta_deg = NaN; alpha_deg = NaN; collective_deg = NaN;
cyclicLong_deg = NaN; elevator_deg = NaN; pitchCommand = NaN;
atLimit = false; withinLimits = false;
status = {'NOT_RUN'}; errorIdentifier = {''};
solutionVector_rad = {NaN(size(definition.initialValues))};
try
    [x,u,r] = trim_general(condition,definition,P);
    trimConverged = r.converged;
    solverConverged = r.solverConverged;
    physicalConverged = r.physicalConverged;
    residualNorm = r.residualNorm;
    theta_deg = x(8)*180/pi;
    alpha_deg = theta_deg-condition.gamma*180/pi;
    collective_deg = u(1)*180/pi;
    cyclicLong_deg = u(3)*180/pi;
    elevator_deg = u(6)*180/pi;
    atLimit = r.atLimit;
    withinLimits = r.withinLimits;
    if isfield(r.trimVariables,'pitchCommand')
        pitchCommand = r.trimVariables.pitchCommand;
    end
    z = zeros(numel(definition.unknownNames),1);
    for k=1:numel(definition.unknownNames)
        z(k) = r.trimVariables.(definition.unknownNames{k});
    end
    solutionVector_rad = {z};
    if r.converged
        status = {'SUPPORTED'};
    elseif ~r.solverConverged
        status = {'SOLVER_NOT_CONVERGED'};
    elseif ~r.physicalConverged
        status = {['PHYSICAL_' r.physicalStatus]};
    elseif r.atLimit || ~r.withinLimits
        status = {'CONTROL_OR_STATE_LIMIT'};
    else
        status = {'RESIDUAL_NOT_ACCEPTED'};
    end
catch ME
    status = {'ERROR'};
    errorIdentifier = {ME.identifier};
end
one = table(caseName,modelDefinition,comparisonRole,nuaaNacelle_deg,betaM_deg, ...
    velocity_mps,trimConverged,solverConverged,physicalConverged,residualNorm, ...
    theta_deg,alpha_deg,collective_deg,cyclicLong_deg,elevator_deg,pitchCommand, ...
    atLimit,withinLimits,status,errorIdentifier,solutionVector_rad);
end

function paired = build_paired_delta(rows,cases)
paired = table();
for ic=1:numel(cases)
    c=cases(ic);
    for iv=1:numel(c.speeds)
        V=c.speeds(iv);
        p = rows(strcmp(rows.caseName,c.caseName) & ...
            strcmp(rows.comparisonRole,'PRODUCTION_COMPARISON_DEFINITION') & ...
            rows.velocity_mps==V,:);
        s = rows(strcmp(rows.caseName,c.caseName) & ...
            ~strcmp(rows.comparisonRole,'PRODUCTION_COMPARISON_DEFINITION') & ...
            rows.velocity_mps==V,:);
        if height(p)~=1 || height(s)~=1
            error('run_stage10_sheng_comparison_definition:Pairing', ...
                'Expected one production and one paper-specific point.');
        end
        caseName={c.caseName}; velocity_mps=V;
        productionMode=p.modelDefinition; paperMode=s.modelDefinition;
        productionConverged=p.trimConverged; paperConverged=s.trimConverged;
        theta_delta_deg=s.theta_deg-p.theta_deg;
        collective_delta_deg=s.collective_deg-p.collective_deg;
        cyclicLong_delta_deg=s.cyclicLong_deg-p.cyclicLong_deg;
        elevator_delta_deg=s.elevator_deg-p.elevator_deg;
        residualNorm_delta=s.residualNorm-p.residualNorm;
        one=table(caseName,velocity_mps,productionMode,paperMode, ...
            productionConverged,paperConverged,theta_delta_deg, ...
            collective_delta_deg,cyclicLong_delta_deg,elevator_delta_deg, ...
            residualNorm_delta);
        paired=[paired;one]; %#ok<AGROW>
    end
end
end

function summary=build_summary(rows,paired,cases)
summary=table();
for ic=1:numel(cases)
    c=cases(ic);
    r=rows(strcmp(rows.caseName,c.caseName),:);
    d=paired(strcmp(paired.caseName,c.caseName),:);
    prod=r(strcmp(r.comparisonRole,'PRODUCTION_COMPARISON_DEFINITION'),:);
    paper=r(~strcmp(r.comparisonRole,'PRODUCTION_COMPARISON_DEFINITION'),:);
    caseName={c.caseName};
    productionMode={c.productionMode}; paperMode={c.paperMode};
    pointCount=numel(c.speeds);
    productionSupported=sum(prod.trimConverged);
    paperSupported=sum(paper.trimConverged);
    pairBothSupported=sum(d.productionConverged & d.paperConverged);
    valid=d.productionConverged & d.paperConverged;
    meanAbsThetaDelta_deg=NaN; maxAbsThetaDelta_deg=NaN;
    meanAbsCollectiveDelta_deg=NaN; maxAbsCollectiveDelta_deg=NaN;
    meanAbsCyclicDelta_deg=NaN; maxAbsCyclicDelta_deg=NaN;
    meanAbsElevatorDelta_deg=NaN; maxAbsElevatorDelta_deg=NaN;
    if any(valid)
        meanAbsThetaDelta_deg=mean(abs(d.theta_delta_deg(valid)));
        maxAbsThetaDelta_deg=max(abs(d.theta_delta_deg(valid)));
        meanAbsCollectiveDelta_deg=mean(abs(d.collective_delta_deg(valid)));
        maxAbsCollectiveDelta_deg=max(abs(d.collective_delta_deg(valid)));
        meanAbsCyclicDelta_deg=mean(abs(d.cyclicLong_delta_deg(valid)));
        maxAbsCyclicDelta_deg=max(abs(d.cyclicLong_delta_deg(valid)));
        meanAbsElevatorDelta_deg=mean(abs(d.elevator_delta_deg(valid)));
        maxAbsElevatorDelta_deg=max(abs(d.elevator_delta_deg(valid)));
    end
    one=table(caseName,productionMode,paperMode,pointCount,productionSupported, ...
        paperSupported,pairBothSupported,meanAbsThetaDelta_deg,maxAbsThetaDelta_deg, ...
        meanAbsCollectiveDelta_deg,maxAbsCollectiveDelta_deg,meanAbsCyclicDelta_deg, ...
        maxAbsCyclicDelta_deg,meanAbsElevatorDelta_deg,maxAbsElevatorDelta_deg);
    summary=[summary;one]; %#ok<AGROW>
end
end

function write_summary(path,S,D)
fid=fopen(path,'w');
if fid<0, error('run_stage10_sheng_comparison_definition:Open','Cannot open summary.'); end
cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'# Stage 10 Sheng comparison-definition isolation\n\n');
fprintf(fid,'No production allocation was changed and no external target was fitted.\n\n');
for i=1:height(S)
    fprintf(fid,['- %s: production %d/%d supported; paper-specific %d/%d; ' ...
        'paired supported %d/%d. Mean |delta| theta %.6g deg, collective %.6g deg, ' ...
        'cyclic %.6g deg, elevator %.6g deg.\n'],S.caseName{i}, ...
        S.productionSupported(i),S.pointCount(i),S.paperSupported(i),S.pointCount(i), ...
        S.pairBothSupported(i),S.pointCount(i),S.meanAbsThetaDelta_deg(i), ...
        S.meanAbsCollectiveDelta_deg(i),S.meanAbsCyclicDelta_deg(i), ...
        S.meanAbsElevatorDelta_deg(i));
end
fprintf(fid,'\nUnsupported/failure points are retained in STAGE10_POINT_COMPARISON.csv.\n');
fprintf(fid,'This experiment measures comparison-definition sensitivity, not external accuracy.\n');
end
