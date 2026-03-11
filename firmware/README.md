# Cortex-M3 SoC Firmware

固件项目用于 Cortex-M3 SoC，基于 GNU Arm Embedded Toolchain。

## 项目结构

```
firmware/
├── Makefile              # 构建脚本
├── linker.ld             # 链接脚本
├── startup.c             # 启动代码
├── vector_table.c        # 中断向量表
├── main.c                # 主程序
├── system.c              # 系统初始化
├── printf.c              # 轻量级 printf
├── drivers/              # 外设驱动
│   ├── gpio.h/.c         # GPIO 驱动
│   ├── uart.h/.c         # UART 驱动
│   ├── timer.h/.c        # 定时器驱动
│   └── sram.h/.c         # SRAM 测试
├── tests/                # 测试程序
│   ├── blinky.c          # GPIO 闪烁测试
│   ├── uart_echo.c       # UART 回环测试
│   ├── memory_test.c     # 内存测试
│   └── benchmark.c       # 性能测试
└── docs/                 # 文档
    ├── README.md         # 本文件
    └── memory_map.md     # 内存映射
```

## 系统要求

### 工具链

- **GNU Arm Embedded Toolchain** (GCC for ARM)
  - macOS: `brew install arm-none-eabi-gcc`
  - Ubuntu: `sudo apt-get install gcc-arm-none-eabi`
  - Windows: 从 [ARM 官网](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm) 下载

- **OpenOCD** (可选，用于烧录)
  - macOS: `brew install openocd`
  - Ubuntu: `sudo apt-get install openocd`

## 编译

### 默认编译

```bash
cd firmware
make
```

输出文件：
- `build/firmware.elf` - ELF 格式（用于调试）
- `build/firmware.bin` - 二进制格式（用于烧录）
- `build/firmware.hex` - Intel HEX 格式
- `build/firmware.lst` - 反汇编列表

### 编译选项

```bash
# Debug 版本（带调试信息，无优化）
make DEBUG=1

# 清理构建
make clean

# 查看代码大小
make size
```

### 编译测试程序

```bash
# Blinky 测试
make CSOURCES="startup.c vector_table.c system.c printf.c drivers/gpio.c drivers/uart.c tests/blinky.c"

# UART Echo 测试
make CSOURCES="startup.c vector_table.c system.c printf.c drivers/uart.c tests/uart_echo.c"

# Memory Test
make CSOURCES="startup.c vector_table.c system.c printf.c drivers/sram.c drivers/uart.c tests/memory_test.c"

# Benchmark
make CSOURCES="startup.c vector_table.c system.c printf.c drivers/timer.c drivers/uart.c tests/benchmark.c"
```

## 烧录

### 使用 OpenOCD + ST-Link

```bash
make flash
```

或手动烧录：

```bash
openocd -f interface/stlink.cfg -f target/stm32f1x.cfg \
  -c "program build/firmware.elf verify reset exit"
```

### 使用 J-Link

```bash
JLinkExe -device Cortex-M3 -speed 4000 -if SWD -AutoConnect 1
```

然后在 J-Link 命令行中：

```
loadfile build/firmware.bin 0x00000000
r
go
exit
```

## 调试

### 使用 GDB

```bash
make debug
```

或手动连接：

```bash
# 终端 1: 启动 OpenOCD
openocd -f interface/stlink.cfg -f target/stm32f1x.cfg

# 终端 2: 连接 GDB
arm-none-eabi-gdb build/firmware.elf
(gdb) target remote :3333
(gdb) monitor reset halt
(gdb) load
(gdb) continue
```

### 常用 GDB 命令

```
(gdb) break main          # 在 main 函数设置断点
(gdb) continue            # 继续执行
(gdb) next                # 单步执行
(gdb) step                # 单步进入
(gdb) info registers      # 查看寄存器
(gdb) x/10x 0x20000000    # 查看内存
```

## 运行测试

### Blinky 测试

闪烁 GPIOA Pin 5，验证 GPIO 功能。

```bash
make CSOURCES="startup.c vector_table.c system.c printf.c drivers/gpio.c drivers/uart.c tests/blinky.c"
make flash
```

### UART Echo 测试

回环测试，发送的字符会被返回。

```bash
make CSOURCES="startup.c vector_table.c system.c printf.c drivers/uart.c tests/uart_echo.c"
make flash
```

使用串口终端连接（115200 8N1）：
```bash
screen /dev/ttyUSB0 115200
# 或
minicom -D /dev/ttyUSB0 -b 115200
```

### Memory Test

测试 SRAM 和 Flash 完整性。

```bash
make CSOURCES="startup.c vector_table.c system.c printf.c drivers/sram.c drivers/uart.c tests/memory_test.c"
make flash
```

### Benchmark

性能测试，测量 CPU 和内存带宽。

```bash
make CSOURCES="startup.c vector_table.c system.c printf.c drivers/timer.c drivers/uart.c tests/benchmark.c"
make flash
```

## 内存布局

| 区域 | 地址范围 | 大小 | 描述 |
|------|----------|------|------|
| Flash | 0x00000000 - 0x0007FFFF | 512KB | 代码和常量 |
| SRAM | 0x20000000 - 0x2001FFFF | 128KB | 数据和栈 |

详细内存映射见 `docs/memory_map.md`。

## 外设地址

| 外设 | 基地址 | 描述 |
|------|--------|------|
| GPIOA | 0x50000000 | GPIO 端口 A |
| GPIOB | 0x50000400 | GPIO 端口 B |
| UART0 | 0x50001000 | UART 通道 0 |
| Timer0 | 0x50002000 | 定时器 0 |

详细寄存器定义见 `arch/arch_spec_v1.0.md`。

## 中断向量表

| IRQ | 名称 | 描述 |
|-----|------|------|
| 0 | WDT | 看门狗中断 |
| 1 | UART0 | UART0 中断 |
| 2 | UART1 | UART1 中断 |
| 3 | Timer0 | 定时器 0 |
| 7 | GPIO | GPIO 中断 |

完整列表见 `vector_table.c`。

## 常见问题

### 编译错误：`arm-none-eabi-gcc: command not found`

安装 ARM 工具链：
```bash
# macOS
brew install arm-none-eabi-gcc

# Ubuntu
sudo apt-get install gcc-arm-none-eabi
```

### 烧录失败

检查：
1. ST-Link/J-Link 连接是否正常
2. 目标板供电是否正常
3. SWD 接线是否正确（SWDIO, SWCLK, GND, VCC）

### 串口无输出

检查：
1. 波特率是否匹配（115200）
2. TX/RX 是否接反
3. 串口设备名是否正确（`/dev/ttyUSB0` 或 `/dev/cu.usbserial-*`）

## 参考文档

- [Cortex-M3 SoC 架构规格](../arch/arch_spec_v1.0.md)
- [ARM Cortex-M3 Technical Reference Manual](https://developer.arm.com/documentation/ddi0337/latest/)
- [GNU Arm Embedded Toolchain](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm)

## 许可证

MIT License
