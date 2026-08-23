function results = run_xv15_metal_hover_validation(outputDir)
%RUN_XV15_METAL_HOVER_VALIDATION XV-15 原始金属桨悬停外部验模。
%
% 本函数保持 production rotor_model_bemt 的物理形式不变，仅为 NASA
% XV-15 原始金属桨 OARF 悬停试验建立一个验证用参数实例，并将计算结果
% 与 NASA CR-2017-219486 Appendix A Table A-2（原始数据来自 TM-86833）
% 的 Run 15 第一组升总距数据比较。
%
% 重要边界：
% 1) 不修改 params_nominal.m；
% 2) 不用试验 CT/CP 反调任何物理参数；
% 3) 弦长采用简单面积等效；
% 4) 真实非线性扭转按 NASA Appendix A Figure A-2 多项式，降阶为当前
%    程序能表达的一条线性扭转，并以 0.75R 桨距定义为锚点；
% 5) 当前低阶截面气动参数 liftSlope/CLmax/CD0/kCD 保持 generic 默认值；
% 6) Ib/Sblade 保持 generic 质量分布假设，仅随 R 重新保持内部自洽，
%    不将其声称为 XV-15 真实桨叶质量参数；
% 7) 低总距不收敛或物理分支不支持时原样记录，不隐藏失败。

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir, 'results', 'xv15_metal_hover_validation');
end
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

Pbase = params_nominal();
d2r = pi/180;
R = 3.81;
rootCut = 0.0875;

%% NASA OARF Run 15 第一组升总距数据（Appendix A Table A-2）
collective75_deg = [0; 2; 4; 6; 7; 8; 9; 10; 11];
Vtip_fps = [769.0; 768.7; 768.4; 768.4; 768.4; 768.4; 768.0; 768.0; 767.7];
CT_exp = [0.004063; 0.005581; 0.007391; 0.009208; 0.010104; ...
          0.011063; 0.012035; 0.013089; 0.013929];
CP_exp = [0.000315; 0.000426; 0.000588; 0.000796; 0.000913; ...
          0.001044; 0.001188; 0.001358; 0.001523];
FM_exp = [0.5814; 0.6921; 0.7641; 0.7849; 0.7866; ...
          0.7881; 0.7858; 0.7797; 0.7632];

%% 当前低阶模型可表达的几何映射
% Figure A-3：0.0875R 附近约 17 in，至 0.25R 线性减为 14 in，之后 14 in。
xGeom = linspace(rootCut, 1, 4001).';
chord_in = 14*ones(size(xGeom));
inboard = xGeom <= 0.25;
chord_in(inboard) = -18.4615*xGeom(inboard) + 18.6154;
chordEq_m = trapz(xGeom, chord_in)/(1-rootCut)*0.0254;

% Figure A-2：XV-15 原始金属桨扭转多项式，角度单位 deg。
thetaSource_deg = nasa_metal_twist_deg(xGeom);
theta75Source_deg = nasa_metal_twist_deg(0.75);
xNorm = (xGeom-rootCut)/(1-rootCut);
x75 = (0.75-rootCut)/(1-rootCut);
shapeCoordinate = xNorm-x75;
shapeTarget = thetaSource_deg-theta75Source_deg;
% 以 0.75R 为锚点的一参数普通最小二乘线性降阶。
twistTipEq_deg = trapz(xGeom, shapeCoordinate.*shapeTarget) / ...
    trapz(xGeom, shapeCoordinate.^2);
twistFit_deg = theta75Source_deg + twistTipEq_deg*shapeCoordinate;
twistRms_deg = sqrt(trapz(xGeom, (thetaSource_deg-twistFit_deg).^2) / ...
    (1-rootCut));
twistMaxAbs_deg = max(abs(thetaSource_deg-twistFit_deg));

Ptemplate = Pbase;
Ptemplate.rotor.R = R;
Ptemplate.rotor.Nb = 3;
Ptemplate.rotor.rootCut = rootCut;
Ptemplate.rotor.chord = chordEq_m;
Ptemplate.rotor.twistTip = twistTipEq_deg*d2r;
% 维持 generic 均匀桨叶质量假设的内部自洽，不作为 XV-15 来源参数。
Ptemplate.rotor.Ib = Ptemplate.rotor.bladeMass*R^2/3;
Ptemplate.rotor.Sblade = Ptemplate.rotor.bladeMass*R/2;

