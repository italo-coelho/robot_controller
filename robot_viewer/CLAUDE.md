# robot_viewer

Portable 3D URDF viewer with live joint updates over WebSocket. Originally extracted from a Fairino FR3 cobot's web HMI; now standalone and embeddable.

## What's in this folder

```
robot_viewer/
├── viewer.html         entrypoint — parameterized HTML page
├── pyside6_example.py  PySide6 / QWebEngineView embedding demo + Bridge
├── lib/                JS deps (vendored — do not modify)
│   ├── three.js                  Three.js r-series (the version the original page ships)
│   ├── OrbitControls.js          camera orbit/zoom/pan
│   ├── TransformControls.js      TCP-target gizmo (translate/rotate)
│   ├── STLLoader.js              for collision meshes (unused by default)
│   ├── ColladaLoader.js          for the FR3 .DAE visual meshes
│   ├── URDFLoader.js             gkjohnson/urdf-loaders
│   ├── urdf-viewer-element.js    custom element wrapping the scene
│   └── urdf-manipulator-element.js  adds hover + click-drag joint control
└── model/
    ├── urdf/fr3v6.urdf
    └── meshes/fr3/visual-v6.0/*.DAE
```

## Three integration paths

### 1. Browser standalone

Open `viewer.html` over HTTP (not `file://` — Collada textures and the URDF need real fetches):

```
http://<host>/viewer.html?host=192.168.167.199:9999
```

URL params:

| param | default | purpose |
|---|---|---|
| `host` | `""` | `ws://host:port` to connect to |
| `urdf` | `./model/urdf/fr3v6.urdf` | URDF path |
| `up` | `+Z` | up axis |
| `highlight` | `#FE6900` | joint highlight color |
| `hud` | `1` | `0` hides both overlays (use when embedded) |
| `autoconnect` | `1` if `host` set | `0` skips auto-connect |

### 2. JS API (when consuming from another web page)

`window.RobotViewer` is exposed once `viewer.html` loads:

```js
RobotViewer.connect('192.168.167.199:9999')
RobotViewer.disconnect()
RobotViewer.setJoints({ j1: 12.3, j2: -45.6, ... })   // degrees
RobotViewer.getJoints()                                // last frame
RobotViewer.isConnected()
RobotViewer.on('joints', joints => ...)                // every frame, {j1: deg, ...}
RobotViewer.on('status', s => ...)                     // 'connecting…' | 'connected' | 'error' | 'closed'
RobotViewer.on('joint-mouseover',  name => ...)
RobotViewer.on('manipulate-start', name => ...)
RobotViewer.on('manipulate-end',   name => ...)
```

### 3. PySide6 embedding (recommended for desktop apps)

`pyside6_example.py` is a full working demo. The two reusable classes:

- **`RobotViewerWidget(QWebEngineView)`** — starts an in-process `http.server` thread, points itself at `viewer.html`, and wires a `QWebChannel` so the JS side can push joint frames to Python.
- **`Bridge(QObject)`** — receives `bridge.onJoints(jsonString)` calls from JS, parses, re-emits `jointsChanged(dict)` as a Qt signal.

Minimal integration:

```python
viewer = RobotViewerWidget(host="192.168.167.199:9999")
viewer.bridge.jointsChanged.connect(lambda j: print(j))
layout.addWidget(viewer)
```

Why the in-process HTTP server? QtWebEngine refuses `fetch`/XHR on `file://` by default. A 30-line static server in a daemon thread is the cleanest portable workaround.

## Bare viewer — 3D only, no overlays

For an embed where the surrounding UI (Qt widgets, another web page) renders its own status/joint readouts, hide the in-canvas HUDs.

### Browser

Append `&hud=0`:

```
http://<host>/viewer.html?host=192.168.167.199:9999&hud=0
```

That hides both panels (`#hud` instructions on the left and `#live` connection/joint readout on the right). Orbit/zoom/joint-drag still work — only the text overlays are gone.

### JS API (runtime toggle)

```js
document.body.classList.add('no-hud');     // hide
document.body.classList.remove('no-hud');  // show
```

`.no-hud` is defined in `viewer.html` and hides every `.panel` element.

### PySide6

