"""Application entry point for irframe_parser with LINE Seed Sans TH font."""
import sys
from pathlib import Path

from PySide6.QtGui import QFont, QFontDatabase, QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

from irframe_parser import db
from irframe_parser.models import RecordTableModel


def setup_fonts() -> str:
    """Load LINE Seed Sans TH fonts from fonts directory."""
    fonts_dir = Path(__file__).parent / "fonts"
    font_family = "LINE Seed Sans TH"
    if fonts_dir.exists():
        for ttf_file in fonts_dir.glob("*.ttf"):
            QFontDatabase.addApplicationFont(str(ttf_file))
    return font_family


def main() -> int:
    app = QGuiApplication(sys.argv)
    app.setApplicationName("IR Frame Parser")
    app.setOrganizationName("RoboQ")

    font_family = setup_fonts()
    default_font = QFont(font_family, 10)
    app.setFont(default_font)

    # Handle self-test flag for CI/Smoke testing
    if "--self-test-exit" in sys.argv:
        engine = QQmlApplicationEngine()
        qml_path = Path(__file__).parent / "qml" / "Main.qml"
        conn = db.connect(":memory:")
        db.init_schema(conn)
        model = RecordTableModel(conn)
        engine.rootContext().setContextProperty("backendModel", model)
        engine.rootContext().setContextProperty("appFontFamily", font_family)

        engine.load(str(qml_path))
        if not engine.rootObjects():
            return 1
        return 0

    db_path = Path(__file__).parent.parent / "irframe.db"
    conn = db.connect(str(db_path))
    db.init_schema(conn)

    model = RecordTableModel(conn)

    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("backendModel", model)
    engine.rootContext().setContextProperty("appFontFamily", font_family)

    qml_file = Path(__file__).parent / "qml" / "Main.qml"
    engine.load(str(qml_file))

    if not engine.rootObjects():
        return -1

    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
