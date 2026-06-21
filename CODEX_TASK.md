# CODEX_TASK.md

STATUS: ACTIVE / GUI PARAMETER WORKBENCH

Branch: `feature/gui-v1.2-parameter-workbench`
Base branch: `main`

## Objective

Develop a comprehensive GUI parameter workbench. Add only parameters that are actively used by current production calculations, have clear physical or numerical meaning, have explicit units, and can be safely validated.

All GUI-visible text must be customer-facing Chinese. Do not show source-code paths, developer labels, reason codes, Git terminology, test terminology, or implementation-stage wording.

## First run

Read:

```text
AGENTS.md
CODEX_TASK.md
docs/GUI_ARCHITECTURE_AND_REQUIREMENTS.md
docs/GUI_PARAMETER_WORKBENCH_PLAN.md
params_nominal.m
app/launch_tiltrotor_app.m
services/validate_parameter_set.m
```

Then inspect actual parameter consumers in `model/`, `analysis/`, and `services/`.

Perform only a read-only parameter inventory. For every numeric field/component, report:

```text
field
Chinese name
category
GUI unit
internal unit
production consumers
meaning
editable or excluded
exclusion reason
dependencies
validation rule
basic or advanced
```

Exclude deprecated aliases, inactive placeholders, derived values, duplicate matrix entries, internal solver states, strings, and fields with no production consumer.

Report totals, category counts, the complete proposed catalog, ambiguities, and expected implementation files.

Do not modify production or test files. Do not commit or push. Stop after the inventory with a clean working tree.

Detailed rules are in `docs/GUI_PARAMETER_WORKBENCH_PLAN.md`.