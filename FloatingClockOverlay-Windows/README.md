# Floating Clock Overlay — Windows

A native Windows port of the always-on-top clock overlay, built with C# / WPF
(no Electron, no web wrapper).

## Status: early MVP

This is a fresh, from-scratch Windows implementation — the macOS app is built
entirely on AppKit (`NSWindow`, `NSStatusItem`, `.screenSaver` window levels),
which has no Windows equivalent, so none of that code could be ported directly.

Currently implemented:

- Borderless, transparent, always-on-top clock window
- Drag to reposition
- Click-through toggle (`Ctrl+Alt+C`), using `WS_EX_TRANSPARENT`
- System tray icon with Show/Hide, click-through, and Quit

Not yet ported from the macOS app: themes, timer/stopwatch modes,
adaptive color, burn-in drift, multi-monitor bounce, and the settings UI.
These can be added incrementally on top of this MVP.

## Building

Requires Windows with the .NET 8 SDK (WPF only builds on Windows — it cannot
be compiled from macOS or Linux).

```powershell
dotnet build FloatingClockOverlay-Windows\FloatingClockOverlay.sln -c Release
```

To produce a single-file `.exe`:

```powershell
dotnet publish FloatingClockOverlay-Windows\FloatingClockOverlay\FloatingClockOverlay.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o publish
```

## CI build

Pushing changes under `FloatingClockOverlay-Windows/` to `main` triggers
[`.github/workflows/windows-build.yml`](../.github/workflows/windows-build.yml),
which builds a self-contained `win-x64` executable on a `windows-latest`
GitHub Actions runner and uploads it as a workflow artifact.
