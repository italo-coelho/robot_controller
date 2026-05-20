"""
Embed robot_viewer in a PySide6 app.

Run:
    pip install PySide6
    python pyside6_example.py              # uses DEFAULT_HOST below
    python pyside6_example.py host:port    # override

Architecture:
  - A background thread runs http.server on 127.0.0.1:<auto port>
    serving this folder. QtWebEngine refuses XHR/fetch on file:// by
    default, so a tiny static server is the cleanest portable fix.
  - QWebEngineView loads /viewer.html?host=...&hud=0
  - QWebChannel exposes a Bridge QObject; the page calls
    bridge.onJoints(json) on every frame, and Bridge re-emits a
    Qt signal that the rest of the app subscribes to.
"""

import json
import sys
import threading
from functools import partial
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path

from PySide6.QtCore import QObject, QUrl, Signal, Slot
from PySide6.QtWebChannel import QWebChannel
from PySide6.QtWebEngineWidgets import QWebEngineView
from PySide6.QtWidgets import (
    QApplication, QFormLayout, QLabel, QMainWindow, QSplitter, QWidget,
)

HERE = Path(__file__).parent

# Default robot endpoint. Override by passing host:port as argv[1].
DEFAULT_HOST = "192.168.167.199:9999"


def start_static_server(directory: Path) -> int:
    handler = partial(SimpleHTTPRequestHandler, directory=str(directory))
    httpd = ThreadingHTTPServer(("127.0.0.1", 0), handler)
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    return httpd.server_address[1]


class Bridge(QObject):
    """Sits between the JS viewer and the rest of the Qt app."""
    jointsChanged = Signal(dict)   # {'j1': deg, 'j2': deg, ...}

    @Slot(str)
    def onJoints(self, payload: str) -> None:
        try:
            self.jointsChanged.emit(json.loads(payload))
        except json.JSONDecodeError:
            pass


class RobotViewerWidget(QWebEngineView):
    """Drop-in QWebEngineView wired to viewer.html + the QWebChannel bridge."""

    def __init__(self, host: str | None = None, parent=None):
        super().__init__(parent)
        self.bridge = Bridge()

        channel = QWebChannel(self.page())
        channel.registerObject("bridge", self.bridge)
        self.page().setWebChannel(channel)

        port = start_static_server(HERE)
        query = f"hud=0&autoconnect=1&host={host}" if host else "hud=1"
        self.setUrl(QUrl(f"http://127.0.0.1:{port}/viewer.html?{query}"))


class JointPanel(QWidget):
    """Right-hand-side numeric readout, updated from the bridge signal."""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.layout_ = QFormLayout(self)
        self.labels: dict[str, QLabel] = {}

    def update_joints(self, joints: dict) -> None:
        for name, deg in joints.items():
            if name not in self.labels:
                lbl = QLabel("0.00°")
                lbl.setStyleSheet("font-family: monospace; font-size: 14px;")
                self.layout_.addRow(name, lbl)
                self.labels[name] = lbl
            self.labels[name].setText(f"{float(deg):+7.2f}°")


class MainWindow(QMainWindow):
    def __init__(self, host: str | None = None):
        super().__init__()
        self.setWindowTitle("Robot viewer demo")
        self.resize(1200, 720)

        self.viewer = RobotViewerWidget(host=host)
        self.panel = JointPanel()
        self.viewer.bridge.jointsChanged.connect(self.panel.update_joints)

        split = QSplitter()
        split.addWidget(self.viewer)
        split.addWidget(self.panel)
        split.setStretchFactor(0, 4)
        split.setStretchFactor(1, 1)
        self.setCentralWidget(split)


def main() -> None:
    host = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_HOST
    app = QApplication(sys.argv)
    win = MainWindow(host=host)
    win.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
