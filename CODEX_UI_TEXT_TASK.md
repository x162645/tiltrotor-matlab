# CODEX_UI_TEXT_TASK.md

STATUS: COMPLETE / GUI TEXT AND INTERACTION FINAL PASS / MATLAB R2021A VERIFIED / HOLD

Branch: `feature/gui-v1.1-trim-diagnostics`

Draft PR: #10

Verified starting head before this task: `10fa98274cdb3afdf0690bdc59edba8c06dd5f6f`

Final correction baseline: `7ddcaf6ffcca4e441a3ea06fff8ac86a1d6e0dea`

Final interaction coverage:

- Chinese workbench title and parameter-source display mapping;
- complete help popup text and close/reuse path;
- export cancellation and real temporary MAT export/reload/delete path;
- all primary and trim-result tab switches;
- default `1420x860` geometry checks and `1180x720` accessibility checks;
- trim, linearization, response, copied diagnostic, and export diagnostic callbacks.

## Goal

Clean the runtime UI text so the workbench reads like an engineering application instead of a development note. Remove model-provenance and fidelity disclaimers from the visible interface, simplify awkward explanations, and make the diagnostic panel consistently Chinese while preserving internal technical identifiers.

This task changes user-facing copy and display formatting only. It must not change calculations, data structures, success criteria, physical equations, parameters, solver behavior, linearization, or response behavior.

## Read first

1. `AGENTS.md`
2. `CODEX_TASK.md`
3. `CODEX_UI_TEXT_TASK.md`
4. `app/launch_tiltrotor_app.m`
5. `services/build_trim_diagnostic.m`
6. `services/build_exception_diagnostic.m`
7. `tests/check_gui_services.m`
8. `docs/GUI_ARCHITECTURE_AND_REQUIREMENTS.md`

Before editing:

```powershell
cd E:\tiltrotor
git status --short
git branch --show-current
git log -1 --oneline
git diff --stat main...HEAD
```

Stop if the branch is wrong or the worktree contains unrelated changes.

## Runtime UI text policy

The following phrases must not appear in runtime-visible UI text, popups, help text, status text, diagnostic summaries, or diagnostic suggestions:

```text
XV-15
型号验证
概念模型
概念参数
当前概念模型
内部一致性
不代表
```

These phrases may remain in architecture documentation or code comments when technically necessary. Do not remove factual project-boundary documentation from `docs/` merely to satisfy the runtime UI scan.

Runtime UI wording must be:

- concise;
- action-oriented;
- Chinese-first;
- free of project-history explanations;
- free of fidelity disclaimers;
- technically accurate;
- clear about what the user should do next.

Keep exact internal field names, MATLAB error identifiers, and reason codes available in technical-detail fields. Do not translate or alter machine-readable values stored in diagnostic structures.

## Required copy cleanup

### 1. Startup and parameter page

Replace visible wording such as:

```text
已载入名义概念参数
这里仅暴露会直接影响当前概念模型和数值计算的关键参数。
“检查通过”仅表示结构、单位和基本数值条件合理，不代表完成 XV-15 型号验证。
已恢复名义概念参数。
```

Use concise wording with the following meaning:

```text
已载入默认参数
此页用于调整当前计算使用的关键参数。
修改参数后，需要重新运行配平、线性化和响应。
参数修改只对当前软件会话生效。
已恢复默认参数。
```

`params_nominal()` may remain in technical details, but the main summary should say “默认参数”.

### 2. Trim diagnostic text

Remove wording such as:

```text
该结果仍只代表当前概念模型的内部一致性。
```

For a successful accepted trim, the default suggestion should simply state:

```text
可以继续运行线性化。
```

Keep failure suggestions grounded in report data. Simplify awkward phrases where possible. Do not remove NaN/Inf/complex, residual, limit, candidate, or invalid-evaluation diagnostics.

### 3. Linearization and response wording

Replace wording such as:

```text
该结论只针对当前配平点和当前概念模型。
```

with concise operational wording such as:

```text
该结果对应当前配平点。
```

Keep the useful limitation:

```text
线性响应适用于当前配平点附近的小扰动。
```

Do not add general model-fidelity explanations to the runtime UI.

### 4. Exception diagnostic wording

Keep the original `MException.identifier` and `MException.message` unchanged in the diagnostic structure.

Simplify user-facing suggestions. Examples:

```text
检查配平输入、初值和详细错误信息。
确认当前配平点有效，并检查线性化步长。
旋翼内部求解未完成，请保留错误标识并检查当前工况。
请记录错误标识和消息，并按当前输入重新检查。
```

The exception summary should use a Chinese display name for the stage while preserving the internal `diagnostic.stage` value.

## Diagnostic panel display cleanup

The current panel must not show English headings such as:

```text
stage:
severity:
reasonCodes:
summary:
details:
suggestions:
stack:
```

Display Chinese headings:

```text
阶段：
级别：
原因代码：
摘要：
详细信息：
建议：
调用栈：
```

Map display values only:

```text
success -> 成功
warning -> 警告
error -> 错误
startup -> 启动
parameter-validation -> 参数检查
trim -> 配平
linearization -> 线性化
response -> 响应
export -> 导出
copy-diagnostic -> 复制诊断
unknown -> 未知阶段
```

Internal diagnostic values must remain unchanged.

Change UI boolean display from `true/false` to `是/否`. This applies to overview tables and copied diagnostic text. It must not change logical data stored in results.

Change the overview label:

```text
reason codes
```

to:

```text
原因代码
```

The initial diagnostic panel should be fully Chinese, for example:

```text
阶段：启动
级别：提示
摘要：尚未运行分析。
```

## Table heading cleanup

