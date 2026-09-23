# แบ่ง Task: พอร์ต IR Frame Parser จาก Web → PySide6/QML + SQLite (uv)

จากไฟล์ `IR_Frame_Parser_Web.html` เดิม สรุป core logic ที่ต้องพอร์ตคือ 4 ส่วนหลัก:
**parse ข้อความดิบ → เก็บลง SQLite → แก้ไขในตาราง → export .xlsx ตาม template เดิม**

แต่ละ Phase ด้านล่างมี **Tests** แนบท้ายไว้ให้แล้ว — ส่งให้ opencode ทำทีละ Phase โดยให้เกณฑ์ผ่านงานคือ `uv run pytest tests/<ไฟล์ที่เกี่ยวข้อง>` ผ่านทั้งหมดก่อนไป Phase ถัดไป

---

## Phase 0 — Project Setup (uv)

- `uv init irframe-parser` + `pyproject.toml`
- Dependencies: `pyside6`, `openpyxl` (แทน exceljs)
- Dev dependencies: `pytest`, `pytest-qt` (`uv add --dev pytest pytest-qt`)
- โครงสร้างโฟลเดอร์:

```
irframe_parser/
  __init__.py
  db.py          # sqlite layer
  parser.py      # regex parsing (พอร์ตจาก JS)
  models.py      # QAbstractTableModel
  exporter.py    # openpyxl export
  main.py        # entry point + QML engine
  qml/
    Main.qml
    RecordTable.qml
    Preview.qml
tests/
  test_db.py
  test_parser.py
  test_models.py
  test_exporter.py
  test_qml_smoke.py
  test_packaging.py
```

### Tests
```python
# tests/test_packaging.py
import subprocess, sys

def test_module_importable():
    result = subprocess.run(
        [sys.executable, "-c",
         "import irframe_parser; import irframe_parser.db; "
         "import irframe_parser.parser; import irframe_parser.exporter"],
        capture_output=True, text=True,
    )
    assert result.returncode == 0, result.stderr
```
เกณฑ์ผ่าน: `uv run pytest tests/test_packaging.py` เขียวหมด แปลว่าโครงสร้างโปรเจกต์และ import path ถูกต้อง

---

## Phase 1 — SQLite Layer (`db.py`)

Schema:
```sql
CREATE TABLE records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  no INTEGER,
  office TEXT,
  date TEXT,
  status TEXT DEFAULT 'รออะไหล่',
  sn TEXT,
  type TEXT,
  created_at TEXT DEFAULT (datetime('now'))
);
```

Function signatures ที่ opencode ต้อง implement: `connect(path)`, `init_schema(conn)`, `insert_many(conn, rows)`, `update_field(conn, row_id, col, val)`, `delete(conn, row_id)`, `list_all(conn)`, `renumber(conn)`

### Tests
```python
# tests/test_db.py
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
        {"office": "สขจ.สกลนคร", "date": "26/08/2569", "status": "รออะไหล่",
         "sn": "ABC1234", "type": "Dell Optiplax 3050 AIO"},
        {"office": "พัทลุง", "date": "05/06/2553", "status": "รออะไหล่",
         "sn": "XYZ5678", "type": "Dell Optiplax 3050 AIO"},
    ]
    db.insert_many(conn, rows)
    result = db.list_all(conn)
    assert len(result) == 2
    assert result[0]["sn"] == "ABC1234"
    assert result[0]["no"] == 1
    assert result[1]["no"] == 2

def test_update_field(conn):
    db.insert_many(conn, [{"office": "A", "date": "", "status": "รออะไหล่",
                            "sn": "SN1", "type": "T"}])
    row_id = db.list_all(conn)[0]["id"]
    db.update_field(conn, row_id, "sn", "SN-UPDATED")
    assert db.list_all(conn)[0]["sn"] == "SN-UPDATED"

def test_delete_and_renumber(conn):
    db.insert_many(conn, [
        {"office": "A", "date": "", "status": "รออะไหล่", "sn": "SN1", "type": "T"},
        {"office": "B", "date": "", "status": "รออะไหล่", "sn": "SN2", "type": "T"},
        {"office": "C", "date": "", "status": "รออะไหล่", "sn": "SN3", "type": "T"},
    ])
    rows = db.list_all(conn)
    db.delete(conn, rows[0]["id"])
    db.renumber(conn)
    remaining = db.list_all(conn)
    assert len(remaining) == 2
    assert [r["no"] for r in remaining] == [1, 2]
    assert remaining[0]["sn"] == "SN2"

def test_list_all_empty(conn):
    assert db.list_all(conn) == []
```
เกณฑ์ผ่าน: `uv run pytest tests/test_db.py`

