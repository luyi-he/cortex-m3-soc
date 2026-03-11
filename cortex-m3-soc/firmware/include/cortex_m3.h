/**
 * @file cortex_m3.h
 * @brief Cortex-M3 SoC 内存映射和寄存器定义
 * 根据 arch_spec_v1.0.md 定义
 */

#ifndef __CORTEX_M3_H
#define __CORTEX_M3_H

#include <stdint.h>

/* ============================================================================
 * 系统配置
 * ============================================================================ */

#define SYSTEM_CORE_CLOCK       200000000UL     /*!< 系统核心时钟：200MHz */

/* ============================================================================
 * 系统函数声明
 * ============================================================================ */

extern void Delay_us(uint32_t us);
extern void Delay_ms(uint32_t ms);

/* ============================================================================
 * 内存映射
 * ============================================================================ */

#define FLASH_BASE      0x00000000UL
#define SRAM_BASE       0x20000000UL
#define SRAM_ITCM_BASE  0x20000000UL
#define SRAM_DTCM_BASE  0x20010000UL
#define APB_PP_BASE     0x50000000UL
#define PPB_BASE        0xE0000000UL

/* ============================================================================
 * APB 外设基地址
 * ============================================================================ */

#define GPIO_A_BASE     (APB_PP_BASE + 0x0000)
#define GPIO_B_BASE     (APB_PP_BASE + 0x0400)
#define GPIO_C_BASE     (APB_PP_BASE + 0x0800)
#define GPIO_D_BASE     (APB_PP_BASE + 0x0C00)

#define UART0_BASE      (APB_PP_BASE + 0x1000)
#define UART1_BASE      (APB_PP_BASE + 0x1400)

#define TIMER0_BASE     (APB_PP_BASE + 0x2000)
#define TIMER1_BASE     (APB_PP_BASE + 0x2400)
#define TIMER2_BASE     (APB_PP_BASE + 0x2800)
#define TIMER3_BASE     (APB_PP_BASE + 0x2C00)

#define WDT_BASE        (APB_PP_BASE + 0x3000)
#define RTC_BASE        (APB_PP_BASE + 0x4000)

#define I2C0_BASE       (APB_PP_BASE + 0x5000)
#define I2C1_BASE       (APB_PP_BASE + 0x5400)

#define SPI0_BASE       (APB_PP_BASE + 0x6000)
#define SPI1_BASE       (APB_PP_BASE + 0x6400)

#define ADC_BASE        (APB_PP_BASE + 0x7000)
#define DAC_BASE        (APB_PP_BASE + 0x8000)

#define RCC_BASE        (APB_PP_BASE + 0xA000)
#define PWR_CTRL_BASE   (APB_PP_BASE + 0xB000)

/* ============================================================================
 * GPIO 寄存器结构
 * ============================================================================ */

typedef struct {
    volatile uint32_t MODER;    /*!< 0x00 模式寄存器 */
    volatile uint32_t OTYPER;   /*!< 0x04 输出类型 */
    volatile uint32_t OSPEEDR;  /*!< 0x08 输出速度 */
    volatile uint32_t PUPDR;    /*!< 0x0C 上下拉 */
    volatile uint32_t IDR;      /*!< 0x10 输入数据 */
    volatile uint32_t ODR;      /*!< 0x14 输出数据 */
    volatile uint32_t BSRR;     /*!< 0x18 置位/复位 */
    volatile uint32_t LCKR;     /*!< 0x1C 锁定寄存器 */
    volatile uint32_t AFRL;     /*!< 0x20 复用功能低 */
    volatile uint32_t AFRH;     /*!< 0x24 复用功能高 */
} GPIO_TypeDef;

/* ============================================================================
 * UART 寄存器结构
 * ============================================================================ */

