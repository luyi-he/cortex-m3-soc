/**
 * @file system.c
 * @brief Cortex-M3 SoC 系统初始化
 */

#include "cortex_m3.h"

/* 系统时钟频率 (200MHz) */
#define SYSTEM_CORE_CLOCK   200000000UL

/**
 * @brief 系统初始化
 */
void System_Init(void)
{
    /* 使能外设时钟 */
    RCC->AHB1ENR |= (1 << 0);  // GPIOA
    RCC->AHB1ENR |= (1 << 1);  // GPIOB
    RCC->AHB1ENR |= (1 << 2);  // GPIOC
    RCC->AHB1ENR |= (1 << 3);  // GPIOD
    
    RCC->APB1ENR |= (1 << 0);  // UART0
    RCC->APB1ENR |= (1 << 2);  // TIMER0
    RCC->APB1ENR |= (1 << 3);  // TIMER1
}

/**
 * @brief 微秒级延时
 * @param us 延时微秒数
 */
__attribute__((used)) void Delay_us(uint32_t us)
{
    uint32_t count = us * (SYSTEM_CORE_CLOCK / 1000000 / 4);
    while (count--);
}

/**
 * @brief 毫秒级延时
 * @param ms 延时毫秒数
 */
__attribute__((used)) void Delay_ms(uint32_t ms)
{
    while (ms--) {
        Delay_us(1000);
    }
}

/**
 * @brief 获取系统时间 (ms)
 * @return 系统运行时间 (毫秒)
 */
uint32_t millis(void)
{
    static uint32_t count = 0;
    return count++;
}
