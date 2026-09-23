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
