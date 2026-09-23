"""Qt Model definitions for irframe_parser."""
from __future__ import annotations

import sqlite3
from typing import Any

from PySide6.QtCore import (
    QAbstractTableModel,
    QModelIndex,
    QObject,
    Qt,
    Signal,
    Slot,
    Property,
)

from irframe_parser import db
from irframe_parser.parser import parse_raw as parse_raw_fn

INITIAL_RECORDS = [
    {"office": "ร้อยเอ็ด แห่ง 2", "date": "13/05/2511", "status": "รออะไหล่", "sn": "FQ79BW2", "type": "Dell Optiplax 3050 AIO"},
    {"office": "พัทลุง ตะโหนด", "date": "05/06/2511", "status": "รออะไหล่", "sn": "FX5DBW2", "type": "Dell Optiplax 3050 AIO"},
    {"office": "สมุทรสงคราม", "date": "13/06/2511", "status": "รออะไหล่", "sn": "FX8BBW2", "type": "Dell Optiplax 3050 AIO"},
    {"office": "พัทลุง ตะโหนด", "date": "16/06/2511", "status": "รออะไหล่", "sn": "JMD7BW2", "type": "Dell Optiplax 3050 AIO"},
    {"office": "พัทลุง จ.", "date": "26/06/2511", "status": "รออะไหล่", "sn": "FSKDBW2", "type": "Dell Optiplax 3050 AIO"},
    {"office": "สขข.สายบุรี", "date": "26/06/2511", "status": "รออะไหล่", "sn": "JNX0WV2", "type": "Dell Optiplax 3050 AIO"},
    {"office": "สขข.สายบุรี", "date": "26/06/2511", "status": "รออะไหล่", "sn": "FWNDBW2", "type": "Dell Optiplax 3050 AIO"},
    {"office": "ชลบุรี สขข.บางละมุง", "date": "02/07/2511", "status": "รออะไหล่", "sn": "10719X2", "type": "Dell Optiplax 3050 AIO"},
    {"office": "ปง", "date": "12/06/2511", "status": "รออะไหล่", "sn": "FLWCBW2", "type": "Dell Optiplax 3050 AIO"},
    {"office": "หนองบัว", "date": "16/07/2511", "status": "รออะไหล่", "sn": "3QMT8X2", "type": "Dell Optiplax 3050 AIO"},
    {"office": "เพชรบุรี", "date": "17/07/2511", "status": "รออะไหล่", "sn": "3QBW8X2", "type": "Dell Optiplax 3050 AIO"},
    {"office": "สุโขทัย", "date": "14/07/2511", "status": "รออะไหล่", "sn": "FML8BW2", "type": "Dell Optiplax 3050 AIO"},
    {"office": "ชลบุรี", "date": "21/07/2511", "status": "รออะไหล่", "sn": "3Q9W8X2", "type": "Dell Optiplax 3050 AIO"},
    {"office": "เดิมบางนางบวช", "date": "21/07/2511", "status": "รออะไหล่", "sn": "3N9Z8X2", "type": "Dell Optiplax 3050 AIO"},
    {"office": "ฉะเชิงเทรา", "date": "30/07/2511", "status": "รออะไหล่", "sn": "1DCZ8X2", "type": "Dell Optiplax 3050 AIO"},
]


