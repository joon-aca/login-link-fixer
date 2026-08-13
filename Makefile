.PHONY: project build test install

project:
	@command -v xcodegen >/dev/null 2>&1 || { echo "xcodegen is required."; exit 1; }
	xcodegen generate

build: project
	xcodebuild -project LoginLinkFixer.xcodeproj -scheme LoginLinkFixer -configuration Release -derivedDataPath DerivedData clean build

test: project
	xcodebuild test -project LoginLinkFixer.xcodeproj -scheme LoginLinkFixer -configuration Debug -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO

install: project
	./scripts/install.sh
