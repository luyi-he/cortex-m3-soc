/**
 * @file vector_table.c
 * @brief Interrupt vector table for Cortex-M3 SoC
 * @details Based on architecture spec v1.0 Section 4
 */

#include <stdint.h>

/* Forward declarations of exception handlers */
extern void Reset_Handler(void);
extern void NMI_Handler(void);
extern void HardFault_Handler(void);
extern void MemManage_Handler(void);
extern void BusFault_Handler(void);
extern void UsageFault_Handler(void);
extern void SVC_Handler(void);
extern void DebugMon_Handler(void);
extern void PendSV_Handler(void);
extern void SysTick_Handler(void);

/* Forward declarations of interrupt handlers */
extern void WDT_Handler(void);
extern void UART0_Handler(void);
extern void UART1_Handler(void);
extern void Timer0_Handler(void);
extern void Timer1_Handler(void);
extern void Timer2_Handler(void);
extern void Timer3_Handler(void);
extern void GPIO_Handler(void);
extern void ADC_Handler(void);
extern void DAC_Handler(void);
extern void I2C0_Handler(void);
extern void I2C1_Handler(void);
extern void SPI0_Handler(void);
extern void SPI1_Handler(void);
extern void DMA_Handler(void);
extern void RTC_Handler(void);

/* Union to represent vector table entries */
typedef union {
    void (*handler)(void);
    void *stack_ptr;
} vector_entry_t;

/* Vector table placed at 0x00000000 */
__attribute__((section(".isr_vector")))
const vector_entry_t vector_table[] = {
    /* Core exceptions */
    {.stack_ptr = (void *)&_stack_top},     /* 0: Initial Stack Pointer */
    {.handler = Reset_Handler},             /* 1: Reset Handler */
    {.handler = NMI_Handler},               /* 2: NMI Handler */
    {.handler = HardFault_Handler},         /* 3: Hard Fault Handler */
    {.handler = MemManage_Handler},         /* 4: Memory Management Handler */
    {.handler = BusFault_Handler},          /* 5: Bus Fault Handler */
    {.handler = UsageFault_Handler},        /* 6: Usage Fault Handler */
    {.handler = 0},                         /* 7: Reserved */
    {.handler = 0},                         /* 8: Reserved */
    {.handler = 0},                         /* 9: Reserved */
    {.handler = 0},                         /* 10: Reserved */
    {.handler = SVC_Handler},               /* 11: SVCall Handler */
    {.handler = DebugMon_Handler},          /* 12: Debug Monitor Handler */
    {.handler = 0},                         /* 13: Reserved */
    {.handler = PendSV_Handler},            /* 14: PendSV Handler */
    {.handler = SysTick_Handler},           /* 15: SysTick Handler */

    /* Device interrupts (IRQ 0-15) */
    {.handler = WDT_Handler},               /* 16: Watchdog Timer */
    {.handler = UART0_Handler},             /* 17: UART0 */
    {.handler = UART1_Handler},             /* 18: UART1 */
    {.handler = Timer0_Handler},            /* 19: Timer0 */
    {.handler = Timer1_Handler},            /* 20: Timer1 */
    {.handler = Timer2_Handler},            /* 21: Timer2 */
    {.handler = Timer3_Handler},            /* 22: Timer3 */
    {.handler = GPIO_Handler},              /* 23: GPIO */
    {.handler = ADC_Handler},               /* 24: ADC */
    {.handler = DAC_Handler},               /* 25: DAC */
    {.handler = I2C0_Handler},              /* 26: I2C0 */
    {.handler = I2C1_Handler},              /* 27: I2C1 */
    {.handler = SPI0_Handler},              /* 28: SPI0 */
    {.handler = SPI1_Handler},              /* 29: SPI1 */
    {.handler = DMA_Handler},               /* 30: DMA */
    {.handler = RTC_Handler}                /* 31: RTC */
};

/* External symbol for stack top (defined in linker script) */
extern uint32_t _stack_top;
