# 最终提交树验证报告

## 执行环境

- 工作树：`E:\tiltrotor-master-thesis-final-iteration`
- 已测试论文提交：`255b4ecce13abe106e9bdff8a575100c96603025`
- MATLAB：R2021a，`F:\matlab\R2021a\bin\matlab.exe`
- Python：本机工作区 Python
- 完整入口：`run('startup.m'); summary = run_all_checks;`

## 完整 MATLAB 回归

- 测试总数：26
- PASS：26
- FAIL：0
- 跳过：0
- `summary.allPassed`：1
- 实测耗时：623.938453 s
- MATLAB 标准错误：空
- 运行期 warning：0
- NaN：0
- Inf：0
- 非预期复数：0

完整入口覆盖了南航公开公式旋翼、九状态回归、十三状态接口、十三状态配平、十三状态线性化、执行机构和独立机翼、时域响应、三步时步收敛、参数方案、通用配平、配平可信度、机翼连续化、旋翼网格收敛与线性化有限值检查。

标准输出：
`E:\tiltrotor-work-output\master-thesis-final-multiround\logs\final_head_full2.stdout.log`

标准错误：
`E:\tiltrotor-work-output\master-thesis-final-multiround\logs\final_head_full2.stderr.log`

标准输出 SHA-256：
`2F9820AB14FD3C2125511660AD9D8CB5B5964EDE8B6F3B0955C44562920F5E20`

## 聚焦与静态检查

- 外部旋翼指标复算：通过；最终数字化与指标 CSV 的 SHA-256 均与冻结文件一致。
- Python 语法检查：4/4 通过。
- MATLAB `checkcode`：扫描 149 个 `.m` 文件；9 个既有文件共有 31 条代码分析提示。本任务新增的 A 块审计脚本无提示；提示未造成运行 warning 或测试失败，本任务未越界修改既有模型代码。
- `git diff --check`：通过。
- 受保护的 `model/`、`params_nominal.m` 和 `tests/` 相对 PR #57 基线无变化。
- 最终 PDF：82 页，SHA-256 为 `A93A7DE456DF1EF6210B6B6241C1BDB3A4924D2CF079F5B2525AA773B1934670`。

## 运行说明

首次完整重跑因外部等待工具设置的 20 分钟上限到期而失去输出管道，不能计为通过；未将该次中间结果用于最终判定。上述 26/26 结果来自随后使用独立标准输出/标准错误文件完成的完整重跑。

本结果只证明当前测试覆盖工况下的内部一致性、数值有限性和回归稳定性，不构成 XV-15 型号试验验证，也不证明研究占位参数具有型号真实性。
