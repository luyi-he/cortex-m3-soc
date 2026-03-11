/**
 * @file uart.h
 * @brief UART driver header
 * @details Based on architecture spec v1.0 Section 3.2
 */

#ifndef __UART_H__
#define __UART_H__

#include <stdint.h>
#include <stdbool.h>

/* UART Base Addresses (Section 2.3) */
#define UART0_BASE  0x50001000UL
#define UART1_BASE  0x50001400UL

/* UART Register Offsets (Section 3.2) */
#define UART_CR1    0x00  /* Control register 1 */
#define UART_CR2    0x04  /* Control register 2 */
#define UART_CR3    0x08  /* Control register 3 */
#define UART_BRR    0x0C  /* Baud rate register */
#define UART_SR     0x10  /* Status register */
#define UART_DR     0x14  /* Data register */

/* CR1 bits */
#define UART_CR1_UE     (1UL << 0)   /* USART enable */
#define UART_CR1_RE     (1UL << 2)   /* Receiver enable */
#define UART_CR1_TE     (1UL << 3)   /* Transmitter enable */
#define UART_CR1_RXNEIE (1UL << 5)   /* RXNE interrupt enable */
#define UART_CR1_TCIE   (1UL << 6)   /* Transmission complete interrupt */
#define UART_CR1_TXEIE  (1UL << 7)   /* TXE interrupt enable */

/* CR2 bits */
#define UART_CR2_STOP   (3UL << 12)  /* STOP bits */

/* CR3 bits */
#define UART_CR3_HDSEL  (1UL << 3)   /* Half-duplex selection */

/* SR bits */
#define UART_SR_PE      (1UL << 0)   /* Parity error */
#define UART_SR_FE      (1UL << 1)   /* Framing error */
#define UART_SR_NE      (1UL << 2)   /* Noise error */
#define UART_SR_ORE     (1UL << 3)   /* Overrun error */
#define UART_SR_IDLE    (1UL << 4)   /* IDLE line detected */
#define UART_SR_RXNE    (1UL << 5)   /* Read data register not empty */
#define UART_SR_TC      (1UL << 6)   /* Transmission complete */
#define UART_SR_TXE     (1UL << 7)   /* Transmit data register empty */

/* UART handle */
typedef struct {
    uint32_t base;
    uint32_t baudrate;
    bool initialized;
} uart_handle_t;

/* Function prototypes */
void uart_init(void *uart_base, uint32_t baudrate);
void uart_deinit(void *uart_base);

void uart_tx(void *uart_base, char c);
char uart_rx(void *uart_base);

bool uart_tx_ready(void *uart_base);
bool uart_rx_ready(void *uart_base);

void uart_puts(void *uart_base, const char *str);
void uart_write(void *uart_base, const uint8_t *data, uint32_t len);
uint32_t uart_read(void *uart_base, uint8_t *data, uint32_t len);

void uart_enable_rx_interrupt(void *uart_base);
void uart_disable_rx_interrupt(void *uart_base);

/* Aliases for bootloader compatibility */
#define UART_Puts     uart_puts
#define UART_Putc     uart_tx
#define UART_Getc     uart_rx

#endif /* __UART_H__ */
