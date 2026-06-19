# CODEX_TASK.md

当前任务：在 `audit/physics-and-correctness` 分支验证物理合理性与程序正确性改动。

开始前读取 `AGENTS.md`。本阶段只检查参数数量级是否合理、程序是否正确、测试是否可靠，并为未来型号数据升级保留接口。精确 XV-15 参数不构成本轮修改前提。

重点复核：

- `docs/PHYSICS_AND_CODE_AUDIT.md`
- `model/total_forces_moments.m`
- `model/tiltrotor_eom.m`
- `analysis/linearize_numeric.m`
- `tests/check_physical_sanity.m`
- `tests/check_control_limits.m`
- `tests/run_physics_correctness_checks.m`

先检查本机工作区和分支状态，再运行现有轻量测试。测试失败时定位最小根因，只修改直接相关文件。禁止一开始执行速度精扫、正反扫、大量多初值、Monte Carlo 或逐点 Jacobian。预计运行超过数分钟时，先估算计算量。

完成后报告测试结果、修改文件、是否修改参数、Git diff、提交 SHA 和遗留问题。不要合并 Draft PR #1，不进入下一阶段。
