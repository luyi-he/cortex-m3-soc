/**
 * @file timer.c
 * @brief Timer driver implementation
 * @details Based on architecture spec v1.0 Section 3.3
 */

#include "timer.h"

/* Register access macros */
#define REG32(addr) (*(volatile uint32_t *)(addr))

/* System clock */
extern uint32_t SystemCoreClock_Get(void);
#define TIMER_CLOCK (SystemCoreClock_Get() / 2) /* APB clock = 100MHz */

/**
 * @brief Initialize timer
 * @param timer Timer base address
 */
void timer_init(timer_handle_t timer)
{
    /* Stop timer */
    REG32(timer + TIMER_CR1) &= ~TIMER_CR1_CEN;

    /* Reset counter */
    REG32(timer + TIMER_CNT) = 0x00000000;

    /* Set prescaler to 1 (no division) */
    REG32(timer + TIMER_PSC) = 0;

    /* Set auto-reload to max */
    REG32(timer + TIMER_ARR) = 0xFFFFFFFF;

    /* Clear status */
    REG32(timer + TIMER_SR) = 0x00000000;

    /* Disable interrupts */
    REG32(timer + TIMER_DIER) = 0x00000000;
}

/**
 * @brief Deinitialize timer
 * @param timer Timer base address
 */
void timer_deinit(timer_handle_t timer)
{
    timer_stop(timer);
    REG32(timer + TIMER_CNT) = 0x00000000;
    REG32(timer + TIMER_DIER) = 0x00000000;
}

/**
 * @brief Start timer
 * @param timer Timer base address
 */
void timer_start(timer_handle_t timer)
{
    REG32(timer + TIMER_CR1) |= TIMER_CR1_CEN;
}

/**
 * @brief Stop timer
 * @param timer Timer base address
 */
void timer_stop(timer_handle_t timer)
{
    REG32(timer + TIMER_CR1) &= ~TIMER_CR1_CEN;
}

/**
 * @brief Set timer prescaler
 * @param timer Timer base address
 * @param psc Prescaler value (timer clock = f_clk / (psc + 1))
 */
void timer_set_prescaler(timer_handle_t timer, uint16_t psc)
{
    REG32(timer + TIMER_PSC) = psc;
}

/**
 * @brief Set timer period (auto-reload value)
 * @param timer Timer base address
 * @param arr Auto-reload value
 */
void timer_set_period(timer_handle_t timer, uint32_t arr)
{
    REG32(timer + TIMER_ARR) = arr;
}

/**
 * @brief Set counter value
 * @param timer Timer base address
 * @param cnt Counter value
 */
void timer_set_counter(timer_handle_t timer, uint32_t cnt)
{
    REG32(timer + TIMER_CNT) = cnt;
}

/**
 * @brief Read current counter value
 * @param timer Timer base address
 * @return Counter value
 */
uint32_t timer_read(timer_handle_t timer)
{
    return REG32(timer + TIMER_CNT);
}

/**
 * @brief Delay in milliseconds
 * @param timer Timer base address
 * @param ms Milliseconds to delay
 */
void timer_delay_ms(timer_handle_t timer, uint32_t ms)
{
    uint32_t ticks = (TIMER_CLOCK / 1000) * ms;
    uint32_t start = timer_read(timer);

    while ((timer_read(timer) - start) < ticks);
}

/**
 * @brief Delay in microseconds
 * @param timer Timer base address
 * @param us Microseconds to delay
 */
void timer_delay_us(timer_handle_t timer, uint32_t us)
{
    uint32_t ticks = (TIMER_CLOCK / 1000000) * us;
    uint32_t start = timer_read(timer);

    while ((timer_read(timer) - start) < ticks);
}

/**
 * @brief Enable timer update interrupt
 * @param timer Timer base address
 */
void timer_enable_interrupt(timer_handle_t timer)
{
    REG32(timer + TIMER_DIER) |= TIMER_DIER_UIE;
}

/**
 * @brief Disable timer update interrupt
 * @param timer Timer base address
 */
void timer_disable_interrupt(timer_handle_t timer)
{
    REG32(timer + TIMER_DIER) &= ~TIMER_DIER_UIE;
}

/**
 * @brief Clear timer update interrupt flag
 * @param timer Timer base address
 */
void timer_clear_interrupt(timer_handle_t timer)
{
    REG32(timer + TIMER_SR) &= ~TIMER_SR_UIF;
}

/**
 * @brief Check if timer interrupt is pending
 * @param timer Timer base address
 * @return true if interrupt is pending
 */
bool timer_interrupt_pending(timer_handle_t timer)
{
    return (REG32(timer + TIMER_SR) & TIMER_SR_UIF) != 0;
}
