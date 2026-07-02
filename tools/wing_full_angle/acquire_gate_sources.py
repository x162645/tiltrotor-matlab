from __future__ import annotations

import csv
import hashlib
import json
import re
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable
from http.client import IncompleteRead
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from pypdf import PdfReader


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "references" / "wing_full_angle"
NACA = OUT / "naca_geometry"
MANIFEST = ROOT / "data" / "wing_full_angle" / "gate_source_manifest.csv"
TEXT_DIR = ROOT / "data" / "wing_full_angle" / "source_text"


@dataclass
class Source:
    name: str
    doc_id: str
    report: str
    out_dir: Path

    @property
    def citation_url(self) -> str:
        return f"https://ntrs.nasa.gov/citations/{self.doc_id}"

    @property
    def api_url(self) -> str:
        return f"https://ntrs.nasa.gov/api/citations/{self.doc_id}"

    @property
    def direct_pdf_url(self) -> str:
        return f"https://ntrs.nasa.gov/api/citations/{self.doc_id}/downloads/{self.doc_id}.pdf"


SOURCES = [
    Source("NASA_CR_114614.pdf", "19730022217", "NASA CR-114614", OUT),
    Source("NASA_TM_X_3069.pdf", "19740025318", "NASA TM-X-3069", NACA),
    Source("NASA_TM_4741.pdf", "19970008124", "NASA TM-4741", NACA),
    Source("NACA_TR_903.pdf", "19930091970", "NACA TR-903", NACA),
    Source("NACA_TN_4322.pdf", "19930085124", "NACA TN-4322", NACA),
    Source("NASA_TR_R_84.pdf", "19980223594", "NASA TR R-84", NACA),
]


def fetch(url: str, timeout: int = 120) -> tuple[int, str, bytes, str]:
    req = Request(url, headers={"User-Agent": "tiltrotor-matlab-source-audit/1.0"})
    try:
        with urlopen(req, timeout=timeout) as response:
            status = getattr(response, "status", 200)
            content_type = response.headers.get("Content-Type", "")
            final_url = response.geturl()
            return status, content_type, response.read(), final_url
    except IncompleteRead as exc:
        return 0, "", exc.partial, url
    except HTTPError as exc:
        content_type = exc.headers.get("Content-Type", "") if exc.headers else ""
        data = exc.read()
        return exc.code, content_type, data, url
    except URLError as exc:
        return 0, "", str(exc).encode("utf-8", "replace"), url


def unique(values: Iterable[str]) -> list[str]:
    seen = set()
    result = []
    for value in values:
        if value not in seen:
            result.append(value)
            seen.add(value)
    return result


def api_download_candidates(source: Source) -> list[str]:
    status, _, data, _ = fetch(source.api_url, timeout=60)
    candidates = [source.direct_pdf_url]
    if status != 200:
        return candidates
    try:
        payload = json.loads(data.decode("utf-8"))
    except Exception:
        return candidates

    def walk(value):
        if isinstance(value, dict):
            for item in value.values():
                walk(item)
        elif isinstance(value, list):
            for item in value:
                walk(item)
        elif isinstance(value, str):
            text = value.replace("\\u002F", "/")
            if "download" in text.lower() or text.lower().endswith(".pdf"):
                if text.startswith("http"):
                    candidates.append(text)
                elif text.startswith("/"):
                    candidates.append("https://ntrs.nasa.gov" + text)

    walk(payload)
    return unique(candidates)


def citation_download_candidates(source: Source) -> list[str]:
    status, _, data, _ = fetch(source.citation_url, timeout=60)
    candidates: list[str] = []
    if status != 200:
        return candidates
    text = data.decode("utf-8", "replace")
    patterns = [
        r'https://ntrs\.nasa\.gov/api/citations/\d+/downloads/[^"\'>\s]+',
        r'/api/citations/\d+/downloads/[^"\'>\s]+',
    ]
    for match in sum((re.findall(pattern, text) for pattern in patterns), []):
        cleaned = match.replace("\\u002F", "/").replace("&amp;", "&")
        cleaned = cleaned.split("&q", 1)[0].split("?q", 1)[0]
        if not cleaned.lower().endswith(".pdf"):
            continue
        if cleaned.startswith("http"):
            candidates.append(cleaned)
        elif cleaned.startswith("/"):
            candidates.append("https://ntrs.nasa.gov" + cleaned)
    return unique(candidates)


