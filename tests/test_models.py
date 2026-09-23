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
