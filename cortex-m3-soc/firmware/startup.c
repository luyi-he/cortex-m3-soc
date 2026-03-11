/**
 * @file startup.c
 * @brief Cortex-M3 startup code
 * @details Reset handler, exception handlers, and system initialization
 */

#include <stdint.h>

/* External declarations */
extern uint32_t _sidata;    /* Start of .data section in FLASH */
extern uint32_t _sdata;     /* Start of .data section in RAM */
extern uint32_t _edata;     /* End of .data section in RAM */
extern uint32_t _sbss;      /* Start of .bss section in RAM */
extern uint32_t _ebss;      /* End of .bss section in RAM */
extern uint32_t _stack_top; /* Top of stack */

/* Function prototypes */
void Reset_Handler(void);
void NMI_Handler(void);
void HardFault_Handler(void);
void MemManage_Handler(void);
void BusFault_Handler(void);
void UsageFault_Handler(void);
void SVC_Handler(void);
void DebugMon_Handler(void);
void PendSV_Handler(void);
void SysTick_Handler(void);

/* Weak aliases for interrupt handlers */
void Default_Handler(void) __attribute__((weak));
void WDT_Handler(void) __attribute__((weak, alias("Default_Handler")));
void UART0_Handler(void) __attribute__((weak, alias("Default_Handler")));
void UART1_Handler(void) __attribute__((weak, alias("Default_Handler")));
void Timer0_Handler(void) __attribute__((weak, alias("Default_Handler")));
void Timer1_Handler(void) __attribute__((weak, alias("Default_Handler")));
void Timer2_Handler(void) __attribute__((weak, alias("Default_Handler")));
void Timer3_Handler(void) __attribute__((weak, alias("Default_Handler")));
void GPIO_Handler(void) __attribute__((weak, alias("Default_Handler")));
void ADC_Handler(void) __attribute__((weak, alias("Default_Handler")));
void DAC_Handler(void) __attribute__((weak, alias("Default_Handler")));
void I2C0_Handler(void) __attribute__((weak, alias("Default_Handler")));
void I2C1_Handler(void) __attribute__((weak, alias("Default_Handler")));
void SPI0_Handler(void) __attribute__((weak, alias("Default_Handler")));
void SPI1_Handler(void) __attribute__((weak, alias("Default_Handler")));
void DMA_Handler(void) __attribute__((weak, alias("Default_Handler")));
void RTC_Handler(void) __attribute__((weak, alias("Default_Handler")));

/* Default interrupt handler */
void Default_Handler(void)
{
    while (1) {
        /* Infinite loop on unhandled interrupt */
    }
}

/**
 * @brief Reset Handler
 * @details Called after reset, initializes data sections and calls main()
 */
void Reset_Handler(void)
{
    uint32_t *src, *dst;

    /* Copy .data section from FLASH to RAM */
    src = &_sidata;
    dst = &_sdata;
    while (dst < &_edata) {
        *dst++ = *src++;
    }

    /* Zero-fill .bss section */
    dst = &_sbss;
    while (dst < &_ebss) {
        *dst++ = 0;
    }

    /* Initialize system (clock, etc.) */
    System_Init();

    /* Call main */
    main();

    /* Should never reach here */
    while (1);
}

/**
 * @brief NMI Handler
 */
void NMI_Handler(void)
{
    while (1);
}

/**
 * @brief Hard Fault Handler
 */
void HardFault_Handler(void)
{
    /* Get fault status registers */
    volatile uint32_t cfsr = (*(volatile uint32_t *)0xE000ED28);
    volatile uint32_t hfsr = (*(volatile uint32_t *)0xE000ED2C);
    volatile uint32_t mmfar = (*(volatile uint32_t *)0xE000ED34);
    volatile uint32_t bfar = (*(volatile uint32_t *)0xE000ED38);

    (void)cfsr;
    (void)hfsr;
    (void)mmfar;
    (void)bfar;

    while (1);
}

void MemManage_Handler(void) { while (1); }
void BusFault_Handler(void) { while (1); }
void UsageFault_Handler(void) { while (1); }
void SVC_Handler(void) { while (1); }
void DebugMon_Handler(void) { while (1); }
void PendSV_Handler(void) { while (1); }
void SysTick_Handler(void) { while (1); }
