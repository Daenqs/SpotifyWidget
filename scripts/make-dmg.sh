#!/bin/sh
set -eu

cd "$(dirname "$0")/.."
[ -f Configs/Local.xcconfig ] || { echo "Configs/Local.xcconfig is missing" >&2; exit 1; }

version=$(sed -n 's/^MARKETING_VERSION = //p' Configs/Base.xcconfig)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

git clone --quiet . "$work/src"
cp Configs/Local.xcconfig "$work/src/Configs/"

xcodebuild -project "$work/src/SpotifyWidget.xcodeproj" -scheme SpotifyWidget \
  -configuration Release -destination 'generic/platform=macOS' \
  -derivedDataPath "$work/build" -allowProvisioningUpdates -quiet build

mkdir "$work/dmg"
cp -R "$work/build/Build/Products/Release/Spotify Widget.app" "$work/dmg/"
ln -s /Applications "$work/dmg/Applications"

mkdir -p dist
hdiutil create -volname "Spotify Widget" -srcfolder "$work/dmg" -format UDZO -ov "dist/SpotifyWidget-$version.dmg" >/dev/null
echo "dist/SpotifyWidget-$version.dmg"