def pdf_info(path: Path) -> tuple[bool, int | str, str]:
    data = path.read_bytes()
    header_valid = data.startswith(b"%PDF-")
    sha = hashlib.sha256(data).hexdigest().upper()
    if not header_valid:
        return False, "NOT_PDF", sha
    try:
        reader = PdfReader(str(path))
        return True, len(reader.pages), sha
    except Exception as exc:
        return True, f"PDF_READ_ERROR:{exc}", sha


def extract_text(path: Path, doc_id: str) -> Path | None:
    ok, pages, _ = pdf_info(path)
    if not ok or not isinstance(pages, int):
        return None
    TEXT_DIR.mkdir(parents=True, exist_ok=True)
    text_path = TEXT_DIR / f"{path.stem}.txt"
    reader = PdfReader(str(path))
    parts = []
    for i, page in enumerate(reader.pages, start=1):
        try:
            text = page.extract_text() or ""
        except Exception as exc:
            text = f"[TEXT_EXTRACTION_ERROR {exc}]"
        parts.append(f"\n\n--- PDF_PAGE {i} DOC_ID {doc_id} ---\n{text}")
    text_path.write_text("".join(parts), encoding="utf-8")
    return text_path


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    NACA.mkdir(parents=True, exist_ok=True)
    MANIFEST.parent.mkdir(parents=True, exist_ok=True)
    rows = []
    for source in SOURCES:
        target = source.out_dir / source.name
        if target.exists():
            existing_ok, existing_pages, existing_sha = pdf_info(target)
            if existing_ok:
                text_path = extract_text(target, source.doc_id)
                rows.append({
                    "name": source.name,
                    "report": source.report,
                    "nasa_id": source.doc_id,
                    "citation_url": source.citation_url,
                    "used_url": "EXISTING_VALID_FILE",
                    "final_url": "",
                    "local_path": str(target.relative_to(ROOT)),
                    "status": "EXISTING_VALID_PDF",
                    "error": "",
                    "content_type": "",
                    "size_bytes": target.stat().st_size,
                    "sha256": existing_sha,
                    "pdf_header_valid": existing_ok,
                    "page_count": existing_pages,
                    "text_path": "" if text_path is None else str(text_path.relative_to(ROOT)),
                })
                continue
        candidates = unique(
            api_download_candidates(source)
            + citation_download_candidates(source)
            + [source.direct_pdf_url]
        )
        status_label = "NOT_ATTEMPTED"
        error = ""
        used_url = ""
        content_type = ""
        final_url = ""
        for url in candidates:
            print(f"TRY {source.name} {url}", flush=True)
            status, ctype, data, landed = fetch(url)
            content_type = ctype
            final_url = landed
            if status == 200 and data.startswith(b"%PDF-"):
                target.write_bytes(data)
                used_url = url
                status_label = "DOWNLOADED"
                error = ""
                break
            status_label = f"HTTP_{status}"
            error = f"not_pdf_or_failed bytes={len(data)}"
            time.sleep(0.5)
        if target.exists():
            header_valid, page_count, sha = pdf_info(target)
            if header_valid:
                size = target.stat().st_size
                text_path = extract_text(target, source.doc_id)
            else:
                target.unlink()
                page_count, sha, size, text_path = "MISSING", "", 0, None
        else:
            header_valid, page_count, sha, size, text_path = False, "MISSING", "", 0, None
        rows.append({
            "name": source.name,
            "report": source.report,
            "nasa_id": source.doc_id,
            "citation_url": source.citation_url,
            "used_url": used_url,
            "final_url": final_url,
            "local_path": str(target.relative_to(ROOT)),
            "status": status_label,
            "error": error,
            "content_type": content_type,
            "size_bytes": size,
            "sha256": sha,
            "pdf_header_valid": header_valid,
            "page_count": page_count,
            "text_path": "" if text_path is None else str(text_path.relative_to(ROOT)),
        })
    with MANIFEST.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)
    print(f"WROTE {MANIFEST.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
