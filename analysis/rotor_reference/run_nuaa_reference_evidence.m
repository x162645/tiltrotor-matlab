function results = run_nuaa_reference_evidence(outputDir)
%RUN_NUAA_REFERENCE_EVIDENCE Generate same-parameter comparison evidence.
% The production and public-formula reference rotors use the same current
% conceptual parameters. Differences therefore expose implementation-form
% sensitivity; they are not external validation and are never used to tune.

rootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'results','nuaa_rotor_reference');
end
if ~exist(outputDir,'dir')
    mkdir(outputDir);
end
P = params_nominal();
P13 = params_berger13();
d2r = pi/180;
x9 = zeros(9,1);
cg = zeros(3,1);
control = struct('collective',18*d2r,'cyclicLong',0);
anglesDeg = [0;15;45;75;90];
n = numel(anglesDeg);

template = struct('betaM_deg',NaN,'implementation','', ...
    'success',false,'errorIdentifier','', ...
    'Fx_N',NaN,'Fy_N',NaN,'Fz_N',NaN, ...
    'Mx_Nm',NaN,'My_Nm',NaN,'Mz_Nm',NaN, ...
    'thrust_N',NaN,'torque_Nm',NaN,'inducedVelocity_mps',NaN, ...
    'beta0_deg',NaN,'beta1c_deg',NaN,'beta1s_deg',NaN, ...
    'inducedIterations',NaN,'flapResidualNorm',NaN);
rotorRows = repmat(template,2*n,1);
for k = 1:n
    betaM = anglesDeg(k)*d2r;
    rotorRows(2*k-1) = evaluate_rotor( ...
        rotorRows(2*k-1),betaM,'CURRENT_PRODUCTION');
    rotorRows(2*k) = evaluate_rotor( ...
        rotorRows(2*k),betaM,'NUAA_PUBLIC_FORMULA_REFERENCE');
end
rotorTable = struct2table(rotorRows);
writetable(rotorTable,fullfile(outputDir, ...
    'ROTOR_SAME_PARAMETER_COMPARISON.csv'));

wholeTemplate = struct('betaM_deg',NaN,'success',false, ...
    'errorIdentifier','', ...
    'deltaFx_N',NaN,'deltaFy_N',NaN,'deltaFz_N',NaN, ...
    'deltaMx_Nm',NaN,'deltaMy_Nm',NaN,'deltaMz_Nm',NaN, ...
    'normDeltaF_N',NaN,'normDeltaM_Nm',NaN);
wholeRows = repmat(wholeTemplate,n,1);
for k = 1:n
    betaM = anglesDeg(k)*d2r;
    wholeRows(k).betaM_deg = anglesDeg(k);
    x13 = [x9;betaM;betaM;0;0];
    u10 = [18*d2r;zeros(9,1)];
    try
        [~,~,info] = total_forces_moments_13x10_reference( ...
            x13,u10,P13);
        dF = info.referenceMinusCurrent.F;
        dM = info.referenceMinusCurrent.M;
        wholeRows(k).success = true;
        wholeRows(k).deltaFx_N = dF(1);
        wholeRows(k).deltaFy_N = dF(2);
        wholeRows(k).deltaFz_N = dF(3);
        wholeRows(k).deltaMx_Nm = dM(1);
        wholeRows(k).deltaMy_Nm = dM(2);
        wholeRows(k).deltaMz_Nm = dM(3);
        wholeRows(k).normDeltaF_N = norm(dF);
        wholeRows(k).normDeltaM_Nm = norm(dM);
    catch ME
        wholeRows(k).errorIdentifier = ME.identifier;
    end
end
wholeTable = struct2table(wholeRows);
writetable(wholeTable,fullfile(outputDir, ...
    'WHOLE_AIRCRAFT_REFERENCE_MINUS_CURRENT.csv'));

% Re-evaluate the three committed credible trim states without retrimming.
% This isolates load-model sensitivity from optimizer behavior.
archiveFile = fullfile(rootDir,'results','thesis_nacelle_consolidation', ...
    'MODEL_HIERARCHY_RESULTS.mat');
operatingTemplate = struct('pointId','','betaM_deg',NaN, ...
    'speed_mps',NaN,'success',false,'errorIdentifier','', ...
    'normCurrentF_N',NaN,'normCurrentM_Nm',NaN, ...
    'normDeltaF_N',NaN,'normDeltaM_Nm',NaN, ...
    'relativeDeltaF',NaN,'relativeDeltaM',NaN);