Make the multistart candidate table readable in Chinese. Use headings with clear units, for example:

```text
初始俯仰角(°)
初始总距(°)
初始纵向周期变距(°)
最终俯仰角(°)
最终总距(°)
最终纵向周期变距(°)
目标函数
残差范数
退出标志
通过
触限
未越限
```

Internal candidate structure field names must remain unchanged.

For limit rows, display user-facing variable names such as:

```text
俯仰角 theta
总距 collective
纵向周期变距 cyclicLong
```

Keep internal names in the underlying diagnostic structure.

Do not translate A/B matrix state names, control channel identifiers, MATLAB error identifiers, reason codes, or physical units when doing so would reduce technical clarity.

## Help text

The help popup should contain only:

- recommended operation order;
- parameter edits are session-only;
- linear response applies near the current trim point;
- where to inspect errors or diagnostics.

Remove project provenance, model-fidelity, paper-reproduction, or aircraft-type disclaimers from the help popup.

## Allowed files

Modify only as needed:

```text
CODEX_UI_TEXT_TASK.md
app/launch_tiltrotor_app.m
services/build_trim_diagnostic.m
services/build_exception_diagnostic.m
tests/check_gui_services.m
docs/GUI_ARCHITECTURE_AND_REQUIREMENTS.md
```

A small new test helper under `tests/` is allowed only if it makes the UI-text audit materially clearer.

Do not modify:

```text
analysis/
model/
params_nominal.m
services/run_trim_case.m
services/run_linearization_case.m
services/simulate_linear_response.m
```

Do not change any diagnostic structure field, reason code, solver result, physical value, or function signature.

## Test requirements

Testing must be careful but staged. Do not run parameter sweeps or repeated expensive trim cases.

### Stage 0 — static audit and checkcode

Run `checkcode` on every changed `.m` file.

Add an automated runtime-source text audit covering at least:

```text
app/launch_tiltrotor_app.m
services/build_trim_diagnostic.m
services/build_exception_diagnostic.m
```

The audit must assert that runtime-source strings do not contain:

```text
XV-15
型号验证
概念模型
概念参数
当前概念模型
内部一致性
不代表
```

It must also assert that expected Chinese headings and replacement text are present.

Do not scan architecture documentation with the runtime forbidden-phrase assertion.

### Stage 1 — existing focused service chain

```powershell
& 'F:\matlab\R2021a\bin\matlab.exe' -batch "cd('E:\tiltrotor'); startup; report = check_gui_services; assert(report.allPassed);"
```

Confirm all previous diagnostic reason-code and failure-state tests still pass.

### Stage 2 — existing full regression

```powershell
& 'F:\matlab\R2021a\bin\matlab.exe' -batch "cd('E:\tiltrotor'); startup; summary = run_all_checks; assert(summary.allPassed);"
```

### Stage 3 — interactive UI text and layout audit

Open MATLAB normally:

```matlab
cd('E:\tiltrotor');
run_app;
```

Carefully verify all visible pages and popups:

1. window header and startup status;
2. parameter-page explanatory text;
3. reset-default diagnostic;
4. parameter validation success and failure;
5. default hover trim overview;
6. trim residual and limit pages;
7. multistart candidate headings;
8. current diagnostic panel after success;
9. current diagnostic panel after an invalid parameter edit;
10. current diagnostic panel after a trim input error;
11. linearization success or unstable-mode warning;
12. response success and control-limit warning if a small safe case can produce it without a sweep;
13. export success and cancel behavior;
14. help popup;
15. copied diagnostic text.

For every state confirm:

- no forbidden phrase appears;
- headings are Chinese;
- internal reason codes and error identifiers remain visible where appropriate;
- booleans display as 是/否;
- no text is clipped, overlapped, or pushed outside its table/panel;
- the 1420×860 default window remains usable;
- buttons remain enabled/disabled correctly;
- no stale result reappears after an error;
- closing the UI leaves no project-file changes.

Do not fabricate a control-limit warning by changing model limits or parameters. If the existing small response does not trigger it, verify the wording through source/diagnostic helper tests and report that the live warning path was not forced.

### Stage 4 — diff and scope check

Run:

```powershell
git diff --check
git diff --stat main...HEAD
git status --short
```

Confirm no algorithm or model file changed.

## Acceptance criteria

- all runtime-visible fidelity/provenance disclaimers are removed;
- runtime UI contains no forbidden phrase listed above;
- diagnostic panel and copied diagnostic use Chinese headings;
- display severity, stage, and booleans are localized without changing internal values;
- candidate table headings are clear and include angle units;
- essential technical limitations remain concise and useful;
- `checkcode` passes;
- runtime-source text audit passes;
- `check_gui_services` passes;
- `run_all_checks` passes;
- interactive UI text/layout audit passes;
- no algorithm, model, nominal parameter, function signature, or result structure changes;
- worktree is clean after commit and push.

## Closeout

After verification, change the status line to:

```text
STATUS: COMPLETE / GUI USER-FACING TEXT CLEANUP / MATLAB R2021A VERIFIED / HOLD
```

Commit and push to the same branch:

```text
feature/gui-v1.1-trim-diagnostics
```

Suggested commit message:

```text
fix(gui): simplify user-facing text and localize diagnostics
```

Do not create another PR and do not merge PR #10.

Final report must include:

- every removed or replaced runtime phrase category;
- modified files;
- localization helpers added;
- source-text audit result;
- checkcode result;
- check_gui_services result;
- run_all_checks result;
- detailed interactive UI text/layout observations;
- any warning path not forced live and how it was otherwise verified;
- confirmation that no algorithms or model files changed;
- final commit SHA;
- final `git status --short`.
