#!/bin/sh
set -eu

GOOGLE_SERVICE_INFO="${SRCROOT}/MeetGrid/GoogleService-Info.plist"
APP_INFO_PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"

if [ ! -f "$GOOGLE_SERVICE_INFO" ] || [ ! -f "$APP_INFO_PLIST" ]; then
    exit 0
fi

REVERSED_CLIENT_ID=$(/usr/libexec/PlistBuddy -c "Print REVERSED_CLIENT_ID" "$GOOGLE_SERVICE_INFO" 2>/dev/null || true)

if [ -z "$REVERSED_CLIENT_ID" ]; then
    exit 0
fi

/usr/libexec/PlistBuddy -c "Delete :CFBundleURLTypes" "$APP_INFO_PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes array" "$APP_INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0 dict" "$APP_INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleTypeRole string Editor" "$APP_INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" "$APP_INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string $REVERSED_CLIENT_ID" "$APP_INFO_PLIST"
