function evidence = run_generic_trim_pr5a_study(outputDir,opts)
%RUN_GENERIC_TRIM_PR5A_STUDY Generate the reproducible PR5A evidence set.

if nargin < 1 || isempty(outputDir)
    root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
    outputDir=fullfile(root,'results','generic_trim_pr5a');
end
if nargin < 2, opts=struct(); end
started=tic;
ensure_dir(outputDir); figureDir=fullfile(outputDir,'figures');
rawDir=fullfile(outputDir,'raw'); ensure_dir(figureDir); ensure_dir(rawDir);

P13=params_berger13();
provenance=build_parameter_provenance_master();
writetable(provenance,fullfile(outputDir,'PARAMETER_PROVENANCE_MASTER.csv'));
write_table_markdown(fullfile(outputDir,'PARAMETER_PROVENANCE_MASTER.md'), ...
    '参数来源总表',provenance);

[~,overlay]=apply_xv15_public_overlay(P13.base);
manifest=overlay_manifest_table(overlay.records);
writetable(manifest,fullfile(outputDir,'XV15_PUBLIC_OVERLAY_MANIFEST.csv'));
write_xv15_sources(fullfile(outputDir,'XV15_PUBLIC_PARAMETER_SOURCES.md'), ...
    overlay,manifest);
write_sign_conventions(fullfile(outputDir,'SOURCE_ANGLE_AND_SIGN_CONVENTIONS.md'));
write_comparison(fullfile(outputDir,'CURRENT_VS_XV15_PARAMETER_COMPARISON.md'), ...
    provenance);

if isfield(opts,'database') && ~isempty(opts.database)
    database=opts.database;
else
    database=evaluate_generic_trim_grid(P13,struct( ...
        'variantName','MODEL_A_GENERIC_BASELINE','runMultipleSeeds',true));
end
database.variantName='MODEL_A_GENERIC_BASELINE';
if ~isfield(database,'grid')
    database.grid=generic_trim_design_grid();
end
writetable(database.summary,fullfile(rawDir,'MODEL_A_PR5A_GRID.csv'));
save(fullfile(rawDir,'MODEL_A_PR5A_DATABASE.mat'),'database','-v7.3');

moments=pitch_moment_decomposition(database);
writetable(moments,fullfile(outputDir,'PITCH_MOMENT_DECOMPOSITION.csv'));
write_moment_report(fullfile(outputDir,'PITCH_MOMENT_DECOMPOSITION.md'),moments);
reuseExisting=isfield(opts,'reuseExisting') && opts.reuseExisting;
diagCsv=fullfile(outputDir,'UNCONSTRAINED_ELEVATOR_DIAGNOSTIC.csv');
diagMat=fullfile(rawDir,'UNCONSTRAINED_ELEVATOR_DETAILS.mat');
if reuseExisting && exist(diagCsv,'file') && exist(diagMat,'file')
    unconstrained=readtable(diagCsv);
    loaded=load(diagMat,'unconstrainedDetails');
    unconstrainedDetails=loaded.unconstrainedDetails;
else
    [unconstrained,unconstrainedDetails]= ...
        unconstrained_elevator_diagnostic(database,P13);
end
writetable(unconstrained, ...
    diagCsv);
save(diagMat, ...
    'unconstrainedDetails','-v7.3');
write_root_cause(fullfile(outputDir,'TRIM_FAILURE_ROOT_CAUSE.md'), ...
    database,unconstrained,moments);

sensMat=fullfile(rawDir,'PARAMETER_SENSITIVITY_RAW.mat');
if reuseExisting && exist(sensMat,'file')
    loaded=load(sensMat,'sensitivity'); sensitivity=loaded.sensitivity;
else
    sensitivity=parameter_sensitivity_analysis(database,P13);
end
writetable(sensitivity.longTable, ...
    fullfile(outputDir,'PARAMETER_SENSITIVITY_MATRIX.csv'));
write_identifiability(fullfile(outputDir,'PARAMETER_IDENTIFIABILITY.md'), ...
    sensitivity);
