# XV-15 外部相关性元数据一致性闭合

## 目的

本文件闭合 `docs/XV15_CODEX_HANDOFF_AUDIT.md` 已识别但尚未完全落实到可复现产物中的最后一个一致性问题：方法学文档已经明确 OARF Run 15 不是 blind hold-out，且 6°–11°是此前已建立物理支持区间上的固定报告窗口，但历史 MATLAB runner 与其提交 CSV 仍保留 `holdout`、`predeclared primary window` 等旧标签。

这属于**证据语义/可复现元数据错误**，不是物理方程或数值结果错误。

## 审计结论

Codex 接手后的三个主要工作包继续保留：

1. 冻结低阶验证配置的 MATLAB 数值结果；
2. 10°质量属性耦合单因素核验；
3. Prandtl 根/尖损失量级筛查。

本修正不改变任何 CT、CP、FM、收敛状态、载荷、诱导速度或物理参数。原冻结编号 `XV15_LOW_ORDER_HOVER_V1_20260825` 也保留，用于追溯已经完成的 MATLAB 运行。

## 为什么需要新的权威入口

历史 `analysis/run_xv15_frozen_low_order_validation.m` 是产生已提交数值的实际运行入口，因此不直接改写它，以免把一次历史 MATLAB 运行事后伪装成采用新方法学标签重新执行的运行。

新增：

`analysis/run_xv15_frozen_external_correlation.m`

它调用历史 runner 获得完全相同的数值计算，然后仅修正证据元数据：

- `claimBoundary`：改为 `FROZEN_LOW_ORDER_EXTERNAL_CORRELATION_NOT_XV15_REPRODUCTION_NO_OARF_PARAMETER_FIT`；
- 评分窗口：改为 `FIXED_REPORT_WINDOW_6_TO_11_DEG`；
- `holdout_source`：改为 `external_correlation_source`；
- 数据角色：改为 `DEVELOPMENT_EXTERNAL_CORRELATION`；
- 新增 `dataset_independence=NOT_BLIND_USED_IN_PRIOR_DIAGNOSTICS`。

该包装入口是后续论文表格、报告重建和再次运行时的**权威入口**。历史 runner 只作为历史数值运行记录保留。

## 静态结果文件

以下三个已提交 CSV 已做相同的 metadata-only 修正：

- `results/xv15_frozen_low_order_validation/XV15_FROZEN_LOW_ORDER_VALIDATION.csv`
- `results/xv15_frozen_low_order_validation/XV15_FROZEN_LOW_ORDER_METRICS.csv`
- `results/xv15_frozen_low_order_validation/XV15_FROZEN_PARAMETER_PACK.csv`

数值列保持不变。此次没有声称重新运行 MATLAB；只是把已经存在的 MATLAB 数值结果与 2026-08-28 方法学审计结论对齐。

## 当前正式解释

OARF Run 15 可以继续支持：

- 开发后冻结的外部相关性比较；
- 误差形态描述；
- 在不使用其结果反调新参数的条件下，对独立文献约束模型形式进行前后比较。

它不能继续支持：

- blind / unseen hold-out 声明；
- “6°–11°在观察模型行为前预注册”的声明；
- 因为某个局部经验修正无效，就宣称尚未验证的非局部尾迹模型已经被证伪。

若论文需要真正独立的最终外部验证，应另选此前未参与模型选择的数据集，或重新设计并冻结独立的数据划分。

## 不变的物理结论

固定报告窗口 6°–11°的原 MATLAB 数值仍为：

- CT MAPE = 42.8716%；
- CP MAPE = 51.1184%；
- FM MAPE = 12.2221%。

因此当前冻结低阶验证配置对 XV-15 原始金属桨 OARF Run 15 的绝对推力和功率仍存在明显系统性低估；本修正既不改善也不恶化该结果。
