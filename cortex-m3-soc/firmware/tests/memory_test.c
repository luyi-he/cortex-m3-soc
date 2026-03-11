/**
 * @file tests/memory_test.c
 * @brief Memory test program
 * @details Test SRAM and Flash integrity
 */

#include <stdint.h>
#include "../drivers/sram.h"
#include "../drivers/uart.h"

/* External functions */
extern void System_Init(void);
extern int printf(const char *fmt, ...);
extern void hexdump(const void *data, uint32_t addr, uint32_t size);

/**
 * @brief Main entry point
 */
int main(void)
{
    sram_result_t result;

    System_Init();
    uart_init(UART0_BASE, 115200);

    printf("\n=== Memory Test ===\n\n");

    /* Test SRAM */
    printf("Testing SRAM @ 0x%08X (%d KB)\n", SRAM_BASE, SRAM_SIZE / 1024);
    result = sram_test((uint32_t *)SRAM_BASE, SRAM_SIZE / 4);

    if (result.passed) {
        printf("  Result: PASSED\n");
        printf("  Patterns: 0x00000000, 0xFFFFFFFF, 0xAAAAAAAA, 0x55555555\n");
        printf("  Walking 1: OK\n");
        printf("  Address test: OK\n");
    } else {
        printf("  Result: FAILED\n");
        printf("  Error address: 0x%08X\n", result.error_addr);
        printf("  Expected: 0x%08X\n", result.expected);
        printf("  Actual:   0x%08X\n", result.actual);
    }

    printf("\n");

    /* Test Flash */
    printf("Testing Flash @ 0x%08X (%d KB)\n", FLASH_BASE, FLASH_SIZE / 1024);
    if (flash_test((uint32_t *)FLASH_BASE, 256)) {
        printf("  Result: PASSED (readable)\n");
        
        /* Show first 64 bytes of flash (vector table) */
        printf("\n  Flash content (first 64 bytes):\n");
        hexdump((void *)FLASH_BASE, FLASH_BASE, 64);
    } else {
        printf("  Result: FAILED\n");
    }

    printf("\n=== Test Complete ===\n");

    return 0;
}
