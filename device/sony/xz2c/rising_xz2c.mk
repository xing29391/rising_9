#
# Copyright (C) 2018-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from xz2c device
$(call inherit-product, device/sony/xz2c/device.mk)

# Inherit some common Rising stuff.
# Must be set before the inherit below: common_full_phone.mk picks the gms_*.mk
# flavor at inherit time. The 4,227,858,432-byte Sony system partition leaves
# 3968 MB for files, and product+system_ext are merged into system here, so the
# full GApps set (4995 MB tree) does not fit; pico trims ~1206 MB of preinstalled
# Google apps that Play Store can install on demand.
TARGET_USES_PICO_GAPPS := true
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)
$(call inherit-product, vendor/rising/config/rising.mk)

# Keep adb root on userdebug for on-device bring-up debugging.
# Must be empty: soong's add_json_bool treats any non-empty value as true.
PRODUCT_NOT_DEBUGGABLE_IN_USERDEBUG :=

PRODUCT_NAME := rising_xz2c
PRODUCT_DEVICE := xz2c
PRODUCT_MANUFACTURER := Sony
PRODUCT_BRAND := Sony
PRODUCT_MODEL := Xperia XZ2 Compact

PRODUCT_GMS_CLIENTID_BASE := android-sony

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="H8324-user 10 52.1.A.3.49 052001A003004902006556692 release-keys" \
    BuildFingerprint=Sony/H8324/H8324:10/52.1.A.3.49/052001A003004902006556692:user/release-keys
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false
