#!/usr/bin/env bash
# embed_icon.sh — builds AppIcon.icns from the source PNG and injects it into the .app bundle.
# Usage: bash scripts/embed_icon.sh <path/to/App.app>
set -euo pipefail

APP="${1:?Usage: embed_icon.sh <path/to/App.app>}"
RESOURCES="${APP}/Contents/Resources"

# ── Find source PNG in project root ──────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

SRC=""
for f in "${PROJECT_DIR}"/*.png "${PROJECT_DIR}"/*.PNG; do
    [[ -f "$f" ]] && SRC="$f" && break
done

if [[ -z "${SRC}" ]]; then
    echo "⚠  No PNG found in project root — skipping icon embed."
    exit 0
fi

echo "  Source icon : ${SRC}"
echo "  Bundle      : ${APP}"

# ── Build iconset ─────────────────────────────────────────────────────────────
TMPDIR=$(mktemp -d)
ICONSET="${TMPDIR}/AppIcon.iconset"
mkdir -p "${ICONSET}"

# macOS iconset requires these exact filenames
declare -a SIZES=(16 32 64 128 256 512)
for SIZE in "${SIZES[@]}"; do
    DOUBLE=$(( SIZE * 2 ))
    sips -z "${SIZE}"  "${SIZE}"  "${SRC}" --out "${ICONSET}/icon_${SIZE}x${SIZE}.png"   >/dev/null 2>&1
    sips -z "${DOUBLE}" "${DOUBLE}" "${SRC}" --out "${ICONSET}/icon_${SIZE}x${SIZE}@2x.png" >/dev/null 2>&1
done

# ── Convert to .icns ──────────────────────────────────────────────────────────
mkdir -p "${RESOURCES}"
iconutil -c icns "${ICONSET}" -o "${RESOURCES}/AppIcon.icns"
echo "  ✓ AppIcon.icns embedded into bundle"

# ── Strip quarantine flags ────────────────────────────────────────────────────
xattr -cr "${APP}" 2>/dev/null || true

# ── Ad-hoc sign the whole bundle ─────────────────────────────────────────────
codesign --force --deep --sign - "${APP}" 2>/dev/null || true
echo "  ✓ Bundle re-signed (ad-hoc)"

# ── Refresh LaunchServices so Dock/Finder pick up the icon ───────────────────
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [[ -x "${LSREGISTER}" ]]; then
    "${LSREGISTER}" -f "${APP}" 2>/dev/null || true
fi

# Cleanup
rm -rf "${TMPDIR}"
echo "  ✓ Done"
