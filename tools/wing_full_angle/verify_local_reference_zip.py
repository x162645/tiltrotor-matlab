from __future__ import annotations

import csv
import hashlib
import io
import shutil
import zipfile
from pathlib import Path

from pypdf import PdfReader


ROOT = Path(__file__).resolve().parents[2]
ZIP_PATH = Path(r"E:\tavernchara\XV15_full_angle_wing_reference_PDFs.zip")
DATA = ROOT / "data" / "wing_full_angle"
REFS = ROOT / "references" / "wing_full_angle"
NACA = REFS / "naca_geometry"
TEXT_DIR = DATA / "source_text"


SOURCES = {
    "NASA_TM_88373_NACA_64A223_near_vertical_flow.pdf": {
        "name": "NASA_TM_88373.pdf",
        "report": "NASA TM-88373",
        "nasa_id": "19870005749",
        "target": REFS / "NASA_TM_88373.pdf",
        "must_contain": ["NASA Technical Memorandum 88373", "Near -90"],
        "source_status": "LOCAL_ZIP_VERIFIED_PDF",
    },
    "NASA_CR_176970_XV15_rotor_wing_download.pdf": {
        "name": "NASA_CR_176970.pdf",
        "report": "NASA CR-176970",
        "nasa_id": "19860020297",
        "target": REFS / "NASA_CR_176970.pdf",
        "must_contain": ["TILT ROTOR RESEARCH AIRCRAFT", "ROTOR/WING DOWNLOAD"],
        "source_status": "LOCAL_ZIP_VERIFIED_PDF",
    },
    "NASA_TM_X_3069_NACA_6_6A_ordinate_program.pdf": {
        "name": "NASA_TM_X_3069.pdf",
        "report": "NASA TM-X-3069",
        "nasa_id": "19740025318",
        "target": NACA / "NASA_TM_X_3069.pdf",
        "must_contain": ["NASA TM X-3069", "NACA 6- AND 6A-SERIES"],
        "source_status": "LOCAL_ZIP_VERIFIED_PDF",
    },
    "NASA_TM_4741_NACA_airfoil_ordinate_program.pdf": {
        "name": "NASA_TM_4741.pdf",
        "report": "NASA TM-4741",
        "nasa_id": "19970008124",
        "target": NACA / "NASA_TM_4741.pdf",
        "must_contain": ["NASA Technical Memorandum 4741", "Computer Program To Obtain Ordinates"],
        "source_status": "LOCAL_ZIP_VERIFIED_PDF",
    },
    "NACA_TR_903_6A_series_theory_and_data.pdf": {
        "name": "NACA_TR_903.pdf",
        "report": "NACA TR-903",
        "nasa_id": "19930091970",
        "target": NACA / "NACA_TR_903.pdf",
        "must_contain": ["REPORT No. 903", "NACA 6A-SERIES"],
        "source_status": "LOCAL_ZIP_VERIFIED_PDF",
    },
    "NASA_CR_114614_source_verified_technical_extract_NOT_FACSIMILE.pdf": {
        "name": "NASA_CR_114614_source_verified_technical_extract_NOT_FACSIMILE.pdf",
        "report": "NASA CR-114614",
        "nasa_id": "19730022217",
        "target": REFS / "NASA_CR_114614_source_verified_technical_extract_NOT_FACSIMILE.pdf",
        "must_contain": ["NASA CR-114614", "Bell Model 301", "not a facsimile"],
        "source_status": "LOCAL_ZIP_VERIFIED_TECHNICAL_EXTRACT_NOT_FACSIMILE",
    },
}


SOURCE_MANIFEST_FIELDS = [
    "name",
    "report",
    "nasa_id",
    "url",
    "local_path",
    "status",
    "size_bytes",
    "sha256",
    "pdf_header_valid",
    "page_count",
    "text_extractable",
]

GATE_MANIFEST_FIELDS = [
    "name",
    "report",
    "nasa_id",
    "citation_url",
    "used_url",
    "final_url",
    "local_path",
    "status",
    "error",
    "content_type",
    "size_bytes",
    "sha256",
    "pdf_header_valid",
    "page_count",
    "text_path",
]


