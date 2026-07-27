#!/usr/bin/env python3
"""Audit CSV numeric integrity and classify structurally inapplicable fields."""

from __future__ import annotations

import csv
from datetime import datetime
from pathlib import Path


REPORT = Path(__file__).resolve().parents[1]
OUTPUT = REPORT / "NUMERIC_OUTPUT_AUDIT.md"
CSV_NAMES = [
    "STATIC_STABILITY_DERIVATIVES.csv",
    "DAMPING_DERIVATIVES.csv",
    "DERIVATIVE_CROSSCHECK.csv",
    "CONTROL_EFFECTIVENESS_DERIVATIVES.csv",
    "CONTROL_DERIVATIVE_CROSSCHECK.csv",
    "MODAL_PARAMETERS.csv",
    "MODAL_PARTICIPATION.csv",
    "MODAL_CLASSIFICATION.csv",
    "MODAL_CONDITIONING.csv",
    "CONTROL_STEP_RESPONSE_METRICS.csv",
    "CONTROL_STEP_LINEAR_NONLINEAR_COMPARISON.csv",
    "CONTROL_STEP_TIMESTEP_CONVERGENCE.csv",
    "TRIM_CHARACTERISTICS_BY_MODE.csv",
    "REPRESENTATIVE_POINT_AUDIT.csv",
]
STRUCTURAL_NA = {
    "MODAL_PARAMETERS.csv": {
        "dampingRatio",
        "oscillationPeriodSeconds",
        "halfAmplitudeTimeSeconds",
        "doublingTimeSeconds",
        "realRootTimeConstantSeconds",
    },
    "CONTROL_STEP_RESPONSE_METRICS.csv": {
        "peakBasedRiseTimeSeconds",
        "endpointOvershootPercent",
        "firstInvalidIndex",
    },
    "TRIM_CHARACTERISTICS_BY_MODE.csv": {
        "thetaDeg",
        "alphaDeg",
        "collectiveDeg",
        "cyclicLongDeg",
        "pitchCommand",
        "elevatorDeg",
        "minimumControlMarginFraction",
        "dynamicResidualNorm",
        "conditionNumber",
    },
}


def missing(value: str) -> bool:
    return value.strip().lower() in {"", "nan", "na", "n/a"}


def main() -> None:
    unexpected = []
    structural_counts = []
    inf_count = 0
    complex_count = 0
    for name in CSV_NAMES:
        path = REPORT / name
        if not path.exists():
            unexpected.append(f"{name}: 文件缺失")
            continue
        with path.open("r", encoding="utf-8-sig", newline="") as stream:
            data = list(csv.DictReader(stream))
        allowed = STRUCTURAL_NA.get(name, set())
        for row_index, row in enumerate(data, start=2):
            for column, value in row.items():
                low = value.strip().lower()
                if low in {"inf", "+inf", "-inf", "infinity", "+infinity", "-infinity"}:
                    inf_count += 1
                    unexpected.append(f"{name}:{row_index}:{column}=Inf")
                if "i" in low and any(ch.isdigit() for ch in low):
                    # Text status fields may contain the letter i; only flag
                    # values that parse as a MATLAB-style complex literal.
                    compact = low.replace(" ", "")
                    if compact.endswith("i") and ("+" in compact[1:] or "-" in compact[1:]):
                        complex_count += 1
                        unexpected.append(f"{name}:{row_index}:{column}=complex")
                if missing(value):
                    if column in allowed:
                        structural_counts.append((name, column))
                    elif column not in {
                        "failureReason",
                        "firstInvalidReason",
                        "pitchCommand",
                    }:
                        unexpected.append(f"{name}:{row_index}:{column}=missing")
    count_map = {}
    for key in structural_counts:
        count_map[key] = count_map.get(key, 0) + 1
    lines = [
        "# 数值输出完整性核查",
        "",
        f"- 核查时间：{datetime.now().isoformat()}",
        f"- CSV 数量：{len(CSV_NAMES)}",
        f"- Inf：{inf_count}",
        f"- 非预期复数文本：{complex_count}",
        f"- 非预期缺失/NaN：{len(unexpected)}",
        "",
        "## 结构性不适用值",
        "",
        "模态周期、半衰时间、倍增时间和实根时间常数只对相应根型适用；"
        "阶跃上升时间、超调和首个失效索引也可能按定义不适用；失败配平点不具有可用配平量。"
        "这些字段保留为空或 NaN，不能解释为数值计算失败。",
        "",
        "|文件|字段|数量|",
        "|---|---|---:|",
    ]
    lines.extend(
        f"|{name}|{column}|{count}|"
        for (name, column), count in sorted(count_map.items())
    )
    lines.extend(["", "## 非预期项", ""])
    if unexpected:
        lines.extend(f"- {item}" for item in unexpected)
    else:
        lines.append("- 无。")
    OUTPUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"NUMERIC_AUDIT_UNEXPECTED={len(unexpected)}")
    print(f"NUMERIC_AUDIT_INF={inf_count}")
    print(f"NUMERIC_AUDIT_COMPLEX={complex_count}")
    if unexpected:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
