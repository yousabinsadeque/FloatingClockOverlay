#!/bin/bash
# Point the in-app updater at a published release, then deploy the website.
#   scripts/rollout.sh 1.4.1      offer v1.4.1 to everyone
#   scripts/rollout.sh 1.4.0      pull a bad 1.4.1: nobody else is offered it
# Users already on a newer version stay on it; only the offer changes.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:?usage: scripts/rollout.sh <version>}"
TAG="v$VERSION"
REPO=yousabinsadeque/FloatingClockOverlay
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

gh release download "$TAG" -R $REPO -p FloatingClockOverlay.dmg -p FloatingClockOverlay.exe -D "$TMP"
NOTES=$(gh release view "$TAG" -R $REPO --json body -q .body)
[ -f "build/release-$VERSION/notes.txt" ] && NOTES=$(cat "build/release-$VERSION/notes.txt")

python3 - "$VERSION" "$TAG" "$NOTES" "$TMP" <<'EOF'
import hashlib, json, sys
version, tag, notes, tmp = sys.argv[1:]
base = f"https://github.com/yousabinsadeque/FloatingClockOverlay/releases/download/{tag}/"
def entry(name):
    sha = hashlib.sha256(open(f"{tmp}/{name}", "rb").read()).hexdigest()
    return {"version": version, "url": base + name, "sha256": sha, "notes": notes[:300]}
json.dump({"mac": entry("FloatingClockOverlay.dmg"), "windows": entry("FloatingClockOverlay.exe")},
          open("firebase-public/update.json", "w"), indent=2, ensure_ascii=False)
EOF

firebase deploy --only hosting --project floating-clock-overlay >/dev/null
git add firebase-public/update.json
git commit -m "Roll out $TAG to the in-app updater" >/dev/null && git push -q origin HEAD || true
echo "✓ Users are now offered $TAG"