def read_csv(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        return []
    with path.open("r", encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def write_csv(path: Path, fieldnames: list[str], rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def rel(path: Path) -> str:
    return str(path.relative_to(ROOT)).replace("\\", "/")


def validate_pdf(data: bytes, expected_terms: list[str]) -> dict[str, object]:
    header_valid = data.startswith(b"%PDF-")
    sha = hashlib.sha256(data).hexdigest().upper()
    result: dict[str, object] = {
        "size_bytes": len(data),
        "sha256": sha,
        "pdf_header_valid": header_valid,
        "page_count": "",
        "text_extractable": False,
        "title_report_match": False,
        "metadata_title": "",
        "error": "",
    }
    if not header_valid or not data:
        result["error"] = "missing_pdf_header_or_zero_size"
        return result

    try:
        reader = PdfReader(io.BytesIO(data))
        result["page_count"] = len(reader.pages)
        result["metadata_title"] = str((reader.metadata or {}).get("/Title", "") or "")
        text_parts = []
        for page_index, page in enumerate(reader.pages, start=1):
            page_text = page.extract_text() or ""
            text_parts.append(f"\n\n--- PDF_PAGE {page_index} ---\n{page_text}")
        text = "\n".join(text_parts)
        normalized = text.upper().replace("-", " ").replace("_", " ")
        result["text_extractable"] = bool(text.strip())
        result["title_report_match"] = all(
            term.upper().replace("-", " ").replace("_", " ") in normalized
            for term in expected_terms
        )
        result["_text"] = text
    except Exception as exc:  # pypdf warnings may still precede successful reads.
        result["error"] = str(exc)
    return result


def replace_by_name(rows: list[dict[str, object]], row: dict[str, object]) -> list[dict[str, object]]:
    key = str(row["name"])
    out = [existing for existing in rows if existing.get("name") != key]
    out.append(row)
    return out


def main() -> int:
    if not ZIP_PATH.exists():
        raise FileNotFoundError(ZIP_PATH)

    REFS.mkdir(parents=True, exist_ok=True)
    NACA.mkdir(parents=True, exist_ok=True)
    TEXT_DIR.mkdir(parents=True, exist_ok=True)

    package_dir = REFS / "local_reference_package"
    package_dir.mkdir(parents=True, exist_ok=True)
    local_rows: list[dict[str, object]] = []
    source_rows = read_csv(DATA / "source_manifest.csv")
    gate_rows = read_csv(DATA / "gate_source_manifest.csv")

    with zipfile.ZipFile(ZIP_PATH) as zf:
        for info in zf.infolist():
            basename = Path(info.filename).name
            if basename in {"MANIFEST.csv", "README_请先阅读.txt"}:
                target = package_dir / basename
                target.write_bytes(zf.read(info.filename))
                continue
            if basename not in SOURCES:
                continue

            spec = SOURCES[basename]
            data = zf.read(info.filename)
            check = validate_pdf(data, spec["must_contain"])
            status = str(spec["source_status"])
            if not (
                check["pdf_header_valid"]
                and check["size_bytes"]
                and isinstance(check["page_count"], int)
                and check["title_report_match"]
            ):
                status = "LOCAL_ZIP_VALIDATION_FAILED"

            target: Path = spec["target"]  # type: ignore[assignment]
            if status != "LOCAL_ZIP_VALIDATION_FAILED":
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(data)
                text_path = TEXT_DIR / f"{target.stem}.txt"
                text_path.write_text(str(check.get("_text", "")), encoding="utf-8")
            else:
                text_path = None

            common = {
                "name": spec["name"],
                "report": spec["report"],
                "nasa_id": spec["nasa_id"],
                "zip_path": str(ZIP_PATH),
                "zip_entry": info.filename,
                "local_path": rel(target),
                "status": status,
                "size_bytes": check["size_bytes"],
                "sha256": check["sha256"],
                "pdf_header_valid": check["pdf_header_valid"],
                "page_count": check["page_count"],
                "text_extractable": check["text_extractable"],
                "title_report_match": check["title_report_match"],
                "metadata_title": check["metadata_title"],
                "error": check["error"],
                "text_path": "" if text_path is None else rel(text_path),
            }
            local_rows.append(common)

            source_row = {
                "name": spec["name"],
                "report": spec["report"],
                "nasa_id": spec["nasa_id"],
                "url": f"LOCAL_ZIP:{ZIP_PATH}",
                "local_path": rel(target),
                "status": status,
                "size_bytes": check["size_bytes"],
                "sha256": check["sha256"],
                "pdf_header_valid": check["pdf_header_valid"],
                "page_count": check["page_count"],
                "text_extractable": check["text_extractable"],
            }
            source_rows = replace_by_name(source_rows, source_row)

            gate_row = {
                "name": spec["name"],
                "report": spec["report"],
                "nasa_id": spec["nasa_id"],
                "citation_url": f"https://ntrs.nasa.gov/citations/{spec['nasa_id']}",
                "used_url": f"LOCAL_ZIP:{ZIP_PATH}",
                "final_url": info.filename,
                "local_path": rel(target),
                "status": status,
                "error": check["error"],
                "content_type": "application/pdf",
                "size_bytes": check["size_bytes"],
                "sha256": check["sha256"],
                "pdf_header_valid": check["pdf_header_valid"],
                "page_count": check["page_count"],
                "text_path": "" if text_path is None else rel(text_path),
            }
            gate_rows = replace_by_name(gate_rows, gate_row)

    source_rows = [
        row for row in source_rows
        if row.get("name") != "NASA_CR_114614.pdf"
    ]
    gate_rows = [
        row for row in gate_rows
        if row.get("name") != "NASA_CR_114614.pdf"
    ]

    write_csv(
        DATA / "local_reference_zip_manifest.csv",
        [
            "name",
            "report",
            "nasa_id",
            "zip_path",
            "zip_entry",
            "local_path",
            "status",
            "size_bytes",
            "sha256",
            "pdf_header_valid",
            "page_count",
            "text_extractable",
            "title_report_match",
            "metadata_title",
            "error",
            "text_path",
        ],
        local_rows,
    )
    write_csv(DATA / "source_manifest.csv", SOURCE_MANIFEST_FIELDS, source_rows)
    write_csv(DATA / "gate_source_manifest.csv", GATE_MANIFEST_FIELDS, gate_rows)

    copied_manifest = package_dir / "LOCAL_ZIP_SOURCE.txt"
    copied_manifest.write_text(
        "Local package used for source recovery after browser/client download failures.\n"
        f"Source ZIP: {ZIP_PATH}\n"
        "NASA_CR_114614_source_verified_technical_extract_NOT_FACSIMILE.pdf is a source-verified "
        "technical extract, not the 268-page facsimile PDF.\n",
        encoding="utf-8",
    )
    for row in local_rows:
        print(
            f"{row['name']}: {row['status']} pages={row['page_count']} "
            f"sha256={row['sha256']} title_report_match={row['title_report_match']}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
