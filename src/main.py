from pathlib import Path
from PySide6.QtCore import QUrl, QDir, QSettings, QCoreApplication
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine
from controllers.position_controller import PositionController
from utils.robot_singleton import RobotSingletonRCP
from db.db_manager import DB_Manager
from PySide6.QtGui import QIcon
import sys


def main() -> None:
    # Identifies QSettings storage location per platform:
    #   macOS:   ~/Library/Preferences/com.robotine.RobotineController.plist
    #   Windows: HKCU\Software\Robotine\Robotine Controller
    #   Linux:   ~/.config/Robotine/Robotine Controller.conf
    QCoreApplication.setOrganizationName("Robotine")
    QCoreApplication.setOrganizationDomain("robotine.com.br")
    QCoreApplication.setApplicationName("Robotine Controller")

    settings = QSettings()
    saved_path = settings.value("last_db_path", "", type=str)

    if saved_path and Path(saved_path).exists():
        DB_Manager.set_custom_path(saved_path)
        DB_Manager().init_database()
        print(f"[DB] Resumed last database: {saved_path}")
    elif saved_path:
        print(f"[DB] Last database missing at {saved_path}; pick another via the UI.")
    else:
        print("[DB] No database selected yet; pick one via the 'Select dB' button.")

    app = QApplication(sys.argv)
    engine = QQmlApplicationEngine()

    engine.addImportPath(QDir.current().filePath("qml"))

    # Use .ico cross-platform at runtime: Qt's .icns handler crashes
    # setWindowIcon on macOS in this Qt build. The .icns is kept in
    # assets/app/ for future .app bundling via Info.plist.
    app.setWindowIcon(QIcon("assets/app/icon.ico"))

    robot = RobotSingletonRCP("192.168.167.199")
    # robot.RobotEnable(True)
    # robot.DragTeachSwitch(False)

    controller = PositionController()
    engine.rootContext().setContextProperty("PositionController", controller)

    qml_file = QUrl.fromLocalFile("qml/main.qml")
    engine.load(qml_file)

    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
