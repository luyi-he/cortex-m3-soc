/**
 * @file gpio.h
 * @brief GPIO driver header
 * @details Based on architecture spec v1.0 Section 3.1
 */

#ifndef __GPIO_H__
#define __GPIO_H__

#include <stdint.h>
#include <stdbool.h>

/* GPIO Base Addresses (Section 2.3) */
#define GPIOA_BASE  0x50000000UL
#define GPIOB_BASE  0x50000400UL
#define GPIOC_BASE  0x50000800UL
#define GPIOD_BASE  0x50000C00UL

/* GPIO Register Offsets (Section 3.1) */
#define GPIO_MODER    0x00  /* Mode register */
#define GPIO_OTYPER   0x04  /* Output type */
#define GPIO_OSPEEDR  0x08  /* Output speed */
#define GPIO_PUPDR    0x0C  /* Pull-up/pull-down */
#define GPIO_IDR      0x10  /* Input data */
#define GPIO_ODR      0x14  /* Output data */
#define GPIO_BSRR     0x18  /* Bit set/reset */
#define GPIO_LCKR     0x1C  /* Lock register */
#define GPIO_AFRL     0x20  /* Alternate function low */
#define GPIO_AFRH     0x24  /* Alternate function high */

/* GPIO Mode */
typedef enum {
    GPIO_MODE_INPUT     = 0x00,
    GPIO_MODE_OUTPUT    = 0x01,
    GPIO_MODE_AF        = 0x02,
    GPIO_MODE_ANALOG    = 0x03
} gpio_mode_t;

/* GPIO Output Type */
typedef enum {
    GPIO_OTYPE_PUSHPULL = 0x00,
    GPIO_OTYPE_OPENDRAIN = 0x01
} gpio_otype_t;

/* GPIO Speed */
typedef enum {
    GPIO_SPEED_LOW      = 0x00,
    GPIO_SPEED_MEDIUM   = 0x01,
    GPIO_SPEED_HIGH     = 0x02,
    GPIO_SPEED_VHIGH    = 0x03
} gpio_speed_t;

/* GPIO Pull */
typedef enum {
    GPIO_PULL_NONE      = 0x00,
    GPIO_PULL_UP        = 0x01,
    GPIO_PULL_DOWN      = 0x02
} gpio_pull_t;

/* GPIO Pin definitions */
#define GPIO_PIN_0    (1UL << 0)
#define GPIO_PIN_1    (1UL << 1)
#define GPIO_PIN_2    (1UL << 2)
#define GPIO_PIN_3    (1UL << 3)
#define GPIO_PIN_4    (1UL << 4)
#define GPIO_PIN_5    (1UL << 5)
#define GPIO_PIN_6    (1UL << 6)
#define GPIO_PIN_7    (1UL << 7)
#define GPIO_PIN_8    (1UL << 8)
#define GPIO_PIN_9    (1UL << 9)
#define GPIO_PIN_10   (1UL << 10)
#define GPIO_PIN_11   (1UL << 11)
#define GPIO_PIN_12   (1UL << 12)
#define GPIO_PIN_13   (1UL << 13)
#define GPIO_PIN_14   (1UL << 14)
#define GPIO_PIN_15   (1UL << 15)
#define GPIO_PIN_ALL  (0xFFFFUL)

/* GPIO Port type */
typedef uint32_t gpio_port_t;

/* Function prototypes */
void gpio_init(gpio_port_t port);
void gpio_set_mode(gpio_port_t port, uint32_t pin, gpio_mode_t mode);
void gpio_set_output_type(gpio_port_t port, uint32_t pin, gpio_otype_t type);
void gpio_set_speed(gpio_port_t port, uint32_t pin, gpio_speed_t speed);
void gpio_set_pull(gpio_port_t port, uint32_t pin, gpio_pull_t pull);

void gpio_set(gpio_port_t port, uint32_t pin);
void gpio_clear(gpio_port_t port, uint32_t pin);
void gpio_toggle(gpio_port_t port, uint32_t pin);
void gpio_write(gpio_port_t port, uint32_t pin, bool value);

bool gpio_read(gpio_port_t port, uint32_t pin);
uint32_t gpio_read_port(gpio_port_t port);

void gpio_set_af(gpio_port_t port, uint32_t pin, uint8_t af);

/* Aliases for bootloader compatibility */
#define GPIO_Read(p, n)         gpio_read((gpio_port_t)(p), n)
#define GPIO_Write(p, n, v)     gpio_write((gpio_port_t)(p), n, v)
#define GPIO_Set(p, n)          gpio_set((gpio_port_t)(p), n)
#define GPIO_Clear(p, n)        gpio_clear((gpio_port_t)(p), n)

#endif /* __GPIO_H__ */
