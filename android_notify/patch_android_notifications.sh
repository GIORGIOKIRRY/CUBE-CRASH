#!/bin/zsh
# Aggancia le notifiche locali Android al custom build Godot (android/build/), che è
# gitignored/rigenerabile. Da chiamare PRIMA di --export-release nella pipeline (build_aab.sh).
# Uso: patch_android_notifications.sh <path_android/build> <path_android_notify_dir>
set -e
BUILD="$1"; SRC="$2"
DST="$BUILD/src/com/godot/game"
mkdir -p "$DST"
cp "$SRC/CCNotifyProvider.java" "$DST/CCNotifyProvider.java"
cp "$SRC/CCNotifyReceiver.java" "$DST/CCNotifyReceiver.java"

MAN="$BUILD/AndroidManifest.xml"
# permessi (una volta, prima di <application)
if ! grep -q "POST_NOTIFICATIONS" "$MAN"; then
	perl -0777 -i -pe 's{(\n\s*<application)}{\n    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />\n    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />\n$1}' "$MAN"
fi
# provider + receiver (una volta, prima di </application>)
if ! grep -q "CCNotifyProvider" "$MAN"; then
	perl -0777 -i -pe 's{(\n\s*</application>)}{\n        <provider android:name=".CCNotifyProvider" android:authorities="\${applicationId}.ccnotify" android:exported="false" />\n        <receiver android:name=".CCNotifyReceiver" android:exported="false"><intent-filter><action android:name="android.intent.action.BOOT_COMPLETED" /></intent-filter></receiver>\n$1}' "$MAN"
fi
echo "notifiche Android agganciate al custom build"
