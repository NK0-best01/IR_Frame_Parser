"""Application entry point for irframe_parser."""
import sys
from pathlib import Path

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

from irframe_parser import db
from irframe_parser.models import RecordTableModel


def main() -> int:
    # Handle self-test flag immediately if headless
    if "--self-test-exit" in sys.argv:
        app = QGuiApplication(sys.argv)
        engine = QQmlApplicationEngine()
        qml_path = Path(__file__).parent / "qml" / "Main.qml"

        # Mock DB in memory for self-test
        conn = db.connect(":memory:")
        db.init_schema(conn)
        model = RecordTableModel(conn)
        engine.rootContext().setContextProperty("backendModel", model)

        engine.load(str(qml_path))
        if not engine.rootObjects():
            return 1
        return 0

    app = QGuiApplication(sys.argv)
    app.setApplicationName("IR Frame Parser")
    app.setOrganizationName("RoboQ")

    db_path = Path(__file__).parent.parent / "irframe.db"
    conn = db.connect(str(db_path))
    db.init_schema(conn)

    model = RecordTableModel(conn)

    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("backendModel", model)

    qml_file = Path(__file__).parent / "qml" / "Main.qml"
    engine.load(str(qml_file))

    if not engine.rootObjects():
        return -1

    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
