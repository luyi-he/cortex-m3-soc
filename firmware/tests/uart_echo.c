/**
 * @file tests/uart_echo.c
 * @brief UART echo test
 * @details Echo received characters back
 */

#include <stdint.h>
#include "../drivers/uart.h"

/* External functions */
extern void System_Init(void);
extern int printf(const char *fmt, ...);

/**
 * @brief Main entry point
 */
int main(void)
{
    char c;

    System_Init();
    uart_init(UART0_BASE, 115200);

    printf("\n=== UART Echo Test ===\n");
    printf("Type characters to echo back\n");
    printf("Send 'q' to quit\n\n");

    /* Echo loop */
    while (1) {
        if (uart_rx_ready(UART0_BASE)) {
            c = uart_rx(UART0_BASE);
            uart_tx(UART0_BASE, c);

            if (c == 'q') {
                printf("\nEcho test completed\n");
                break;
            }
        }
    }

    return 0;
}
