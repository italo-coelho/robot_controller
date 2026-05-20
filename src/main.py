from pathlib import Path
from functools import partial
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
import threading

from PySide6.QtCore import QUrl, QSettings, QCoreApplication
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtWebEngineQuick import QtWebEngineQuick
from controllers.position_controller import PositionController
from utils.robot_singleton import RobotSingletonRCP
from db.db_manager import DB_Manager
from PySide6.QtGui import QIcon
import sys


def _start_robot_viewer_server(directory: Path) -> ThreadingHTTPServer:
    handler = partial(SimpleHTTPRequestHandler, directory=str(directory))
    httpd = ThreadingHTTPServer(("127.0.0.1", 0), handler)
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    return httpd


# Locate bundled resources whether running from source or from a PyInstaller
# build. In a frozen build, sys._MEIPASS is the path to the bundled resource
# directory; in source it's the project root (one level above this file).
if getattr(sys, "frozen", False):
    RESOURCE_DIR = Path(sys._MEIPASS)
else:
    RESOURCE_DIR = Path(__file__).resolve().parent.parent


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

    # Windows: without an explicit AppUserModelID, the taskbar groups this
    # process under the Python launcher and shows its generic icon. Setting
    # our own ID before QApplication is created makes Windows use the icon
    # we pass to setWindowIcon() in the taskbar as well.
    if sys.platform == "win32":
        import ctypes
        ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID(
            "com.robotine.controller"
        )

    # QtWebEngine in QML requires initialization before QApplication is built.
    QtWebEngineQuick.initialize()

    app = QApplication(sys.argv)
    engine = QQmlApplicationEngine()

    engine.addImportPath(str(RESOURCE_DIR / "qml"))

    # Serve robot_viewer over HTTP — QtWebEngine refuses fetch/XHR on file://,
    # so the URDF + Collada meshes can only load from a real origin.
    viewer_dir = RESOURCE_DIR / "robot_viewer"
    viewer_httpd = _start_robot_viewer_server(viewer_dir)
    viewer_port = viewer_httpd.server_address[1]
    viewer_url = (
        f"http://127.0.0.1:{viewer_port}/viewer.html"
        f"?hud=0&autoconnect=1&host=192.168.167.199:9999"
    )
    engine.rootContext().setContextProperty("robotViewerUrl", viewer_url)

    def _stop_viewer_server() -> None:
        viewer_httpd.shutdown()
        viewer_httpd.server_close()

    app.aboutToQuit.connect(_stop_viewer_server)

    # Use .ico cross-platform at runtime: Qt's .icns handler crashes
    # setWindowIcon on macOS in this Qt build. The .icns is kept in
    # assets/app/ for the .app bundle (referenced via Info.plist).
    app.setWindowIcon(QIcon(str(RESOURCE_DIR / "assets" / "app" / "icon.ico")))

    robot = RobotSingletonRCP("192.168.167.199")
    # robot.RobotEnable(True)
    # robot.DragTeachSwitch(False)

    controller = PositionController()
    engine.rootContext().setContextProperty("PositionController", controller)

    qml_file = QUrl.fromLocalFile(str(RESOURCE_DIR / "qml" / "main.qml"))
    engine.load(qml_file)

    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
