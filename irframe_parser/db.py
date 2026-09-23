"""SQLite database layer for irframe_parser."""
from __future__ import annotations

import sqlite3
from typing import Any

ALLOWED_COLUMNS = {"no", "office", "date", "status", "sn", "type", "completed_at"}


def connect(path: str) -> sqlite3.Connection:
    """Connect to SQLite database and set row_factory."""
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    return conn


def init_schema(conn: sqlite3.Connection) -> None:
    """Initialize SQLite schema for records table and handle migrations."""
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
            completed_at TEXT,
            created_at TEXT DEFAULT (datetime('now'))
        );
        """
    )
    # Check if completed_at column exists for existing DB migration
    cur = conn.cursor()
    cur.execute("PRAGMA table_info(records)")
    columns = [row["name"] for row in cur.fetchall()]
    if "completed_at" not in columns:
        conn.execute("ALTER TABLE records ADD COLUMN completed_at TEXT")
    conn.commit()


def insert_many(conn: sqlite3.Connection, rows: list[dict[str, Any]]) -> None:
    """Insert multiple records into records table with completed_at tracking."""
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
        completed_at = r.get("completed_at")
        if not completed_at and "เสร็จ" in str(status):
            cur.execute("SELECT datetime('now', 'localtime')")
            completed_at = cur.fetchone()[0]

        cur.execute(
            """
            INSERT INTO records (no, office, date, status, sn, type, completed_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (no_val, office, date, status, sn, type_, completed_at),
        )
    conn.commit()


def update_field(conn: sqlite3.Connection, row_id: int, col: str, val: Any) -> None:
    """Update a specific field for a given record ID, managing completed_at timestamps."""
    if col not in ALLOWED_COLUMNS:
        raise ValueError(f"Invalid column: {col}")

    if col == "status":
        if "เสร็จ" in str(val):
            conn.execute(
                "UPDATE records SET status = ?, completed_at = datetime('now', 'localtime') WHERE id = ?",
                (val, row_id),
            )
        else:
            conn.execute(
                "UPDATE records SET status = ?, completed_at = NULL WHERE id = ?",
                (val, row_id),
            )
    else:
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


def get_expired_completed_records(conn: sqlite3.Connection, days: int = 30) -> list[dict[str, Any]]:
    """List completed records whose completion date is older than `days` days."""
    cur = conn.cursor()
    cur.execute(
        """
        SELECT id, no, office, date, status, sn, type, completed_at, created_at
        FROM records
        WHERE (status LIKE '%เสร็จ%')
          AND completed_at IS NOT NULL
          AND (julianday('now', 'localtime') - julianday(completed_at)) >= ?
        ORDER BY no ASC, id ASC
        """,
        (days,),
    )
    return [dict(r) for r in cur.fetchall()]


def delete_expired_completed(conn: sqlite3.Connection, days: int = 30) -> int:
    """Delete completed records older than `days` days and renumber remaining records."""
    cur = conn.cursor()
    cur.execute(
        """
        DELETE FROM records
        WHERE (status LIKE '%เสร็จ%')
          AND completed_at IS NOT NULL
          AND (julianday('now', 'localtime') - julianday(completed_at)) >= ?
        """,
        (days,),
    )
    deleted_count = cur.rowcount
    conn.commit()
    if deleted_count > 0:
        renumber(conn)
    return deleted_count


def list_all(conn: sqlite3.Connection) -> list[dict[str, Any]]:
    """List all records ordered by no."""
    cur = conn.cursor()
    cur.execute(
        """
        SELECT id, no, office, date, status, sn, type, completed_at, created_at
        FROM records
        ORDER BY no ASC, id ASC
        """
    )
    return [dict(r) for r in cur.fetchall()]