operatingRows = repmat(operatingTemplate,3,1);
if exist(archiveFile,'file')
    archive = load(archiveFile);
    P13Operating = params_generic_trim_optimized();
    for k = 1:3
        sim = archive.results.simulations{k};
        xOperating = sim.x(1,:).';
        uOperating = sim.u(1,:).';
        operatingRows(k).pointId = archive.results.pointSummary.pointId{k};
        operatingRows(k).betaM_deg = ...
            archive.results.pointSummary.betaMDeg(k);
        operatingRows(k).speed_mps = ...
            archive.results.pointSummary.speedMps(k);
        try
            [~,~,info] = total_forces_moments_13x10_reference( ...
                xOperating,uOperating,P13Operating);
            dF = info.referenceMinusCurrent.F;
            dM = info.referenceMinusCurrent.M;
            operatingRows(k).success = true;
            operatingRows(k).normCurrentF_N = ...
                norm(info.currentReferenceOnly.F);
            operatingRows(k).normCurrentM_Nm = ...
                norm(info.currentReferenceOnly.M);
            operatingRows(k).normDeltaF_N = norm(dF);
            operatingRows(k).normDeltaM_Nm = norm(dM);
            operatingRows(k).relativeDeltaF = norm(dF)/ ...
                max(norm(info.currentReferenceOnly.F),1);
            operatingRows(k).relativeDeltaM = norm(dM)/ ...
                max(norm(info.currentReferenceOnly.M),1);
        catch ME
            operatingRows(k).errorIdentifier = ME.identifier;
        end
    end
else
    for k = 1:3
        operatingRows(k).errorIdentifier = ...
            'run_nuaa_reference_evidence:ArchiveMissing';
    end
end
operatingTable = struct2table(operatingRows);
writetable(operatingTable,fullfile(outputDir, ...
    'CREDIBLE_OPERATING_POINT_LOAD_SENSITIVITY.csv'));

% Differential-longitudinal-cyclic response at symmetric hover.
h = 1e-4;
x13 = [x9;0;0;0;0];
u0 = [18*d2r;zeros(9,1)];
up = u0; um = u0;
up(4) = h;
um(4) = -h;
[Fp,Mp] = total_forces_moments_13x10_reference(x13,up,P13);
[Fm,Mm] = total_forces_moments_13x10_reference(x13,um,P13);
diffCyclicDerivative = ([Fp;Mp]-[Fm;Mm])/(2*h);
derivativeTable = table({'Fx';'Fy';'Fz';'Mx';'My';'Mz'}, ...
    diffCyclicDerivative, ...
    'VariableNames',{'component','derivative_per_rad'});
writetable(derivativeTable,fullfile(outputDir, ...
    'REFERENCE_DIFF_CYCLIC_DERIVATIVE.csv'));

results.modelId = 'NUAA_PUBLIC_FORMULA_REFERENCE';
results.claimBoundary = ['SAME_PARAMETER_INDEPENDENT_IMPLEMENTATION_' ...
    'COMPARISON_NOT_EXTERNAL_VALIDATION'];
results.parameterSet = P;
results.rotorTable = rotorTable;
results.wholeAircraftTable = wholeTable;
results.operatingPointTable = operatingTable;
results.diffCyclicDerivative = diffCyclicDerivative;
results.generatedAt = datestr(now,30);
save(fullfile(outputDir,'NUAA_REFERENCE_EVIDENCE.mat'),'results');

fid = fopen(fullfile(outputDir,'EVIDENCE_SUMMARY.md'),'w');
if fid < 0
    error('run_nuaa_reference_evidence:OutputOpenFailed', ...
        'Could not create EVIDENCE_SUMMARY.md.');
end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'# 南航公开公式旋翼参考模型计算证据\n\n');
fprintf(fid,['本目录为同参数独立实现比较，不是南航作者程序复现，' ...
    '也不是外部试验验证。计算未改变正式默认模型或参数。\n\n']);
fprintf(fid,'- 旋翼角度工况：0°、15°、45°、75°、90°；\n');
fprintf(fid,'- 总距：18°；纵向周期变距：0°；空速：0 m/s；\n');
fprintf(fid,'- 差动纵向周期变距导数步长：1e-4 rad；\n');
fprintf(fid,'- 失败工况保留在CSV中，不插值、不补零。\n\n');
fprintf(fid,['零平面来流时，公开式(12)的方位一阶诱导分布需要' ...
    '人为选定风轴；由此产生的非零一阶挥舞和面内力属于' ...
    '适用性病态证据，不能解释为真实悬停侧向载荷。\n']);

    function row = evaluate_rotor(row,betaM,implementation)
        row.betaM_deg = betaM/d2r;
        row.implementation = implementation;
        try
            if strcmp(implementation,'CURRENT_PRODUCTION')
                [F,M,out] = rotor_model_bemt( ...
                    x9,control,betaM,-1,cg,P);
            else
                [F,M,out] = nuaa_public_formula_rotor( ...
                    x9,control,betaM,-1,cg,P);
            end
            if isfield(out,'inducedIterations')
                row.inducedIterations = out.inducedIterations;
            end
            row.success = true;
            row.Fx_N = F(1); row.Fy_N = F(2); row.Fz_N = F(3);
            row.Mx_Nm = M(1); row.My_Nm = M(2); row.Mz_Nm = M(3);
            row.thrust_N = out.thrust;
            row.torque_Nm = out.torque;
            row.inducedVelocity_mps = out.inducedVelocity;
            row.beta0_deg = out.beta0/d2r;
            row.beta1c_deg = out.beta1c/d2r;
            row.beta1s_deg = out.beta1s/d2r;
            row.flapResidualNorm = out.flap.residualNorm;
        catch ME
            row.errorIdentifier = ME.identifier;
        end
    end
end
