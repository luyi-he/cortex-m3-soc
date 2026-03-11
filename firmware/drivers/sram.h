/**
 * @file sram.h
 * @brief SRAM test driver header
 * @details Memory test utilities for SRAM and Flash
 */

#ifndef __SRAM_H__
#define __SRAM_H__

#include <stdint.h>
#include <stdbool.h>

/* SRAM base address and size (Section 2.1) */
#define SRAM_BASE   0x20000000UL
#define SRAM_SIZE   (128 * 1024UL)

/* Flash base address and size (Section 2.1) */
#define FLASH_BASE  0x00000000UL
#define FLASH_SIZE  (512 * 1024UL)

/* Test result structure */
typedef struct {
    bool passed;
    uint32_t error_addr;
    uint32_t expected;
    uint32_t actual;
    uint32_t pattern;
} sram_result_t;

/* Test patterns */
#define PATTERN_ZERO        0x00000000UL
#define PATTERN_ONES        0xFFFFFFFFUL
#define PATTERN_ALT_01      0xAAAAAAAAUL
#define PATTERN_ALT_10      0x55555555UL
#define PATTERN_WALKING_1   0x00000001UL
#define PATTERN_ADDR        0x00000001UL

/* Function prototypes */
sram_result_t sram_test(uint32_t *start, uint32_t size_words);
sram_result_t sram_test_pattern(uint32_t *start, uint32_t size_words, uint32_t pattern);
sram_result_t sram_test_walking(uint32_t *start, uint32_t size_words);
sram_result_t sram_test_address(uint32_t *start, uint32_t size_words);

bool flash_test(uint32_t *start, uint32_t size_words);

void memory_fill(uint32_t *start, uint32_t size_words, uint32_t value);
bool memory_verify(uint32_t *start, uint32_t size_words, uint32_t value);

#endif /* __SRAM_H__ */
