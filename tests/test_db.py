import pytest
from irframe_parser import db


@pytest.fixture
def conn(tmp_path):
    db_path = tmp_path / "test.db"
    connection = db.connect(str(db_path))
    db.init_schema(connection)
    yield connection
    connection.close()


def test_insert_many_and_list_all(conn):
    rows = [
        {
            "office": "สขจ.สกลนคร",
            "date": "26/08/2569",
            "status": "รออะไหล่",
            "sn": "ABC1234",
            "type": "Dell Optiplax 3050 AIO",
        },
        {
            "office": "พัทลุง",
            "date": "05/06/2553",
            "status": "รออะไหล่",
            "sn": "XYZ5678",
            "type": "Dell Optiplax 3050 AIO",
        },
    ]
    db.insert_many(conn, rows)
    result = db.list_all(conn)
    assert len(result) == 2
    assert result[0]["sn"] == "ABC1234"
    assert result[0]["no"] == 1
    assert result[1]["no"] == 2


def test_update_field(conn):
    db.insert_many(
        conn,
        [{"office": "A", "date": "", "status": "รออะไหล่", "sn": "SN1", "type": "T"}],
    )
    row_id = db.list_all(conn)[0]["id"]
    db.update_field(conn, row_id, "sn", "SN-UPDATED")
    assert db.list_all(conn)[0]["sn"] == "SN-UPDATED"


def test_delete_and_renumber(conn):
    db.insert_many(
        conn,
        [
            {"office": "A", "date": "", "status": "รออะไหล่", "sn": "SN1", "type": "T"},
            {"office": "B", "date": "", "status": "รออะไหล่", "sn": "SN2", "type": "T"},
            {"office": "C", "date": "", "status": "รออะไหล่", "sn": "SN3", "type": "T"},
        ],
    )
    rows = db.list_all(conn)
    db.delete(conn, rows[0]["id"])
    db.renumber(conn)
    remaining = db.list_all(conn)
    assert len(remaining) == 2
    assert [r["no"] for r in remaining] == [1, 2]
    assert remaining[0]["sn"] == "SN2"


def test_list_all_empty(conn):
    assert db.list_all(conn) == []


def test_completed_at_timestamp_tracking(conn):
    db.insert_many(conn, [{"office": "A", "date": "", "status": "รออะไหล่", "sn": "SN1", "type": "T"}])
    row = db.list_all(conn)[0]
    assert row["completed_at"] is None

    # Change to เสร็จแล้ว -> completed_at should be set
    db.update_field(conn, row["id"], "status", "เสร็จแล้ว")
    row_updated = db.list_all(conn)[0]
    assert row_updated["completed_at"] is not None

    # Change back to รออะไหล่ -> completed_at should be cleared
    db.update_field(conn, row["id"], "status", "รออะไหล่")
    row_reverted = db.list_all(conn)[0]
    assert row_reverted["completed_at"] is None


def test_get_and_delete_expired_completed(conn):
    # Insert:
    # 1. Old completed (40 days ago)
    # 2. Recent completed (5 days ago)
    # 3. Waiting (no completed_at)
    db.insert_many(conn, [
        {"office": "A", "status": "เสร็จแล้ว", "sn": "OLD-SN", "completed_at": "2026-01-01 10:00:00"},
        {"office": "B", "status": "เสร็จแล้ว", "sn": "RECENT-SN", "completed_at": "2026-09-20 10:00:00"},
        {"office": "C", "status": "รออะไหล่", "sn": "WAIT-SN"},
    ])

    expired = db.get_expired_completed_records(conn, days=30)
    assert len(expired) == 1
    assert expired[0]["sn"] == "OLD-SN"

    # Delete expired
    deleted = db.delete_expired_completed(conn, days=30)
    assert deleted == 1

    remaining = db.list_all(conn)
    assert len(remaining) == 2
    assert [r["sn"] for r in remaining] == ["RECENT-SN", "WAIT-SN"]
    assert [r["no"] for r in remaining] == [1, 2]

