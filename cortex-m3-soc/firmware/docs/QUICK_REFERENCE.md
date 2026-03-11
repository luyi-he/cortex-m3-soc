# 快速参考卡片

## 编译命令

```bash
# 默认编译
make

# Debug 版本
make DEBUG=1

# 清理
make clean

# 查看大小
make size
```

## 烧录命令

```bash
# ST-Link
make flash

# 手动烧录
openocd -f interface/stlink.cfg -f target/stm32f1x.cfg \
  -c "program build/firmware.elf verify reset exit"
```

## 调试命令

```bash
# 启动调试
make debug

# GDB 连接
arm-none-eabi-gdb build/firmware.elf
(gdb) target remote :3333
(gdb) monitor reset halt
(gdb) load
```

## 关键地址

| 外设 | 地址 |
|------|------|
| GPIOA | 0x50000000 |
| UART0 | 0x50001000 |
| Timer0 | 0x50002000 |
| SRAM | 0x20000000 |
| Flash | 0x00000000 |

## 常用寄存器

### GPIO (0x50000000)

| 偏移 | 名称 | 描述 |
|------|------|------|
| 0x00 | MODER | 模式 |
| 0x14 | ODR | 输出数据 |
| 0x18 | BSRR | 置位/复位 |

### UART (0x50001000)

| 偏移 | 名称 | 描述 |
|------|------|------|
| 0x00 | CR1 | 控制 1 |
| 0x0C | BRR | 波特率 |
| 0x14 | DR | 数据 |

## 系统时钟

- HCLK: 200MHz (CPU)
- PCLK: 100MHz (APB 外设)
- 源：PLL (24MHz * 50 / 6)

## 中断向量

```
0x00: MSP (栈顶)
0x04: Reset_Handler
0x08: NMI_Handler
0x0C: HardFault_Handler
0x3C: WDT_Handler
0x40: UART0_Handler
```

## 内存大小

- Flash: 512KB
- SRAM: 128KB
- 栈：8KB
- 堆：4KB

## 驱动 API

### GPIO

```c
gpio_init(GPIOA_BASE);
gpio_set_mode(GPIOA_BASE, GPIO_PIN_5, GPIO_MODE_OUTPUT);
gpio_set(GPIOA_BASE, GPIO_PIN_5);
gpio_clear(GPIOA_BASE, GPIO_PIN_5);
gpio_toggle(GPIOA_BASE, GPIO_PIN_5);
```

### UART

```c
uart_init(UART0_BASE, 115200);
uart_tx(UART0_BASE, 'A');
char c = uart_rx(UART0_BASE);
printf("Value: %d\n", value);
```

### Timer

```c
timer_init(Timer0);
timer_start(Timer0);
uint32_t val = timer_read(Timer0);
timer_delay_ms(Timer0, 100);
```

### SRAM Test

```c
sram_result_t result = sram_test((uint32_t*)0x20000000, 0x20000);
if (result.passed) {
    printf("Test PASSED\n");
}
```

## 测试程序

| 程序 | 功能 |
|------|------|
| blinky | GPIO 闪烁 |
| uart_echo | UART 回环 |
| memory_test | 内存测试 |
| benchmark | 性能测试 |

## 编译测试程序

```bash
# Blinky
make CSOURCES="startup.c vector_table.c system.c printf.c drivers/gpio.c drivers/uart.c tests/blinky.c"

# UART Echo
make CSOURCES="startup.c vector_table.c system.c printf.c drivers/uart.c tests/uart_echo.c"

# Memory Test
make CSOURCES="startup.c vector_table.c system.c printf.c drivers/sram.c drivers/uart.c tests/memory_test.c"

# Benchmark
make CSOURCES="startup.c vector_table.c system.c printf.c drivers/timer.c drivers/uart.c tests/benchmark.c"
```
