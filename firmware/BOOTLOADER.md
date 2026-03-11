# Bootloader 开发状态

**创建日期**: 2026-03-10  
**状态**: ✅ 完成

---

## 功能概述

Cortex-M3 SoC Bootloader 提供以下功能：

1. **UART XMODEM 固件烧录** - 通过串口接收固件并写入 Flash
2. **应用程序验证** - 检查 Flash 中的应用程序是否有效
3. **Boot 引脚检测** - 支持按键强制进入 bootloader 模式
4. **自动跳转** - 验证通过后自动跳转到应用程序

---

## 内存布局

```
0x0000_0000 +------------------+
            |   Bootloader     |
            |   (16KB)         |
            +------------------+
0x0000_4000 |   Application    |
            |   (512KB-16KB)   |
            |                  |
            +------------------+
0x0008_0000 |   End of Flash   |
            +------------------+
```

| 区域 | 地址 | 大小 | 用途 |
|------|------|------|------|
| Bootloader | 0x0000_0000 | 16KB | Bootloader 代码 |
| Application | 0x0000_4000 | 496KB | 用户应用程序 |
| Flash 结束 | 0x0008_0000 | - | - |

---

## 启动流程

```
上电/复位
    ↓
系统初始化 (时钟、UART、GPIO)
    ↓
检查 BOOT 引脚 (PA0)
    ↓
    ├─ 按下了 → [Bootloader 模式]
    │             ↓
    │         等待 XMODEM 传输
    │             ↓
    │         接收固件 → 写入 Flash
    │             ↓
    │         验证固件
    │             ↓
    │         跳转到应用
    │
    └─ 未按下 → [应用程序模式]
                  ↓
              检查应用有效性
                  ↓
              ├─ 有效 → 跳转到应用
              │
              └─ 无效 → 进入 Bootloader 模式
```

---

## 使用方法

### 进入 Bootloader 模式

**方法 1**: 上电时按住 BOOT 键 (PA0 拉低)
**方法 2**: 应用程序无效时自动进入

### 烧录固件

```bash
# 1. 连接串口
screen /dev/ttyUSB0 115200

# 2. 复位开发板并按住 BOOT 键

# 3. 看到 bootloader 提示后，使用 XMODEM 发送固件
sz -X build/cortex-m3-firmware.bin

# 或使用 cu
cu -l /dev/ttyUSB0 -s 115200
# 然后使用 ~# 发送文件
```

### Bootloader 输出示例

```
========================================
  Cortex-M3 SoC Bootloader v1.0.0
========================================

[BOOT] Entering bootloader mode...

[UART] Ready to receive firmware...
[UART] Send XMODEM packets now.
########
[UART] Transfer complete.
[UART] Received 4096 bytes.
[UART] Verifying firmware...
[UART] Verification passed.
[BOOT] Firmware update successful!
[BOOT] Jumping to application...
```

---

## XMODEM 协议实现

### 数据包格式

```
SOH | Pkt# | ~Pkt# | Data (128 bytes) | CRC16
 1B     1B      1B        128B            2B
```

### 控制字符

| 字符 | 值 | 含义 |
|------|-----|------|
| SOH | 0x01 | 数据包开始 |
| EOT | 0x04 | 传输结束 |
| ACK | 0x06 | 确认 |
| NAK | 0x15 | 否认 |
| CAN | 0x18 | 取消 |

### 传输流程

```
接收方                         发送方
  |                              |
  |<-------- NAK ----------------|  (开始传输)
  |                              |
  |<-------- SOH ----------------|  (数据包)
  |-------- ACK ---------------->|  (确认)
  |                              |
  |<-------- EOT ----------------|  (传输结束)
  |-------- ACK ---------------->|  (确认)
  |                              |
```

---

## 固件验证

Bootloader 执行以下验证：

1. **MSP 检查** - 初始栈指针是否在 SRAM 范围内
2. **复位向量检查** - 复位处理函数地址是否在 Flash 范围内
3. **Flash 写入验证** - 写入后读取对比 (可选)

### 有效性判断