typedef struct {
    volatile uint32_t CR1;      /*!< 0x00 控制寄存器 1 */
    volatile uint32_t CR2;      /*!< 0x04 控制寄存器 2 */
    volatile uint32_t CR3;      /*!< 0x08 控制寄存器 3 */
    volatile uint32_t BRR;      /*!< 0x0C 波特率寄存器 */
    volatile uint32_t SR;       /*!< 0x10 状态寄存器 */
    volatile uint32_t DR;       /*!< 0x14 数据寄存器 */
} UART_TypeDef;

/* UART 状态寄存器位定义 */
#define UART_SR_TXE     (1 << 7)    /*!< 发送数据寄存器空 */
#define UART_SR_TC      (1 << 6)    /*!< 发送完成 */
#define UART_SR_RXNE    (1 << 5)    /*!< 读数据寄存器非空 */
#define UART_SR_ORE     (1 << 3)    /*!< 溢出错误 */

/* UART 控制寄存器位定义 */
#define UART_CR1_UE     (1 << 13)   /*!< UART 使能 */
#define UART_CR1_TE     (1 << 3)    /*!< 发送使能 */
#define UART_CR1_RE     (1 << 2)    /*!< 接收使能 */

/* ============================================================================
 * Timer 寄存器结构
 * ============================================================================ */

typedef struct {
    volatile uint32_t CR1;      /*!< 0x00 控制寄存器 1 */
    volatile uint32_t CR2;      /*!< 0x04 控制寄存器 2 */
    volatile uint32_t SMCR;     /*!< 0x08 从模式控制 */
    volatile uint32_t DIER;     /*!< 0x0C DMA/中断使能 */
    volatile uint32_t SR;       /*!< 0x10 状态寄存器 */
    volatile uint32_t EGR;      /*!< 0x14 事件生成 */
    volatile uint32_t CNT;      /*!< 0x18 计数器 */
    volatile uint32_t PSC;      /*!< 0x1C 预分频 */
    volatile uint32_t ARR;      /*!< 0x20 自动重载 */
    volatile uint32_t CCR1;     /*!< 0x24 捕获比较 1 */
    volatile uint32_t CCR2;     /*!< 0x28 捕获比较 2 */
    volatile uint32_t CCR3;     /*!< 0x2C 捕获比较 3 */
    volatile uint32_t CCR4;     /*!< 0x30 捕获比较 4 */
} TIMER_TypeDef;

/* ============================================================================
 * RCC 寄存器结构
 * ============================================================================ */

typedef struct {
    volatile uint32_t CR;       /*!< 0x00 时钟控制 */
    volatile uint32_t PLLCFGR;  /*!< 0x04 PLL 配置 */
    volatile uint32_t CFGR;     /*!< 0x08 时钟配置 */
    volatile uint32_t AHB1ENR;  /*!< 0x10 AHB1 时钟使能 */
    volatile uint32_t APB1ENR;  /*!< 0x20 APB1 时钟使能 */
} RCC_TypeDef;

/* ============================================================================
 * 外设实例指针
 * ============================================================================ */

#define GPIO_A      ((GPIO_TypeDef *)GPIO_A_BASE)
#define GPIO_B      ((GPIO_TypeDef *)GPIO_B_BASE)
#define GPIO_C      ((GPIO_TypeDef *)GPIO_C_BASE)
#define GPIO_D      ((GPIO_TypeDef *)GPIO_D_BASE)

#define UART0       ((UART_TypeDef *)UART0_BASE)
#define UART1       ((UART_TypeDef *)UART1_BASE)

#define TIMER0      ((TIMER_TypeDef *)TIMER0_BASE)
#define TIMER1      ((TIMER_TypeDef *)TIMER1_BASE)
#define TIMER2      ((TIMER_TypeDef *)TIMER2_BASE)
#define TIMER3      ((TIMER_TypeDef *)TIMER3_BASE)

#define RCC         ((RCC_TypeDef *)RCC_BASE)

/* ============================================================================
 * 系统函数声明
 * ============================================================================ */

extern void System_Init(void);
extern void Delay_ms(uint32_t ms);
extern void Delay_us(uint32_t us);

#endif /* __CORTEX_M3_H */