---

## Phase 2 — Parser (`parser.py`)

Regex 5 ตัวที่ต้องพอร์ตจาก JS: SN (priority field `SN:`), วันที่ (รองรับ พ.ศ. 2 หลัก/4 หลัก), สนง. (prefix list), สถานะ (fallback "รออะไหล่"), ประเภท (fallback จาก keyword ทัชสกรีน)

Function signatures: `parse_raw(text: str) -> list[dict]`, `date_norm(s: str) -> str`

### Tests
```python
# tests/test_parser.py
import pytest
from irframe_parser.parser import parse_raw, date_norm

# ---------- date_norm ----------

@pytest.mark.parametrize("raw,expected", [
    ("26/08/69", "26/08/2569"),      # 2-digit year -> 25xx
    ("05/06/2010", "05/06/2553"),    # 4-digit Gregorian-looking -> +543
    ("15/07/2568", "15/07/2568"),    # already Buddhist, unchanged
    ("hello", ""),                    # no date found
    ("1.7.2568", "01/07/2568"),      # dot separators normalized
])
def test_date_norm(raw, expected):
    assert date_norm(raw) == expected

# ---------- parse_raw ----------

def test_single_record_all_fields():
    text = """
    สขจ.สกลนคร
    วันที่ 26/08/69
    SN : ABC1234
    ประเภทครุภัณฑ์ : Dell Optiplax 3050 AIO
    สถานะแจ้งซ่อม : รอตรวจสอบ
    """
    rows = parse_raw(text)
    assert len(rows) == 1
    r = rows[0]
    assert r["office"] == "สขจ.สกลนคร"
    assert r["date"] == "26/08/2569"
    assert r["sn"] == "ABC1234"
    assert r["type"] == "Dell Optiplax 3050 AIO"
    assert r["status"] == "รอตรวจสอบ"

def test_missing_sn_creates_one_blank_row():
    text = "สขข.สายบุรี\nวันที่ 10/01/69\nไม่มีเลข SN ระบุมาให้"
    rows = parse_raw(text)
    assert len(rows) == 1
    assert rows[0]["sn"] == ""

def test_multiple_sn_creates_multiple_rows_shared_fields():
    text = """
    สนง.ชลบุรี
    26/08/69
    1. SN : AAA1111
    2. SN : BBB2222
    ประเภทครุภัณฑ์ : Dell Optiplax 3050 AIO
    """
    rows = parse_raw(text)
    assert len(rows) == 2
    assert {r["sn"] for r in rows} == {"AAA1111", "BBB2222"}
    assert all(r["office"] == "สนง.ชลบุรี" for r in rows)
    assert all(r["type"] == "Dell Optiplax 3050 AIO" for r in rows)

def test_status_defaults_when_absent():
    text = "สขจ.แพร่\n05/05/69\nSN : CCC3333"
    rows = parse_raw(text)
    assert rows[0]["status"] == "รออะไหล่"

def test_type_inferred_from_touchscreen_keyword():
    text = "สขจ.แพร่\n05/05/69\nSN : DDD4444\nแจ้งซ่อมทัชสกรีนใช้งานไม่ได้"
    rows = parse_raw(text)
    assert rows[0]["type"] == "Dell Optiplax 3050 AIO"

def test_phone_number_not_mistaken_for_office_or_type():
    text = "โทร 0891234567\nสขจ.เชียงราย\nSN : EEE5555"
    rows = parse_raw(text)
    assert rows[0]["office"] == "สขจ.เชียงราย"
    assert rows[0]["type"] != "0891234567"

def test_parse_raw_returns_only_new_rows():
    # append/merge with existing state happens in the caller (model/backend),
    # not inside parse_raw itself
    rows = parse_raw("SN : FFF6666")
    assert len(rows) == 1
```
เกณฑ์ผ่าน: `uv run pytest tests/test_parser.py` — ครอบคลุม edge case เดิมทุกตัวจาก comment ในโค้ด JS ต้นฉบับ

