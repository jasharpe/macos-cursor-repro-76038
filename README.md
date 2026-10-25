# macos-cursor-repro-76038

Minimal reproduction for
[godotengine/godot#76038](https://github.com/godotengine/godot/issues/76038):
a custom mouse cursor reverts to the system cursor in fullscreen on macOS.

## The bug

Run the project in fullscreen on macOS, move the pointer into the band at the
**top of the screen**, then move back down. The custom cursor (a magenta disc)
is replaced by the system arrow cursor, and it stays replaced.

The **menu bar is not involved**. You do not need to reach the top edge of the
screen or make the menu bar appear. In fullscreen the content view does not
cover the whole screen: a band of approximately 37 points at the top belongs to
a window owned by macOS. On a 1117 point tall screen the view is 1080 points
tall. Crossing that line and coming back is enough.

macOS resets the cursor state of the application when the pointer leaves the
view at the top and returns, and it sends no event for this change. The engine
does not know that it must set the cursor again. The reset affects the cursor
image, and also the visibility of the system cursor.

Moving into the **Dock** at the bottom does *not* cause the bug, because the
Dock overlays the content view, so the pointer never leaves it.

## How to run

```
godot --path .
```

The project starts in fullscreen with a custom cursor. The cursor is built in
code, so the project contains no imported asset and needs no import step.

| Key | Action |
| --- | --- |
| `1` `2` `3` | windowed / fullscreen / exclusive fullscreen |
| `V` `H` `C` `N` | mouse visible / hidden / captured / confined |
| `A` `S` `D` | cursor arrow (custom magenta) / ibeam / pointing hand |
| `ESC` | quit |

The current window mode and mouse mode are shown on screen.

## Affected versions

Reproduced on Godot 4.4.1 and on 4.8.dev (master), macOS 15 and macOS 26,
Apple Silicon. Both `FULLSCREEN` and `EXCLUSIVE_FULLSCREEN` are affected.

## Not a Godot-specific defect

The same defect appears in other applications that use the macOS hardware
cursor:

- **Unity 6** (`6000.3.22f1`) behaves identically. See
  [macos-cursor-unity-repro-76038](https://github.com/jasharpe/macos-cursor-unity-repro-76038)
  for the equivalent Unity project. Both cursor modes of Unity fail. The
  hardware cursor (`CursorMode.Auto`) reverts to the system arrow cursor. The
  software cursor (`CursorMode.ForceSoftware`) keeps its own cursor, but macOS
  also makes the system cursor visible again, so two cursors appear.
- [Chromium issue 430116472](https://issues.chromium.org/issues/430116472).
  Chrome observed no `updateCursor` call when the cursor changes, and concluded
  that the change comes from a window the application does not own.
- [Deskflow PR #10184](https://github.com/deskflow/deskflow/pull/10184) reports the
  same defect on macOS 26, worked around with an undocumented menu bar
  notification.
- [Apple Developer Forums thread 803069](https://developer.apple.com/forums/thread/803069)
  reports that custom cursors revert when they touch the top screen edge in
  fullscreen.

## Useful measurements

In fullscreen on an Apple M3 Max:

- `[NSCursor set]` needs approximately 0.5 ms, because it waits for the window
  server.
- `[NSCursor currentCursor]` needs approximately 2 ns, and it holds the cursor
  that macOS applied.

A fix can therefore compare the two cursors on each mouse movement, and set the
cursor only when they are different.