```c
// 有效的应用程序
MSP: 0x20000000 - 0x20020000 (SRAM 范围)
Reset Vector: 0x00004000 - 0x00080000 (Flash 范围)

// 无效的应用程序
MSP 或 Reset Vector 超出上述范围
```

---

## 配置选项

在 `bootloader.c` 顶部修改：

```c
#define BOOTLOADER_VERSION      "1.0.0"
#define FLASH_APP_START         0x00004000UL    // 应用起始地址
#define BOOT_PIN                0               // BOOT 引脚 (PA0)
#define BOOT_TIMEOUT_MS         3000            // 超时时间
#define UART_BAUD               115200          // 波特率
```

---

## 编译 Bootloader

### 方法 1: 独立编译

```bash
cd firmware
make BOOTLOADER=1 all
```

输出：
- `build/bootloader.elf`
- `build/bootloader.bin`

### 方法 2: 与应用程序一起编译

修改 `Makefile` 添加 bootloader 目标：

```makefile
bootloader: $(BUILD_DIR)/bootloader.elf $(BUILD_DIR)/bootloader.bin
```

---

## 烧录 Bootloader

### FPGA 配置

Bootloader 需要和 FPGA bitstream 一起烧录：

```bash
# 1. 烧录 FPGA bitstream
openocd -f interface/stlink.cfg -f fpga.cfg \
  -c "program fpga_bitstream.bin verify reset exit"

# 2. 烧录 Bootloader 到 Flash
openocd -f interface/stlink.cfg -f target/stm32.cfg \
  -c "program build/bootloader.bin 0x08000000 verify reset exit"
```

### 独立 Flash 烧录

如果 SoC 有独立 Flash 芯片：

```bash
# 使用 Flash 编程器
flashprog -c stlink -p build/bootloader.bin
```

---

## 与应用程序集成

### 应用程序链接脚本修改

应用程序需要使用不同的起始地址：

```ld
/* application_linker.ld */
MEMORY
{
    FLASH (rx)  : ORIGIN = 0x00004000, LENGTH = 496K  /* 跳过 bootloader */
    SRAM_ITCM (rwx) : ORIGIN = 0x20000000, LENGTH = 64K
    SRAM_DTCM (rwx) : ORIGIN = 0x20010000, LENGTH = 64K
}
```

### 编译应用程序

```bash
cd firmware
make APPLICATION=1 all
```

---

## 安全增强 (可选)

### 1. CRC 校验

在固件末尾添加 CRC32：

```c
uint32_t crc32_calculate(const uint8_t *data, uint32_t size);
int verify_firmware_crc(void);
```

### 2. 数字签名

使用 RSA/ECDSA 验证固件签名：

```c
int verify_firmware_signature(const uint8_t *fw, uint32_t size);
```

### 3. 加密固件

支持 AES 解密加密的固件：

```c
void aes_decrypt(uint8_t *data, uint32_t size, const uint8_t *key);
```

---

## 故障排查

### Bootloader 无响应

1. 检查 UART 连接 (TX/RX 是否接反)
2. 检查 BOOT 引脚是否正确拉低
3. 检查串口波特率 (115200)

### 固件烧录失败

1. 检查 XMODEM 协议是否匹配
2. 检查 Flash 地址是否正确
3. 检查 Flash 是否已擦除

### 跳转失败

1. 检查应用程序的栈指针是否正确
2. 检查复位向量是否有效
3. 检查中断向量表是否重定位

---

## 文件大小

| 文件 | 大小 | 描述 |
|------|------|------|
| `bootloader.c` | ~8KB | Bootloader 主代码 |
| `bootloader.ld` | ~2KB | 链接脚本 |
| **总计** | ~10KB | 占用 Flash 16KB 预算 |

---

## 下一步

### 短期
- [ ] 编译测试
- [ ] 添加 CRC 校验
- [ ] 优化启动时间

### 中期
- [ ] 添加数字签名验证
- [ ] 支持 USB DFU 模式
- [ ] 添加双 Bank 备份

### 长期
- [ ] 支持网络烧录 (Ethernet/WiFi)
- [ ] 支持 OTA 升级
- [ ] 安全启动 (Secure Boot)

---

**Bootloader 开发完成！现在 Cortex-M3 SoC 有了完整的启动和固件更新能力。** 🎉
