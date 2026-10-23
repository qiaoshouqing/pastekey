#!/usr/bin/env bash
# PasteKey 一条命令发版：归档 → Developer ID 签名 + 公证 + 盖章 → dist/ 里出 zip 和 dmg → （可选）上传 App Store
#   bash scripts/release.sh 1.0.0            只出官网 / GitHub 下载包
#   bash scripts/release.sh 1.0.0 --appstore 同时上传到 App Store Connect
# 依赖：Xcode 26.3 登录了 POMODIARY LLC 团队；~/.appstoreconnect/beihao.env 里的 API 密钥（公证用）
set -euo pipefail
VERSION="${1:?用法: bash scripts/release.sh 版本号 [--appstore]}"
APPSTORE="${2:-}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PBX="$ROOT/PasteKey.xcodeproj/project.pbxproj"
export DEVELOPER_DIR=/Applications/Xcode-26.3.app/Contents/Developer
set -a; . "$HOME/.appstoreconnect/beihao.env"; set +a
KEY="$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8"

BUILD=$(( $(grep -o 'CURRENT_PROJECT_VERSION = [0-9]*' "$PBX" | head -1 | grep -o '[0-9]*$') + 1 ))
sed -i '' -E "s/CURRENT_PROJECT_VERSION = [0-9]+;/CURRENT_PROJECT_VERSION = $BUILD;/g; s/MARKETING_VERSION = [0-9.]+;/MARKETING_VERSION = $VERSION;/g" "$PBX"
echo "版本 $VERSION（构建 $BUILD）"

WORK="$(mktemp -d)"
cd "$ROOT"
xcodebuild archive -project PasteKey.xcodeproj -scheme PasteKey -configuration Release \
  -destination 'generic/platform=macOS' -archivePath "$WORK/PasteKey.xcarchive" \
  -allowProvisioningUpdates DEVELOPMENT_TEAM=5358ZM6WV2 -quiet

# 官网 / GitHub 版：Developer ID 签名 + 公证
xcodebuild -exportArchive -archivePath "$WORK/PasteKey.xcarchive" \
  -exportOptionsPlist Config/ExportOptions-developerid.plist -exportPath "$WORK/devid" -allowProvisioningUpdates -quiet
ditto -c -k --keepParent "$WORK/devid/PasteKey.app" "$WORK/notarize.zip"
xcrun notarytool submit "$WORK/notarize.zip" --key "$KEY" --key-id "$ASC_KEY_ID" --issuer "$ASC_ISSUER_ID" --wait
xcrun stapler staple "$WORK/devid/PasteKey.app"
spctl -a -t exec "$WORK/devid/PasteKey.app"

mkdir -p dist "$WORK/dmg"
ditto -c -k --keepParent "$WORK/devid/PasteKey.app" "dist/PasteKey-$VERSION-macOS.zip"
ditto "$WORK/devid/PasteKey.app" "$WORK/dmg/PasteKey.app"
ln -s /Applications "$WORK/dmg/Applications"
hdiutil create -quiet -volname PasteKey -srcfolder "$WORK/dmg" -ov -format UDZO "dist/PasteKey-$VERSION.dmg"
shasum -a 256 "dist/PasteKey-$VERSION-macOS.zip" "dist/PasteKey-$VERSION.dmg"

if [[ "$APPSTORE" == "--appstore" ]]; then
  xcodebuild -exportArchive -archivePath "$WORK/PasteKey.xcarchive" \
    -exportOptionsPlist Config/ExportOptions-appstore.plist -exportPath "$WORK/appstore" -allowProvisioningUpdates \
    -authenticationKeyPath "$KEY" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID"
  echo "已上传 App Store Connect，构建 $BUILD"
fi
echo "完成。记得提交版本号：git commit -am \"chore: release $VERSION ($BUILD)\""
