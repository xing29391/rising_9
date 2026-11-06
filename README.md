# RisingOS Revived 9.0 — Sony Xperia XZ2 Compact (xz2c / apollo)

RisingOS Revived 9.0（Android 17，`seventeen` = lineage-24.0 分支）在 Xperia XZ2 Compact
（`xz2c`，代号 apollo，H8324，sdm845，内核 4.9.337-perf+）上的移植与修复代码。

系统已可完整启动并保持 SELinux **Enforcing**：GMS、相机（前后置静态照片）、VoLTE 通话、
蓝牙、GNSS 均已在真机验证。

## 目录结构

```
device/sony/xz2c/          设备树（BoardConfig、device.mk、overlay、fstab、init 脚本等）
device/sony/tama-common/   平台公共树（含本次 SELinux 修复：socket_ioctl.te 等）
patches/
  0001-lineage-sepolicy-hidl-touch.patch        lineage sepolicy：HIDL 触摸 HAL 的 hwservice 定义
  0002-qcom-sepolicy-bluetooth-bdaddr.patch     qcom sepolicy：蓝牙工厂 MAC 读取权限
  kernel/0001-4.9-backports-wipeonfork-nlmsg.patch
                                              内核 4.9 回移：MADV_WIPEONFORK + SELinux NLMSG xperms
docs/KERNEL-4.9-feature-backports.md           4.9 内核可回移特性分析
scripts/push-risingwalls.sh                    通过 adb 部署已修补 RisingWalls APK
artifacts/RisingWalls-patched.apk              去除 Glide 依赖的 RisingWalls
```

## 关键修复

### 1. GNSS / QMI（`device/sony/tama-common/sepolicy/vendor/socket_ioctl.te`）

`sdm845` 上的 QMI 守护进程在首次 `read` 之前就需要操作 socket，而 `qmi_cci` 用守护进程
自身的标签创建控制 socket。缺少 `create` 时 GNSS 客户端始终无法初始化
（`qmi_client_notifier_init -16`、`qmi_cci_xport_ctrl_port_init` 报 `-13 EACCES`，
每秒重试一次）。现为 `vendor_location` / `vendor_hal_gnss_qti` 补齐
`create ioctl write getattr setopt getopt connect`，并给 `vendor_cnd`、`vendor_ims`、
`vendor_time_daemon`、`vendor_qti` 补上必要的 `read` / `ioctl`。

修复后 `dumpsys location` 可读到 `qcom;MPSS.AT.4.0.c2.16-00052-SDM845_GEN_PACK-1`，
GNSS 不再产生 AVC 拒绝。

### 2. 蓝牙工厂 MAC（`patches/0002`）

Sony 把出厂 BD 地址存放在 `/data/vendor/etc/bluetooth_bdaddr`（由 `taimport_vendor` 写入，
标签 `bluetooth_vendor_data_file`，位于 `/data`）。BT HAL（`hal_bluetooth_default`）没有
读权限时会回退到随机生成的地址。补一条 `r_file_perms` 后，
`settings get secure bluetooth_address` 与文件中记录的地址一致。

### 3. HIDL 触摸 HAL（`patches/0001`）

`vendor.lineage.touch@1.0-service` 通过 `hwservicemanager` 注册 `IGloveMode`，需要
`hal_lineage_touch_hwservice` 类型、contexts 映射和 `hal_attribute_hwservice` 关联。

### 4. 内核 4.9 回移（`patches/kernel`）

- `MADV_WIPEONFORK` / `MADV_KEEPONFORK`：`dup_mmap()` 中带该标志的 VMA 不建立 anon_vma、
  不复制页表，从 Android 10 起 bionic 的 `pthread_atfork` 依赖它。
- SELinux `AVTAB_XPERMS_NLMSG`（0x03）：兼容新版 `secilc` 生成含 netlink 扩展权限的
  vendor policy，避免 `avtab_read_item` 解析失败。

## 应用补丁

`device/sony/*` 已包含全部修复，直接覆盖到源码树即可。其余补丁按各自仓库根目录应用：

```bash
git -C device/lineage/sepolicy      apply /path/to/patches/0001-lineage-sepolicy-hidl-touch.patch
git -C device/qcom/sepolicy_vndr    apply /path/to/patches/0002-qcom-sepolicy-bluetooth-bdaddr.patch
git -C kernel/sony/sdm845           apply /path/to/patches/kernel/0001-4.9-backports-wipeonfork-nlmsg.patch
```

## 构建

```bash
source build/envsetup.sh
lunch rising_xz2c-userdebug
m
```

修改已有 `.te` 文件后只需重建 vendor policy，避免完整的 Soong 分析：

```bash
prebuilts/build-tools/linux-x86/bin/ninja -f out/combined-rising_xz2c.ninja \
    out/target/product/xz2c/vendor/etc/selinux/vendor_sepolicy.cil
```

## 注意事项

- `/system/bin/init` 为预编译二进制，**不要修改**；所有 init 改动都在 `.rc` / ramdisk。
- stock TWRP 刷入时 `system.img` 是 Android sparse 格式，需先 `simg2img` 再 `dd`。
- `docs/KERNEL-4.9-feature-backports.md` 记录了 4.9 树中已有特性、建议回移项
  （userfaultfd、MADV_COLD/PAGEOUT、zstd、BBR、statx/clone3 等）以及不建议移植的部分
  （MGLRU、io_uring、GKI、sched_ext 等）。
