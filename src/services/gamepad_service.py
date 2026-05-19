"""
Gamepad service — polls a connected Bluetooth / USB gamepad using pygame
and emits Qt signals that PositionController connects to.

Runs entirely on the Qt main thread via QTimer (no extra threads needed).

Nintendo Switch Pro Controller layout (via Bluetooth on macOS):
  Axis 0  →  Left stick X
  Axis 1  →  Left stick Y   (up = negative)
  Axis 2  →  Right stick X
  Axis 3  →  Right stick Y  (up = negative)
  Hat  0  →  D-pad  (x, y) each in {-1, 0, 1}

  Button 0  →  B
  Button 1  →  A
  Button 2  →  Y
  Button 3  →  X
  Button 4  →  L  (left bumper)
  Button 5  →  R  (right bumper)
  Button 6  →  ZL (left trigger)
  Button 7  →  ZR (right trigger)
  Button 8  →  −  (minus / select)
  Button 9  →  +  (plus  / start)  ← mode toggle
  Button 10 →  Left stick click
  Button 11 →  Right stick click
  Button 12 →  Home
  Button 13 →  Capture

The controller name and full axis/button count are printed to the console on
connection — use that output to verify and adjust AXIS_* / BTN_* if needed.
"""

from __future__ import annotations

import os
import sys

from PySide6.QtCore import QObject, QTimer, Signal

# Suppress pygame's greeting banner
os.environ.setdefault("PYGAME_HIDE_SUPPORT_PROMPT", "1")

# On non-macOS headless systems initialise SDL with a dummy video driver so
# pygame doesn't try to open a display window.
if sys.platform not in ("darwin", "win32"):
    os.environ.setdefault("SDL_VIDEODRIVER", "dummy")
    os.environ.setdefault("SDL_AUDIODRIVER", "dummy")

import pygame  # noqa: E402  (must come after env-var setup)

# ── Tunables ──────────────────────────────────────────────────────────────────
POLL_INTERVAL_MS = 50    # 20 Hz — responsive without hammering the CPU
DEADZONE         = 0.30  # Ignore stick deflection below this threshold (Pro Controller drift guard)

# Axis indices (same for Pro Controller and most generic gamepads)
AXIS_LEFT_X  = 0
AXIS_LEFT_Y  = 1
AXIS_RIGHT_X = 2
AXIS_RIGHT_Y = 3

# Button indices — Nintendo Switch Pro Controller (Bluetooth, macOS)
BTN_LB    = 4   # L  button
BTN_RB    = 5   # R  button
BTN_START = 9   # +  button  (use 7 for Xbox / generic controllers)


def _scale(val: float) -> float:
    """Remove deadzone and rescale remaining range to [−1, 1]."""
    if abs(val) < DEADZONE:
        return 0.0
    sign = 1.0 if val > 0 else -1.0
    return sign * (abs(val) - DEADZONE) / (1.0 - DEADZONE)


