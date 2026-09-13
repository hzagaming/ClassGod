#!/bin/bash
set -euo pipefail

helper_root="$SRCROOT/../ClassGodHelper"
helper_build_dir="$DERIVED_FILE_DIR/ClassGodHelperBuild"
helper_cache_dir="$DERIVED_FILE_DIR/ClassGodHelperModuleCache"
helper_resources="$BUILT_PRODUCTS_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH"
helper_daemon_dir="$BUILT_PRODUCTS_DIR/$CONTENTS_FOLDER_PATH/Library/LaunchDaemons"
read -r -a helper_archs <<< "${ARCHS:?Missing target architectures}"
helper_slices=()

for helper_arch in "${helper_archs[@]}"; do
    case "$helper_arch" in
        arm64|x86_64) ;;
        *) echo "Unsupported helper architecture: $helper_arch" >&2; exit 1 ;;
    esac
    helper_options=(--disable-sandbox --package-path "$helper_root" --configuration release
        --scratch-path "$helper_build_dir/$helper_arch"
        --triple "$helper_arch-apple-macosx${MACOSX_DEPLOYMENT_TARGET:-14.0}")
    CLANG_MODULE_CACHE_PATH="$helper_cache_dir" SWIFTPM_MODULECACHE_OVERRIDE="$helper_cache_dir" \
        xcrun swift build "${helper_options[@]}"
    helper_bin_dir=$(xcrun swift build "${helper_options[@]}" --show-bin-path)
    helper_slices+=("$helper_bin_dir/ClassGodHelper")
done

xcrun lipo -create "${helper_slices[@]}" -output "$DERIVED_FILE_DIR/ClassGodHelper"
xcrun lipo "$DERIVED_FILE_DIR/ClassGodHelper" -verify_arch "${helper_archs[@]}"
mkdir -p "$helper_resources" "$helper_daemon_dir"
cp "$DERIVED_FILE_DIR/ClassGodHelper" "$helper_resources/ClassGodHelper"
cp "$helper_root/com.hanazar.classgod.helper.plist" "$helper_daemon_dir/"
chmod 755 "$helper_resources/ClassGodHelper"

if [ "${CODE_SIGNING_ALLOWED:-NO}" = YES ]; then
    codesign --force --identifier com.hanazar.classgod.helper \
        --sign "${EXPANDED_CODE_SIGN_IDENTITY:--}" --timestamp=none "$helper_resources/ClassGodHelper"
fi
