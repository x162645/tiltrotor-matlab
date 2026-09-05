# [AUDIT] M1-G 分支 OARF Run 14 / WADC 与 NASA TM-86833 只读审计

## 证据强度

- `DIRECTLY_VERIFIED`：当前研究分支、数据载体、加载函数、结果文件、元数据、Git 跟踪状态与 identity-gate 文件哈希均已直接读取。
- `DIRECTLY_VERIFIED`：NASA TM-86833 的正文、表 1、表 2、表 3、图 5，以及 NASA/CR-2017-219486 Appendix A Table A-2 已从 PDF 逐页读取，并对关键页做了渲染目视复核。
- `DIRECTLY_VERIFIED`：本文列出的 OARF Run 14 与仓库实际采用的 Run 15 Point 7–15，在 TM-86833 与 Harris Table A-2 之间的 Run/Point、collective、Mtip、CT 对照。
- `INDIRECTLY_INFERRED`：无。凡是需要计算单位换算、图线数字化或由“未找到”推出“绝对不存在”的内容，本文均不作数值推断。
- `UNVERIFIED`：TM-86833 是否在未明说处对 collective 做过其他处理；原始 WADC 报告 NASA CR-114626 的原表号、逐点 rpm、逐点密度；TM-86833 与 WPAFB/Wright Field 数据的未刊对比。

## 审计结论

1. 审计证据基线已更正为 `research/m1-large-angle-local-closure-20260902`，提交 `26acaa582358c7358c93f078b3b7fee05f28e9a7`。该分支包含 M1-G 结果。交付收尾时共享工作区被另一个过程切到其后代 `diag/twist-linearization-rpm-20260904` / `309c79133e5f86796ae7f4f232e0eab28101018e`；两提交间只新增一个诊断脚本和一个诊断文档，本文审计的源数据、loader 与 validation 产物没有变化。
2. OARF Run 14 的完整实验数据直接写在 `run_xv15_v1_run14_external_validation.m`；M1-G transport runner 又内嵌了固定报告窗口内的子集。WADC 完整数据载体是 `analysis/data/xv15_wadc_metal_table_a3.csv`。
3. 数据文件/数组进入 validation manifest 时，Run 14 与 WADC 均为 `NO_OFFSET_APPLIED`：没有对源 θ75 加减固定经验量，也没有出现约 4° 的修正。
4. M0 计算接口另有一个明确的坐标基准转换：`modelCollective_deg = collective75_deg-twistTipEq_deg*x75`。这把 0.75R collective 映射到当前低阶模型的控制参考，不改写实验 θ75，也不是 Harris/WPAFB 文献修正。Run 14 已跟踪逐点结果中，该转换后的 `modelCollective_deg` 与源 θ75 均同时保留。M1-G/M1-HOLDOUT 路径则以 0.75R 直接锚定：`thetaBlade=(theta75_deg+thetaSource_deg-theta75Source_deg)*pi/180`。
5. Run 14 和 WADC 的仓库源记录都存逐点 `Vtip_fps`，不存逐点 rpm。运行器由每点 Vtip 与 R 设置 `Omega`；没有走 `565` 默认。Run 14 跟踪结果另外保存了由该路径得到的 rpm；WADC 的逐点 rpm 未在现有跟踪产物中物化，故为 `UNAVAILABLE_NOT_MATERIALIZED`。`565` 只存在于通用 builder 的“缺 rpm 才回退”分支，本任务两组数据不经过该回退。
6. NASA TM-86833 明说总距来自作动器位置，并保留控制系统几何非线性所致、估计小于 ±1° 的误差；报告只明确说明了风对 torque/CQ 的修正，没有声明对 collective 做零风、塔架阻塞、静态/动态或仪表标定修正。（NASA TM-86833，RESULTS—Performance and Loads Data，PDF p.8 / printed p.6；WIND CORRECTIONS，PDF pp.7–8 / printed pp.5–6）
7. 在本任务逐点范围内，Harris Table A-2 的 Run 14 Point 15–27 与 Run 15 Point 7–15 的 collective、Mtip、CT 与 TM-86833 相同；Run/Point 也相同。TM 表以 m/s 给 Vtip、Harris 以 fps 给 Vtip，本文禁止自行换算，故不把两列数字宣称为逐字相同；两表 Mtip 逐点相同。TM-86833 的性能参数字典没有 CP 字段，因而 CP 的直接逐点对照为 `UNAVAILABLE`。（NASA TM-86833，Appendix A Table 3，PDF pp.12–17 / printed pp.10–15；NASA/CR-2017-219486，Appendix A Table A-2，PDF p.74 / printed p.66）
8. 对“是否约 4°修正”的事实认定：相对于直接 OARF 来源 TM-86833，逐点结果为 `A. HARRIS_UNCORRECTED`。这一新增直接证据不改写上一次仅以 CR-177436 缺少逐点原表而得到的、严格限于 Harris-vs-Bartie 表格对照的 `UNDETERMINED`。
9. TM-86833 给出径向扭转曲线（图 5），表 1将总扭转标为非线性；但没有找到逐径向站数字表。径向数值为 `UNAVAILABLE`，本文没有数字化图线。（NASA TM-86833，DESCRIPTION OF TEST APPARATUS—Rotor System，PDF p.6 / printed p.4；Table 1，PDF p.67 / printed p.63；Figure 5，PDF p.75 / printed p.71）