class GamepadService(QObject):
    """Emits gamepad events as Qt signals; safe to use from the main thread."""

    # Scaled stick values (after deadzone removal).  0.0 means centred.
    left_stick_changed  = Signal(float, float)   # (x, y)
    right_stick_changed = Signal(float, float)   # (x, y)

    # D-pad hat: each component is −1 / 0 / +1
    hat_changed = Signal(int, int)               # (x, y)

    # Rising-edge button press (fires once per physical press)
    button_pressed = Signal(int)

    # True when a joystick is detected / False on disconnect
    connected_changed = Signal(bool)

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)

        self._joystick: pygame.joystick.JoystickType | None = None
        self._connected      = False
        self._prev_count     = 0
        self._prev_buttons:  dict[int, bool] = {}
        self._prev_hat:      tuple[int, int] = (0, 0)
        self._prev_left:     tuple[float, float] = (0.0, 0.0)
        self._prev_right:    tuple[float, float] = (0.0, 0.0)

        pygame.init()
        pygame.joystick.init()

        self._timer = QTimer(self)
        self._timer.setInterval(POLL_INTERVAL_MS)
        self._timer.timeout.connect(self._poll)
        self._timer.start()

        # Check immediately so the UI reflects the initial state at startup
        self._check_connection()

    # ── Connection management ─────────────────────────────────────────────────

    def _check_connection(self) -> None:
        pygame.joystick.quit()
        pygame.joystick.init()
        count = pygame.joystick.get_count()

        if count > 0 and not self._connected:
            self._joystick = pygame.joystick.Joystick(0)
            self._joystick.init()
            self._connected = True
            js = self._joystick
            print(
                f"[Gamepad] Connected: '{js.get_name()}' — "
                f"{js.get_numaxes()} axes, "
                f"{js.get_numbuttons()} buttons, "
                f"{js.get_numhats()} hat(s)"
            )
            print(
                f"[Gamepad] Active mapping — "
                f"LB=btn{BTN_LB}, RB=btn{BTN_RB}, Start/Mode=btn{BTN_START} | "
                f"Sticks: L=(ax{AXIS_LEFT_X},ax{AXIS_LEFT_Y}) R=(ax{AXIS_RIGHT_X},ax{AXIS_RIGHT_Y})"
            )
            self.connected_changed.emit(True)

        elif count == 0 and self._connected:
            self._joystick = None
            self._connected = False
            self._prev_buttons = {}
            self._prev_hat = (0, 0)
            self._prev_left = (0.0, 0.0)
            self._prev_right = (0.0, 0.0)
            print("[Gamepad] Disconnected")
            self.connected_changed.emit(False)

        self._prev_count = count

    # ── Main poll ─────────────────────────────────────────────────────────────

    def _poll(self) -> None:
        pygame.event.pump()

        # Re-check for connect / disconnect
        current_count = pygame.joystick.get_count()
        if current_count != self._prev_count:
            self._check_connection()

        if not self._connected or self._joystick is None:
            return

        self._poll_sticks()
        self._poll_hat()
        self._poll_buttons()

    def _poll_sticks(self) -> None:
        js = self._joystick
        try:
            lx = _scale(js.get_axis(AXIS_LEFT_X))
            ly = _scale(js.get_axis(AXIS_LEFT_Y))
            rx = _scale(js.get_axis(AXIS_RIGHT_X))
            ry = _scale(js.get_axis(AXIS_RIGHT_Y))
        except pygame.error:
            return

        # Enforce one axis per stick: zero out the weaker component so the
        # controller never has two competing candidates from the same stick.
        if abs(lx) >= abs(ly):
            ly = 0.0
        else:
            lx = 0.0

        if abs(rx) >= abs(ry):
            ry = 0.0
        else:
            rx = 0.0

        left  = (lx, ly)
        right = (rx, ry)

        # Emit every tick while the stick is non-zero (continuous jogging) and
        # once when it returns to centre (so the controller knows to stop).
        if lx != 0.0 or ly != 0.0 or left != self._prev_left:
            self._prev_left = left
            self.left_stick_changed.emit(lx, ly)

        if rx != 0.0 or ry != 0.0 or right != self._prev_right:
            self._prev_right = right
            self.right_stick_changed.emit(rx, ry)

    def _poll_hat(self) -> None:
        js = self._joystick
        try:
            hat = js.get_hat(0) if js.get_numhats() > 0 else (0, 0)
        except pygame.error:
            return

        if hat != self._prev_hat:
            self._prev_hat = hat
            self.hat_changed.emit(hat[0], hat[1])

    def _poll_buttons(self) -> None:
        js = self._joystick
        for i in range(js.get_numbuttons()):
            try:
                pressed = bool(js.get_button(i))
            except pygame.error:
                continue
            was_pressed = self._prev_buttons.get(i, False)
            if pressed and not was_pressed:
                self.button_pressed.emit(i)
            self._prev_buttons[i] = pressed
