import pytest
from PySide6.QtCore import Qt
from irframe_parser import db
from irframe_parser.models import RecordTableModel


@pytest.fixture
def model(tmp_path):
    db_path = tmp_path / "test.db"
    conn = db.connect(str(db_path))
    db.init_schema(conn)
    m = RecordTableModel(conn)
    yield m
    conn.close()


def test_row_count_reflects_db(model):
    model.parse_raw("SN : GGG7777")
    assert model.rowCount() == 1


def test_set_data_persists_to_db(model):
    model.parse_raw("SN : HHH8888")
    index = model.index(0, model.COL_SN)
    model.setData(index, "HHH-EDITED", Qt.EditRole)
    assert model.data(index, Qt.EditRole) == "HHH-EDITED"
    reloaded = RecordTableModel(model.conn)
    assert reloaded.data(reloaded.index(0, reloaded.COL_SN), Qt.EditRole) == "HHH-EDITED"


def test_delete_row_updates_count_and_renumbers(model):
    model.parse_raw("SN : III9999")
    model.parse_raw("SN : JJJ0000")
    model.delete_row(0)
    assert model.rowCount() == 1
    assert model.data(model.index(0, model.COL_NO), Qt.DisplayRole) == 1


def test_stats_signal_emitted_on_change(model, qtbot):
    with qtbot.waitSignal(model.statsChanged, timeout=1000) as blocker:
        model.parse_raw("SN : KKK1111")
    total, with_sn, missing_sn = blocker.args
    assert total == 1
    assert with_sn == 1
    assert missing_sn == 0


def test_summary_stats_changed_signal(model, qtbot):
    with qtbot.waitSignal(model.summaryStatsChanged, timeout=1000) as blocker:
        model.parse_raw("SN : LLL2222\nสถานะ : รออะไหล่")
    total, waiting, completed = blocker.args
    assert total == 1
    assert waiting == 1
    assert completed == 0

    # Update to เสร็จแล้ว
    with qtbot.waitSignal(model.summaryStatsChanged, timeout=1000) as blocker2:
        model.update_cell(0, "status", "เสร็จแล้ว")
    total, waiting, completed = blocker2.args
    assert total == 1
    assert waiting == 0
    assert completed == 1


def test_date_sorting_newest_to_oldest(model):
    # Insert older date and newer date
    model.parse_raw("วันที่ 10/05/2567\nSN : AAA1111")
    model.parse_raw("วันที่ 25/08/2567\nSN : BBB2222")
    model.parse_raw("วันที่ 05/01/2568\nSN : CCC3333")

    # Default sort is sequence number (no) ascending
    assert model.sortColumn == "no"
    assert model.sortAscending is True

    # Sort by date defaults to newest to oldest (descending)
    model.sort_by_col("date")
    assert model.sortColumn == "date"
    assert model.sortAscending is False
    assert model.data(model.index(0, model.COL_DATE), Qt.DisplayRole) == "05/01/2568"
    assert model.data(model.index(1, model.COL_DATE), Qt.DisplayRole) == "25/08/2567"
    assert model.data(model.index(2, model.COL_DATE), Qt.DisplayRole) == "10/05/2567"

    # Toggle sort on date (oldest to newest)
    model.sort_by_col("date")
    assert model.sortAscending is True
    assert model.data(model.index(0, model.COL_DATE), Qt.DisplayRole) == "10/05/2567"
    assert model.data(model.index(2, model.COL_DATE), Qt.DisplayRole) == "05/01/2568"


def test_expired_completed_cleanup_slots(model):
    db.insert_many(model.conn, [
        {"office": "สำนักงาน A", "status": "เสร็จแล้ว", "sn": "OLD-999", "completed_at": "2026-01-01 12:00:00"},
        {"office": "สำนักงาน B", "status": "รออะไหล่", "sn": "WAIT-111"},
    ])
    model._reload_records()

    # Check expired count
    count = model.check_expired_completed_count(30)
    assert count == 1

    records = model.get_expired_completed_records(30)
    assert len(records) == 1
    assert records[0]["sn"] == "OLD-999"

    # Confirm deletion
    deleted = model.confirm_delete_expired(30)
    assert deleted == 1
    assert model.rowCount() == 1
    assert model.data(model.index(0, model.COL_SN), Qt.DisplayRole) == "WAIT-111"


