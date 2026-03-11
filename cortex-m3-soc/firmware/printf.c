/**
 * @file printf.c
 * @brief Lightweight printf implementation via UART
 * @details Minimal footprint printf for embedded systems
 */

#include <stdint.h>
#include <stdarg.h>
#include <stdbool.h>

/* External UART functions */
extern void uart_tx(uint32_t uart_base, char c);

/**
 * @brief Convert integer to string
 */
static int int_to_str(char *buf, int size, long value, int base, bool uppercase)
{
    char *p = buf;
    char *p1, *p2;
    unsigned long uvalue;
    char tmp;
    int len = 0;

    /* Handle negative numbers */
    if (base == 10 && value < 0) {
        if (len < size) buf[len++] = '-';
        uvalue = -value;
    } else {
        uvalue = (unsigned long)value;
    }

    /* Convert number */
    p1 = p2 = buf + len;
    if (uvalue == 0) {
        if (len < size) *p2++ = '0';
    } else {
        while (uvalue && p2 < buf + size) {
            int digit = uvalue % base;
            *p2++ = (digit < 10) ? ('0' + digit) : 
                    (uppercase ? ('A' + digit - 10) : ('a' + digit - 10));
            uvalue /= base;
        }
    }

    /* Reverse string */
    p2--;
    while (p1 < p2) {
        tmp = *p1;
        *p1 = *p2;
        *p2 = tmp;
        p1++;
        p2--;
    }

    return p2 - buf + 1;
}

/**
 * @brief Output a single character
 */
static void putchar(char c)
{
    if (c == '\n') {
        uart_tx((uint32_t)0x50001000UL, '\r');
        uart_tx((uint32_t)0x50001000UL, '\n');
    } else {
        uart_tx((uint32_t)0x50001000UL, c);
    }
}

/**
 * @brief Lightweight printf implementation
 */
int printf(const char *fmt, ...)
{
    va_list args;
    char c;
    char buf[32];
    int count = 0;

    va_start(args, fmt);

    while ((c = *fmt++) != '\0') {
        if (c != '%') {
            putchar(c);
            count++;
            continue;
        }

        c = *fmt++;
        if (c == '\0') break;

        switch (c) {
            case 'd':
            case 'i':
                count += int_to_str(buf, sizeof(buf), va_arg(args, int), 10, false);
                printf("%s", buf);
                break;

            case 'u':
                count += int_to_str(buf, sizeof(buf), va_arg(args, unsigned int), 10, false);
                printf("%s", buf);
                break;

            case 'x':
                count += int_to_str(buf, sizeof(buf), va_arg(args, unsigned int), 16, false);
                printf("%s", buf);
                break;

            case 'X':
                count += int_to_str(buf, sizeof(buf), va_arg(args, unsigned int), 16, true);
                printf("%s", buf);
                break;

            case 'p':
                putchar('0');
                putchar('x');
                count += 2;
                count += int_to_str(buf, sizeof(buf), (long)va_arg(args, void *), 16, false);
                printf("%s", buf);
                break;

            case 's':
                {
                    char *str = va_arg(args, char *);
                    if (str == 0) str = "(null)";
                    while (*str) {
                        putchar(*str++);
                        count++;
                    }
                }
                break;

            case 'c':
                putchar(va_arg(args, int));
                count++;
                break;

            case '%':
                putchar('%');
                count++;
                break;

            default:
                putchar('%');
                putchar(c);
                count += 2;
                break;
        }
    }

    va_end(args);
    return count;
}

/**
 * @brief Print a hexadecimal dump
 */
void hexdump(const void *data, uint32_t addr, uint32_t size)
{
    const uint8_t *p = (const uint8_t *)data;
    uint32_t i, j;

    for (i = 0; i < size; i += 16) {
        printf("%08X: ", addr + i);

        /* Hex values */
        for (j = 0; j < 16 && (i + j) < size; j++) {
            printf("%02X ", p[i + j]);
        }

        /* Fill remaining spaces */
        for (; j < 16; j++) {
            printf("   ");
        }

        /* ASCII values */
        printf(" |");
        for (j = 0; j < 16 && (i + j) < size; j++) {
            char c = p[i + j];
            putchar((c >= 32 && c < 127) ? c : '.');
        }
        printf("|\n");
    }
}
