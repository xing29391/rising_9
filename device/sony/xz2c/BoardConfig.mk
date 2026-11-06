#
# Copyright (C) 2018-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from tama-common
-include device/sony/tama-common/BoardConfigCommon.mk

DEVICE_PATH := device/sony/xz2c

# Display
TARGET_SCREEN_DENSITY := 480

# Kernel
TARGET_KERNEL_CONFIG := tama_apollo_defconfig

# HIDL
DEVICE_MANIFEST_FILE += $(DEVICE_PATH)/manifest.xml

# Partitions
BOARD_USERDATAIMAGE_PARTITION_SIZE := 51448807424

# Properties
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop

# Inherit from the proprietary version
-include vendor/sony/xz2c/BoardConfigVendor.mk
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

# The vendor graphics blobs only implement the legacy gralloc mapper (2.x/3.x).
# A17 libui requires gralloc 4+ when ro.board.api_level >= 36, so opt back in to
# the legacy mapper fallback (system + vendor variants of libui).
$(call soong_config_set_bool,libui,legacy_gralloc,true)

# build/make only includes vendor/lineage's board config when LINEAGE_BUILD is
# set, which happens solely for lineage_* lunch targets. RisingOS lunches
# rising_xz2c, so pull it in here (after TARGET_KERNEL_CONFIG) to get the
# kernel build variables and their Soong exports.
ifeq ($(LINEAGE_BUILD),)
include vendor/lineage/config/BoardConfigLineage.mk
$(eval include device/lineage/sepolicy/common/sepolicy.mk)
endif

# The newest AOSP clang that Lineage defaults the kernel to treats QCACLD's
# `return A_ERROR;` inside QDF_STATUS-typed functions as a hard
# -Wimplicit-enum-enum-cast error; keep it a warning for these legacy drivers.
KERNEL_MAKE_FLAGS += KCFLAGS=-Wno-error=implicit-enum-enum-cast
