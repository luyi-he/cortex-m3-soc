# Cortex-M3 SoC 固件项目 - 完成总结

## 项目状态：✅ 完成

创建时间：2026-03-10  
位置：`~/.openclaw/workspace/cortex-m3-soc/firmware/`

---

## 已创建文件

### 核心文件 (7 个)

| 文件 | 大小 | 描述 |
|------|------|------|
| `Makefile` | 2.3KB | GNU Make 构建脚本 |
| `linker.ld` | 2.5KB | 链接脚本 (512KB Flash, 128KB SRAM) |
| `startup.c` | 3.6KB | 启动代码和异常处理 |
| `vector_table.c` | 3.6KB | 中断向量表 (16 个中断) |
| `main.c` | 4.1KB | 主程序和测试框架 |
| `system.c` | 5.1KB | 系统初始化 (时钟 200MHz) |
| `printf.c` | 4.3KB | 轻量级 printf 实现 |

### 外设驱动 (8 个)

| 文件 | 大小 | 描述 |
|------|------|------|
| `drivers/gpio.h` | 2.9KB | GPIO 头文件 |
| `drivers/gpio.c` | 4.7KB | GPIO 驱动实现 |
| `drivers/uart.h` | 2.4KB | UART 头文件 |
| `drivers/uart.c` | 3.8KB | UART 驱动实现 |
| `drivers/timer.h` | 3.2KB | Timer 头文件 |
| `drivers/timer.c` | 3.7KB | Timer 驱动实现 |
| `drivers/sram.h` | 1.4KB | SRAM 测试头文件 |
| `drivers/sram.c` | 4.7KB | SRAM 测试实现 |

### 测试程序 (4 个)

| 文件 | 大小 | 描述 |
|------|------|------|
| `tests/blinky.c` | 1.0KB | GPIO 闪烁测试 |
| `tests/uart_echo.c` | 0.8KB | UART 回环测试 |
| `tests/memory_test.c` | 1.7KB | SRAM/Flash 完整性测试 |
| `tests/benchmark.c` | 3.0KB | CPU/内存性能测试 |

### 文档 (5 个)

| 文件 | 大小 | 描述 |
|------|------|------|
| `README.md` | 4.9KB | 项目说明和编译指南 |
| `docs/memory_map.md` | 5.5KB | 内存映射详细说明 |
| `docs/TOOLCHAIN_INSTALL.md` | 2.1KB | 工具链安装指南 |
| `docs/QUICK_REFERENCE.md` | 2.3KB | 快速参考卡片 |
| `.gitignore` | 0.2KB | Git 忽略规则 |

**总计**: 24 个文件，约 70KB 代码和文档

---

## 技术规格

### 系统配置

- **CPU**: ARM Cortex-M3 @ 200MHz
- **Flash**: 512KB @ 0x00000000
- **SRAM**: 128KB @ 0x20000000
- **栈大小**: 8KB
- **堆大小**: 4KB

### 时钟配置

```
输入：24MHz (内部 RC) 或 25MHz (外部 OSC)
PLL: 24MHz × 50 / 6 = 200MHz
HCLK: 200MHz (CPU, AHB)
PCLK: 100MHz (APB)
```

### 外设地址

| 外设 | 基地址 | 总线 |
|------|--------|------|
| GPIOA-D | 0x50000000-0x50000C00 | APB |
| UART0-1 | 0x50001000-0x50001400 | APB |
| Timer0-3 | 0x50002000-0x50002C00 | APB |
| RCC | 0x5000A000 | APB |

### 中断向量

| IRQ# | 名称 | 地址偏移 |
|------|------|----------|
| -15 | NMI | 0x08 |
| -14 | HardFault | 0x0C |
| 0 | WDT | 0x3C |
| 1 | UART0 | 0x40 |
| 3 | Timer0 | 0x48 |
| 7 | GPIO | 0x58 |

---

## 编译说明

### 前置要求

安装 GNU Arm Embedded Toolchain:

```bash
# macOS
brew install arm-none-eabi-gcc

# Ubuntu
sudo apt-get install gcc-arm-none-eabi
```

### 编译项目

```bash
cd ~/.openclaw/workspace/cortex-m3-soc/firmware
make
```