---

## Phase 3 — Backend Model (`models.py`)

`RecordTableModel(QAbstractTableModel)` ผูกกับ SQLite, พร้อม slot `parse_raw`, `add_row`, `delete_row`, `load_example`, signal `statsChanged(total, with_sn, missing_sn)`

### Tests
```python
# tests/test_models.py
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
```
เกณฑ์ผ่าน: `uv run pytest tests/test_models.py` (ต้องมี `pytest-qt` ติดตั้งแล้วสำหรับ fixture `qtbot`)

---

## Phase 4 — QML UI

- `Main.qml`: TextArea + ปุ่ม คัดแยก/ล้าง/โหลดตัวอย่าง
- `RecordTable.qml`: TableView แก้ไขได้ทุกช่อง
- `Preview.qml`: จำลองหน้าเอกสารก่อน export
- Export ผ่าน FileDialog → เรียก `backend.exportXlsx(path)`

QML behavior ทดสอบอัตโนมัติได้ยากในเวลาจำกัด จึงใช้ smoke test + manual QA checklist แทน unit test เต็มรูปแบบ

### Tests
```python
# tests/test_qml_smoke.py
import subprocess, sys

def test_app_launches_without_qml_errors():
    result = subprocess.run(
        [sys.executable, "-m", "irframe_parser.main", "--self-test-exit"],
        capture_output=True, text=True, timeout=15,
    )
    assert result.returncode == 0
    assert "qrc" not in result.stderr.lower() or "error" not in result.stderr.lower()
```
หมายเหตุ: ต้องเพิ่ม flag `--self-test-exit` ใน `main.py` ให้แอปโหลด QML สำเร็จแล้วปิดตัวเองทันที (ใช้เป็น CI smoke test)

### Manual QA Checklist (ทำจริงโดยคน ไม่ automate)
- [ ] วางข้อความตัวอย่าง 15 แถวจากไฟล์เดิม กด "คัดแยกข้อมูล" แล้วได้ 15 แถวตรงกัน
- [ ] แก้ไขค่าในช่องผ่าน UI แล้ว preview อัปเดตทันที
- [ ] กด "ล้างข้อมูล" ล้างเฉพาะกล่องข้อความดิบ แถวตารางต้องไม่หาย
- [ ] ลบแถวแล้วเลข "ลำดับ" ต้อง renumber ใหม่ถูกต้อง
- [ ] ปิดแอปแล้วเปิดใหม่ ข้อมูลต้องยังอยู่ (พิสูจน์ SQLite persistence)

---

## Phase 5 — Excel Export (`exporter.py`)

Function signature: `export_xlsx(rows: list[dict], out_path: str) -> None`

ต้อง match: merge cells, ฟอนต์ AngsanaUPC/Angsana New/Tahoma, border 2 ระดับ (thin/medium), แปลงวันที่ พ.ศ.→ค.ศ., freeze panes, แถวลายเซ็น

