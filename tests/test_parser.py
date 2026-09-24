import pytest
from irframe_parser.parser import date_norm, parse_raw

# ---------- date_norm ----------


@pytest.mark.parametrize(
    "raw,expected",
    [
        ("26/08/69", "26/08/2569"),  # 2-digit year -> 25xx
        ("05/06/2010", "05/06/2553"),  # 4-digit Gregorian-looking -> +543
        ("15/07/2568", "15/07/2568"),  # already Buddhist, unchanged
        ("hello", ""),  # no date found
        ("1.7.2568", "01/07/2568"),  # dot separators normalized
    ],
)
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
    assert rows[0]["status"] == "เคสทัสสกรีนเสีย"


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


def test_parse_inline_sn_with_model_prefix():
    text = """1/4/69

***สาขาอำเภอทองผาภูมิ (จนท.ไม่สะดวกส่งvdo เบื้องต้นให้ค่ะ)

Epson L5190 SN : X5NY048080

อาการ : พิมพ์เอกสารไม่ได้ ไฟแดงขึ้นโชว์ ส่งเช็คเบื้องต้นร้านคอมพิวเตอร์ในพื้น สายแพร ช๊อต เมนบอร์ดช๊อต  

ผู้แจ้ง กัลย์วสุ  ธนบูรณ์กาญจน์
0861673593 เจ้าหน้าที่บันทึกข้อมูล
ชั้น1 สำนักงานขนส่งจังหวัดกาญจนบุรี สาขาอำเภอทองผาภูมิ"""

    rows = parse_raw(text)
    assert len(rows) == 1
    r = rows[0]
    assert r["sn"] == "X5NY048080"
    assert r["date"] == "01/04/2569"
    assert r["office"] == "สาขาอำเภอทองผาภูมิ"
    assert r["type"] == "Epson L5190"
    assert r["status"] == "เคสทัสสกรีนเสีย"


def test_item_numbered_sn_does_not_capture_phone_as_model():
    text = """21/08/69

แจ้งซ่อม 1 เครื่อง

สขจ.กระบี่ 

มะลิวัลย์  ชุมทอง 
เจ้าพนักงานขนส่งปฏิบัติงาน
088-7541163

1. SN : JMHYVV2
อาการ : ไม่บู้ทเข้า windows """

    rows = parse_raw(text)
    assert len(rows) == 1
    r = rows[0]
    assert r["sn"] == "JMHYVV2"
    assert r["date"] == "21/08/2569"
    assert r["office"] == "สขจ.กระบี่"
    assert r["type"] == ""
    assert "088" not in r["type"]


