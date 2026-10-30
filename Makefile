APP_NAME  = FloatingClockOverlay
PROJECT   = FloatingClockOverlay.xcodeproj
SCHEME    = FloatingClockOverlay
BUILD_DIR = build
APP_DIR   = $(BUILD_DIR)/Build/Products/Debug
APP_PATH  = $(APP_DIR)/$(APP_NAME).app
ARCHIVE   = $(BUILD_DIR)/$(APP_NAME).xcarchive

# A stable local certificate keeps macOS privacy grants (Screen Recording) across
# rebuilds; ad-hoc signatures change every build and silently revoke them.
SIGN_ID  := $(shell security find-identity -p codesigning 2>/dev/null | awk -F'"' '/FloatingClockOverlay Local Signing/{print $$2; exit}')
SIGN_ID  := $(if $(SIGN_ID),$(SIGN_ID),-)

.PHONY: build run clean open-xcode icons install-local install-release package package-dmg _embed-icon

# ── Compile ───────────────────────────────────────────────────────────────────
build:
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Debug \
		-derivedDataPath $(BUILD_DIR) \
		CODE_SIGN_IDENTITY="-" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO \
		build
	@$(MAKE) --no-print-directory _embed-icon

# ── Embed icon + re-sign (runs after every build automatically) ───────────────
_embed-icon:
	@echo "→ Embedding app icon…"
	@bash scripts/embed_icon.sh "$(APP_PATH)"

# ── Build + Launch ────────────────────────────────────────────────────────────
run: build
	@pkill -x $(APP_NAME) 2>/dev/null || true
	@sleep 0.4
	@open "$(APP_PATH)"

# ── Clean ─────────────────────────────────────────────────────────────────────
clean:
	rm -rf $(BUILD_DIR) dist
	@xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean 2>/dev/null || true

# ── Open in Xcode ─────────────────────────────────────────────────────────────
open-xcode:
	open $(PROJECT)

# ── Regenerate icon PNGs inside Assets.xcassets (optional) ───────────────────
icons:
	@echo "→ Regenerating icon assets from source PNG…"
	@swift scripts/create_icon.swift
	@echo "→ Run 'make build' to pick up the new icons."

# ── Install into /Applications ────────────────────────────────────────────────
# Uses ditto (preserves macOS metadata) then registers with LaunchServices.
install-local: build
	@echo "→ Installing to /Applications (may prompt for your password)…"
	@sudo rm -rf "/Applications/$(APP_NAME).app"
	@sudo ditto "$(APP_PATH)" "/Applications/$(APP_NAME).app"
	@sudo xattr -cr "/Applications/$(APP_NAME).app" 2>/dev/null || true
	@sudo codesign --force --deep --sign "$(SIGN_ID)" "/Applications/$(APP_NAME).app" 2>/dev/null || true
	@/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
		-f "/Applications/$(APP_NAME).app" 2>/dev/null || true
	@echo "✓ Installed: /Applications/$(APP_NAME).app"
	@echo "  The icon will appear in Launchpad after the next Dock refresh."

# ── Release build → /Applications, signed with the stable local certificate ───
install-release:
	xcodebuild archive -project $(PROJECT) -scheme $(SCHEME) -configuration Release \
		-archivePath "$(ARCHIVE)" -quiet
	@pkill -x $(APP_NAME) 2>/dev/null || true
	@sleep 1
	@rm -rf "/Applications/$(APP_NAME).app"
	@cp -R "$(ARCHIVE)/Products/Applications/$(APP_NAME).app" /Applications/
	@codesign --force --deep --preserve-metadata=entitlements,flags,identifier \
		--sign "$(SIGN_ID)" "/Applications/$(APP_NAME).app"
	@echo "✓ Installed release build, signed with: $(SIGN_ID)"
	@open "/Applications/$(APP_NAME).app"

# ── Create distributable ZIP (preserves macOS app bundle metadata) ────────────
package: build
	@mkdir -p dist
	@rm -f "dist/$(APP_NAME).zip"
	@ditto -c -k --sequesterRsrc --keepParent "$(APP_PATH)" "dist/$(APP_NAME).zip"
	@echo "✓ Package: dist/$(APP_NAME).zip"
	@ls -lh "dist/$(APP_NAME).zip"

# ── Create DMG for normal user distribution ──────────────────────────────────
package-dmg: build
	@echo "→ Creating DMG…"
	@mkdir -p dist
	@rm -rf dist/dmg-staging dist/$(APP_NAME).dmg
	@mkdir -p dist/dmg-staging
	@ditto "$(APP_PATH)" "dist/dmg-staging/$(APP_NAME).app"
	@ln -s /Applications "dist/dmg-staging/Applications"
	@hdiutil create \
		-volname "$(APP_NAME)" \
		-srcfolder "dist/dmg-staging" \
		-ov -format UDZO \
		"dist/$(APP_NAME).dmg"
	@rm -rf dist/dmg-staging
	@echo ""
	@echo "✓ DMG created: dist/$(APP_NAME).dmg"
	@ls -lh "dist/$(APP_NAME).dmg"
