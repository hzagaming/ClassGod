#!/bin/bash
set -euo pipefail

release_repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
if [ "$#" -gt 0 ]; then
    mkdir -p "$1"
    release_root=$(cd "$1" && pwd)
else
    release_root=$(mktemp -d "${TMPDIR:-/tmp}/ClassGodRelease.XXXXXX")
fi
echo "Release workspace: $release_root"
release_derived="$release_root/DerivedData"
release_artifacts="$release_root/artifacts"
mkdir -p "$release_artifacts"

xcodebuild -project "$release_repo/ClassGod/ClassGod.xcodeproj" -scheme ClassGod \
    -configuration Release -destination 'generic/platform=macOS' \
    -derivedDataPath "$release_derived" ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO \
    CODE_SIGN_IDENTITY=- build analyze

release_app="$release_derived/Build/Products/Release/ClassGod.app"
release_version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$release_app/Contents/Info.plist")
release_build=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$release_app/Contents/Info.plist")
release_name="ClassGod-v$release_version-Build$release_build-macOS-universal"
for release_binary in \
    "$release_app/Contents/MacOS/ClassGod" \
    "$release_app/Contents/PlugIns/ClassGodWidget.appex/Contents/MacOS/ClassGodWidget" \
    "$release_app/Contents/Resources/ClassGodHelper"; do
    xcrun lipo "$release_binary" -verify_arch arm64 x86_64
    codesign --verify --strict "$release_binary"
done
codesign --verify --deep --strict "$release_app"
test ! -e "$release_app/Contents/Resources/Info.plist"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleURLTypes:0:CFBundleURLSchemes:0' "$release_app/Contents/Info.plist")" = classgod

for release_suffix in pkg dmg app.zip; do
    if [ -e "$release_artifacts/$release_name.$release_suffix" ]; then
        echo "Artifact already exists: $release_name.$release_suffix" >&2
        exit 1
    fi
done
release_stage=$(mktemp -d "$release_root/staging.XXXXXX")
release_payload="$release_stage/payload"
mkdir -p "$release_payload/Applications"
ditto --norsrc --noextattr "$release_app" "$release_payload/Applications/ClassGod.app"
pkgbuild --analyze --root "$release_payload" "$release_stage/components.plist"
/usr/libexec/PlistBuddy -c 'Set :0:BundleIsRelocatable false' "$release_stage/components.plist"
pkgbuild --root "$release_payload" --component-plist "$release_stage/components.plist" \
    --identifier com.hanazar.classgod.pkg --version "$release_version" \
    --install-location / --ownership recommended "$release_stage/ClassGod-component.pkg"
cat > "$release_stage/Distribution.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="1">
    <title>ClassGod $release_version</title>
    <options customize="never" require-scripts="false" hostArchitectures="arm64,x86_64"/>
    <domains enable_localSystem="true" enable_currentUserHome="false" enable_anywhere="false"/>
    <volume-check><allowed-os-versions><os-version min="14.0"/></allowed-os-versions></volume-check>
    <choices-outline><line choice="default"/></choices-outline>
    <choice id="default" visible="false"><pkg-ref id="com.hanazar.classgod.pkg"/></choice>
    <pkg-ref id="com.hanazar.classgod.pkg" version="$release_version">ClassGod-component.pkg</pkg-ref>
</installer-gui-script>
EOF
productbuild --distribution "$release_stage/Distribution.xml" --package-path "$release_stage" \
    "$release_artifacts/$release_name.pkg"

release_dmg_root="$release_stage/dmg"
mkdir "$release_dmg_root"
ditto --norsrc --noextattr "$release_app" "$release_dmg_root/ClassGod.app"
ln -s /Applications "$release_dmg_root/Applications"
hdiutil create -volname "ClassGod $release_version" -srcfolder "$release_dmg_root" \
    -format UDZO -fs HFS+ "$release_artifacts/$release_name.dmg"
ditto -c -k --norsrc --noextattr --keepParent "$release_app" "$release_artifacts/$release_name.app.zip"

cd "$release_artifacts"
shasum -a 256 "$release_name.pkg" "$release_name.dmg" "$release_name.app.zip" > SHA256SUMS.txt
shasum -a 256 -c SHA256SUMS.txt
echo "Artifacts: $release_artifacts"
