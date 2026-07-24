# 第一轮基线回归报告

## 执行环境

- 工作树：`E:\tiltrotor-master-thesis-final-iteration`
- 基线提交：`97694120eff16f0edab4b5671fb5606638d30f8e`
- MATLAB：R2021a，`F:\matlab\R2021a\bin\matlab.exe`
- 入口：`startup; summary = run_all_checks;`

## 结果

- 测试总数：26
- 通过：26
- 失败：0
- `summary.allPassed`：1
- 实测耗时：728.072365 s
- 标准错误日志：空
- 新出现 warning：无
- 测试报告中的 NaN/Inf/非预期复数：无

完整标准输出保存于外部构建根目录：
`E:\tiltrotor-work-output\master-thesis-final-multiround\logs\round1_run_all_checks.stdout.log`。

## 解释边界

本结果证明 PR #57 基线在项目现有 26 项覆盖工况下内部一致，并不构成 XV-15 型号
试验验证，也不证明占位参数、线性气动系数或短舱执行机构参数具有型号真实性。
最终提交仍须在最终 HEAD 上再次运行同一完整回归。
