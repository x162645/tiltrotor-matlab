# 最终提交树验证报告

## 执行环境

- 隔离工作树：`E:\tiltrotor-worktrees\independent-logic-consistency-pr59-20260726`
- 审计基线（PR #59 实际 head）：`65e459504dd473f6dcf18326028f3a8a7991c55a`
- MATLAB：R2021a，`F:\matlab\R2021a\bin\matlab.exe`
- 完整入口：`run('startup.m'); summary = run_all_checks;`

## 完整 MATLAB 回归

- 测试总数：28
- PASS：28
- FAIL：0
- 跳过：0
- `summary.allPassed`：1
- 实测耗时：1777.308212 s
- MATLAB 标准错误：空
- 运行期 warning：0
- NaN、Inf、非预期复数：0

本次在原 26 项入口上新增“旋翼数值/物理收敛分离”和“配平模式边界审计”两项。
完整输出见 `logs/full_run_all_checks.stdout.log`，SHA-256 为
`B1EF63662A3A8F2F29192414DD65B9C0A293E28FCED61A28C59A88FA63928839`；
对应 stderr 文件为空。

## 聚焦复核

- `check_rotor_physical_convergence`：6/6 通过。4° 点保持原始
  \(T=-930.152042\ {\rm N}\) 与约 \(-930.152042\ {\rm N}\) 未截断闭合残差，
  数值序列收敛但物理门禁拒绝；12° 正推力基准载荷未变。
- `check_trim_mode_boundaries`：通过。30° 双侧可信但直接量最大跳变约
  4.49569°；60° 双侧旋翼物理闭合通过、整机配平残差门禁未过，诊断量最大跳变约
  11.6676°；两处均分类为 `CONTINUITY_NOT_DEMONSTRATED`。
- `check_low_collective_quick_audit`：9/9 通过。4° 明确标为
  `UNSUPPORTED_NEGATIVE_THRUST_BRANCH`，8°/10° 保留迭代失败，12° 物理闭合。
- 外部悬停关联重算：当前正式旋翼 6 个有效点、6 个失败点；最终二次数字化
  MAE 为 0.0643401712415，RMSE 为 0.0643726685288。
- 兼容性聚焦回归：NUAA Eq.12/13/16 为 6/6、旋翼物理闭合为 6/6、
  Berger13 正式配平为 9/9，全部通过。
- 全量回归后仅将闭合阈值字段更名为明确的“无量纲相对阈值”，数值判据未变；
  随后再次执行 NUAA Eq.12/13/16（6/6）和旋翼物理闭合（6/6），均通过。

## 静态与文稿检查

- MATLAB `checkcode`：扫描本任务 23 个修改/新增 `.m` 文件；20 个无提示，
  3 个各有 1 条位于未修改代码行的既有提示（2 条 `MSNU`、1 条 `NASGU`）。
- Python AST：2/2 修改脚本通过。
- `git diff --check`：通过；仅有仓库既有 LF/CRLF 转换提醒。
- Markdown、归档 LaTeX 与 `xelatex_project/main.tex` 已同步；两个 TeX 文件哈希一致。
- 当前环境没有 XeLaTeX/Biber，故未重建 PDF。现存上一版 82 页 PDF 已用
  Poppler 全页渲染检查，但不能作为本次源文件修订已进入 PDF 的证据。

本结果只证明当前测试覆盖工况下的内部一致性、数值有限性和回归稳定性，不构成
XV-15 型号试验验证，也不证明研究占位参数具有型号真实性。
