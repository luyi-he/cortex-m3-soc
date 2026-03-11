/**
 * @file uart.c
 * @brief UART driver implementation
 * @details Based on architecture spec v1.0 Section 3.2
 */

#include "uart.h"
#include <stdint.h>

/* Register access macros */
#define REG32(addr) (*(volatile uint32_t *)(uintptr_t)(addr))

/* System clock (from system.c) */
extern uint32_t SystemCoreClock_Get(void);

/* APB clock = HCLK / 2 = 100MHz */
#define APB_CLOCK (SystemCoreClock_Get() / 2)

/**
 * @brief Initialize UART
 * @param uart_base UART base address
 * @param baudrate Baud rate
 */
void uart_init(void *uart_base, uint32_t baudrate)
{
    uint32_t brr_value;

    /* Disable UART during configuration */
    REG32((uintptr_t)uart_base + UART_CR1) &= ~UART_CR1_UE;

    /* Configure baud rate */
    /* BRR = f_CLK / baudrate */
    brr_value = APB_CLOCK / baudrate;
    REG32((uintptr_t)uart_base + UART_BRR) = brr_value;

    /* Configure control registers */
    /* Enable: TX, RX */
    REG32((uintptr_t)uart_base + UART_CR1) = UART_CR1_UE | UART_CR1_TE | UART_CR1_RE;

    /* Configure STOP bits (1 stop bit) */
    REG32((uintptr_t)uart_base + UART_CR2) = 0x00000000;

    /* Clear status register */
    REG32((uintptr_t)uart_base + UART_SR) = 0x00;
}

/**
 * @brief Deinitialize UART
 * @param uart_base UART base address
 */
void uart_deinit(void *uart_base)
{
    /* Disable UART */
    REG32((uintptr_t)uart_base + UART_CR1) = 0x00000000;
}

/**
 * @brief Transmit a character
 * @param uart_base UART base address
 * @param c Character to transmit
 */
void uart_tx(void *uart_base, char c)
{
    /* Wait until TXE (transmit data register empty) */
    while (!(REG32((uintptr_t)uart_base + UART_SR) & UART_SR_TXE));

    /* Write data */
    REG32((uintptr_t)uart_base + UART_DR) = c & 0xFF;

    /* Wait until TC (transmission complete) */
    while (!(REG32((uintptr_t)uart_base + UART_SR) & UART_SR_TC));
}

/**
 * @brief Receive a character
 * @param uart_base UART base address
 * @return Received character
 */
char uart_rx(void *uart_base)
{
    /* Wait until RXNE (read data register not empty) */
    while (!(REG32((uintptr_t)uart_base + UART_SR) & UART_SR_RXNE));

    /* Read data */
    return (char)(REG32((uintptr_t)uart_base + UART_DR) & 0xFF);
}

/**
 * @brief Check if transmitter is ready
 * @param uart_base UART base address
 * @return true if TX is ready
 */
bool uart_tx_ready(void *uart_base)
{
    return (REG32((uintptr_t)uart_base + UART_SR) & UART_SR_TXE) != 0;
}

/**
 * @brief Check if receiver has data
 * @param uart_base UART base address
 * @return true if RX has data
 */
bool uart_rx_ready(void *uart_base)
{
    return (REG32((uintptr_t)uart_base + UART_SR) & UART_SR_RXNE) != 0;
}

/**
 * @brief Transmit a string
 * @param uart_base UART base address
 * @param str String to transmit
 */
void uart_puts(void *uart_base, const char *str)
{
    while (*str) {
        uart_tx(uart_base, *str++);
    }
}

/**
 * @brief Transmit a buffer
 * @param uart_base UART base address
 * @param data Data buffer
 * @param len Number of bytes
 */
void uart_write(void *uart_base, const uint8_t *data, uint32_t len)
{
    for (uint32_t i = 0; i < len; i++) {
        uart_tx(uart_base, data[i]);
    }
}

/**
 * @brief Receive a buffer
 * @param uart_base UART base address
 * @param data Data buffer
 * @param len Maximum number of bytes
 * @return Number of bytes received
 */
uint32_t uart_read(void *uart_base, uint8_t *data, uint32_t len)
{
    uint32_t count = 0;

    while (count < len && uart_rx_ready(uart_base)) {
        data[count++] = uart_rx(uart_base);
    }

    return count;
}

/**
 * @brief Enable RX interrupt
 * @param uart_base UART base address
 */
void uart_enable_rx_interrupt(void *uart_base)
{
    REG32((uintptr_t)uart_base + UART_CR1) |= UART_CR1_RXNEIE;
}

/**
 * @brief Disable RX interrupt
 * @param uart_base UART base address
 */
void uart_disable_rx_interrupt(void *uart_base)
{
    REG32((uintptr_t)uart_base + UART_CR1) &= ~UART_CR1_RXNEIE;
}
