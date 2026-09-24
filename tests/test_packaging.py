from pathlib import Path
import subprocess
import sys


def test_module_importable():
    result = subprocess.run(
        [
            sys.executable,
            "-c",
            "import irframe_parser; import irframe_parser.db; "
            "import irframe_parser.parser; import irframe_parser.exporter",
        ],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stderr


def test_package_assets_exist():
    base_dir = Path(__file__).resolve().parent.parent / "irframe_parser"
    assert (base_dir / "qml" / "Main.qml").exists()
    assert (base_dir / "qml" / "RecordTable.qml").exists()
    assert (base_dir / "qml" / "Preview.qml").exists()
    assert (base_dir / "fonts").exists()
    assert len(list((base_dir / "fonts").glob("*.ttf"))) >= 1


def test_entrypoint_self_test():
    result = subprocess.run(
        [sys.executable, "-m", "irframe_parser.main", "--self-test-exit"],
        capture_output=True,
        text=True,
        timeout=15,
    )
    assert result.returncode == 0, result.stderr

