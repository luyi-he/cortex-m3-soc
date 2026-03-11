/**
 * @file timer.c
 * @brief 定时器驱动
 */

#include "cortex_m3.h"

/**
 * @brief 初始化定时器
 * @param timer 定时器实例
 * @param period_ms 周期 (毫秒)
 */
void Timer_Init(TIMER_TypeDef *timer, uint32_t period_ms)
{
    /* 计算预分频和重装载值 */
    uint32_t prescaler = (SYSTEM_CORE_CLOCK / 1000) - 1;  // 1kHz 计数
    uint32_t reload = period_ms - 1;
    
    timer->PSC = prescaler;
    timer->ARR = reload;
    timer->EGR = 1;  // 事件生成 (更新计数器)
}

/**
 * @brief 启动定时器
 * @param timer 定时器实例
 */
void Timer_Start(TIMER_TypeDef *timer)
{
    timer->CR1 = 1;  // 使能计数器
}

/**
 * @brief 停止定时器
 * @param timer 定时器实例
 */
void Timer_Stop(TIMER_TypeDef *timer)
{
    timer->CR1 = 0;
}

/**
 * @brief 使能定时器中断
 * @param timer 定时器实例
 */
void Timer_EnableIRQ(TIMER_TypeDef *timer)
{
    timer->DIER = 1;  // 更新中断使能
}

/**
 * @brief 禁用定时器中断
 * @param timer 定时器实例
 */
void Timer_DisableIRQ(TIMER_TypeDef *timer)
{
    timer->DIER = 0;
}

/**
 * @brief 清除定时器中断标志
 * @param timer 定时器实例
 */
void Timer_ClearIRQ(TIMER_TypeDef *timer)
{
    timer->SR = 0;
}

/**
 * @brief 获取当前计数值
 * @param timer 定时器实例
 * @return 计数值
 */
uint32_t Timer_GetCounter(TIMER_TypeDef *timer)
{
    return timer->CNT;
}

/**
 * @brief 延时函数 (使用 Timer0)
 * @param ms 延时毫秒数
 */
void Timer_Delay_ms(uint32_t ms)
{
    TIMER0->PSC = (SYSTEM_CORE_CLOCK / 1000) - 1;
    TIMER0->ARR = ms - 1;
    TIMER0->CNT = 0;
    TIMER0->CR1 = 1;
    
    while (!(TIMER0->SR & 1));
    
    TIMER0->CR1 = 0;
    TIMER0->SR = 0;
}
