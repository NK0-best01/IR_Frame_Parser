"""SQLite database layer for irframe_parser."""
from __future__ import annotations

import sqlite3
from typing import Any

ALLOWED_COLUMNS = {"no", "office", "date", "status", "sn", "type", "completed_at", "entry_date"}


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
            status TEXT DEFAULT 'เคสทัสสกรีนเสีย',
            sn TEXT,
            type TEXT,
            entry_date TEXT DEFAULT (date('now', 'localtime')),
            completed_at TEXT,
            created_at TEXT DEFAULT (datetime('now', 'localtime'))
        );
        """
    )
    # Check for column migrations on existing DBs
    cur = conn.cursor()
    cur.execute("PRAGMA table_info(records)")
    columns = [row["name"] for row in cur.fetchall()]
    if "completed_at" not in columns:
        conn.execute("ALTER TABLE records ADD COLUMN completed_at TEXT")
    if "entry_date" not in columns:
        conn.execute("ALTER TABLE records ADD COLUMN entry_date TEXT")
        conn.execute("UPDATE records SET entry_date = COALESCE(substr(created_at, 1, 10), date('now', 'localtime')) WHERE entry_date IS NULL")
    conn.commit()


def insert_many(conn: sqlite3.Connection, rows: list[dict[str, Any]], entry_date: str | None = None) -> None:
    """Insert multiple records into records table with entry_date tracking."""
    if not rows:
        return

    cur = conn.cursor()
    for r in rows:
        target_entry_date = str(r.get("entry_date") or entry_date or "").strip()
        if not target_entry_date:
            cur.execute("SELECT date('now', 'localtime')")
            target_entry_date = cur.fetchone()[0]

        cur.execute("SELECT COALESCE(MAX(no), 0) FROM records WHERE entry_date = ?", (target_entry_date,))
        current_max_no = cur.fetchone()[0]

        no_val = r.get("no") if r.get("no") is not None else (current_max_no + 1)
        office = r.get("office", "")
        date = r.get("date", "")
        status = r.get("status") or "เคสทัสสกรีนเสีย"
        sn = r.get("sn", "")
        type_ = r.get("type", "")
        completed_at = r.get("completed_at")
        if not completed_at and "เสร็จ" in str(status):
            cur.execute("SELECT datetime('now', 'localtime')")
            completed_at = cur.fetchone()[0]

        cur.execute(
            """
            INSERT INTO records (no, office, date, status, sn, type, entry_date, completed_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (no_val, office, date, status, sn, type_, target_entry_date, completed_at),
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


def delete_by_entry_date(conn: sqlite3.Connection, entry_date: str) -> int:
    """Delete all records for a specific entry_date."""
    cur = conn.cursor()
    cur.execute("DELETE FROM records WHERE entry_date = ?", (entry_date,))
    deleted = cur.rowcount
    conn.commit()
    return deleted


def renumber(conn: sqlite3.Connection, entry_date: str | None = None) -> None:
    """Renumber records sequentially from 1 to N within entry_date (or across all if None)."""
    cur = conn.cursor()
    if entry_date:
        dates = [entry_date]
    else:
        cur.execute("SELECT DISTINCT entry_date FROM records ORDER BY entry_date ASC")
        dates = [r[0] for r in cur.fetchall()]

    for ed in dates:
        if ed is None:
            cur.execute("SELECT id FROM records WHERE entry_date IS NULL ORDER BY no ASC, id ASC")
        else:
            cur.execute("SELECT id FROM records WHERE entry_date = ? ORDER BY no ASC, id ASC", (ed,))
        rows = cur.fetchall()
        for new_no, row in enumerate(rows, start=1):
            cur.execute("UPDATE records SET no = ? WHERE id = ?", (new_no, row["id"]))
    conn.commit()


def get_distinct_entry_dates(conn: sqlite3.Connection) -> list[str]:
    """Get list of distinct entry dates ordered ascending."""
    cur = conn.cursor()
    cur.execute("SELECT DISTINCT entry_date FROM records WHERE entry_date IS NOT NULL AND entry_date != '' ORDER BY entry_date ASC")
    return [row[0] for row in cur.fetchall() if row[0]]


def get_expired_records(conn: sqlite3.Connection, days: int = 10) -> list[dict[str, Any]]:
    """List records whose entry_date or completed_at is older than `days` days."""
    cur = conn.cursor()
    cur.execute(
        """
        SELECT id, no, office, date, status, sn, type, entry_date, completed_at, created_at
        FROM records
        WHERE (
            (entry_date IS NOT NULL AND (julianday('now', 'localtime') - julianday(entry_date)) >= ?)
            OR
            (completed_at IS NOT NULL AND (julianday('now', 'localtime') - julianday(completed_at)) >= ?)
        )
        ORDER BY entry_date ASC, no ASC
        """,
        (days, days),
    )
    return [dict(r) for r in cur.fetchall()]


def delete_expired_records(conn: sqlite3.Connection, days: int = 10) -> int:
    """Delete records older than `days` days from entry_date or completed_at."""
    cur = conn.cursor()
    cur.execute(
        """
        DELETE FROM records
        WHERE (
            (entry_date IS NOT NULL AND (julianday('now', 'localtime') - julianday(entry_date)) >= ?)
            OR
            (completed_at IS NOT NULL AND (julianday('now', 'localtime') - julianday(completed_at)) >= ?)
        )
        """,
        (days, days),
    )
    deleted_count = cur.rowcount
    conn.commit()
    if deleted_count > 0:
        renumber(conn)
    return deleted_count


def get_expired_completed_records(conn: sqlite3.Connection, days: int = 30) -> list[dict[str, Any]]:
    """Alias for backwards compatibility."""
    return get_expired_records(conn, days)


def delete_expired_completed(conn: sqlite3.Connection, days: int = 30) -> int:
    """Alias for backwards compatibility."""
    return delete_expired_records(conn, days)


def list_by_entry_date(conn: sqlite3.Connection, entry_date: str) -> list[dict[str, Any]]:
    """List records for a specific entry_date ordered by no."""
    cur = conn.cursor()
    cur.execute(
        """
        SELECT id, no, office, date, status, sn, type, entry_date, completed_at, created_at
        FROM records
        WHERE entry_date = ?
        ORDER BY no ASC, id ASC
        """,
        (entry_date,),
    )
    return [dict(r) for r in cur.fetchall()]


def list_all(conn: sqlite3.Connection) -> list[dict[str, Any]]:
    """List all records ordered by entry_date, no."""
    cur = conn.cursor()
    cur.execute(
        """
        SELECT id, no, office, date, status, sn, type, entry_date, completed_at, created_at
        FROM records
        ORDER BY entry_date ASC, no ASC, id ASC
        """
    )
    return [dict(r) for r in cur.fetchall()]
