/**
 * @file gpio.c
 * @brief GPIO driver implementation
 * @details Based on architecture spec v1.0 Section 3.1
 */

#include "gpio.h"

/* Register access macros */
#define REG32(addr) (*(volatile uint32_t *)(addr))

/**
 * @brief Initialize GPIO port
 * @param port GPIO port base address
 */
void gpio_init(gpio_port_t port)
{
    /* All pins default to input mode */
    REG32(port + GPIO_MODER) = 0x00000000;
    REG32(port + GPIO_OTYPER) = 0x00000000;
    REG32(port + GPIO_OSPEEDR) = 0x00000000;
    REG32(port + GPIO_PUPDR) = 0x00000000;
    REG32(port + GPIO_ODR) = 0x00000000;
    REG32(port + GPIO_AFRL) = 0x00000000;
    REG32(port + GPIO_AFRH) = 0x00000000;
}

/**
 * @brief Configure pin mode
 * @param port GPIO port base address
 * @param pin Pin number (GPIO_PIN_x)
 * @param mode Pin mode
 */
void gpio_set_mode(gpio_port_t port, uint32_t pin, gpio_mode_t mode)
{
    uint32_t moder = REG32(port + GPIO_MODER);
    int pin_num = 0;

    /* Find pin number */
    while (!(pin & (1UL << pin_num)) && pin_num < 16) {
        pin_num++;
    }

    /* Clear current mode */
    moder &= ~(0x03UL << (pin_num * 2));
    
    /* Set new mode */
    moder |= (mode << (pin_num * 2));

    REG32(port + GPIO_MODER) = moder;
}

/**
 * @brief Configure output type
 * @param port GPIO port base address
 * @param pin Pin number
 * @param type Output type
 */
void gpio_set_output_type(gpio_port_t port, uint32_t pin, gpio_otype_t type)
{
    uint32_t otyper = REG32(port + GPIO_OTYPER);
    int pin_num = 0;

    while (!(pin & (1UL << pin_num)) && pin_num < 16) {
        pin_num++;
    }

    if (type == GPIO_OTYPE_OPENDRAIN) {
        otyper |= (1UL << pin_num);
    } else {
        otyper &= ~(1UL << pin_num);
    }

    REG32(port + GPIO_OTYPER) = otyper;
}

/**
 * @brief Configure output speed
 * @param port GPIO port base address
 * @param pin Pin number
 * @param speed Speed setting
 */
void gpio_set_speed(gpio_port_t port, uint32_t pin, gpio_speed_t speed)
{
    uint32_t ospeedr = REG32(port + GPIO_OSPEEDR);
    int pin_num = 0;

    while (!(pin & (1UL << pin_num)) && pin_num < 16) {
        pin_num++;
    }

    ospeedr &= ~(0x03UL << (pin_num * 2));
    ospeedr |= (speed << (pin_num * 2));

    REG32(port + GPIO_OSPEEDR) = ospeedr;
}

/**
 * @brief Configure pull-up/pull-down
 * @param port GPIO port base address
 * @param pin Pin number
 * @param pull Pull setting
 */
void gpio_set_pull(gpio_port_t port, uint32_t pin, gpio_pull_t pull)
{
    uint32_t pupdr = REG32(port + GPIO_PUPDR);
    int pin_num = 0;

    while (!(pin & (1UL << pin_num)) && pin_num < 16) {
        pin_num++;
    }

    pupdr &= ~(0x03UL << (pin_num * 2));
    pupdr |= (pull << (pin_num * 2));

    REG32(port + GPIO_PUPDR) = pupdr;
}

/**
 * @brief Set pin high
 * @param port GPIO port base address
 * @param pin Pin number
 */
void gpio_set(gpio_port_t port, uint32_t pin)
{
    REG32(port + GPIO_BSRR) = pin;
}

/**
 * @brief Set pin low
 * @param port GPIO port base address
 * @param pin Pin number
 */
void gpio_clear(gpio_port_t port, uint32_t pin)
{
    REG32(port + GPIO_BSRR) = pin << 16;
}

/**
 * @brief Toggle pin
 * @param port GPIO port base address
 * @param pin Pin number
 */
void gpio_toggle(gpio_port_t port, uint32_t pin)
{
    uint32_t odr = REG32(port + GPIO_ODR);
    REG32(port + GPIO_ODR) = odr ^ pin;
}

/**
 * @brief Write pin value
 * @param port GPIO port base address
 * @param pin Pin number
 * @param value Value to write (true = high, false = low)
 */
void gpio_write(gpio_port_t port, uint32_t pin, bool value)
{
    if (value) {
        gpio_set(port, pin);
    } else {
        gpio_clear(port, pin);
    }
}

/**
 * @brief Read pin value
 * @param port GPIO port base address
 * @param pin Pin number
 * @return true if pin is high, false if low
 */
bool gpio_read(gpio_port_t port, uint32_t pin)
{
    return (REG32(port + GPIO_IDR) & pin) != 0;
}

/**
 * @brief Read entire port
 * @param port GPIO port base address
 * @return Port input value
 */
uint32_t gpio_read_port(gpio_port_t port)
{
    return REG32(port + GPIO_IDR);
}

/**
 * @brief Configure alternate function
 * @param port GPIO port base address
 * @param pin Pin number
 * @param af Alternate function number (0-15)
 */
void gpio_set_af(gpio_port_t port, uint32_t pin, uint8_t af)
{
    int pin_num = 0;
    uint32_t *afr;

    while (!(pin & (1UL << pin_num)) && pin_num < 16) {
        pin_num++;
    }

    /* Select AFR register */
    afr = (pin_num < 8) ? (uint32_t *)(port + GPIO_AFRL) : 
                          (uint32_t *)(port + GPIO_AFRH);
    
    pin_num %= 8;

    /* Set alternate function */
    *afr &= ~(0x0FUL << (pin_num * 4));
    *afr |= (af << (pin_num * 4));
}