save(sensMat,'sensitivity','-v7.3');

make_figures(provenance,moments,unconstrained,sensitivity,figureDir);
elapsedSeconds=toc(started);
write_evidence(fullfile(outputDir,'PR5A_EVIDENCE.md'),database, ...
    provenance,manifest,sensitivity,elapsedSeconds);

allNumeric=[database.summary.dynamicResidualNorm;moments.MyNm; ...
    unconstrained.productionResidualNorm;sensitivity.longTable.derivative];
evidence.outputDir=outputDir;
evidence.modelASummary=database.summary;
evidence.provenanceRows=height(provenance);
evidence.overlayRows=height(manifest);
evidence.sensitivityRows=height(sensitivity.longTable);
evidence.finiteReal=all(isfinite(allNumeric(~isnan(allNumeric)))) && ...
    all(arrayfun(@(p)~isempty(p.trim) && p.trim.finiteReal,database.points));
evidence.elapsedSeconds=elapsedSeconds;
save(fullfile(outputDir,'PR5A_EVIDENCE.mat'),'evidence','-v7.3');
end

function T=overlay_manifest_table(records)
n=numel(records); rows=repmat(struct('codePath','','subscripts','', ...
    'valueSI','','unitSI','','sourceClass','','claimClass','', ...
    'roleClass','','sourceFile','','pdfPage',NaN,'printedPage',NaN, ...
    'sourceTitle','','reportNumber','','authors','', ...
    'publicationYear',NaN,'locator','','originalValue','', ...
    'originalUnit','','conversion','', ...
    'configuration','','manualReview',false,'applyToModel',false,'note',''),n,1);
for k=1:n
    r=records(k); rows(k).codePath=r.path;
    rows(k).subscripts=mat2str(r.subscripts); rows(k).valueSI=mat2str(r.valueSI,12);
    rows(k).unitSI=r.unitSI; rows(k).sourceClass=r.sourceClass;
    rows(k).claimClass=r.claimClass; rows(k).roleClass=r.roleClass;
    rows(k).sourceFile=r.sourceFile; rows(k).pdfPage=r.pdfPage;
    rows(k).sourceTitle=r.sourceTitle; rows(k).reportNumber=r.reportNumber;
    rows(k).authors=r.authors; rows(k).publicationYear=r.publicationYear;
    rows(k).printedPage=r.printedPage; rows(k).locator=r.locator;
    rows(k).originalValue=r.originalValue; rows(k).originalUnit=r.originalUnit;
    rows(k).conversion=r.conversion; rows(k).configuration=r.applicableConfiguration;
    rows(k).manualReview=r.manualReview; rows(k).applyToModel=r.applyToModel;
    rows(k).note=r.note;
end
T=struct2table(rows);
end

function write_sign_conventions(path)
text=[ ...
"# 来源角度与符号约定" newline newline ...
"本文件冻结比较所用映射；所有模型输入角均为 rad，表格展示角为 deg。" newline newline ...
"|量|本项目约定|来源约定与映射|" newline ...
"|---|---|---|" newline ...
"|机体系|x 前、y 右、z 下；正 My 为右手定则俯仰力矩|所有来源先转换到本项目机体系|" newline ...
"|短舱角 betaM|0° 直升机，90° 飞机|若来源 deltaNac 为 0° 飞机、90° 直升机，则 betaM=90°-deltaNac|" newline ...
"|NUAA|代码已按 betaM=0° 直升机、90° 飞机解释其诱导速度方向|只作方法/趋势比较，不宣称完全同构|" newline ...
"|Berger|论文图中的 nacelle angle 须逐图核实；本项目展示统一转为 betaM|Berger generic model 不是 XV-15 真值|" newline ...
"|NASA XV-15|公开报告常用 conversion angle 0° airplane、90° helicopter|仅在原文定义明确时使用 betaM=90°-deltaNac|" newline ...
"|俯仰角 theta|机体相对惯性系的 3-2-1 欧拉俯仰角，抬头为正|来源曲线若符号不同必须单独标注|" newline ...
"|升降舵|正输入增大平尾 CL、产生更负 My；当前配平通常需负升降舵|不得仅凭曲线形状反转符号|" newline ...
"|总距|左右旋翼共同增加 collective|rad；图表用 deg|" newline ...
"|纵向周期变距|正 cyclicLong 使两盘法向共同向 +eD 倾斜|内部 theta1sSide=-rotDir*cyclicSide|" newline newline ...
"自动测试同时检查端点角度映射、控制方向与默认路径不变。" newline];
write_text(path,text);
end

