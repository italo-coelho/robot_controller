from PySide6.QtCore import QUrl, QDir
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine
from controllers.position_controller import PositionController
from utils.robot_singleton import RobotSingletonRCP
from db.db_manager import DB_Manager
from PySide6.QtGui import QIcon
import sys


def main() -> None:
    db = DB_Manager()
    db.init_database()
    
    app = QApplication(sys.argv)
    engine = QQmlApplicationEngine()

    engine.addImportPath(QDir.current().filePath("qml"))

    app.setWindowIcon(QIcon("assets/icons/robotine.ico"))

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
