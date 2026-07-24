# 事实源索引

|事实类别|首要来源|用途|
|---|---|---|
|九状态方程|`model/tiltrotor_eom.m`|状态顺序、刚体导数|
|十三状态接口|`model/berger13/berger13_names.m`、`berger13_eom.m`|状态、输入与动态扩展|
|部件载荷合成|`model/total_forces_moments.m`、`model/berger13/berger13_total_forces_moments.m`|力、矩、实际重心|
|质量与惯量|`model/mass_properties.m`、`model/berger13/berger13_mass_properties.m`|质量矩、平行轴和正定性|
|正式旋翼|`model/rotor_model_bemt.m`|默认旋翼载荷|
|南航参考旋翼|`model/rotor_reference/`|公开公式独立参考实现|
|正式默认参数|`params_nominal.m`|默认值与来源标签|
|十三状态研究参数|`model/berger13/berger13_params.m`|执行机构占位参数|
|配平证据|`docs/master_thesis_validation/TRIM_POINT_EVIDENCE.csv`|代表点、失败点、残差、余度|
|模型层级比较|`raw_figure_data/*MODEL_HIERARCHY_POINT_SUMMARY.csv`|A/B 子块、短舱导数、惯量|
|时域响应|`raw_figure_data/*MODEL_HIERARCHY_RESPONSE_METRICS.csv`|峰值与时间步收敛|
|参数来源|`docs/master_thesis_validation/PARAMETER_PROVENANCE_MASTER.csv`|219 项来源主表|
|NASA 首次数字化|`validation_data/XV15_ATB_HOVER_DIGITIZED.csv`|图 25 首次代表点|
|外部旋翼计算|`validation_data/ROTOR_HOVER_MODEL_CURVES.csv`|未调参模型曲线和失败点|
|外部旋翼指标|`validation_data/ROTOR_HOVER_EXTERNAL_COMPARISON_METRICS.csv`|首次 MAE/RMSE|
|原始公开文献|`E:/tiltrotor-work-output/master-thesis-validation-full-20260723/source_evidence/`|原文页、图、表和公式核查|
|PR 依赖链|GitHub Draft PR #49--#57|提交级版本基线和历史边界|

原始文献优先于旧审计报告；代码和冻结 CSV 优先于论文散文。若三者冲突，
必须在审计中显式记录，不能以语言修改覆盖冲突。
