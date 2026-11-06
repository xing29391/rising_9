#!/bin/bash
# Deploy patched RisingWalls.apk to the running RisingOS device.
set -u
ADB="C:/Env/platform-tools/adb.exe"
APK_LOCAL="C:/Users/478717611/Downloads/rom/RisingWalls-patched.apk"
APK_REMOTE="/system/system_ext/priv-app/RisingWalls/RisingWalls.apk"

export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL='*'

"$ADB" root || { echo "FATAL: adb root failed"; exit 1; }
sleep 4
"$ADB" wait-for-device
"$ADB" remount || echo "WARN: remount returned non-zero"
"$ADB" shell "mount | grep -E ' /system_ext | /system ' | head -5"

OLD=$("$ADB" shell "md5sum $APK_REMOTE 2>/dev/null | awk '{print \$1}'" | tr -d '\r')
NEW=$(md5sum "$APK_LOCAL" | awk '{print $1}')
echo "old=$OLD new=$NEW"

"$ADB" shell "rm -rf /system/system_ext/priv-app/RisingWalls/oat"
"$ADB" push "$APK_LOCAL" "$APK_REMOTE" || { echo "FATAL: push failed"; exit 1; }
"$ADB" shell "chmod 644 $APK_REMOTE; chown root:root $APK_REMOTE; restorecon -v $APK_REMOTE; sync"
"$ADB" shell "md5sum $APK_REMOTE; ls -lZ $APK_REMOTE"
