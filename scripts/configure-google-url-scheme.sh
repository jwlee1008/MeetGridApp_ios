#!/bin/sh
set -eu

GOOGLE_SERVICE_INFO="${SRCROOT}/MeetGrid/GoogleService-Info.plist"
SOURCE_INFO_PLIST="${SRCROOT}/MeetGrid/Info.plist"

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

if [ ! -f "$SOURCE_INFO_PLIST" ]; then
    fail "MeetGrid/Info.plist is required for Google Sign-In URL scheme registration."
fi

CLIENT_ID=$(/usr/libexec/PlistBuddy -c "Print CLIENT_ID" "$GOOGLE_SERVICE_INFO" 2>/dev/null || true)
REVERSED_CLIENT_ID=$(/usr/libexec/PlistBuddy -c "Print REVERSED_CLIENT_ID" "$GOOGLE_SERVICE_INFO" 2>/dev/null || true)

if [ -z "$CLIENT_ID" ] || [ -z "$REVERSED_CLIENT_ID" ]; then
    fail "GoogleService-Info.plist is missing CLIENT_ID or REVERSED_CLIENT_ID. Enable the Google sign-in provider in Firebase Authentication, download a fresh iOS GoogleService-Info.plist, and replace MeetGrid/GoogleService-Info.plist."
fi

if ! /usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes" "$SOURCE_INFO_PLIST" 2>/dev/null | /usr/bin/grep -Fq "$REVERSED_CLIENT_ID"; then
    fail "MeetGrid/Info.plist must include the Firebase REVERSED_CLIENT_ID URL scheme: ${REVERSED_CLIENT_ID}"
fi
