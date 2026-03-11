/**
 * @file timer.h
 * @brief Timer driver header
 * @details Based on architecture spec v1.0 Section 3.3
 */

#ifndef __TIMER_H__
#define __TIMER_H__

#include <stdint.h>
#include <stdbool.h>

/* Timer Base Addresses (Section 2.3) */
#define Timer0_BASE  0x50002000UL
#define Timer1_BASE  0x50002400UL
#define Timer2_BASE  0x50002800UL
#define Timer3_BASE  0x50002C00UL

/* Timer Register Offsets (Section 3.3) */
#define TIMER_CR1     0x00  /* Control register 1 */
#define TIMER_CR2     0x04  /* Control register 2 */
#define TIMER_SMCR    0x08  /* Slave mode control */
#define TIMER_DIER    0x0C  /* DMA/Interrupt enable */
#define TIMER_SR      0x10  /* Status register */
#define TIMER_EGR     0x14  /* Event generator */
#define TIMER_CNT     0x18  /* Counter */
#define TIMER_PSC     0x1C  /* Prescaler */
#define TIMER_ARR     0x20  /* Auto-reload */
#define TIMER_CCR1    0x24  /* Capture/compare 1 */
#define TIMER_CCR2    0x28  /* Capture/compare 2 */
#define TIMER_CCR3    0x2C  /* Capture/compare 3 */
#define TIMER_CCR4    0x30  /* Capture/compare 4 */

/* CR1 bits */
#define TIMER_CR1_CEN   (1UL << 0)   /* Counter enable */
#define TIMER_CR1_UDIS  (1UL << 1)   /* Update disable */
#define TIMER_CR1_URS   (1UL << 2)   /* Update request source */
#define TIMER_CR1_OPM   (1UL << 3)   /* One pulse mode */
#define TIMER_CR1_DIR   (1UL << 4)   /* Direction */
#define TIMER_CR1_CMS   (3UL << 5)   /* Center-aligned mode */
#define TIMER_CR1_ARPE  (1UL << 7)   /* Auto-reload preload enable */

/* CR2 bits */
#define TIMER_CR2_MMS   (7UL << 4)   /* Master mode selection */

/* DIER bits */
#define TIMER_DIER_UIE  (1UL << 0)   /* Update interrupt enable */
#define TIMER_DIER_CC1IE (1UL << 1)  /* Capture/compare 1 interrupt */
#define TIMER_DIER_CC2IE (1UL << 2)  /* Capture/compare 2 interrupt */
#define TIMER_DIER_CC3IE (1UL << 3)  /* Capture/compare 3 interrupt */
#define TIMER_DIER_CC4IE (1UL << 4)  /* Capture/compare 4 interrupt */

/* SR bits */
#define TIMER_SR_UIF    (1UL << 0)   /* Update interrupt flag */
#define TIMER_SR_CC1IF  (1UL << 1)   /* Capture/compare 1 flag */
#define TIMER_SR_CC2IF  (1UL << 2)   /* Capture/compare 2 flag */
#define TIMER_SR_CC3IF  (1UL << 3)   /* Capture/compare 3 flag */
#define TIMER_SR_CC4IF  (1UL << 4)   /* Capture/compare 4 flag */

/* Timer handle */
typedef uint32_t timer_handle_t;

/* Timer aliases */
#define Timer0  Timer0_BASE
#define Timer1  Timer1_BASE
#define Timer2  Timer2_BASE
#define Timer3  Timer3_BASE

/* Function prototypes */
void timer_init(timer_handle_t timer);
void timer_deinit(timer_handle_t timer);

void timer_start(timer_handle_t timer);
void timer_stop(timer_handle_t timer);

void timer_set_prescaler(timer_handle_t timer, uint16_t psc);
void timer_set_period(timer_handle_t timer, uint32_t arr);
void timer_set_counter(timer_handle_t timer, uint32_t cnt);

uint32_t timer_read(timer_handle_t timer);

void timer_delay_ms(timer_handle_t timer, uint32_t ms);
void timer_delay_us(timer_handle_t timer, uint32_t us);

void timer_enable_interrupt(timer_handle_t timer);
void timer_disable_interrupt(timer_handle_t timer);
void timer_clear_interrupt(timer_handle_t timer);

#endif /* __TIMER_H__ */
