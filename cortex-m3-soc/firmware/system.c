/**
 * @file system.c
 * @brief System initialization (clock, reset, power)
 * @details Based on architecture spec v1.0 Sections 5, 6, 7
 */

#include <stdint.h>

/* Register definitions */

/* RCC Base Address: 0x5000_A000 */
#define RCC_BASE        0x5000A000UL
#define RCC_CR          (*(volatile uint32_t *)(RCC_BASE + 0x00))
#define RCC_PLLCFG      (*(volatile uint32_t *)(RCC_BASE + 0x04))
#define RCC_CFGR        (*(volatile uint32_t *)(RCC_BASE + 0x08))
#define RCC_AHB1ENR     (*(volatile uint32_t *)(RCC_BASE + 0x10))
#define RCC_APB1ENR     (*(volatile uint32_t *)(RCC_BASE + 0x20))
#define RCC_CSR         (*(volatile uint32_t *)(RCC_BASE + 0x30))

/* PWR Base Address: 0x5000_B000 */
#define PWR_BASE        0x5000B000UL
#define PWR_CR          (*(volatile uint32_t *)(PWR_BASE + 0x00))
#define PWR_CSR         (*(volatile uint32_t *)(PWR_BASE + 0x04))

/* Flash Controller Base Address: 0x5000_9000 */
#define FLASH_BASE      0x50009000UL
#define FLASH_ACR       (*(volatile uint32_t *)(FLASH_BASE + 0x00))

/* Bit definitions */
#define RCC_CR_HSION        (1UL << 0)
#define RCC_CR_HSIRDY       (1UL << 1)
#define RCC_CR_HSEON        (1UL << 16)
#define RCC_CR_HSERDY       (1UL << 17)
#define RCC_CR_PLLON        (1UL << 24)
#define RCC_CR_PLLRDY       (1UL << 25)

#define RCC_PLLCFG_PLLM       0x000000FFUL
#define RCC_PLLCFG_PLLN       0x00007F00UL
#define RCC_PLLCFG_PLLP       0x00030000UL

#define RCC_CFGR_SW           0x00000003UL
#define RCC_CFGR_SWS          0x0000000CUL
#define RCC_CFGR_HPRE         0x000000F0UL
#define RCC_CFGR_PPRE         0x00000700UL

#define FLASH_ACR_LATENCY     0x0000000FUL
#define FLASH_ACR_PRFTBE      (1UL << 4)

/* System clock frequency */
static uint32_t SystemCoreClock = 24000000; /* Default internal RC */

/**
 * @brief Initialize system clock
 * @details Configure PLL for 200MHz operation
 */
static void SystemClock_Init(void)
{
    /* Enable internal RC oscillator */
    RCC_CR |= RCC_CR_HSION;
    while (!(RCC_CR & RCC_CR_HSIRDY));

    /* Configure Flash latency for 200MHz */
    FLASH_ACR = (FLASH_ACR & ~FLASH_ACR_LATENCY) | 0x05; /* 5 wait states */
    FLASH_ACR |= FLASH_ACR_PRFTBE; /* Enable prefetch buffer */

    /* Configure PLL: 24MHz * 50 / 6 = 200MHz */
    RCC_PLLCFG = (25 << 0) |    /* PLLM = 25 (input divider) */
                 (400 << 8) |   /* PLLN = 400 (multiplier) */
                 (2 << 16);     /* PLLP = 2 (system clock divider) */

    /* Enable PLL */
    RCC_CR |= RCC_CR_PLLON;
    while (!(RCC_CR & RCC_CR_PLLRDY));

    /* Configure clock dividers: HCLK=200MHz, PCLK=100MHz */
    RCC_CFGR = (0x00 << 4) |    /* HPRE: AHB prescaler = 1 */
               (0x04 << 8);     /* PPRE: APB prescaler = 2 */

    /* Switch to PLL as system clock */
    RCC_CFGR |= 0x02; /* SW = PLL */
    while ((RCC_CFGR & RCC_CFGR_SWS) != (0x02 << 2));

    /* Update system core clock */
    SystemCoreClock = 200000000;
}

/**
 * @brief Enable peripheral clocks
 */
static void PeripheralClocks_Init(void)
{
    /* Enable AHB peripherals */
    RCC_AHB1ENR = (1UL << 0) |  /* GPIOA */
                  (1UL << 1) |  /* GPIOB */
                  (1UL << 2) |  /* GPIOC */
                  (1UL << 3) |  /* GPIOD */
                  (1UL << 4);   /* DMA */

    /* Enable APB peripherals */
    RCC_APB1ENR = (1UL << 0) |  /* UART0 */
                  (1UL << 1) |  /* UART1 */
                  (1UL << 2) |  /* TIMER0 */
                  (1UL << 3) |  /* TIMER1 */
                  (1UL << 4) |  /* TIMER2 */
                  (1UL << 5) |  /* TIMER3 */
                  (1UL << 8) |  /* WDT */
                  (1UL << 9);   /* RTC */
}

/**
 * @brief Configure NVIC
 */
static void NVIC_Init(void)
{
    /* Set priority grouping */
    /* SCB->AIRCR = (0x5FA << 16) | (0x03 << 8); */

    /* Enable interrupts as needed */
    /* NVIC_EnableIRQ(UART0_IRQn); */
}

/**
 * @brief System initialization
 * @details Called from Reset_Handler before main()
 */
void System_Init(void)
{
    /* Initialize system clock */
    SystemClock_Init();

    /* Enable peripheral clocks */
    PeripheralClocks_Init();

    /* Configure NVIC */
    NVIC_Init();

    /* Configure SysTick for 1ms tick */
    /* SysTick->LOAD = (SystemCoreClock / 1000) - 1; */
    /* SysTick->VAL = 0; */
    /* SysTick->CTRL = 0x07; */
}

/**
 * @brief Get system core clock frequency
 * @return SystemCoreClock in Hz
 */
uint32_t SystemCoreClock_Get(void)
{
    return SystemCoreClock;
}

/**
 * @brief Enter sleep mode
 */
void System_Sleep(void)
{
    __WFI();
}

/**
 * @brief Enter stop mode
 */
void System_Stop(void)
{
    /* Clear SLEEPDEEP bit */
    /* SCB->SCR &= ~SCB_SCR_SLEEPDEEP_Msk; */
    __WFI();
}

/**
 * @brief Enter standby mode
 */
void System_Standby(void)
{
    /* Set SLEEPDEEP bit */
    /* SCB->SCR |= SCB_SCR_SLEEPDEEP_Msk; */
    
    /* Set PDDS bit */
    PWR_CR |= (1UL << 1);
    
    __WFI();
}

/**
 * @brief System reset
 */
void System_Reset(void)
{
    /* AIRCR = 0x5FA0004 */
    (*(volatile uint32_t *)0xE000ED0C) = 0x05FA0004UL;
    while (1);
}
