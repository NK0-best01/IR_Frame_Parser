import subprocess
import sys


def test_app_launches_without_qml_errors():
    result = subprocess.run(
        [sys.executable, "-m", "irframe_parser.main", "--self-test-exit"],
        capture_output=True,
        text=True,
        timeout=15,
    )
    assert result.returncode == 0, f"Error: {result.stderr}\nOutput: {result.stdout}"