function write_xv15_sources(path,overlay,T)
head=["# XV-15 公开参数来源" newline newline ...
"参数集 `GENERIC_MODEL_WITH_XV15_PUBLIC_OVERLAY` 是部分、显式 opt-in 的公开值覆盖层，不是完整 XV-15 模型。" newline newline ...
"主要一手来源：NASA TM X-62407（1975，Tilt Rotor Project Office Staff，Martin Maisel 协调）与 NASA TM-81244（1980，Dugan、Erhart、Schroers）。书目信息由 NASA NTRS 条目与报告扉页交叉核对。每行保留题名、报告号、作者、年份、PDF 页、印刷页、原单位、换算和适用构型。" newline newline ...
"未列字段沿用通用基线，并标记 `INHERITED_GENERIC_NOT_XV15`。旋翼转速只采用 565 rpm 直升机/悬停参考；公开的 458 rpm 飞机值无法由当前单标量接口同时表达。" newline newline ...
"## 覆盖清单" newline newline];
write_text(path,head);
append_table_markdown(path,T(:,{'codePath','valueSI','unitSI','claimClass', ...
    'reportNumber','authors','publicationYear','sourceFile','pdfPage', ...
    'printedPage','manualReview'}));
append_text(path,[newline "## 声明边界" newline newline overlay.claimBoundary newline]);
end

function write_comparison(path,T)
mask=strcmp(T.parameterSet,'PARAMS_NOMINAL_GENERIC_BASELINE') & ...
    ~cellfun(@isempty,T.xv15PublicValue);
C=T(mask,{'parameterName','currentValue','unitSI','claimClass', ...
    'xv15PublicValue','xv15DifferencePercent','note'});
write_text(path,["# 当前参数与 XV-15 公开值比较" newline newline ...
"相近量级不等于来源相同。基线列统一为 `XV15_LIKE_UNVERIFIED`，直接/推导公开值只存在于独立覆盖记录。" newline newline]);
append_table_markdown(path,C);
end

function write_moment_report(path,T)
mask=ismember(T.pointId,{'B15_V020','B45_V035','B75_V040','B75_V060','B75_V080'}) & ...
    ismember(T.component,{'rotorLeft','rotorRight','wing','fuselage', ...
    'horizontalTail','verticalTail','TOTAL','gravity_or_CG_effect'});
C=T(mask,{'pointId','component','MyNm','armMomentMyNm', ...
    'intrinsicMomentMyNm','rXFromActualCGm','rZFromActualCGm', ...
    'localSpeedMps','localDynamicPressurePa','localAlphaDeg', ...
    'elevatorDeg','controlAtLimit','finiteReal'});
write_text(path,["# 俯仰力矩分解" newline newline ...
"所有力矩均关于 `mass_properties` 返回的实际重心，力臂项使用 `cross(r,F)`。重力通过实际重心施加，因此显式重力矩为零。左右机翼行是诊断拆分，`wing` 行才进入总和。" newline newline]);
append_table_markdown(path,C);
end

