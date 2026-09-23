"""Regex parsing module for irframe_parser."""
from __future__ import annotations

import re
from typing import Any


def norm(s: str | None) -> str:
    """Normalize text by replacing non-breaking spaces and trimming."""
    if not s:
        return ""
    return re.sub(r"[|]+", " ", s.replace("\u00a0", " ")).strip()


def date_norm(s: str | None) -> str:
    """Normalize Thai date strings (BE/CE 2-digit and 4-digit years)."""
    if not s:
        return ""

    cleaned = norm(s).replace(".", "/").replace("-", "/")
    match = re.search(r"(\d{1,2})/(\d{1,2})/(\d{2,4})", cleaned)
    if not match:
        return ""

    day_str, month_str, year_str = match.groups()
    if len(year_str) == 2:
        year_str = f"25{year_str}"

    year_num = int(year_str)
    if 1900 < year_num < 2400:
        year_str = str(year_num + 543)

    return f"{int(day_str):02d}/{int(month_str):02d}/{year_str}"


def parse_raw(text: str) -> list[dict[str, Any]]:
    """Parse raw repair log text into list of records."""
    if not text or not text.strip():
        return []

    lines = [
        line.replace("\u00a0", " ").strip()
        for line in text.splitlines()
        if line.replace("\u00a0", " ").strip()
    ]
    joined_text = "\n".join(lines)

    # 1. Serial Number(s)
    sn_matches = list(
        re.finditer(
            r"(?:^|\n)\s*(?:\d+\.\s*)?SN\s*[:：]\s*([A-Za-z0-9][A-Za-z0-9._-]{3,29})",
            joined_text,
            re.IGNORECASE,
        )
    )
    sns = [m.group(1).strip() for m in sn_matches]

    # 2. Date
    date_match = re.search(r"\b(\d{1,2}[/.-]\d{1,2}[/.-]\d{2,4})\b", joined_text)
    date = date_norm(date_match.group(1)) if date_match else ""

    # 3. Office
    office_pattern = re.compile(
        r"^(?:สขจ\.|สขข\.|สนง\.|สำนักงาน|สสจ\.|ศูนย์|สาขา)",
        re.IGNORECASE,
    )
    office = ""
    for line in lines:
        if office_pattern.search(line):
            office = line
            break

    # 4. Status
    status_match = re.search(
        r"(?:สถานะแจ้งซ่อม|สถานะ)\s*[:：-]?\s*([^\n]+)",
        joined_text,
        re.IGNORECASE,
    )
    status = norm(status_match.group(1)) if status_match else "รออะไหล่"

    # 5. Type
    type_match = re.search(
        r"(?:ประเภท(?:ครุภัณฑ์)?|รุ่น|Model)\s*[:：-]?\s*([^\n]+)",
        joined_text,
        re.IGNORECASE,
    )
    if type_match:
        type_ = norm(type_match.group(1))
    elif re.search(r"ทัชสกรีน|touch\s*screen", joined_text, re.IGNORECASE):
        type_ = "Dell Optiplax 3050 AIO"
    else:
        type_ = ""

    # Build rows: 1 row per SN, or 1 row with empty SN
    if sns:
        rows = [
            {
                "office": office,
                "date": date,
                "status": status,
                "sn": sn,
                "type": type_,
            }
            for sn in sns
        ]
    else:
        rows = [
            {
                "office": office,
                "date": date,
                "status": status,
                "sn": "",
                "type": type_,
            }
        ]

    # Clean phone numbers accidentally captured as office or type
    for r in rows:
        if re.match(r"^\d[\d\s-]{8,}$", r["office"]):
            r["office"] = ""
        if re.match(r"^\d{9,}$", r["type"]):
            r["type"] = ""

    return rows