## 范围与只读约束

仓库根目录：

`C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g`

本次没有修改、暂存或提交任何仓库跟踪文件；没有改动模型代码、参数或数值。输出仅写入本任务的 `outputs` 目录。审计中途观察到共享仓库出现未跟踪诊断内容；收尾时另一个过程已将其中两个文件提交到上述 `diag/` 后代分支。本文没有删除、改写或纳入这些并发内容。

## 阶段 0——当前 M1-G 研究分支仓库审计

### 0.1 数据载体、构建器、验证入口与契约文件

以下为与两组数据的承载或实际加载/验证路径直接相关的完整路径。

#### OARF Run 14

- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\analysis\run_xv15_v1_run14_external_validation.m`：完整 Point 15–27 数组、M0 加载与逐点输出。
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\analysis\run_m1_stage3b_large_angle_transport_validation.m`：M1-G/M1-E transport 的 Run 14 固定窗口子集。
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\analysis\audit_xv15_v1_baseline_model_identity.m`：Run 14 M0 runner 调用的 fail-closed 身份审计。
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\model\parameter_sets\build_xv15_v1_hover_validation_instance.m`：通用验证实例的 rpm/rho 契约与 `565` 回退逻辑；Run 14 直接 runner 不调用此 builder。
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\params_nominal.m`：两条 Run 14 路径继承的 generic 环境密度。
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\results\xv15_validation_baseline\v1_run14_external_validation\XV15_V1_RUN14_M0_POINTS.csv`：完整逐点跟踪结果，含由 Vtip 路径得到的 rpm。
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\results\xv15_validation_baseline\v1_run14_external_validation\XV15_V1_RUN14_M0_METRICS.csv`
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\results\xv15_validation_baseline\v1_run14_external_validation\XV15_V1_RUN14_M0_REPORT.md`
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\results\m1_stage3b_large_angle_transport_validation\M1_STAGE3B_TRANSPORT_COMPARISON.csv`
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\results\m1_stage3b_large_angle_transport_validation\M1_STAGE3B_TRANSPORT_M1E_IDENTITY.csv`
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\results\m1_stage3b_large_angle_transport_validation\M1_STAGE3B_TRANSPORT_M1G_IDENTITY.csv`
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\results\m1_stage3b_large_angle_transport_validation\M1_STAGE3B_TRANSPORT_METADATA.csv`
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\results\m1_stage3b_large_angle_transport_validation\M1_STAGE3B_TRANSPORT_METRICS.csv`
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\.github\workflows\m1-stage3b-large-angle-transport.yml`：M1-G transport CI 入口。
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\docs\M1_STAGE3B_LARGE_ANGLE_LOCAL_CLOSURE_RESULTS.md`
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\docs\XV15_VALIDATION_EXECUTION_STATUS.md`
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\results\VALIDATION_CREDIBLE_DOMAIN_MATRIX.csv`

没有找到独立的 Run 14 测试夹具文件；fail-closed 检查位于上述 runner/identity audit 内。

#### WADC

- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\analysis\data\xv15_wadc_metal_table_a3.csv`：正式 Run 1–3 全部源记录。
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\analysis\run_m1_stage5_wadc_holdout.m`：正式 post-freeze loader、manifest gate、M0/M1 计算入口。
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\analysis\run_m1_stage3b_large_angle_transport_validation.m`：M1-G transport loader。
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\analysis\run_m1_wadc_input_homology_sensitivity.m`：由正式 Stage-5 manifest 读取 WADC 的只读环境敏感度路径。
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\params_nominal.m`：generic rho 输入。
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\results\m1_stage5_wadc_holdout\M1_STAGE5_M1_IDENTITY_EQUIVALENCE.csv`
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\results\m1_stage5_wadc_holdout\M1_STAGE5_WADC_M0_M1_COMPARISON.csv`
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\results\m1_stage5_wadc_holdout\M1_STAGE5_WADC_METADATA.csv`
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\results\m1_stage5_wadc_holdout\M1_STAGE5_WADC_METRICS.csv`
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\.github\workflows\m1-stage5-wadc-holdout.yml`
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\.github\workflows\m1-stage3b-large-angle-transport.yml`
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\.github\workflows\m1-audit-wadc-input-homology.yml`
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\docs\M1_STAGE5_WADC_SOURCE_AUDIT.md`
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\docs\M1_STAGE5_WADC_RESULTS.md`
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\docs\M1_HOLDOUT_FREEZE.md`
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\docs\M1_FULL_PHYSICS_AUDIT_20260830.md`
- `C:\Users\86173\Documents\Codex\2026-09-04\identity-gate-oarf-run14-run15-collective\work\current-research-m1g\results\VALIDATION_CREDIBLE_DOMAIN_MATRIX.csv`

没有找到独立 WADC fixture；源 CSV schema、逐 Run 点集与数量检查均内置于 `run_m1_stage5_wadc_holdout.m`。

### 0.2 Run 14 逐点原始记录

下表保持仓库源数组的小数表示；`rpm(repo output)` 是现有跟踪结果文件逐字值，不是报告原始 rpm。rho 的来源记录不存在，runner 继承 `params_nominal.m` 中的 generic 值。

|Point|θ75 (deg)|Vtip (fps)|CT|CP|FM|rpm(repo output)|rho(repo)|rpm disposition|
|---:|---:|---:|---:|---:|---:|---:|---:|---|
|15|-7|769.4|-0.000027|0.000241|0.0004|587.778303431541|1.225|derived from point Vtip; not 565|
|16|-5|769.4|0.001344|0.000185|0.1883|587.778303431541|1.225|derived from point Vtip; not 565|
|17|-3|769.4|0.002319|0.000214|0.3690|587.778303431541|1.225|derived from point Vtip; not 565|
|18|-1|769.4|0.003320|0.000277|0.4883|587.778303431541|1.225|derived from point Vtip; not 565|
|19|1|769.4|0.004732|0.000382|0.6025|587.778303431541|1.225|derived from point Vtip; not 565|
|20|3|769.0|0.006405|0.000521|0.6957|587.472725940804|1.225|derived from point Vtip; not 565|
|21|5|769.0|0.008148|0.000703|0.7398|587.472725940804|1.225|derived from point Vtip; not 565|
|22|6|768.7|0.009022|0.000815|0.7435|587.243542822752|1.225|derived from point Vtip; not 565|
|23|7|768.7|0.010095|0.000942|0.7614|587.243542822752|1.225|derived from point Vtip; not 565|
|24|8|768.4|0.010960|0.001076|0.7540|587.014359704699|1.225|derived from point Vtip; not 565|
|25|9|768.4|0.011985|0.001242|0.7470|587.014359704699|1.225|derived from point Vtip; not 565|
|26|10|768.0|0.013014|0.001427|0.7357|586.708782213963|1.225|derived from point Vtip; not 565|
|27|11|767.7|0.013978|0.001615|0.7236|586.479599095911|1.225|derived from point Vtip; not 565|

机器可读完整表见 `m1g_stage0_exact_records.csv`。

### 0.2 WADC 逐点原始记录

WADC CSV 没有 rpm 与 rho 字段。现有跟踪结果也没有逐点 rpm 文件；因此 rpm 数值为 `UNAVAILABLE_NOT_MATERIALIZED`。正式 loader 对每点执行 `Vtip_fps*0.3048` 后以 `Vtip_mps/R` 设置 `Omega`，不是 `565` 回退。rho 使用 `params_nominal.m` 中的 generic `1.225`，不是实测记录。

|Run|Point|θ75 (deg)|Vtip (fps)|Mtip|CT|CP|FM|rpm disposition|
|---:|---:|---:|---:|---:|---:|---:|---:|---|
|1|1|-3.7|596.9|0.5301|0.002520|0.000215|0.4162|runtime derived; not 565|
|1|2|-2.0|596.9|0.5301|0.003539|0.000268|0.5554|runtime derived; not 565|
|1|3|0.0|598.2|0.5312|0.005020|0.000359|0.7010|runtime derived; not 565|
|1|4|2.0|595.6|0.5289|0.006890|0.000502|0.8059|runtime derived; not 565|
|1|5|4.0|599.5|0.5324|0.008604|0.000671|0.8407|runtime derived; not 565|
|1|6|6.0|600.8|0.5336|0.010432|0.000869|0.8671|runtime derived; not 565|
|1|7|8.0|598.2|0.5312|0.011924|0.001131|0.8138|runtime derived; not 565|
|1|8|9.0|596.9|0.5301|0.012921|0.001285|0.8083|runtime derived; not 565|
|1|9|10.0|595.6|0.5289|0.013464|0.001412|0.7825|runtime derived; not 565|
|1|10|11.0|595.6|0.5289|0.014560|0.001592|0.7802|runtime derived; not 565|
|1|11|12.0|599.5|0.5324|0.014923|0.001736|0.7425|runtime derived; not 565|
|1|12|13.0|600.8|0.5336|0.015397|0.001929|0.7003|runtime derived; not 565|
|1|13|14.0|598.2|0.5312|0.015642|0.002201|0.6285|runtime derived; not 565|
|2|1|-3.7|700.3|0.6219|0.002608|0.000214|0.4400|runtime derived; not 565|
|2|2|-2.0|699.0|0.6207|0.003608|0.000262|0.5847|runtime derived; not 565|
|2|3|0.0|700.3|0.6219|0.005253|0.000365|0.7376|runtime derived; not 565|
|2|4|2.0|697.7|0.6196|0.006747|0.000504|0.7782|runtime derived; not 565|
|2|5|4.0|700.3|0.6219|0.008494|0.000664|0.8338|runtime derived; not 565|
|2|6|6.0|699.0|0.6207|0.010897|0.000942|0.8536|runtime derived; not 565|
|2|7|8.0|701.6|0.6231|0.012537|0.001205|0.8240|runtime derived; not 565|
|2|8|9.0|701.6|0.6231|0.013240|0.001295|0.8321|runtime derived; not 565|
|2|9|10.0|701.6|0.6231|0.014012|0.001497|0.7838|runtime derived; not 565|
|2|10|11.0|702.9|0.6242|0.014694|0.001674|0.7524|runtime derived; not 565|
|2|11|12.0|699.0|0.6207|0.015178|0.001936|0.6832|runtime derived; not 565|
|2|12|13.0|702.9|0.6242|0.015673|0.002076|0.6685|runtime derived; not 565|
|3|1|-3.7|739.6|0.6624|0.002680|0.000219|0.4480|runtime derived; not 565|
|3|2|-2.0|739.6|0.6624|0.003615|0.000273|0.5639|runtime derived; not 565|
|3|3|0.0|742.2|0.6648|0.005280|0.000377|0.7199|runtime derived; not 565|
|3|4|2.0|742.2|0.6648|0.007026|0.000519|0.8030|runtime derived; not 565|
|3|5|4.0|739.6|0.6624|0.008960|0.000703|0.8525|runtime derived; not 565|
|3|6|6.0|742.2|0.6648|0.010707|0.000948|0.8260|runtime derived; not 565|
|3|7|8.0|743.5|0.6660|0.012856|0.001213|0.8499|runtime derived; not 565|
|3|8|9.0|739.6|0.6624|0.013579|0.001388|0.8059|runtime derived; not 565|
|3|9|10.0|740.9|0.6636|0.014040|0.001514|0.7768|runtime derived; not 565|
|3|10|11.0|740.9|0.6636|0.014809|0.001686|0.7560|runtime derived; not 565|
|3|11|12.0|740.9|0.6636|0.015394|0.001948|0.6935|runtime derived; not 565|
|3|12|12.0|740.9|0.6636|0.015087|0.001868|0.7016|runtime derived; not 565|

### 0.3 provenance 元数据逐字摘录

#### Run 14

`analysis/run_xv15_v1_run14_external_validation.m` 的源注释原样为：

```text
% NASA CR-2017-219486 Appendix A, Table A-2, XV-15 metal-blade proprotor
% OARF Run 14.  Table A-2 defines the collective column at 3/4 radius.
```

同一文件写出的 metadata 值原样为：

```text
NASA_CR_2017_219486_APPENDIX_A_TABLE_A2_OARF_RUN14
THREE_QUARTER_RADIUS
NO
NO
YES
NO
```

对应字段依次为 `source`、`collective_reference`、`validation_target_parameter_fit`、`model_change_after_target_audit`、`same_campaign_as_run15`、`blind_claim`。仓库没有 `entry_date`、`entered_by` 或等价字段：`UNAVAILABLE`。

#### WADC

`results/m1_stage5_wadc_holdout/M1_STAGE5_WADC_METADATA.csv` 原样为：

```text
stage,STAGE_5
dataset,XV15_ORIGINAL_METAL_BLADE_WADC
dataset_role,POST_FREEZE_CROSS_FACILITY_EXTERNAL_VALIDATION
dataset_independence,MODEL_FROZEN_BEFORE_WADC_VALUES_VIEWED_ANALYST_POSTFREEZE_DATA_VISIBLE_NO_TUNING
source_compilation,NASA_CR_2017_219486_APPENDIX_A_TABLE_A3
original_test_report,NASA_CR_114626_BELL_300_099_010
facility,WADC_RIG_3_WRIGHT_PATTERSON_AFB
formal_runs,RUN_1_RUN_2_RUN_3
report_window,INHERITED_FIXED_6_TO_11_DEG_ALL_AVAILABLE_POINTS_NO_INTERPOLATION
points_per_run,5_EACH_TOTAL_15
missing_7deg_handling,NO_INTERPOLATION
model_freeze_before_WADC_values,YES
m1_freeze_record_commit,d313296a35319dc8a5e6c398adbed0d54e0f8ede
m1_model_identity,M1_HOLDOUT_V1_GENERIC_CORRIGAN_N1
m1_implementation_reference,analysis/run_m1_stage3_corrigan_stall_delay.m:CORRIGAN_GENERIC_N1
m1_identity_max_abs_difference,0
m0_model_identity,M0_PRODUCTION_LOW_ORDER
M0_parameter_fit_to_WADC,NO
M1_parameter_fit_to_WADC,NO
WADC_collective_offset_fit,NO
WADC_gain_fit,NO
WADC_model_selection,NO
WADC_facility_correction,NO
WADC_Mtip_used_to_retune_aSound,NO
failure_retention,ALL_FAILURES_AND_HIGH_ERRORS_RETAINED
claim_boundary,WADC_POSTFREEZE_CROSS_FACILITY_VALIDATION_NO_RETUNING_NOT_BLIND_WADC_FACILITY_INTERFERENCE_CAVEAT
```

仓库 provenance 因而记录：机器可读汇编来源为 NASA/CR-2017-219486 Appendix A Table A-3；所称原始试验报告为 NASA CR-114626 / Bell 300-099-010。原始 CR-114626 的具体表号没有记录：`UNAVAILABLE`；本次没有重新获取 CR-114626。尝试范围为仓库全局文本检索与现有 provenance 文档检查，失败原因是仓库只给出报告号/书目与 Harris 汇编表号，没有原始表 locator。录入日期、录入者也为 `UNAVAILABLE`。

### 0.4 数据到验证脚本的角度、转速与密度加载路径

|数据集/路径|逐函数读取结果|角度结论|Vtip/rpm 结论|rho 结论|
|---|---|---|---|---|
|Run 14 source → `run_xv15_v1_run14_external_validation`|源数组 `collective75_deg` 原样写入输出 `rows.collective75_deg`；M0 调用前另算 `modelCollective_deg = collective75_deg-twistTipEq_deg*x75`|源数据：`NO_OFFSET_APPLIED`。模型坐标：存在 0.75R→模型控制参考转换；不是源数据修正，也不是约 4°修正|逐点 Vtip 来自源数组；`Omega=Vtip/R`；跟踪结果保存 derived rpm；不走 565|`params_nominal` generic `1.225`；非逐点实测|
|Run 14 M1-G transport → `run_m1_stage3b_large_angle_transport_validation`|固定窗口 θ75 原样传给 `evaluate_pair`；M1-G helper以 θ75 为 0.75R 锚点|`NO_OFFSET_APPLIED`|逐点 Vtip 子集；`Omega=Vtip/R`；不走 565|继承 generic rho|
|WADC CSV → `run_m1_stage5_wadc_holdout` manifest|`readtable` 后只按正式 Run 与固定 θ75 窗口筛选，不改数值|manifest：`NO_OFFSET_APPLIED`|逐点 Vtip 来自 CSV；M0、M1 均 `Omega=Vtip/R`；不走 565|继承 generic rho|
|WADC manifest → Stage-5 M0|`solve_m0_direct` 执行与 Run 14 同类 0.75R→M0 控制参考转换|源数据：`NO_OFFSET_APPLIED`；模型坐标转换明确存在，但不是数据校正|沿用逐点 Vtip-derived Omega|generic rho|
|WADC manifest → Stage-5 M1|`thetaBlade=theta75+thetaSource-theta75Source`，使 0.75R 等于输入 θ75|`NO_OFFSET_APPLIED`|沿用逐点 Vtip-derived Omega|generic rho|
|WADC CSV → M1-G transport|筛选后将 `collective75_deg` 原样传给 M1-E/M1-G pair|`NO_OFFSET_APPLIED`|逐点 `Omega=Vtip/R`；不走 565|继承 generic rho|
|WADC Stage-5 → input-homology sensitivity|由 Stage-5 validation manifest 读取；没有 collective offset 分支|`NO_OFFSET_APPLIED`|仍由逐点 Vtip 设置 Omega|显式做 post-hoc rho sensitivity；metadata 明确不替代正式 holdout|

`build_xv15_v1_hover_validation_instance.m` 的通用回退分支逐字状态值是 `REFERENCE_HOVER_DEFAULT_NOT_TEST_POINT_CONFIRMED`，其 public reference rpm 是 `565`。但 Run 14 的直接 runner、M1-G transport、WADC Stage-5 和 WADC M1-G transport均自行设置 `P.rotor.Omega`，没有调用该回退来确定这些点的转速。

### 0.5 WADC 来源报告与表号

- 汇编数值来源：NASA/CR-2017-219486，Appendix A，Table A-3。`DIRECTLY_VERIFIED` 于仓库 CSV/provenance；旧文献阶段已读取 Harris 表。
- 仓库所记原始报告：NASA CR-114626 / Bell 300-099-010。原始表号：`UNAVAILABLE`，locator `UNLOCATED`。
- collective offset/facility correction metadata：`WADC_collective_offset_fit,NO` 与 `WADC_facility_correction,NO`。
- 角度加载结论：`NO_OFFSET_APPLIED`（源 θ75/manifest 层）。M0 内部坐标转换已在 0.4 单独披露。

## NASA TM-86833 获取与摘录

获取状态：`DIRECTLY_VERIFIED`。从 NASA NTRS citation `19860005773` 获取 99 页 PDF，并使用文本抽取、关键字全篇检索、关键页渲染和目视复核。官方入口：<https://ntrs.nasa.gov/citations/19860005773>；PDF：<https://ntrs.nasa.gov/api/citations/19860005773/downloads/19860005773.pdf>。

### 1. collective 如何测量；在什么转速状态读取

原文关键短语：

> “obtained from the collective actuator position”

紧接着对误差的原文是：

> “These errors are estimated to be less than ±1°.”

定位：NASA TM-86833，RESULTS—Performance and Loads Data，PDF p.8 / printed p.6。

事实读取：collective 由 collective actuator 的位置得到；报告说数据中仍有控制系统几何非线性造成的误差。报告的每个性能点同时列出非零 RPM，且 TEST CONDITIONS 说明 rotor rotation speed 由 phototach 信号计算；但是报告没有说明 collective 的作动器位置—角度关系是在零转速静态标定、旋转中动态标定，还是以别的转速状态读取。因此，对“collective 校准/读取的转速状态”的回答是 `UNAVAILABLE`。尝试了全文检索 `collective`、`actuator`、`zero rpm`、`static`、`dynamic`、`calibration` 并目视检查 apparatus、test conditions、results 与 Appendix A 参数字典；没有找到该声明。（NASA TM-86833，TEST CONDITIONS，PDF p.7 / printed p.5；RESULTS—Performance and Loads Data，PDF p.8 / printed p.6；Appendix A Table 2，PDF pp.68–69 / printed pp.64–65）

### 2. collective 是否做过修正

报告关于风修正的原文关键片段是：

> “the measured rotor torque was corrected”

定位：NASA TM-86833，WIND CORRECTIONS，PDF p.7 / printed p.5。

逐项审计结果：

- 零风：报告明确描述的是 rotor torque/CQ 的风修正，并同时给 corrected 与 uncorrected performance data；没有声明 collective 做零风修正。（NASA TM-86833，WIND CORRECTIONS，PDF pp.7–8 / printed pp.5–6；RESULTS—Performance and Loads Data，PDF p.8 / printed p.6）
- 塔架/试验台阻塞：报告称 Prop Test Rig 及支撑对 rotor wake 的阻塞很小，用此解释装置干扰被尽量减小；没有给 collective blockage correction。（NASA TM-86833，DESCRIPTION OF TEST APPARATUS—Prop Test Rig，PDF p.5 / printed p.3）
- 静态/动态：`UNAVAILABLE`。全文未定位到 collective 静态—动态修正或旋转状态修正声明；locator `UNLOCATED`。（NASA TM-86833，全报告检索，章节/页码 `UNLOCATED`）
- 仪表标定：报告有 balance-system laboratory calibration、thrust/torque interaction 与精度说明；没有定位到 collective actuator 的仪表标定修正。（NASA TM-86833，DESCRIPTION OF TEST APPARATUS—Balance Systems，PDF pp.5–6 / printed pp.3–4；collective calibration locator `UNLOCATED`）
- 控制几何：报告不是说已消除此项；而是说几何非线性误差仍在 collective 数据内，并给出上述小于 ±1° 的估计。（NASA TM-86833，RESULTS—Performance and Loads Data，PDF p.8 / printed p.6）

结论仅限“报告是否声明”：未声明对 collective 施加零风、阻塞、静态/动态或仪表标定修正；不能由此推断未披露处理绝对不存在。

### 3. 是否与 WPAFB / Wright Field whirl tower 对比

`UNAVAILABLE`。TM-86833 中没有定位到 WPAFB、Wright/Wright Field、whirl tower 对比段落或图表，故无法原文摘录对比结论。尝试：对整份 PDF 文本检索 `WPAFB`、`Wright`、`Wright Field`、`whirl`、`tower`，并目视检查 Introduction、Results、References 与 figure/table lists；失败原因是没有命中相应对比内容。报告编号 NASA TM-86833；章节/页码/表号 `UNLOCATED`。

### 4. TM-86833 与 Harris Table A-2 逐点对照

范围说明：对照覆盖本任务数据对象——OARF Run 14 全部 Point 15–27，以及仓库 Run 15 载入的第一段 Point 7–15。TM-86833 其他 run/point 不在此次仓库对象内，本文不宣称已对整个 Appendix A 所有行完成复核。

TM-86833 Table 2 的 performance-data 参数字典列有 COLL、CT、CQ、RPM、VTIP 等字段，但没有 CP 字段；因此 CP 不作 CQ→CP 推导，逐点均标 `UNAVAILABLE`。（NASA TM-86833，Appendix A Table 2，PDF pp.68–69 / printed pp.64–65）

|Run|Point|TM PDF/printed|TM RPM|TM Vtip (m/s)|TM Mtip|TM θ75|TM CT|Harris Vtip (fps)|Harris Mtip|Harris θ75|Harris CT|Harris CP|判定|
|---:|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
|14|15|12/10|587.6|234.5|0.6922|-7.0|-0.000027|769.4|0.6922|-7.00|-0.000027|0.000241|Run/Point、Mtip、θ75、CT同值；CP unavailable|
|14|16|12/10|587.8|234.5|0.6922|-5.0|0.001344|769.4|0.6922|-5.00|0.001344|0.000185|同上|
|14|17|12/10|587.9|234.5|0.6922|-3.0|0.002319|769.4|0.6922|-3.00|0.002319|0.000214|同上|
|14|18|12/10|587.6|234.5|0.6921|-1.0|0.003320|769.4|0.6921|-1.00|0.003320|0.000277|同上|
|14|19|12/10|587.7|234.5|0.6917|1.0|0.004732|769.4|0.6917|1.00|0.004732|0.000382|同上|
|14|20|13/11|587.5|234.4|0.6914|3.0|0.006405|769.0|0.6914|3.00|0.006405|0.000521|同上|
|14|21|13/11|587.4|234.4|0.6911|5.0|0.008148|769.0|0.6911|5.00|0.008148|0.000703|同上|
|14|22|13/11|587.3|234.3|0.6911|6.0|0.009022|768.7|0.6911|6.00|0.009022|0.000815|同上|
|14|23|13/11|587.2|234.3|0.6907|7.0|0.010095|768.7|0.6907|7.00|0.010095|0.000942|同上|
|14|24|13/11|587.1|234.2|0.6904|8.0|0.010960|768.4|0.6904|8.00|0.010960|0.001076|同上|
|14|25|14/12|586.9|234.2|0.6903|9.0|0.011985|768.4|0.6903|9.00|0.011985|0.001242|同上|
|14|26|14/12|586.8|234.1|0.6899|10.0|0.013014|768.0|0.6899|10.00|0.013014|0.001427|同上|
|14|27|14/12|586.6|234.0|0.6896|11.0|0.013978|767.7|0.6896|11.00|0.013978|0.001615|同上|
|15|7|15/13|587.4|234.4|0.6905|0.0|0.004063|769.0|0.6905|0.00|0.004063|0.000315|同上|
|15|8|15/13|587.3|234.3|0.6904|2.0|0.005581|768.7|0.6904|2.00|0.005581|0.000426|同上|
|15|9|15/13|587.2|234.3|0.6902|4.0|0.007391|768.4|0.6902|4.00|0.007391|0.000588|同上|
|15|10|16/14|587.1|234.2|0.6901|6.0|0.009208|768.4|0.6901|6.00|0.009208|0.000796|同上|
|15|11|16/14|587.0|234.2|0.6899|7.0|0.010104|768.4|0.6899|7.00|0.010104|0.000913|同上|
|15|12|16/14|586.9|234.2|0.6898|8.0|0.011063|768.4|0.6898|8.00|0.011063|0.001044|同上|
|15|13|16/14|586.8|234.1|0.6896|9.0|0.012035|768.0|0.6896|9.00|0.012035|0.001188|同上|
|15|14|16/14|586.7|234.1|0.6894|10.0|0.013089|768.0|0.6894|10.00|0.013089|0.001358|同上|
|15|15|17/15|586.5|234.0|0.6893|11.0|0.013929|767.7|0.6893|11.00|0.013929|0.001523|同上|

来源定位：TM 列来自 NASA TM-86833，Appendix A Table 3，PDF pp.12–17 / printed pp.10–15；Harris 列来自 NASA/CR-2017-219486，Appendix A Table A-2，PDF p.74 / printed p.66。完整机器可读对照见 `tm86833_harris_a2_pointwise.csv`。

Vtip 结论：两报告使用不同单位。本文没有执行数值换算，故 literal value comparison 为 `UNAVAILABLE_LITERAL_UNIT_MISMATCH`；作为不依赖单位换算的独立列，Mtip 在上述各点逐字相同。（NASA TM-86833，Appendix A Table 2/Table 3，PDF pp.68–70 与 pp.12–17 / printed pp.64–66 与 pp.10–15；NASA/CR-2017-219486，Appendix A Table A-2，PDF p.74 / printed p.66）

θ75 结论：显示精度不同，但每一点报告值相同，没有系统性约 4°差值。按原任务四分类，对这一 TM-86833→Harris 直接来源链判为 `A. HARRIS_UNCORRECTED`。（NASA TM-86833，Appendix A Table 3，PDF pp.12–17 / printed pp.10–15；NASA/CR-2017-219486，Appendix A Table A-2，PDF p.74 / printed p.66）

### 5. 桨叶扭转分布

图题原文：

> “Rotor Blade Twist Distribution”

定位：NASA TM-86833，Figure 5，PDF p.75 / printed p.71。

报告在 Rotor System 小节指向该图；Table 1 将 blade twist 描述为总扭转 -42° 且非线性。图 5 给出以 r/R 为横轴的径向曲线，因此“是否给出径向扭转数据”的事实回答是：给出图形数据，但未找到逐站数值表。（NASA TM-86833，DESCRIPTION OF TEST APPARATUS—Rotor System，PDF p.6 / printed p.4；Table 1，PDF p.67 / printed p.63；Figure 5，PDF p.75 / printed p.71）

逐径向站数值：`UNAVAILABLE`。尝试了 Appendix A/Table 1/Table 2/Table 3 全文检索与图 5 目视检查；失败原因是报告只给曲线图和总扭转描述，没有机器可读或印刷数值表。按任务规则禁止推断，故没有从曲线数字化。

## 与既有阶段 1–2 结论的关系

既有文献阶段没有重做。原审计已经直接定位：Harris 将 OARF Appendix A 数据指向 NASA TM-86833（NASA/CR-2017-219486，References，PDF p.217 / printed p.209），而 CR-177436 §7.1 讨论 OARF 与 WPAFB collective 差异，却未提供可用于逐点 Harris-vs-Bartie 表格对数的原始性能表（NASA CR-177436，§7.1，PDF p.69 / printed p.53；详细数据说明见 §2，PDF p.22 / printed p.6）。因此原来的“仅依据 CR-177436 表格”的 `UNDETERMINED` 仍有效。

本次新增的 TM-86833 表 3 是 Harris 所列 OARF 来源。它使本任务 Run 14 与已载入 Run 15 点的直接来源链可以单独判定为 `A. HARRIS_UNCORRECTED`，且没有改写上一段所限定的 CR-177436 对照结论。

## Identity gate

本次只读工作未运行会覆盖既有结果目录的验证脚本。任务开始记录的高风险跟踪产物 SHA-256 与交付前复核逐位相同：

|跟踪产物|before SHA-256|after SHA-256|
|---|---|---|
|`results/xv15_frozen_low_order_validation/XV15_FROZEN_LOW_ORDER_VALIDATION.csv`|`047D8E147883093375F6D3BA8D31DE01D00FAD51144F08C425BC9F9BA66934CF`|`047D8E147883093375F6D3BA8D31DE01D00FAD51144F08C425BC9F9BA66934CF`|
|`results/xv15_frozen_low_order_validation/XV15_FROZEN_PARAMETER_PACK.csv`|`CF3804774301140DB646F68ECA04E54A426D7AFBF54BF8A11238FB58B2F56FCE`|`CF3804774301140DB646F68ECA04E54A426D7AFBF54BF8A11238FB58B2F56FCE`|
|`results/xv15_metal_hover_validation/XV15_METAL_HOVER_VALIDATION_EQUATION_REPLICA_PREVIEW.csv`|`46C2F1CCEACC5ED6DB79184C7949941634B2B6CE860FD4C08CE146816590D95E`|`46C2F1CCEACC5ED6DB79184C7949941634B2B6CE860FD4C08CE146816590D95E`|
|`results/xv15_section_aero_validation/XV15_SECTION_AERO_EQUATION_REPLICA_PREVIEW.csv`|`AA051166BC242C0F7F868F6A61CFF93B053C2DA2251113E748E308D17271D925`|`AA051166BC242C0F7F868F6A61CFF93B053C2DA2251113E748E308D17271D925`|
|`results/m1_stage3b_large_angle_transport_validation/M1_STAGE3B_TRANSPORT_COMPARISON.csv`|`BCBC7BBB679CC55FBB3D83C0045A27D8CB5CF12DF599017EE972FC12E3371C27`|`BCBC7BBB679CC55FBB3D83C0045A27D8CB5CF12DF599017EE972FC12E3371C27`|
|`results/m1_stage5_wadc_holdout/M1_STAGE5_WADC_METADATA.csv`|`E20676F523062E2EF1A65919D8663E39662AFCDC2966AA768F3912944A82B291`|`E20676F523062E2EF1A65919D8663E39662AFCDC2966AA768F3912944A82B291`|

`git diff -- results analysis model params_nominal.m` 与 staged diff 均为空。`git diff 26acaa582358c7358c93f078b3b7fee05f28e9a7..309c79133e5f86796ae7f4f232e0eab28101018e` 仅列出新增 `analysis/diagnose_xv15_twist_equivalent_collective_offset.m` 与 `docs/DIAG_TWIST_LINEARIZATION_AND_RPM.md`；本次审计的跟踪模型/参数/数据/验证产物未改变。这两个并发新增文件不是本交付物。

## 最终判定

- 核心问题（Harris 是否对本任务所核 OARF collective 应用约 4°修正）：`A. HARRIS_UNCORRECTED`，直接证据是 TM-86833 Table 3 与 Harris Table A-2 的 θ75 逐点同值。
- 当前 M1-G 分支源数据载入：Run 14 `NO_OFFSET_APPLIED`；WADC `NO_OFFSET_APPLIED`。
- M0 内部 0.75R→模型控制参考映射：存在且已披露，但不改写数据载体中的 θ75，不能作为 Harris 文献修正证据。
- WPAFB/Wright Field 对比摘录：`UNAVAILABLE`（NASA TM-86833，`UNLOCATED`）。
- TM-86833 逐站扭转数字：`UNAVAILABLE`；图形分布存在（NASA TM-86833，Figure 5，PDF p.75 / printed p.71）。
- 模型修改建议：未提供，符合纯审计边界。

