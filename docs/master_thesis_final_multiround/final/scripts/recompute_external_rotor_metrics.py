#!/usr/bin/env python3
"""Recompute final NASA TM-86854 Fig. 25 correlation metrics.

The script consumes two independently recorded digitizations and the frozen
untuned model curves. It does not alter model data or fill failed points.
"""

from __future__ import annotations

import argparse
import csv
import math
from pathlib import Path


def read_rows(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def write_rows(path: Path, fieldnames: list[str], rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def linear_slope(xs: list[float], ys: list[float]) -> float:
    xbar = sum(xs) / len(xs)
    ybar = sum(ys) / len(ys)
    denominator = sum((x - xbar) ** 2 for x in xs)
    return sum((x - xbar) * (y - ybar) for x, y in zip(xs, ys)) / denominator


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--first", type=Path, required=True)
    parser.add_argument("--second", type=Path, required=True)
    parser.add_argument("--model", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()

    first = read_rows(args.first)
    second = read_rows(args.second)
    if len(first) != len(second):
        raise ValueError("Digitizations have different point counts.")

    final_rows: list[dict] = []
    difference_rows: list[dict] = []
    final_by_collective: dict[float, float] = {}
    for a, b in zip(first, second):
        xa = float(a["collective_deg"])
        xb = float(b["collective_deg"])
        if abs(xa - xb) > 1e-12:
            raise ValueError(f"Collective mismatch: {xa} versus {xb}")
        ya = float(a["CT_over_sigma"])
        yb = float(b["CT_over_sigma"])
        adopted = 0.5 * (ya + yb)
        final_by_collective[xa] = adopted
        difference_rows.append(
            {
                "collective_deg": f"{xa:g}",
                "first_CT_over_sigma": f"{ya:.6f}",
                "second_CT_over_sigma": f"{yb:.6f}",
                "second_minus_first": f"{yb - ya:.6f}",
                "absolute_difference": f"{abs(yb - ya):.6f}",
                "within_declared_uncertainty": int(abs(yb - ya) <= 0.003),
            }
        )
        final_rows.append(
            {
                "collective_deg": f"{xa:g}",
                "CT_over_sigma": f"{adopted:.6f}",
                "collective_uncertainty_deg": "1",
                "CT_over_sigma_uncertainty": "0.003",
                "adoption_rule": "MEAN_OF_TWO_INDEPENDENT_DIGITIZATIONS",
                "source": "NASA-TM-86854 PDF54 printed52 Fig.25",
            }
        )

    model_rows = read_rows(args.model)
    implementations = sorted({row["implementation"] for row in model_rows})
    metric_rows: list[dict] = []
    for implementation in implementations:
        rows = [row for row in model_rows if row["implementation"] == implementation]
        valid: list[tuple[float, float, float]] = []
        failures: list[float] = []
        for row in rows:
            x = float(row["collective_deg"])
            # Compare collective >= 4 deg only when the producing model marks
            # the point successful. Raw negative-thrust loads remain in the
            # model CSV as evidence, but the current production path now
            # rejects them as an unsupported physical branch.
            if (
                x >= 4
                and row["success"] == "1"
                and row["CT_over_sigma"] not in {"", "NaN"}
            ):
                if x in final_by_collective:
                    valid.append((x, float(row["CT_over_sigma"]), final_by_collective[x]))
            elif row["success"] != "1":
                failures.append(x)
        errors = [model - experiment for _, model, experiment in valid]
        absolute = [abs(value) for value in errors]
        relative = [abs(model - experiment) / abs(experiment)
                    for _, model, experiment in valid if abs(experiment) > 1e-12]
        xs = [x for x, _, _ in valid]
        model_values = [model for _, model, _ in valid]
        experiment_values = [experiment for _, _, experiment in valid]
        observed_range = max(experiment_values) - min(experiment_values)
        mae = sum(absolute) / len(absolute)
        rmse = math.sqrt(sum(value * value for value in errors) / len(errors))
        model_slope = linear_slope(xs, model_values)
        experiment_slope = linear_slope(xs, experiment_values)
        metric_rows.append(
            {
                "implementation": implementation,
                "validCount": len(valid),
                "failureCount": len(failures),
                "commonCollectiveMinDeg": f"{min(xs):g}",
                "commonCollectiveMaxDeg": f"{max(xs):g}",
                "MAE_CT_over_sigma": f"{mae:.12g}",
                "RMSE_CT_over_sigma": f"{rmse:.12g}",
                "normalizedMAE_by_observed_range": f"{mae / observed_range:.12g}",
                "maximumAbsoluteError": f"{max(absolute):.12g}",
                "meanAbsoluteRelativeError": f"{sum(relative) / len(relative):.12g}",
                "experimentSlopePerDeg": f"{experiment_slope:.12g}",
                "modelSlopePerDeg": f"{model_slope:.12g}",
                "slopeSignAgreement": int(model_slope * experiment_slope > 0),
                "failedCollectiveDeg": ";".join(f"{x:g}" for x in failures),
                "evidenceStatement": "PUBLIC_FIGURE_COMPONENT_LEVEL_CORRELATION_WITH_LARGE_BIAS",
            }
        )

    args.output_dir.mkdir(parents=True, exist_ok=True)
    write_rows(
        args.output_dir / "EXTERNAL_ROTOR_DIGITIZATION_FINAL.csv",
        list(final_rows[0]),
        final_rows,
    )
    write_rows(
        args.output_dir / "EXTERNAL_ROTOR_DIGITIZATION_DIFFERENCE.csv",
        list(difference_rows[0]),
        difference_rows,
    )
    write_rows(
        args.output_dir / "EXTERNAL_ROTOR_CORRELATION_METRICS_FINAL.csv",
        list(metric_rows[0]),
        metric_rows,
    )


if __name__ == "__main__":
    main()