输出文件：
- `build/firmware.elf` - ELF 格式（调试用）
- `build/firmware.bin` - 二进制格式（烧录用）
- `build/firmware.hex` - Intel HEX 格式
- `build/firmware.map` - 内存映射
- `build/firmware.lst` - 反汇编列表

### 编译测试程序

```bash
# Blinky 测试
make CSOURCES="startup.c vector_table.c system.c printf.c drivers/gpio.c drivers/uart.c tests/blinky.c"

# Memory Test
make CSOURCES="startup.c vector_table.c system.c printf.c drivers/sram.c drivers/uart.c tests/memory_test.c"
```

---

## 驱动 API 概览

### GPIO 驱动

```c
gpio_init(GPIOA_BASE);
gpio_set_mode(GPIOA_BASE, GPIO_PIN_5, GPIO_MODE_OUTPUT);
gpio_set(GPIOA_BASE, GPIO_PIN_5);      // 输出高
gpio_clear(GPIOA_BASE, GPIO_PIN_5);    // 输出低
gpio_toggle(GPIOA_BASE, GPIO_PIN_5);   // 翻转
bool val = gpio_read(GPIOA_BASE, GPIO_PIN_5);
```

### UART 驱动

```c
uart_init(UART0_BASE, 115200);
uart_tx(UART0_BASE, 'A');              // 发送字符
char c = uart_rx(UART0_BASE);          // 接收字符
if (uart_rx_ready(UART0_BASE)) { ... } // 检查接收就绪
printf("Value: %d\n", 42);             // 格式化输出
```

### Timer 驱动

```c
timer_init(Timer0);
timer_start(Timer0);
uint32_t val = timer_read(Timer0);     // 读取计数值
timer_delay_ms(Timer0, 100);           // 毫秒延时
timer_set_prescaler(Timer0, 99);       // 设置预分频
```

### SRAM 测试

```c
sram_result_t result = sram_test((uint32_t*)0x20000000, 0x20000);
if (result.passed) {
    printf("SRAM test PASSED\n");
} else {
    printf("Error at 0x%08X\n", result.error_addr);
}
```

---

## 项目结构

```
firmware/
├── Makefile                  # 构建脚本
├── linker.ld                 # 链接脚本
├── startup.c                 # 启动代码
├── vector_table.c            # 中断向量表
├── main.c                    # 主程序
├── system.c                  # 系统初始化
├── printf.c                  # 轻量级 printf
├── .gitignore                # Git 忽略
├── README.md                 # 项目说明
├── drivers/
│   ├── gpio.h/.c             # GPIO 驱动
│   ├── uart.h/.c             # UART 驱动
│   ├── timer.h/.c            # Timer 驱动
│   └── sram.h/.c             # SRAM 测试
├── tests/
│   ├── blinky.c              # GPIO 闪烁测试
│   ├── uart_echo.c           # UART 回环测试
│   ├── memory_test.c         # 内存测试
│   └── benchmark.c           # 性能测试
└── docs/
    ├── memory_map.md         # 内存映射
    ├── TOOLCHAIN_INSTALL.md  # 工具链安装
    └── QUICK_REFERENCE.md    # 快速参考
```

---

## 下一步

### 1. 安装工具链

参考 `docs/TOOLCHAIN_INSTALL.md` 安装 GNU Arm Embedded Toolchain。

### 2. 编译验证

```bash
cd ~/.openclaw/workspace/cortex-m3-soc/firmware
make clean
make
```

### 3. 烧录测试

使用 OpenOCD 或 J-Link 烧录到 FPGA/ASIC 验证平台。

### 4. 扩展驱动

根据架构文档添加更多外设驱动：
- I2C 驱动
- SPI 驱动
- ADC 驱动
- DMA 驱动
- RTC 驱动
- WDT 驱动

### 5. 添加 RTOS

移植 FreeRTOS 或 RT-Thread:
```bash
# 创建 RTOS 目录
mkdir -p rtos/FreeRTOS
# 移植 Port 层 (port.c, portmacro.h)
```

---

## 参考文档

- [Cortex-M3 SoC 架构规格 v1.0](../arch/arch_spec_v1.0.md)
- [ARM Cortex-M3 Technical Reference Manual](https://developer.arm.com/documentation/ddi0337/latest/)
- [GNU Arm Embedded Toolchain](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm)

---

**项目创建完成！🎉**

所有源代码、驱动、测试程序和文档已就绪。安装工具链后即可编译运行。
