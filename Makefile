VERSION ?= 1.0.0

.PHONY: all build build-debug test app install uninstall \
        release release-dmg release-all clean help

all: app

# ── Swift build targets ──────────────────────────────────────────────────────

build:
	swift build -c release

build-debug:
	swift build

# ── Tests ────────────────────────────────────────────────────────────────────

test:
	swift test

# ── App bundle ───────────────────────────────────────────────────────────────

app:
	./scripts/build-app.sh $(VERSION)

# ── Install / uninstall ──────────────────────────────────────────────────────

install:
	./scripts/install.sh

uninstall:
	./scripts/uninstall.sh

# ── Release packaging ────────────────────────────────────────────────────────

release:
	./scripts/create-release.sh $(VERSION)

release-dmg:
	./scripts/create-dmg.sh $(VERSION)

release-all:
	./scripts/create-all-releases.sh $(VERSION)

# ── Cleanup ──────────────────────────────────────────────────────────────────

clean:
	swift package clean
	rm -rf ClosedDisplay.app
	rm -rf ClosedDisplay-v*/
	rm -f ClosedDisplay-v*.tar.gz ClosedDisplay-v*.tar.gz.sha256
	rm -f ClosedDisplay-v*.dmg ClosedDisplay-v*.dmg.sha256
	rm -rf dmg_staging/

# ── Help ─────────────────────────────────────────────────────────────────────

help:
	@echo "Usage: make [target] [VERSION=x.y.z]"
	@echo ""
	@echo "Build"
	@echo "  build          Release binary (swift build -c release)"
	@echo "  build-debug    Debug binary (swift build)"
	@echo "  app            Build ClosedDisplay.app bundle (default)"
	@echo ""
	@echo "Test"
	@echo "  test           Run swift test suite"
	@echo ""
	@echo "Install"
	@echo "  install        Install app to /Applications"
	@echo "  uninstall      Remove app and supporting files"
	@echo ""
	@echo "Release  (VERSION defaults to 1.0.0)"
	@echo "  release        Create tar.gz release package"
	@echo "  release-dmg    Create DMG release package"
	@echo "  release-all    Create both tar.gz and DMG packages"
	@echo ""
	@echo "Misc"
	@echo "  clean          Remove build artefacts and release files"
	@echo "  help           Show this message"
