/**
 * @file examples.c
 * @brief 示例程序集合
 */

#include "cortex_m3.h"

/* ============================================================================
 * 示例 1: UART Echo
 * 接收到的字符原样发送回去
 * ============================================================================ */

void example_uart_echo(void)
{
    /* 初始化 UART0 (115200 8N1) */
    UART_Init(UART0, 115200);
    
    UART_Puts(UART0, "Cortex-M3 UART Echo Test\r\n");
    UART_Puts(UART0, "Type anything: ");
    
    while (1) {
        if (UART_Available(UART0)) {
            char c = UART_Getc(UART0);
            UART_Putc(UART0, c);  // Echo back
        }
    }
}

/* ============================================================================
 * 示例 2: SRAM 内存测试
 * 测试 ITCM 和 DTCM 的读写功能
 * ============================================================================ */

#include <stdint.h>
#include <string.h>

#define TEST_PATTERN1   0xDEADBEEF
#define TEST_PATTERN2   0xCAFEBABE

int example_memory_test(void)
{
    volatile uint32_t *sram = (volatile uint32_t *)SRAM_ITCM_BASE;
    int errors = 0;
    
    UART_Puts(UART0, "SRAM Memory Test\r\n");
    UART_Puts(UART0, "==============\r\n");
    
    /* 测试 1: 写入并读取 */
    UART_Puts(UART0, "Test 1: Write/Read... ");
    for (int i = 0; i < 256; i++) {
        sram[i] = TEST_PATTERN1;
    }
    
    for (int i = 0; i < 256; i++) {
        if (sram[i] != TEST_PATTERN1) {
            errors++;
        }
    }
    UART_Puts(UART0, errors ? "FAILED\r\n" : "PASSED\r\n");
    
    /* 测试 2: 不同模式 */
    UART_Puts(UART0, "Test 2: Pattern Test... ");
    for (int i = 0; i < 256; i++) {
        sram[i] = (i % 2) ? TEST_PATTERN1 : TEST_PATTERN2;
    }
    
    for (int i = 0; i < 256; i++) {
        uint32_t expected = (i % 2) ? TEST_PATTERN1 : TEST_PATTERN2;
        if (sram[i] != expected) {
            errors++;
        }
    }
    UART_Puts(UART0, errors ? "FAILED\r\n" : "PASSED\r\n");
    
    /* 测试 3: 地址线测试 */
    UART_Puts(UART0, "Test 3: Address Test... ");
    for (int i = 0; i < 256; i++) {
        sram[i] = (uint32_t)&sram[i];
    }
    
    for (int i = 0; i < 256; i++) {
        if (sram[i] != (uint32_t)&sram[i]) {
            errors++;
        }
    }
    UART_Puts(UART0, errors ? "FAILED\r\n" : "PASSED\r\n");
    
    /* 总结 */
    UART_Puts(UART0, "==============\r\n");
    if (errors == 0) {
        UART_Puts(UART0, "All tests PASSED!\r\n");
        return 0;
    } else {
        UART_Puts(UART0, "FAILED: ");
        // 打印错误数 (简化)
        UART_Puts(UART0, " errors\r\n");
        return -1;
    }
}

/* ============================================================================
 * 示例 3: GPIO Blinky
 * 闪烁 LED (PA5)
 * ============================================================================ */

void example_blinky(void)
{
    /* 配置 PA5 为输出 */
    GPIO_Init(GPIO_A, 5, 1);  // 输出模式
    GPIO_SetSpeed(GPIO_A, 5, 2);  // 高速
    
    UART_Puts(UART0, "GPIO Blinky Test\r\n");
    
    while (1) {
        GPIO_Toggle(GPIO_A, 5);
        Delay_ms(500);
    }
}

/* ============================================================================
 * 示例 4: Timer 测试
 * 使用定时器产生精确延时
 * ============================================================================ */

void example_timer(void)
{
    /* 初始化 Timer0 (1ms) */
    Timer_Init(TIMER0, 1);
    Timer_Start(TIMER0);
    
    UART_Puts(UART0, "Timer Test\r\n");
    
    uint32_t last = 0;
    uint32_t count = 0;
    
    while (1) {
        uint32_t now = Timer_GetCounter(TIMER0);
        if (now - last >= 1000) {  // 1 秒
            last = now;
            count++;
            
            /* 切换 LED */
            GPIO_Toggle(GPIO_A, 5);
            
            /* 打印计数 */
            UART_Puts(UART0, "Tick: ");
            // 打印 count (需要完整 printf)
            UART_Puts(UART0, "\r\n");
        }
    }
}