`RobotViewerWidget` already passes `hud=0` when `host` is given (see `pyside6_example.py` — `query = f"hud=0&autoconnect=1&host={host}"`). To get the 3D model with **no** extra Python panels either, embed just the widget and skip `JointPanel`:

```python
from pyside6_example import RobotViewerWidget

viewer = RobotViewerWidget(host="192.168.167.199:9999")
layout.addWidget(viewer)        # done — pure 3D scene
```

You still have access to `viewer.bridge.jointsChanged` if you want to drive other widgets without showing the demo's readout.

If you want **hud=0 even without a host** (so the user can't see/edit the WS field), pass it explicitly — modify `RobotViewerWidget.__init__` to set `query = "hud=0"` unconditionally, or expose a `hud: bool = False` constructor argument.

### What's hidden

- Hover hint: "Drag a link to rotate its joint · drag empty space to orbit · wheel to zoom"
- WS host text input and connect button
- Status indicator ("connected" / "error" / …)
- Frame counter
- Per-joint degree readout (`j1: +12.34°`, …)

What's **not** hidden (because they belong to the 3D scene itself, not the overlay): the orange highlight on hovered joints, the TCP-target gizmo if it's instantiated, shadows. To suppress the hover highlight too, set `disable-dragging` on the `<urdf-viewer>` element ([urdf-manipulator-element.js:25](lib/urdf-manipulator-element.js#L25)).

## Data flow (real-time updates)

```
ws://<host>:9999  ─► JSON frames
                     │
                     ▼  data.joints = { j1: deg, j2: deg, ... }
                     │
                     ▼  applyJoints():
                         v.setAngle(name, deg * π/180)         ← visible robot
                         v.setVirtualAngle(name, deg * π/180)  ← raycast/drag copy
                     │
                     ▼  fire('joints', now) + bridge.onJoints(JSON)
```

This mirrors the original HMI's pipeline (`index.js:10758 → 10793 → 8342 → 10888-10894`). The 0.1° diff filter and `ExecuteSmoothMotion` tween from the original are intentionally dropped — frames are pushed fast enough that snap-per-frame looks fine. Add them back from [urdf-viewer-element.js:570](lib/urdf-viewer-element.js#L570) if you ever need smoothing.

## Joint conventions

- The URDF defines joints `j1` … `j6` (revolute). Joint names in WS frames must match exactly.
- Wire format: **degrees**. The page converts with `DEG2RAD = Math.PI / 180`.
- Two robots live in the scene: the "real" robot (driven by WS) and the "virtual" robot (driven by user drag). `URDFManipulator` raycasts against the virtual copy, so any drag UI uses `setVirtualAngle`; live updates write both so the virtual stays pinned to reality between drags.

## Swapping the model

Drop a new URDF + meshes under `model/` (or anywhere reachable by URL), then pass `?urdf=…`. The URDF's mesh `filename="…"` paths are resolved relative to the URDF file's URL — keep the meshes in the same directory tree. `package://` URIs are also supported (see [URDFLoader.js:396](lib/URDFLoader.js#L396)).

If joint names differ from `j1..j6`, the WS-frame keys must match — there's no name mapping layer.

## Origin / auth gotchas

Cross-origin WebSocket from `http://127.0.0.1:*` to `ws://<robot>:9999`:

- Works on this FR3 controller — the WS doesn't validate `Origin` or require a cookie.
- On controllers that do: serve `viewer.html` from the robot itself, or run a tiny local proxy that fixes the `Origin` header. Cookies won't carry across origins under `SameSite=Lax` (default) even if you log in to the robot in another tab.

## When extending

- **New control panel widgets** — subscribe to `Bridge.jointsChanged` in Python, or `RobotViewer.on('joints', …)` in JS. Don't poll.
- **Sending commands back to the robot** — not implemented. The original HMI uses a separate REST endpoint (not the WS). Don't try to push commands through this WS.
- **Smooth interpolation** — re-enable `ExecuteSmoothMotion` from the original (15-step tween, see [urdf-viewer-element.js:570](lib/urdf-viewer-element.js#L570)).
- **Multiple robots in one page** — `<urdf-viewer>` is a custom element; instantiate multiple. The `RobotViewer` JS API singleton would need to be rebuilt as a class-per-element.
