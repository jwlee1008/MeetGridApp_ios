#!/bin/sh
set -eu

GOOGLE_SERVICE_INFO="${SRCROOT}/MeetGrid/GoogleService-Info.plist"
APP_INFO_PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"

fail() {
    echo "error: $1" >&2
    exit 1
}

warn() {
    echo "warning: $1" >&2
}

if [ ! -f "$GOOGLE_SERVICE_INFO" ]; then
    if [ "${CONFIGURATION:-Debug}" = "Release" ]; then
        fail "MeetGrid/GoogleService-Info.plist is required for Release builds."
    fi

    warn "MeetGrid/GoogleService-Info.plist is missing. The app will run in local demo mode."
    exit 0
fi

if [ ! -f "$APP_INFO_PLIST" ]; then
    fail "Generated app Info.plist was not found at ${APP_INFO_PLIST}."
fi

CLIENT_ID=$(/usr/libexec/PlistBuddy -c "Print CLIENT_ID" "$GOOGLE_SERVICE_INFO" 2>/dev/null || true)
REVERSED_CLIENT_ID=$(/usr/libexec/PlistBuddy -c "Print REVERSED_CLIENT_ID" "$GOOGLE_SERVICE_INFO" 2>/dev/null || true)

if [ -z "$CLIENT_ID" ] || [ -z "$REVERSED_CLIENT_ID" ]; then
    fail "GoogleService-Info.plist is missing CLIENT_ID or REVERSED_CLIENT_ID. Enable the Google sign-in provider in Firebase Authentication, download a fresh iOS GoogleService-Info.plist, and replace MeetGrid/GoogleService-Info.plist."
fi

/usr/libexec/PlistBuddy -c "Delete :CFBundleURLTypes" "$APP_INFO_PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes array" "$APP_INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0 dict" "$APP_INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleTypeRole string Editor" "$APP_INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" "$APP_INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string $REVERSED_CLIENT_ID" "$APP_INFO_PLIST"
