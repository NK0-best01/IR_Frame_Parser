"""Qt Model definitions for irframe_parser with date chronological sorting, status dropdown, and summary stats."""
from __future__ import annotations

import datetime
import re
import sqlite3
from typing import Any

from PySide6.QtCore import (
    QAbstractTableModel,
    QModelIndex,
    QObject,
    Qt,
    QUrl,
    Signal,
    Slot,
    Property,
)

from irframe_parser import db
from irframe_parser.parser import date_norm, parse_raw as parse_raw_fn

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


def _parse_date_tuple(date_str: str) -> tuple[int, int, int]:
    """Parse Thai date string into (year, month, day) tuple for chronological sorting."""
    if not date_str:
        return (0, 0, 0)
    normed = date_norm(str(date_str))
    if not normed:
        m = re.match(r"(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})", str(date_str).strip())
        if not m:
            return (0, 0, 0)
        day = int(m.group(1))
        month = int(m.group(2))
        year = int(m.group(3))
        if year < 100:
            year += 2500
        elif year < 2400:
            year += 543
        return (year, month, day)
    parts = normed.split("/")
    return (int(parts[2]), int(parts[1]), int(parts[0]))


def _format_thai_date(iso_date: str) -> str:
    """Format YYYY-MM-DD into DD/MM/BBBB Thai date string."""
    if not iso_date or len(iso_date) != 10:
        return iso_date or ""
    parts = iso_date.split("-")
    if len(parts) == 3:
        try:
            return f"{int(parts[2]):02d}/{int(parts[1]):02d}/{int(parts[0]) + 543}"
        except ValueError:
            pass
    return iso_date


