#!/usr/bin/env python3
"""Create the deterministic SHA-256 inventory for report deliverables."""

from __future__ import annotations

import hashlib
from datetime import datetime
from pathlib import Path


REPORT = Path(__file__).resolve().parents[1]
OUTPUT = REPORT / "SHA256SUMS.txt"
EXCLUDED_PARTS = {"rendered_docx_pages", "contact_sheets"}
EXCLUDED_NAMES = {OUTPUT.name, "TECHNICAL_REPORT_DOCX_RENDER_QA.pdf"}


def main() -> None:
    files = []
    for path in REPORT.rglob("*"):
        if not path.is_file():
            continue
        relative = path.relative_to(REPORT)
        if path.name in EXCLUDED_NAMES or any(part in EXCLUDED_PARTS for part in relative.parts):
            continue
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        files.append((relative.as_posix(), digest, path.stat().st_size))
    files.sort()
    lines = [
        "# SHA-256 manifest",
        f"# generated={datetime.now().isoformat()}",
        f"# files={len(files)}",
    ]
    lines.extend(f"{digest}  {size:12d}  {name}" for name, digest, size in files)
    OUTPUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"SHA256_MANIFEST_FILES={len(files)}")
    print(f"SHA256_MANIFEST={OUTPUT}")


if __name__ == "__main__":
    main()
