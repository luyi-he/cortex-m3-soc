/**
 * @file startup.c
 * @brief Cortex-M3 启动代码
 */

#include <stdint.h>

/* 链接脚本定义的符号 */
extern uint32_t _sidata;
extern uint32_t _sdata;
extern uint32_t _edata;
extern uint32_t _sbss;
extern uint32_t _ebss;
extern uint32_t _estack;

/* 函数原型 */
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

/* 外部中断处理函数 (弱定义) */
void WDT_Handler(void)           __attribute__((weak, alias("Default_Handler")));
void UART0_Handler(void)         __attribute__((weak, alias("Default_Handler")));
void UART1_Handler(void)         __attribute__((weak, alias("Default_Handler")));
void Timer0_Handler(void)        __attribute__((weak, alias("Default_Handler")));
void Timer1_Handler(void)        __attribute__((weak, alias("Default_Handler")));
void Timer2_Handler(void)        __attribute__((weak, alias("Default_Handler")));
void Timer3_Handler(void)        __attribute__((weak, alias("Default_Handler")));
void GPIO_Handler(void)          __attribute__((weak, alias("Default_Handler")));
void ADC_Handler(void)           __attribute__((weak, alias("Default_Handler")));
void DAC_Handler(void)           __attribute__((weak, alias("Default_Handler")));
void I2C0_Handler(void)          __attribute__((weak, alias("Default_Handler")));
void I2C1_Handler(void)          __attribute__((weak, alias("Default_Handler")));
void SPI0_Handler(void)          __attribute__((weak, alias("Default_Handler")));
void SPI1_Handler(void)          __attribute__((weak, alias("Default_Handler")));
void DMA_Handler(void)           __attribute__((weak, alias("Default_Handler")));
void RTC_Handler(void)           __attribute__((weak, alias("Default_Handler")));

/* 中断向量表 */
__attribute__((section(".isr_vector")))
const uint32_t vector_table[] = {
    (uint32_t)&_estack,              // 初始栈指针 (MSP)
    (uint32_t)Reset_Handler,         // 复位处理函数
    (uint32_t)NMI_Handler,           // NMI
    (uint32_t)HardFault_Handler,     // Hard Fault
    (uint32_t)MemManage_Handler,     // MPU Fault
    (uint32_t)BusFault_Handler,      // Bus Fault
    (uint32_t)UsageFault_Handler,    // Usage Fault
    0, 0, 0, 0,                      // Reserved
    (uint32_t)SVC_Handler,           // SVCall
    (uint32_t)DebugMon_Handler,      // Debug Monitor
    0,                               // Reserved
    (uint32_t)PendSV_Handler,        // PendSV
    (uint32_t)SysTick_Handler,       // SysTick
    
    /* 外部中断 */
    (uint32_t)WDT_Handler,           // IRQ0: Watchdog
    (uint32_t)UART0_Handler,         // IRQ1: UART0
    (uint32_t)UART1_Handler,         // IRQ2: UART1
    (uint32_t)Timer0_Handler,        // IRQ3: Timer0
    (uint32_t)Timer1_Handler,        // IRQ4: Timer1
    (uint32_t)Timer2_Handler,        // IRQ5: Timer2
    (uint32_t)Timer3_Handler,        // IRQ6: Timer3
    (uint32_t)GPIO_Handler,          // IRQ7: GPIO
    (uint32_t)ADC_Handler,           // IRQ8: ADC
    (uint32_t)DAC_Handler,           // IRQ9: DAC
    (uint32_t)I2C0_Handler,          // IRQ10: I2C0
    (uint32_t)I2C1_Handler,          // IRQ11: I2C1
    (uint32_t)SPI0_Handler,          // IRQ12: SPI0
    (uint32_t)SPI1_Handler,          // IRQ13: SPI1
    (uint32_t)DMA_Handler,           // IRQ14: DMA
    (uint32_t)RTC_Handler            // IRQ15: RTC
};

/**
 * @brief 复位处理函数
 */
void Reset_Handler(void)
{
    uint32_t *src, *dst;
    
    /* 初始化 .data 段 */
    src = &_sidata;
    dst = &_sdata;
    while (dst < &_edata) {
        *dst++ = *src++;
    }
    
    /* 清零 .bss 段 */
    dst = &_sbss;
    while (dst < &_ebss) {
        *dst++ = 0;
    }
    
    /* 调用系统初始化 */
    System_Init();
    
    /* 调用主函数 */
    main();
    
    /* 永不返回 */
    while (1);
}

/**
 * @brief 默认中断处理函数
 */
void Default_Handler(void)
{
    while (1);
}

/**
 * @brief NMI 处理函数
 */
void NMI_Handler(void)
{
    while (1);
}

/**
 * @brief HardFault 处理函数
 */
__attribute__((naked))
void HardFault_Handler(void)
{
    __asm volatile (
        "TST LR, #4 \n"
        "ITE EQ \n"
        "MRSEQ R0, MSP \n"
        "MRSNE R0, PSP \n"
        "B HardFault_Handler_C \n"
    );
}

void HardFault_Handler_C(uint32_t *stack)
{
    uint32_t r0 = stack[0];
    uint32_t r1 = stack[1];
    uint32_t r2 = stack[2];
    uint32_t r3 = stack[3];
    uint32_t r12 = stack[4];
    uint32_t lr = stack[5];
    uint32_t pc = stack[6];
    uint32_t psr = stack[7];
    
    (void)r0; (void)r1; (void)r2; (void)r3;
    (void)r12; (void)lr; (void)pc; (void)psr;
    
    while (1);
}

void MemManage_Handler(void)   { while (1); }
void BusFault_Handler(void)    { while (1); }
void UsageFault_Handler(void)  { while (1); }
void SVC_Handler(void)         { while (1); }
void DebugMon_Handler(void)    { while (1); }
void PendSV_Handler(void)      { while (1); }
void SysTick_Handler(void)     { while (1); }