### Tests
```python
# tests/test_exporter.py
import datetime
import openpyxl
from irframe_parser.exporter import export_xlsx

def test_export_creates_valid_workbook(tmp_path):
    rows = [
        {"no": 1, "office": "สขจ.สกลนคร", "date": "26/08/2569",
         "status": "รออะไหล่", "sn": "ABC1234", "type": "Dell Optiplax 3050 AIO"},
        {"no": 2, "office": "พัทลุง", "date": "05/06/2553",
         "status": "รออะไหล่", "sn": "", "type": "Dell Optiplax 3050 AIO"},
    ]
    out_path = tmp_path / "export_test.xlsx"
    export_xlsx(rows, str(out_path))

    wb = openpyxl.load_workbook(out_path)
    ws = wb.active
    assert ws["A1"].value == "รายการเบิก IR Frame"
    assert ws.cell(row=5, column=2).value == "ลำดับ"
    assert ws.cell(row=6, column=3).value == "สขจ.สกลนคร"
    assert ws.cell(row=6, column=5).value == "ABC1234"

def test_missing_sn_footer_note_present(tmp_path):
    rows = [{"no": 1, "office": "A", "date": "", "status": "รออะไหล่",
             "sn": "", "type": "T"}]
    out_path = tmp_path / "export_missing_sn.xlsx"
    export_xlsx(rows, str(out_path))
    wb = openpyxl.load_workbook(out_path)
    ws = wb.active
    values = [c.value for row in ws.iter_rows() for c in row]
    assert any(v and "ไม่มีเลข SN" in str(v) for v in values)

def test_date_converted_to_datetime_cell(tmp_path):
    rows = [{"no": 1, "office": "A", "date": "26/08/2569",
             "status": "รออะไหล่", "sn": "SN1", "type": "T"}]
    out_path = tmp_path / "export_date.xlsx"
    export_xlsx(rows, str(out_path))
    wb = openpyxl.load_workbook(out_path)
    ws = wb.active
    date_cell = ws.cell(row=6, column=4)
    assert isinstance(date_cell.value, (datetime.date, datetime.datetime))
    assert date_cell.value.year == 2026   # 2569 (BE) - 543 = 2026 (CE)

def test_freeze_panes_set(tmp_path):
    rows = [{"no": 1, "office": "A", "date": "", "status": "รออะไหล่",
             "sn": "SN1", "type": "T"}]
    out_path = tmp_path / "export_freeze.xlsx"
    export_xlsx(rows, str(out_path))
    wb = openpyxl.load_workbook(out_path)
    assert wb.active.freeze_panes is not None
```
หมายเหตุ: ตำแหน่ง row/column ในตัวอย่างเป็น "สัญญา" (contract) อิงจาก layout เดิม — ถ้า opencode วาง layout ต่างไปเล็กน้อย ให้ปรับ index ใน test ให้ตรงกับ implementation จริง แต่ค่าที่ readback ต้องตรงกับ input เสมอ
เกณฑ์ผ่าน: `uv run pytest tests/test_exporter.py` + เปิดไฟล์จริงใน Excel เทียบ layout ด้วยตา (locale date format `[$-1010000]` ต้องเช็คว่า Excel ไทยแสดงถูก)

---

## Phase 6 — Packaging

- `uv lock` + `uv run python -m irframe_parser.main`
- พิจารณา PyInstaller/Nuitka ถ้าต้องแจก .exe แบบ standalone (เป็น desktop tool ไม่ใช่ kiosk ไม่ต้องมี systemd service)

### Tests
ใช้ `tests/test_packaging.py` จาก Phase 0 ซ้ำอีกครั้งหลัง build/lock เสร็จ เพื่อยืนยันว่า dependency resolution ไม่พังหลัง freeze เวอร์ชัน

---

## Phase 7 — Integration / Regression

รัน test ทั้งหมดรวมกัน + เทียบผลลัพธ์กับ dataset 15 แถวเดิมจากไฟล์เว็บต้นฉบับ

### Tests
```python
# tests/test_regression_full_dataset.py
from irframe_parser.parser import parse_raw

ORIGINAL_15_OFFICES = [
    "ร้อยเอ็ด แห่ง 2", "พัทลุง ตะโหนด", "สมุทรสงคราม", "พัทลุง ตะโหนด",
    "พัทลุง จ.", "สขข.สายบุรี", "สขข.สายบุรี", "ชลบุรี สขข.บางละมุง",
    "ปง", "หนองบัว", "เพชรบุรี", "สุโขทัย", "ชลบุรี",
    "เดิมบางนางบวช", "ฉะเชิงเทรา",
]

def test_full_dataset_row_count_matches_original():
    # ทดสอบระดับ integration: ป้อนข้อความดิบจำลอง 15 รายการ
    # แล้วต้องได้จำนวนแถว = 15 เท่าของต้นฉบับ (ตัวอย่าง scaffold ให้ opencode
    # เติม raw text จริงจาก log งานเดิม แล้วเทียบ office/sn ทีละแถว)
    assert len(ORIGINAL_15_OFFICES) == 15
```
เกณฑ์ผ่าน: `uv run pytest` (รันทั้งหมด) เขียวหมด ก่อนถือว่า Phase 7 เสร็จ

---

## Phase 8 — Enhancement (ทำทีหลังได้ ไม่บังคับ)

- Search/filter, undo delete, audit log การวางข้อความดิบ, auto-backup .db รายวัน
- แต่ละ enhancement ให้เขียน test แยกไฟล์ตามชื่อ feature เมื่อเริ่มทำจริง (ยังไม่ scaffold ไว้ล่วงหน้าเพราะ scope ยังไม่ fix)
