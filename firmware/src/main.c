/**
 * @file main.c
 * @brief Cortex-M3 SoC 主程序 - Blinky 示例
 */

#include "cortex_m3.h"

/* LED 引脚 (假设 PA5) */
#define LED_PIN     5
#define LED_PORT    GPIO_A

/**
 * @brief GPIO 初始化
 */
static void GPIO_Init(void)
{
    /* 配置 PA5 为推挽输出 */
    LED_PORT->MODER &= ~(3 << (LED_PIN * 2));
    LED_PORT->MODER |= (1 << (LED_PIN * 2));  // 输出模式
    
    LED_PORT->OTYPER &= ~(1 << LED_PIN);      // 推挽输出
    LED_PORT->OSPEEDR |= (3 << (LED_PIN * 2)); // 高速
    LED_PORT->PUPDR &= ~(3 << (LED_PIN * 2));  // 无上拉下拉
}

/**
 * @brief LED 开关
 */
static void LED_On(void)
{
    LED_PORT->BSRR = (1 << LED_PIN);
}

static void LED_Off(void)
{
    LED_PORT->BSRR = (1 << (LED_PIN + 16));
}

static void LED_Toggle(void)
{
    LED_PORT->ODR ^= (1 << LED_PIN);
}

/**
 * @brief 主函数
 */
int main(void)
{
    /* 系统初始化 */
    System_Init();
    
    /* GPIO 初始化 */
    GPIO_Init();
    
    /* 主循环 */
    while (1) {
        /* LED 闪烁测试 */
        LED_Toggle();
        Delay_ms(500);
        
        LED_Toggle();
        Delay_ms(500);
    }
}