class RecordTableModel(QAbstractTableModel):
    """Table model managing repair records with chronological date sorting and status tracking."""

    COL_NO = 0
    COL_OFFICE = 1
    COL_DATE = 2
    COL_STATUS = 3
    COL_SN = 4
    COL_TYPE = 5

    COL_NAMES = ["no", "office", "date", "status", "sn", "type"]
    HEADERS = ["ลำดับ", "สนง.", "วันที่รับเคส", "สถานะแจ้งซ่อม", "Serial Number", "เครื่อง/อุปกรณ์"]

    NoRole = Qt.UserRole + 1
    OfficeRole = Qt.UserRole + 2
    DateRole = Qt.UserRole + 3
    StatusRole = Qt.UserRole + 4
    SnRole = Qt.UserRole + 5
    TypeRole = Qt.UserRole + 6
    IdRole = Qt.UserRole + 7
    SelectedRole = Qt.UserRole + 8

    COL_ROLES = {
        "no": NoRole,
        "office": OfficeRole,
        "date": DateRole,
        "status": StatusRole,
        "sn": SnRole,
        "type": TypeRole,
    }

    statsChanged = Signal(int, int, int)
    summaryStatsChanged = Signal(int, int, int)
    hasMissingSnChanged = Signal(bool)
    sortColumnChanged = Signal(str)
    sortAscendingChanged = Signal(bool)
    selectedCountChanged = Signal(int)
    allSelectedChanged = Signal(bool)
    currentEntryDateChanged = Signal(str)
    displayEntryDateChanged = Signal(str)
    isTodayChanged = Signal(bool)

    def __init__(self, connection: sqlite3.Connection, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self.conn = connection
        self._current_entry_date: str = datetime.date.today().isoformat()
        self._all_records: list[dict[str, Any]] = []
        self._records: list[dict[str, Any]] = []
        self._selected_ids: set[int] = set()
        self._search_text: str = ""
        self._row_limit: int = 10  # Default 10 rows
        self._sort_col: str = "no"  # Default sort by sequence number (ลำดับ)
        self._sort_asc: bool = True  # Default 1, 2, 3...
        self._reload_records()

    def _apply_filter_and_sort(self) -> None:
        """Apply search filter, chronological sorting, and row limits."""
        filtered = list(self._all_records)

        # 1. Search filter
        if self._search_text.strip():
            kw = self._search_text.strip().lower()
            filtered = [
                r for r in filtered
                if kw in str(r.get("no", "")).lower()
                or kw in str(r.get("office", "")).lower()
                or kw in str(r.get("sn", "")).lower()
                or kw in str(r.get("date", "")).lower()
                or kw in str(r.get("status", "")).lower()
                or kw in str(r.get("type", "")).lower()
            ]

        # 2. Sort key
        def sort_key(item: dict[str, Any]) -> Any:
            val = item.get(self._sort_col, "")
            if self._sort_col == "no":
                try:
                    return int(val)
                except (ValueError, TypeError):
                    return 0
            elif self._sort_col == "date":
                dt = _parse_date_tuple(str(val))
                if dt == (0, 0, 0):
                    return (-1, -1, -1) if not self._sort_asc else (99999, 99, 99)
                return dt
            return str(val).lower()

        filtered.sort(key=sort_key, reverse=not self._sort_asc)

        # 3. Row Limit Filter (0 = All rows)
        if self._row_limit > 0:
            filtered = filtered[:self._row_limit]

        self.beginResetModel()
        self._records = filtered
        self.endResetModel()

    def _reload_records(self) -> None:
        prev_ids = {r["id"] for r in self._all_records} if self._all_records else set()
        self._all_records = db.list_by_entry_date(self.conn, self._current_entry_date)
        new_ids = {r["id"] for r in self._all_records}

        if not prev_ids:
            self._selected_ids = set(new_ids)
        else:
            added_ids = new_ids - prev_ids
            self._selected_ids = (self._selected_ids & new_ids) | added_ids

        self._apply_filter_and_sort()
        self._emit_stats()
        self.selectedCountChanged.emit(len(self._selected_ids))
        self.allSelectedChanged.emit(self.allSelected)
        self.currentEntryDateChanged.emit(self._current_entry_date)
        self.displayEntryDateChanged.emit(self.displayEntryDate)
        self.isTodayChanged.emit(self.isToday)

    def _emit_stats(self) -> None:
        total = len(self._all_records)
        with_sn = sum(1 for r in self._all_records if str(r.get("sn", "")).strip())
        missing_sn = total - with_sn

        # Status summary counts: "เคสทัสสกรีนเสีย" vs "เคสทำเครื่องทดแทน"
        touchscreen_broken = sum(
            1 for r in self._all_records
            if "ทัส" in str(r.get("status", "")) or "ทัช" in str(r.get("status", "")) or "เสีย" in str(r.get("status", "")) or "รอ" in str(r.get("status", ""))
        )
        replacement = sum(
            1 for r in self._all_records
            if "ทดแทน" in str(r.get("status", "")) or "เสร็จ" in str(r.get("status", ""))
        )

        self.statsChanged.emit(total, with_sn, missing_sn)
        self.summaryStatsChanged.emit(total, touchscreen_broken, replacement)
        self.hasMissingSnChanged.emit(missing_sn > 0)

    # Properties
    def get_sort_col(self) -> str:
        return self._sort_col

    def get_sort_asc(self) -> bool:
        return self._sort_asc

    def get_selected_count(self) -> int:
        return len(self._selected_ids)

    def get_all_selected(self) -> bool:
        return len(self._all_records) > 0 and len(self._selected_ids) == len(self._all_records)

    def get_current_entry_date(self) -> str:
        return self._current_entry_date

    def get_display_entry_date(self) -> str:
        return _format_thai_date(self._current_entry_date)

    def get_is_today(self) -> bool:
        return self._current_entry_date == datetime.date.today().isoformat()

    sortColumn = Property(str, get_sort_col, notify=sortColumnChanged)
    sortAscending = Property(bool, get_sort_asc, notify=sortAscendingChanged)
    selectedCount = Property(int, get_selected_count, notify=selectedCountChanged)
    allSelected = Property(bool, get_all_selected, notify=allSelectedChanged)
    currentEntryDate = Property(str, get_current_entry_date, notify=currentEntryDateChanged)
    displayEntryDate = Property(str, get_display_entry_date, notify=displayEntryDateChanged)
    isToday = Property(bool, get_is_today, notify=isTodayChanged)

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
            self.SelectedRole: b"selected",
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
        elif role == self.SelectedRole:
            return row.get("id", 0) in self._selected_ids

        return None

    def setData(self, index: QModelIndex, value: Any, role: int = Qt.EditRole) -> bool:
        if not index.isValid() or not (0 <= index.row() < len(self._records)):
            return False

        if role == self.SelectedRole:
            row_id = self._records[index.row()]["id"]
            if bool(value):
                self._selected_ids.add(row_id)
            else:
                self._selected_ids.discard(row_id)
            self.dataChanged.emit(index, index, [self.SelectedRole])
            self.selectedCountChanged.emit(len(self._selected_ids))
            self.allSelectedChanged.emit(self.allSelected)
            return True

        if role == Qt.EditRole:
            col = index.column()
            if 0 <= col < len(self.COL_NAMES):
                col_name = self.COL_NAMES[col]
                row_id = self._records[index.row()]["id"]
                val_str = str(value)
                if str(self._records[index.row()].get(col_name, "")) == val_str:
                    return True

                db.update_field(self.conn, row_id, col_name, val_str)
                self._records[index.row()][col_name] = val_str
                for r in self._all_records:
                    if r["id"] == row_id:
                        r[col_name] = val_str
                        break

                start_idx = self.index(index.row(), 0)
                end_idx = self.index(index.row(), len(self.COL_NAMES) - 1)
                role_val = self.COL_ROLES.get(col_name)
                roles = [Qt.DisplayRole, Qt.EditRole]
                if role_val is not None:
                    roles.append(role_val)
                self.dataChanged.emit(start_idx, end_idx, roles)
                self._emit_stats()
                return True

        return False

    def flags(self, index: QModelIndex) -> Qt.ItemFlags:
        if not index.isValid():
            return Qt.NoItemFlags
        return Qt.ItemIsEnabled | Qt.ItemIsSelectable | Qt.ItemIsEditable

    # Search & Filter & Sort Slots
    @Slot(str)
    def set_search_text(self, text: str) -> None:
        """Filter table by search query string."""
        self._search_text = text or ""
        self._apply_filter_and_sort()

    @Slot(int)
    def set_row_limit(self, limit: int) -> None:
        """Set maximum rows to display: 10, 25, 50, or 0 (All)."""
        self._row_limit = max(0, limit)
        self._apply_filter_and_sort()

    @Slot(str)
    def sort_by_col(self, col_name: str) -> None:
        """Sort by column. For date, defaults to newest-to-oldest (descending)."""
        if col_name not in self.COL_NAMES:
            return

        if self._sort_col == col_name:
            self._sort_asc = not self._sort_asc
        else:
            self._sort_col = col_name
            # For date, default to newest-to-oldest (descending) as requested by user
            if col_name == "date":
                self._sort_asc = False
            else:
                self._sort_asc = True

        self.sortColumnChanged.emit(self._sort_col)
        self.sortAscendingChanged.emit(self._sort_asc)
        self._apply_filter_and_sort()

    @Slot(str)
    def parse_raw(self, text: str) -> None:
        """Parse raw text and insert into database for current entry date."""
        rows = parse_raw_fn(text)
        if not rows:
            return
        for r in rows:
            r["entry_date"] = self._current_entry_date
        db.insert_many(self.conn, rows, entry_date=self._current_entry_date)
        self._reload_records()

    @Slot()
    def add_row(self) -> None:
        """Add a single row to current entry date."""
        new_record = {
            "office": "",
            "date": "",
            "status": "เคสทัสสกรีนเสีย",
            "sn": "",
            "type": "Dell Optiplax 3050 AIO",
            "entry_date": self._current_entry_date,
        }
        db.insert_many(self.conn, [new_record], entry_date=self._current_entry_date)
        self._reload_records()

    @Slot(int)
    def delete_row(self, row_idx: int) -> None:
        """Delete row safely by mapped DB id and refresh."""
        if not (0 <= row_idx < len(self._records)):
            return

        row_id = self._records[row_idx]["id"]
        db.delete(self.conn, row_id)
        db.renumber(self.conn, self._current_entry_date)
        self._reload_records()

    @Slot(int, str, str)
    def update_cell(self, row_idx: int, col_name: str, value: str) -> None:
        """Update a specific cell if changed, avoiding redundant DB writes."""
        if not (0 <= row_idx < len(self._records)):
            return
        if col_name not in self.COL_NAMES:
            return

        current_val = str(self._records[row_idx].get(col_name, ""))
        if current_val == value:
            return

        row_id = self._records[row_idx]["id"]
        db.update_field(self.conn, row_id, col_name, value)
        self._records[row_idx][col_name] = value
        if col_name == "status":
            ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S") if "เสร็จ" in value else None
            self._records[row_idx]["completed_at"] = ts
        for r in self._all_records:
            if r["id"] == row_id:
                r[col_name] = value
                if col_name == "status":
                    r["completed_at"] = self._records[row_idx].get("completed_at")
                break

        start_idx = self.index(row_idx, 0)
        end_idx = self.index(row_idx, len(self.COL_NAMES) - 1)
        role_val = self.COL_ROLES.get(col_name)
        roles = [Qt.DisplayRole, Qt.EditRole]
        if role_val is not None:
            roles.append(role_val)
        self.dataChanged.emit(start_idx, end_idx, roles)
        self._emit_stats()

    @Slot()
    def go_to_previous_day(self) -> None:
        """Navigate to the previous calendar day."""
        try:
            curr_dt = datetime.date.fromisoformat(self._current_entry_date)
        except ValueError:
            curr_dt = datetime.date.today()
        prev_date = (curr_dt - datetime.timedelta(days=1)).isoformat()
        self.set_entry_date(prev_date)

    @Slot()
    def go_to_next_day(self) -> None:
        """Navigate to the next calendar day."""
        try:
            curr_dt = datetime.date.fromisoformat(self._current_entry_date)
        except ValueError:
            curr_dt = datetime.date.today()
        next_date = (curr_dt + datetime.timedelta(days=1)).isoformat()
        self.set_entry_date(next_date)

    @Slot()
    def go_to_today(self) -> None:
        """Navigate directly to today."""
        self.set_entry_date(datetime.date.today().isoformat())

    @Slot(str)
    def set_entry_date(self, date_str: str) -> None:
        """Set current entry date and refresh table view."""
        if not date_str or date_str == self._current_entry_date:
            return
        self._current_entry_date = date_str
        self._reload_records()

    @Slot()
    def clear_current_page(self) -> None:
        """Clear all records on the currently active date page."""
        db.delete_by_entry_date(self.conn, self._current_entry_date)
        self._reload_records()

    @Slot()
    def load_example(self) -> None:
        """Load sample records into the current day."""
        db.delete_by_entry_date(self.conn, self._current_entry_date)
        records = [dict(r, entry_date=self._current_entry_date, status="เคสทัสสกรีนเสีย") for r in INITIAL_RECORDS]
        db.insert_many(self.conn, records, entry_date=self._current_entry_date)
        db.renumber(self.conn, self._current_entry_date)
        self._reload_records()

    @Slot()
    def clear_all(self) -> None:
        """Clear records on current page."""
        self.clear_current_page()

    @Slot(int, bool)
    def set_row_selected(self, row_idx: int, is_selected: bool) -> None:
        """Set selection state for a specific visible row index."""
        if not (0 <= row_idx < len(self._records)):
            return
        row_id = self._records[row_idx]["id"]
        if is_selected:
            self._selected_ids.add(row_id)
        else:
            self._selected_ids.discard(row_id)

        idx = self.index(row_idx, 0)
        self.dataChanged.emit(idx, idx, [self.SelectedRole])
        self.selectedCountChanged.emit(len(self._selected_ids))
        self.allSelectedChanged.emit(self.allSelected)

    @Slot(bool)
    def toggle_select_all(self, select: bool) -> None:
        """Select or deselect all records on current page."""
        if select:
            self._selected_ids = {r["id"] for r in self._all_records}
        else:
            self._selected_ids.clear()

        if self._records:
            start_idx = self.index(0, 0)
            end_idx = self.index(len(self._records) - 1, len(self.COL_NAMES) - 1)
            self.dataChanged.emit(start_idx, end_idx, [self.SelectedRole])
        self.selectedCountChanged.emit(len(self._selected_ids))
        self.allSelectedChanged.emit(self.allSelected)

    @Slot(str)
    def export_xlsx(self, file_path: str) -> None:
        """Export selected records (or all records on current page if none selected) to Excel."""
        from irframe_parser.exporter import export_xlsx

        clean_path = QUrl(file_path).toLocalFile() if file_path.startswith("file:") else file_path
        if not clean_path.endswith(".xlsx"):
            clean_path += ".xlsx"

        # Export selected records if any, otherwise fallback to all on current page
        if self._selected_ids:
            rows_to_export = [dict(r) for r in self._all_records if r["id"] in self._selected_ids]
        else:
            rows_to_export = [dict(r) for r in self._all_records]

        # Renumber sequentially for the exported sheet (1..N)
        for i, r in enumerate(rows_to_export, start=1):
            r["no"] = i

        export_xlsx(rows_to_export, clean_path)

    @Slot(result=list)
    def get_all_records(self) -> list[dict[str, Any]]:
        """Return all records for current page."""
        return list(self._records)

    @Slot(int, result=int)
    def check_expired_count(self, days: int = 10) -> int:
        """Return number of records whose entry_date is older than `days` days."""
        return len(db.get_expired_records(self.conn, days))

    @Slot(int, result=list)
    def get_expired_records(self, days: int = 10) -> list[dict[str, Any]]:
        """Return expired records for displaying in confirmation dialog."""
        return db.get_expired_records(self.conn, days)

    @Slot(int, result=int)
    def confirm_delete_expired(self, days: int = 10) -> int:
        """Delete expired records and refresh table."""
        deleted = db.delete_expired_records(self.conn, days)
        if deleted > 0:
            self._reload_records()
        return deleted

    # Aliases for backward compatibility
    @Slot(int, result=int)
    def check_expired_completed_count(self, days: int = 10) -> int:
        return self.check_expired_count(days)

    @Slot(int, result=list)
    def get_expired_completed_records(self, days: int = 10) -> list[dict[str, Any]]:
        return self.get_expired_records(days)