function write_root_cause(path,D,U,M)
failed=D.summary(~strcmp(D.summary.status,'CREDIBLE'),:);
text=["# 配平失败根因" newline newline ...
"## 证据链" newline newline ...
"1. 生产控制限位保持不变；失败点和所有有限候选均保留。" newline ...
"2. 仅在复制的诊断参数结构中将升降舵临时放宽到 ±80°，该结果不是可飞工况。" newline ...
"3. 75°/60 m/s 在放宽后恢复内部可信配平，表明以控制权不足为主；75°/40 m/s 放宽后仍失败，表明存在几何/模型形式与多重限制。" newline ...
"4. 俯仰力矩分解表明低速 75° 工况存在旋翼、机翼和平尾共同形成的显著低头力矩缺口。" newline newline ...
"## 基线失败点" newline newline];
write_text(path,text); append_table_markdown(path,failed);
append_text(path,[newline "## 独立升降舵诊断" newline newline]);
append_table_markdown(path,U);
mask=ismember(M.pointId,failed.pointId) & strcmp(M.component,'TOTAL');
append_text(path,[newline "## 关于实际重心的总俯仰力矩" newline newline]);
append_table_markdown(path,M(mask,{'pointId','MyNm','elevatorDeg','controlAtLimit'}));
end

function write_identifiability(path,S)
sv=table((1:numel(S.singularValues)).',S.singularValues, ...
    'VariableNames',{'index','singularValue'});
text=["# 参数可辨识性分析" newline newline ...
"方法为中心参数差分与局部隐函数配平修正。矩阵覆盖 5 个代表工况、11 个候选量及姿态/控制/裕度代理/部件俯仰力矩输出。" newline newline ...
sprintf("数值秩：%d / %d；条件数：%.6g。",S.numericalRank,numel(S.parameterNames),S.conditionNumber) newline newline ...
"条件数较高表示仅凭这些稳态配平输出仍存在强相关；后续每阶段最多选择 4–6 个变量，且优先选择几何层。有效气动参数只能称为 `CALIBRATED_EFFECTIVE`。" newline newline ...
"## 奇异值" newline newline];
write_text(path,text); append_table_markdown(path,sv);
append_text(path,[newline "## |相关系数|≥0.95 的参数对" newline newline]);
append_table_markdown(path,S.highCorrelationPairs);
end

function write_evidence(path,D,P,M,S,elapsed)
[claimCount,claimName]=groupcounts(categorical(P.claimClass));
claims=table(claimName,claimCount,'VariableNames',{'claimClass','count'});
text=["# PR5A 证据" newline newline ...
sprintf("- MATLAB：%s\n",version) ...
sprintf("- 生成耗时：%.3f s\n",elapsed) ...
sprintf("- 参数审计行数：%d\n",height(P)) ...
sprintf("- XV-15 覆盖记录：%d\n",height(M)) ...
sprintf("- Model A：%d/9 CREDIBLE\n",D.credibleCount) ...
sprintf("- 敏感性长表：%d 行，全部有限实数=%d\n",height(S.longTable),all(S.longTable.finiteReal)) ...
sprintf("- 参数敏感性矩阵秩：%d，条件数 %.6g\n",S.numericalRank,S.conditionNumber) ...
"- 声明：结果证明所覆盖工况下的内部一致性，不构成 XV-15 飞行试验验证。" newline newline ...
"## claimClass 统计" newline newline];
write_text(path,text); append_table_markdown(path,claims);
append_text(path,[newline "## 9 点基线" newline newline]);
append_table_markdown(path,D.summary);
end