%% 逐试验点调用正式 production rotor model
n = numel(collective75_deg);
rows = repmat(empty_row(), n, 1);
for k = 1:n
    P = Ptemplate;
    Vtip_mps = Vtip_fps(k)*0.3048;
    P.rotor.Omega = Vtip_mps/R;
    collectiveModel_deg = collective75_deg(k) - twistTipEq_deg*x75;
    ctrl = struct('collective', collectiveModel_deg*d2r, 'cyclicLong', 0);

    rows(k).collective75_deg = collective75_deg(k);
    rows(k).Vtip_fps = Vtip_fps(k);
    rows(k).rpm = P.rotor.Omega*60/(2*pi);
    rows(k).modelCollective_deg = collectiveModel_deg;
    rows(k).CT_exp = CT_exp(k);
    rows(k).CP_exp = CP_exp(k);
    rows(k).FM_exp = FM_exp(k);

    try
        [~, ~, out] = rotor_model_bemt(zeros(9,1), ctrl, 0, -1, zeros(3,1), P);
        rows(k).returned = true;
        rows(k).physicalStatus = out.physicalStatus;
        rows(k).numericalConverged = out.numericalConverged;
        rows(k).physicalConverged = out.physicalConverged;
        rows(k).iterations = out.iterations;
        rows(k).inducedVelocity_mps = out.inducedVelocity;
        rows(k).closureResidualRelative = out.inducedClosureResidualRelative;
        rows(k).thrust_N = out.thrust;
        rows(k).torque_Nm = out.torque;

        A = pi*R^2;
        denomT = P.env.rho*A*Vtip_mps^2;
        rows(k).CT_model = out.thrust/denomT;
        rows(k).CP_model = out.torque*P.rotor.Omega/(P.env.rho*A*Vtip_mps^3);
        if rows(k).CT_model > 0 && rows(k).CP_model > 0
            rows(k).FM_model = rows(k).CT_model^(3/2)/(sqrt(2)*rows(k).CP_model);
        end
        rows(k).CT_relativeError_pct = 100*(rows(k).CT_model-CT_exp(k))/CT_exp(k);
        rows(k).CP_relativeError_pct = 100*(rows(k).CP_model-CP_exp(k))/CP_exp(k);
        if isfinite(rows(k).FM_model)
            rows(k).FM_relativeError_pct = 100*(rows(k).FM_model-FM_exp(k))/FM_exp(k);
        end
    catch ME
        rows(k).physicalStatus = ME.identifier;
        rows(k).errorIdentifier = ME.identifier;
        rows(k).errorMessage = ME.message;
    end
end
validationTable = struct2table(rows);
writetable(validationTable, fullfile(outputDir, 'XV15_METAL_HOVER_MATLAB_VALIDATION.csv'));

%% 只用 production 明确物理收敛的点计算原始外部验模指标
valid = validationTable.physicalConverged & ...
    isfinite(validationTable.CT_model) & isfinite(validationTable.CP_model);
metricName = {'CT_MAE'; 'CT_RMSE'; 'CT_MAPE_PCT'; ...
              'CP_MAE'; 'CP_RMSE'; 'CP_MAPE_PCT'; ...
              'FM_MAE'; 'FM_RMSE'; 'FM_MAPE_PCT'};
metricValue = NaN(size(metricName));
if any(valid)
    metricValue(1:3) = error_metrics(validationTable.CT_model(valid), CT_exp(valid));
    metricValue(4:6) = error_metrics(validationTable.CP_model(valid), CP_exp(valid));
    fmValid = valid & isfinite(validationTable.FM_model);
    if any(fmValid)
        metricValue(7:9) = error_metrics(validationTable.FM_model(fmValid), FM_exp(fmValid));
    end
end
metricTable = table(metricName, metricValue);
writetable(metricTable, fullfile(outputDir, 'XV15_METAL_HOVER_MATLAB_METRICS.csv'));

%% 10 deg 点的基本径向/方位离散敏感性
radialCases = [6; 12; 24; 48; 96];
convRows = table();
for k = 1:numel(radialCases)
    convRows = [convRows; run_convergence_case(Ptemplate, 10, 768.0, ...
        twistTipEq_deg, x75, radialCases(k), 16)]; %#ok<AGROW>
