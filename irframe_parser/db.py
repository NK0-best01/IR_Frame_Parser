"""SQLite database layer for irframe_parser."""
from __future__ import annotations

import sqlite3
from typing import Any

ALLOWED_COLUMNS = {"no", "office", "date", "status", "sn", "type"}


def connect(path: str) -> sqlite3.Connection:
    """Connect to SQLite database and set row_factory."""
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    return conn


def init_schema(conn: sqlite3.Connection) -> None:
    """Initialize SQLite schema for records table."""
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            no INTEGER,
            office TEXT,
            date TEXT,
            status TEXT DEFAULT 'รออะไหล่',
            sn TEXT,
            type TEXT,
            created_at TEXT DEFAULT (datetime('now'))
        );
        """
    )
    conn.commit()


def insert_many(conn: sqlite3.Connection, rows: list[dict[str, Any]]) -> None:
    """Insert multiple records into records table."""
    if not rows:
        return

    cur = conn.cursor()
    cur.execute("SELECT COALESCE(MAX(no), 0) FROM records")
    current_max_no = cur.fetchone()[0]

    for r in rows:
        current_max_no += 1
        no_val = r.get("no") if r.get("no") is not None else current_max_no
        office = r.get("office", "")
        date = r.get("date", "")
        status = r.get("status", "รออะไหล่")
        sn = r.get("sn", "")
        type_ = r.get("type", "")

        cur.execute(
            """
            INSERT INTO records (no, office, date, status, sn, type)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (no_val, office, date, status, sn, type_),
        )
    conn.commit()


def update_field(conn: sqlite3.Connection, row_id: int, col: str, val: Any) -> None:
    """Update a specific field for a given record ID."""
    if col not in ALLOWED_COLUMNS:
        raise ValueError(f"Invalid column: {col}")

    conn.execute(f"UPDATE records SET {col} = ? WHERE id = ?", (val, row_id))
    conn.commit()


def delete(conn: sqlite3.Connection, row_id: int) -> None:
    """Delete a record by ID."""
    conn.execute("DELETE FROM records WHERE id = ?", (row_id,))
    conn.commit()


def renumber(conn: sqlite3.Connection) -> None:
    """Renumber all records sequentially from 1 to N."""
    cur = conn.cursor()
    cur.execute("SELECT id FROM records ORDER BY no ASC, id ASC")
    rows = cur.fetchall()
    for new_no, row in enumerate(rows, start=1):
        cur.execute("UPDATE records SET no = ? WHERE id = ?", (new_no, row["id"]))
    conn.commit()


def list_all(conn: sqlite3.Connection) -> list[dict[str, Any]]:
    """List all records ordered by no."""
    cur = conn.cursor()
    cur.execute(
        """
        SELECT id, no, office, date, status, sn, type, created_at
        FROM records
        ORDER BY no ASC, id ASC
        """
    )
    return [dict(r) for r in cur.fetchall()]