function make_figures(P,M,U,S,dirPath)
[claimCount,claimName]=groupcounts(categorical(P.claimClass));
f=figure('Visible','off'); bar(claimCount); set(gca,'XTickLabel',cellstr(claimName),'XTickLabelRotation',35); ylabel('参数记录数'); title('参数来源声明分类统计'); grid on; save_figure(f,dirPath,'01_参数来源分类');
mask=strcmp(P.parameterSet,'PARAMS_NOMINAL_GENERIC_BASELINE') & isfinite(P.xv15DifferencePercent);
f=figure('Visible','off'); bar(P.xv15DifferencePercent(mask)); set(gca,'XTickLabel',P.parameterName(mask),'XTickLabelRotation',35); ylabel('相对差异（%）'); title('当前通用参数与 XV-15 公开值对比'); grid on; save_figure(f,dirPath,'02_当前参数与XV15对比');
mask=ismember(M.pointId,{'B75_V040','B75_V060','B75_V080'}) & ismember(M.component,{'rotorLeft','rotorRight','wing','fuselage','horizontalTail','verticalTail'});
X=unstack(M(mask,{'pointId','component','MyNm'}),'MyNm','component');
f=figure('Visible','off'); bar(table2array(X(:,2:end)),'stacked'); set(gca,'XTickLabel',X.pointId); ylabel('俯仰力矩（N·m）'); title('75°转换工况部件俯仰力矩分解'); legend(X.Properties.VariableNames(2:end),'Location','bestoutside'); grid on; save_figure(f,dirPath,'03_75度俯仰力矩分解');
f=figure('Visible','off'); bar(categorical(U.pointId),[U.productionElevatorDeg,U.unconstrainedElevatorDeg]); yline(-20,'r--','生产下限'); ylabel('升降舵（deg）'); title('生产限位与无约束理论升降舵需求'); legend({'生产候选','独立放宽诊断'},'Location','best'); grid on; save_figure(f,dirPath,'04_无约束升降舵需求');
f=figure('Visible','off'); imagesc(S.matrix); colorbar; xlabel('候选参数'); ylabel('工况/输出组合'); title('归一化参数敏感性矩阵'); set(gca,'XTick',1:numel(S.parameterNames),'XTickLabel',S.parameterNames,'XTickLabelRotation',35); save_figure(f,dirPath,'05_归一化参数敏感性');
f=figure('Visible','off'); imagesc(S.parameterCorrelation,[-1 1]); axis square; colorbar; title('参数敏感性相关矩阵'); set(gca,'XTick',1:numel(S.parameterNames),'YTick',1:numel(S.parameterNames),'XTickLabel',S.parameterNames,'YTickLabel',S.parameterNames,'XTickLabelRotation',35); save_figure(f,dirPath,'06_参数相关矩阵');
f=figure('Visible','off'); semilogy(1:numel(S.singularValues),S.singularValues,'o-','LineWidth',1.3); xlabel('序号'); ylabel('奇异值'); title('参数敏感性矩阵奇异值谱'); grid on; save_figure(f,dirPath,'07_参数SVD');
end

function save_figure(f,dirPath,name)
set(f,'Color','w','Position',[100 100 1000 650]);
exportgraphics(f,fullfile(dirPath,[name,'.png']),'Resolution',180);
exportgraphics(f,fullfile(dirPath,[name,'.pdf']),'ContentType','vector'); close(f);
end

function write_table_markdown(path,titleText,T)
write_text(path,['# ',titleText,newline,newline]); append_table_markdown(path,T);
end
function append_table_markdown(path,T)
fid=fopen(path,'a','n','UTF-8'); assert(fid>0); cleanup=onCleanup(@()fclose(fid));
names=T.Properties.VariableNames; fprintf(fid,'|%s|\n',strjoin(names,'|')); fprintf(fid,'|%s|\n',strjoin(repmat({'---'},1,numel(names)),'|'));
for i=1:height(T)
    cells=cell(1,width(T));
    for j=1:width(T), cells{j}=escape_md(value_text(T{i,j})); end
    fprintf(fid,'|%s|\n',strjoin(cells,'|'));
end
end
function s=value_text(v)
if iscell(v), v=v{1}; end
if iscategorical(v), s=char(v); elseif ischar(v), s=v; elseif isstring(v), s=char(v); elseif islogical(v), s=mat2str(v); elseif isnumeric(v), s=mat2str(v,8); else, s='<unsupported>'; end
end
function s=escape_md(s), s=strrep(strrep(s,'|','\|'),newline,' '); end
function write_text(path,text), fid=fopen(path,'w','n','UTF-8'); assert(fid>0); cleanup=onCleanup(@()fclose(fid)); fprintf(fid,'%s',text); end
function append_text(path,text), fid=fopen(path,'a','n','UTF-8'); assert(fid>0); cleanup=onCleanup(@()fclose(fid)); fprintf(fid,'%s',text); end
function ensure_dir(path), if ~exist(path,'dir'), mkdir(path); end, end