end
azCases = [8; 16; 32; 64];
for k = 1:numel(azCases)
    if azCases(k) == 16
        continue;
    end
    convRows = [convRows; run_convergence_case(Ptemplate, 10, 768.0, ...
        twistTipEq_deg, x75, 48, azCases(k))]; %#ok<AGROW>
end
writetable(convRows, fullfile(outputDir, 'XV15_METAL_HOVER_MATLAB_CONVERGENCE.csv'));

%% 映射信息单独输出，避免把 derived 值误写成 NASA 直接参数
mappingName = {'R_m'; 'rootCut'; 'chordEq_m'; 'twistTipEq_deg'; ...
    'theta75Source_deg'; 'twistRms_deg'; 'twistMaxAbs_deg'; ...
    'generic_liftSlope_1_per_rad'; 'generic_CLmax'; 'generic_CD0'; 'generic_kCD'};
mappingValue = [R; rootCut; chordEq_m; twistTipEq_deg; ...
    theta75Source_deg; twistRms_deg; twistMaxAbs_deg; ...
    Pbase.rotor.liftSlope; Pbase.rotor.CLmax; Pbase.rotor.CD0; Pbase.rotor.kCD];
mappingTable = table(mappingName, mappingValue);
writetable(mappingTable, fullfile(outputDir, 'XV15_METAL_HOVER_MAPPING.csv'));

results = struct();
results.validationTable = validationTable;
results.metricTable = metricTable;
results.convergenceTable = convRows;
results.mappingTable = mappingTable;
results.validPhysicalPointCount = sum(valid);
results.claimBoundary = ['XV15_ORIGINAL_METAL_BLADE_COMPONENT_HOVER_EXTERNAL_' ...
    'VALIDATION_NO_HOLDOUT_TUNING'];
save(fullfile(outputDir, 'XV15_METAL_HOVER_VALIDATION_RESULTS.mat'), 'results');
end

function theta_deg = nasa_metal_twist_deg(x)
theta_deg = 289.98*x.^5 - 892.87*x.^4 + 987.06*x.^3 ...
    - 438.31*x.^2 + 15.695*x + 32.057;
end

function row = run_convergence_case(Ptemplate, collective75_deg, Vtip_fps, ...
        twistTipEq_deg, x75, nRadial, nAzimuth)
P = Ptemplate;
P.rotor.nRadial = nRadial;
P.rotor.nAzimuth = nAzimuth;
Vtip_mps = Vtip_fps*0.3048;
P.rotor.Omega = Vtip_mps/P.rotor.R;
modelCollective_deg = collective75_deg-twistTipEq_deg*x75;
ctrl = struct('collective', modelCollective_deg*pi/180, 'cyclicLong', 0);
status = 'NOT_RUN';
CT = NaN;
CP = NaN;
iterations = NaN;
try
    [~, ~, out] = rotor_model_bemt(zeros(9,1), ctrl, 0, -1, zeros(3,1), P);
    status = out.physicalStatus;
    iterations = out.iterations;
    A = pi*P.rotor.R^2;
    CT = out.thrust/(P.env.rho*A*Vtip_mps^2);
    CP = out.torque*P.rotor.Omega/(P.env.rho*A*Vtip_mps^3);
catch ME
    status = ME.identifier;
end
row = table(nRadial, nAzimuth, {status}, iterations, CT, CP, ...
    'VariableNames', {'nRadial','nAzimuth','status','iterations','CT','CP'});
end

function metrics = error_metrics(model, experiment)
err = model-experiment;
metrics = [mean(abs(err)); sqrt(mean(err.^2)); ...
    100*mean(abs(err)./abs(experiment))];
end

function row = empty_row()
row = struct('collective75_deg',NaN,'Vtip_fps',NaN,'rpm',NaN, ...
    'modelCollective_deg',NaN,'returned',false, ...
    'numericalConverged',false,'physicalConverged',false, ...
    'physicalStatus','NOT_RUN','errorIdentifier','','errorMessage','', ...
    'iterations',NaN,'inducedVelocity_mps',NaN, ...
    'closureResidualRelative',NaN,'thrust_N',NaN,'torque_Nm',NaN, ...
    'CT_exp',NaN,'CT_model',NaN,'CT_relativeError_pct',NaN, ...
    'CP_exp',NaN,'CP_model',NaN,'CP_relativeError_pct',NaN, ...
    'FM_exp',NaN,'FM_model',NaN,'FM_relativeError_pct',NaN);
end