class RecordTableModel(QAbstractTableModel):
    """Table model managing repair records backed by SQLite."""

    COL_NO = 0
    COL_OFFICE = 1
    COL_DATE = 2
    COL_STATUS = 3
    COL_SN = 4
    COL_TYPE = 5

    COL_NAMES = ["no", "office", "date", "status", "sn", "type"]
    HEADERS = ["ลำดับ", "สนง.", "วันที่รับเคส", "สถานะแจ้งซ่อม", "Serial Number", "ประเภทครุภัณฑ์"]

    NoRole = Qt.UserRole + 1
    OfficeRole = Qt.UserRole + 2
    DateRole = Qt.UserRole + 3
    StatusRole = Qt.UserRole + 4
    SnRole = Qt.UserRole + 5
    TypeRole = Qt.UserRole + 6
    IdRole = Qt.UserRole + 7

    statsChanged = Signal(int, int, int)
    hasMissingSnChanged = Signal(bool)

    def __init__(self, connection: sqlite3.Connection, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self.conn = connection
        self._records: list[dict[str, Any]] = []
        self._reload_records()

    def _reload_records(self) -> None:
        self.beginResetModel()
        self._records = db.list_all(self.conn)
        self.endResetModel()
        self._emit_stats()

    def _emit_stats(self) -> None:
        total = len(self._records)
        with_sn = sum(1 for r in self._records if r.get("sn"))
        missing_sn = total - with_sn
        self.statsChanged.emit(total, with_sn, missing_sn)
        self.hasMissingSnChanged.emit(missing_sn > 0)

    def rowCount(self, parent: QModelIndex = QModelIndex()) -> int:
        return len(self._records)

    def columnCount(self, parent: QModelIndex = QModelIndex()) -> int:
        return len(self.COL_NAMES)

    def headerData(self, section: int, orientation: Qt.Orientation, role: int = Qt.DisplayRole) -> Any:
        if orientation == Qt.Horizontal and role == Qt.DisplayRole:
            if 0 <= section < len(self.HEADERS):
                return self.HEADERS[section]
        return None

    def roleNames(self) -> dict[int, bytes]:
        return {
            self.NoRole: b"no",
            self.OfficeRole: b"office",
            self.DateRole: b"date",
            self.StatusRole: b"status",
            self.SnRole: b"sn",
            self.TypeRole: b"type",
            self.IdRole: b"rowId",
        }

    def data(self, index: QModelIndex, role: int = Qt.DisplayRole) -> Any:
        if not index.isValid() or not (0 <= index.row() < len(self._records)):
            return None

        row = self._records[index.row()]
        col = index.column()

        if role in (Qt.DisplayRole, Qt.EditRole):
            if 0 <= col < len(self.COL_NAMES):
                col_name = self.COL_NAMES[col]
                return row.get(col_name, "")
        elif role == self.NoRole:
            return row.get("no", index.row() + 1)
        elif role == self.OfficeRole:
            return row.get("office", "")
        elif role == self.DateRole:
            return row.get("date", "")
        elif role == self.StatusRole:
            return row.get("status", "")
        elif role == self.SnRole:
            return row.get("sn", "")
        elif role == self.TypeRole:
            return row.get("type", "")
        elif role == self.IdRole:
            return row.get("id", 0)

        return None

    def setData(self, index: QModelIndex, value: Any, role: int = Qt.EditRole) -> bool:
        if not index.isValid() or not (0 <= index.row() < len(self._records)):
            return False

        if role == Qt.EditRole:
            col = index.column()
            if 0 <= col < len(self.COL_NAMES):
                col_name = self.COL_NAMES[col]
                row_id = self._records[index.row()]["id"]
                val_str = str(value)
                db.update_field(self.conn, row_id, col_name, val_str)
                self._records[index.row()][col_name] = val_str
                self.dataChanged.emit(index, index, [Qt.DisplayRole, Qt.EditRole])
                self._emit_stats()
                return True

        return False

    def flags(self, index: QModelIndex) -> Qt.ItemFlags:
        if not index.isValid():
            return Qt.NoItemFlags
        return Qt.ItemIsEnabled | Qt.ItemIsSelectable | Qt.ItemIsEditable

    @Slot(str)
    def parse_raw(self, text: str) -> None:
        """Parse raw text and insert into database."""
        rows = parse_raw_fn(text)
        if rows:
            db.insert_many(self.conn, rows)
            self._reload_records()

    @Slot()
    def add_row(self) -> None:
        """Add a new empty record."""
        new_record = {
            "office": "",
            "date": "",
            "status": "รออะไหล่",
            "sn": "",
            "type": "Dell Optiplax 3050 AIO",
        }
        db.insert_many(self.conn, [new_record])
        self._reload_records()

    @Slot(int)
    def delete_row(self, row_idx: int) -> None:
        """Delete row at given index and renumber."""
        if 0 <= row_idx < len(self._records):
            row_id = self._records[row_idx]["id"]
            db.delete(self.conn, row_id)
            db.renumber(self.conn)
            self._reload_records()

    @Slot(int, str, str)
    def update_cell(self, row_idx: int, col_name: str, value: str) -> None:
        """Update a specific field for a row index directly from QML."""
        if 0 <= row_idx < len(self._records) and col_name in self.COL_NAMES:
            row_id = self._records[row_idx]["id"]
            db.update_field(self.conn, row_id, col_name, value)
            self._records[row_idx][col_name] = value
            col_idx = self.COL_NAMES.index(col_name)
            idx = self.index(row_idx, col_idx)
            self.dataChanged.emit(idx, idx, [Qt.DisplayRole, Qt.EditRole])
            self._emit_stats()

    @Slot()
    def load_example(self) -> None:
        """Load 15 sample records from the original template."""
        for r in self._records:
            db.delete(self.conn, r["id"])
        db.insert_many(self.conn, INITIAL_RECORDS)
        db.renumber(self.conn)
        self._reload_records()

    @Slot()
    def clear_all(self) -> None:
        """Clear all records from database."""
        for r in self._records:
            db.delete(self.conn, r["id"])
        self._reload_records()

    @Slot(str)
    def export_xlsx(self, file_path: str) -> None:
        """Export current records to Excel .xlsx."""
        from irframe_parser.exporter import export_xlsx
        clean_path = file_path.replace("file:///", "").replace("file://", "")
        export_xlsx(self._records, clean_path)

    @Slot(result=list)
    def get_all_records(self) -> list[dict[str, Any]]:
        """Return all records for preview in QML."""
        return list(self._records)
