/**
 * @file tests/blinky.c
 * @brief GPIO blinky test
 * @details Standalone blinky test program
 */

#include <stdint.h>
#include "../drivers/gpio.h"

/* External functions */
extern void System_Init(void);
extern void uart_init(uint32_t uart_base, uint32_t baudrate);
extern int printf(const char *fmt, ...);

/**
 * @brief Simple delay loop
 */
static void delay(volatile uint32_t count)
{
    while (count--) {
        __asm__("nop");
    }
}

/**
 * @brief Main entry point
 */
int main(void)
{
    System_Init();
    uart_init(0x50001000UL, 115200);

    printf("\n=== BLINKY Test ===\n");

    /* Initialize GPIOA Pin 5 */
    gpio_init(GPIOA_BASE);
    gpio_set_mode(GPIOA_BASE, GPIO_PIN_5, GPIO_MODE_OUTPUT);
    gpio_set_speed(GPIOA_BASE, GPIO_PIN_5, GPIO_SPEED_HIGH);

    printf("Toggling PA5...\n");

    /* Blink loop */
    while (1) {
        gpio_toggle(GPIOA_BASE, GPIO_PIN_5);
        delay(500000);
        
        gpio_toggle(GPIOA_BASE, GPIO_PIN_5);
        delay(500000);

        printf(".");
    }

    return 0;
}
