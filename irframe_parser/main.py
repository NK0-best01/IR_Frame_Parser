import os
import sys
from pathlib import Path

from PySide6.QtGui import QFont, QFontDatabase, QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuickControls2 import QQuickStyle

from irframe_parser import db
from irframe_parser.models import RecordTableModel


def get_base_dir() -> Path:
    """Return the base directory for irframe_parser package resources."""
    if getattr(sys, "frozen", False) and hasattr(sys, "_MEIPASS"):
        return Path(sys._MEIPASS) / "irframe_parser"
    return Path(__file__).resolve().parent


def get_db_path() -> Path:
    """Return path to SQLite database."""
    if not getattr(sys, "frozen", False):
        repo_db = Path(__file__).resolve().parent.parent / "irframe.db"
        if repo_db.parent.joinpath("pyproject.toml").exists():
            return repo_db

    local_app_data = os.environ.get("LOCALAPPDATA")
    app_dir = Path(local_app_data or (Path.home() / "AppData" / "Local")) / "IRFrameParser"
    app_dir.mkdir(parents=True, exist_ok=True)
    return app_dir / "irframe.db"



def setup_fonts(base_dir: Path) -> str:
    """Load LINE Seed Sans TH fonts from fonts directory."""
    fonts_dir = base_dir / "fonts"
    font_family = "LINE Seed Sans TH"
    if fonts_dir.exists():
        for ttf_file in fonts_dir.glob("*.ttf"):
            QFontDatabase.addApplicationFont(str(ttf_file))
    return font_family


def main() -> int:
    # Set QQuickStyle to Basic for full customization support without warnings
    QQuickStyle.setStyle("Basic")

    app = QGuiApplication(sys.argv)
    app.setApplicationName("IR Frame Parser")
    app.setOrganizationName("RoboQ")
    app.setApplicationVersion("1.0.0")

    base_dir = get_base_dir()
    font_family = setup_fonts(base_dir)
    default_font = QFont(font_family, 10)
    app.setFont(default_font)

    # Handle self-test flag for CI/Smoke testing
    if "--self-test-exit" in sys.argv:
        engine = QQmlApplicationEngine()
        qml_path = base_dir / "qml" / "Main.qml"
        conn = db.connect(":memory:")
        db.init_schema(conn)
        model = RecordTableModel(conn)
        engine.rootContext().setContextProperty("backendModel", model)
        engine.rootContext().setContextProperty("appFontFamily", font_family)

        engine.load(str(qml_path))
        if not engine.rootObjects():
            return 1
        return 0

    db_path = get_db_path()
    conn = db.connect(str(db_path))
    db.init_schema(conn)

    model = RecordTableModel(conn)

    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("backendModel", model)
    engine.rootContext().setContextProperty("appFontFamily", font_family)

    qml_file = base_dir / "qml" / "Main.qml"
    engine.load(str(qml_file))

    if not engine.rootObjects():
        return -1

    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
