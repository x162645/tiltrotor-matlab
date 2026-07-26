# 任务基线与范围记录

## GitHub 参考基线

任务开始时通过 GitHub 连接器重新核实 PR #61：

- 状态：Open
- 类型：Draft
- base 分支：`codex/low-collective-quick-audit-pr58-20260726`
- base SHA：`65e459504dd473f6dcf18326028f3a8a7991c55a`
- head 分支：`codex/independent-logic-consistency-pr59-20260726`
- head SHA：`99acba44740087fdf3d7cdc82efd191c87cfb2d1`

本任务从该实际远程 head SHA 创建：

- 独立 worktree：`E:\tiltrotor-control-stability-technical-report-20260726`
- 任务分支：`codex/control-stability-technical-report-20260726`
- 初始 `git status --short`：空

## 原工作区保护

原工作区 `E:\tiltrotor` 在开始时存在未提交内容。其状态指纹为：

`eef9bdedcaed0fc9e351c364a5fe3654baf13aa3`

本任务未读取利用、覆盖、暂存、清理、提交或重置原工作区中的未提交内容。所有分析、生成、测试和 Git 操作均在独立 worktree 中完成。

## 修改边界

本任务只增加操纵稳定性后处理、聚焦测试、数值结果、图件、报告源和构建材料。正式部件气动力公式、默认物理参数、质量、惯量、几何、控制限位、九/十三状态顺序、既有输入接口、配平残差判据、旋翼物理闭合条件和负推力/风车分支边界均保持基线不变。
