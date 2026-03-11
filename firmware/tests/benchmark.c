/**
 * @file tests/benchmark.c
 * @brief Performance benchmark
 * @details CPU and memory performance tests
 */

#include <stdint.h>
#include "../drivers/timer.h"
#include "../drivers/uart.h"

/* External functions */
extern void System_Init(void);
extern uint32_t SystemCoreClock_Get(void);
extern int printf(const char *fmt, ...);

/**
 * @brief Dhrystone-like benchmark
 */
static uint32_t benchmark_cpu(void)
{
    volatile uint32_t result = 0;
    uint32_t start, end, cycles;

    start = timer_read(Timer0);
    
    for (volatile uint32_t i = 0; i < 1000000; i++) {
        result += i * 2;
        result ^= result >> 3;
    }
    
    end = timer_read(Timer0);
    cycles = end - start;

    return cycles;
}

/**
 * @brief Memory copy benchmark
 */
static uint32_t benchmark_memcpy(void)
{
    uint32_t *src = (uint32_t *)0x20000000;
    uint32_t *dst = (uint32_t *)0x20004000;
    uint32_t start, end, cycles;
    const uint32_t size = 4096; /* 16KB */

    /* Initialize source */
    for (uint32_t i = 0; i < size; i++) {
        src[i] = i;
    }

    start = timer_read(Timer0);
    
    for (uint32_t i = 0; i < size; i++) {
        dst[i] = src[i];
    }
    
    end = timer_read(Timer0);
    cycles = end - start;

    return cycles;
}

/**
 * @brief Memory fill benchmark
 */
static uint32_t benchmark_memset(void)
{
    uint32_t *buf = (uint32_t *)0x20000000;
    uint32_t start, end, cycles;
    const uint32_t size = 4096; /* 16KB */

    start = timer_read(Timer0);
    
    for (uint32_t i = 0; i < size; i++) {
        buf[i] = 0xDEADBEEF;
    }
    
    end = timer_read(Timer0);
    cycles = end - start;

    return cycles;
}

/**
 * @brief Main entry point
 */
int main(void)
{
    uint32_t cycles;
    float rate;
    uint32_t sysclk;

    System_Init();
    uart_init(UART0_BASE, 115200);

    sysclk = SystemCoreClock_Get();

    printf("\n=== Performance Benchmark ===\n");
    printf("System Clock: %lu Hz (%lu MHz)\n", sysclk, sysclk / 1000000);
    printf("Timer Clock: %lu Hz\n", sysclk / 2);
    printf("\n");

    /* CPU benchmark */
    printf("CPU Benchmark (1M iterations):\n");
    cycles = benchmark_cpu();
    printf("  Cycles: %lu\n", cycles);
    printf("  Cycles/iter: %.2f\n", (float)cycles / 1000000.0f);
    printf("  DMIPS: %.2f\n", (float)sysclk / cycles);
    printf("\n");

    /* Memory copy benchmark */
    printf("Memory Copy Benchmark (16KB):\n");
    cycles = benchmark_memcpy();
    rate = (16384.0f * sysclk) / (cycles * 2.0f);
    printf("  Cycles: %lu\n", cycles);
    printf("  Bandwidth: %.2f MB/s\n", rate / 1000000.0f);
    printf("\n");

    /* Memory fill benchmark */
    printf("Memory Fill Benchmark (16KB):\n");
    cycles = benchmark_memset();
    rate = (16384.0f * sysclk) / (cycles * 4.0f);
    printf("  Cycles: %lu\n", cycles);
    printf("  Bandwidth: %.2f MB/s\n", rate / 1000000.0f);
    printf("\n");

    printf("=== Benchmark Complete ===\n");

    return 0;
}