def test_startup_expired_detection_and_confirmation(tmp_path):
    db_path = tmp_path / "test_startup.db"
    conn = db.connect(str(db_path))
    db.init_schema(conn)
    db.insert_many(conn, [
        {"office": "สำนักงาน A", "status": "เสร็จแล้ว", "sn": "EXPIRED-1", "completed_at": "2026-01-01 12:00:00"},
        {"office": "สำนักงาน B", "status": "เสร็จแล้ว", "sn": "RECENT-2", "completed_at": "2026-09-20 12:00:00"},
        {"office": "สำนักงาน C", "status": "รออะไหล่", "sn": "WAIT-3"},
    ])

    # Startup: Model loads all records safely without silent deletion
    new_model = RecordTableModel(conn)
    assert new_model.rowCount() == 3

    # On startup check: UI detects 1 expired record
    expired_count = new_model.check_expired_completed_count(30)
    assert expired_count == 1

    # User confirms deletion
    deleted = new_model.confirm_delete_expired(30)
    assert deleted == 1
    assert new_model.rowCount() == 2

    sns = [new_model.data(new_model.index(i, new_model.COL_SN), Qt.DisplayRole) for i in range(new_model.rowCount())]
    assert "EXPIRED-1" not in sns
    assert "RECENT-2" in sns
    assert "WAIT-3" in sns
    conn.close()


def test_row_selection_and_select_all(model):
    model.parse_raw("SN : SN-001\n\nSN : SN-002\n\nSN : SN-003")
    assert model.rowCount() == 3
    assert model.selectedCount == 3
    assert model.allSelected is True

    # Unselect row 1
    model.set_row_selected(1, False)
    assert model.selectedCount == 2
    assert model.allSelected is False
    assert model.data(model.index(1, 0), model.SelectedRole) is False
    assert model.data(model.index(0, 0), model.SelectedRole) is True

    # Toggle select all False
    model.toggle_select_all(False)
    assert model.selectedCount == 0
    assert model.allSelected is False
    assert model.data(model.index(0, 0), model.SelectedRole) is False

    # Toggle select all True
    model.toggle_select_all(True)
    assert model.selectedCount == 3
    assert model.allSelected is True
    assert model.data(model.index(0, 0), model.SelectedRole) is True


def test_export_only_selected_rows(model, tmp_path):
    import openpyxl

    model.parse_raw("SN : SN-KEEP\n\nSN : SN-DROP")
    assert model.rowCount() == 2

    # Deselect row 1 (SN-DROP)
    model.set_row_selected(1, False)
    assert model.selectedCount == 1

    out_file = tmp_path / "selected_export.xlsx"
    model.export_xlsx(str(out_file))

    wb = openpyxl.load_workbook(out_file)
    ws = wb.active
    # Row 6 should be SN-KEEP
    assert ws.cell(row=6, column=6).value == "SN-KEEP"
    # Row 7 should not be SN-DROP (instead it might be note or empty)
    assert ws.cell(row=7, column=6).value != "SN-DROP"


def test_daily_page_isolation_and_navigation(model):
    import datetime

    # 1. Today page: Add 2 cases
    model.parse_raw("SN : TODAY-1\n\nSN : TODAY-2")
    assert model.rowCount() == 2
    assert model.data(model.index(0, model.COL_NO), Qt.DisplayRole) == 1
    assert model.data(model.index(1, model.COL_NO), Qt.DisplayRole) == 2

    # 2. Navigate to previous day (yesterday)
    model.go_to_previous_day()
    assert model.rowCount() == 0  # Yesterday has no cases yet

    # 3. Add 1 case to yesterday
    model.parse_raw("SN : YESTERDAY-1")
    assert model.rowCount() == 1
    assert model.data(model.index(0, model.COL_NO), Qt.DisplayRole) == 1  # Sequence starts at 1 for yesterday

    # 4. Navigate back to today
    model.go_to_today()
    assert model.rowCount() == 2
    assert model.data(model.index(0, model.COL_SN), Qt.DisplayRole) == "TODAY-1"


def test_clear_current_page_only(model):
    # Setup: 2 records on today, 1 on previous day
    model.parse_raw("SN : TODAY-1\n\nSN : TODAY-2")
    model.go_to_previous_day()
    model.parse_raw("SN : PREV-1")

    # Clear previous day's page
    model.clear_current_page()
    assert model.rowCount() == 0

    # Switch to today -> today's records are intact
    model.go_to_today()
    assert model.rowCount() == 2
    assert model.data(model.index(0, model.COL_SN), Qt.DisplayRole) == "TODAY-1"


def test_ticket_date_independent_of_entry_date(model):
    # Raw ticket date is from last year, parsed today
    model.parse_raw("วันที่ 10/01/2568\nSN : OLD-TICKET")
    assert model.rowCount() == 1
    assert model.data(model.index(0, model.COL_DATE), Qt.DisplayRole) == "10/01/2568"
    assert model.isToday is True  # Stored in today's entry page!


def test_ten_day_expiration(model):
    # Insert 1 record from 15 days ago, and 1 from 2 days ago
    db.insert_many(model.conn, [
        {"sn": "EXPIRED-15D", "entry_date": "2026-01-01"},
        {"sn": "VALID-2D", "entry_date": "2026-09-22"},
    ])
    assert model.check_expired_count(10) == 1
    expired = model.get_expired_records(10)
    assert len(expired) == 1
    assert expired[0]["sn"] == "EXPIRED-15D"

    deleted = model.confirm_delete_expired(10)
    assert deleted == 1
    assert model.check_expired_count(10) == 0





