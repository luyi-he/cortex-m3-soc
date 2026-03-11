/**
 * @file sram.c
 * @brief SRAM test driver implementation
 * @details Memory test utilities for SRAM and Flash
 */

#include "sram.h"

/**
 * @brief Fill memory with a pattern
 * @param start Start address
 * @param size_words Size in 32-bit words
 * @param value Fill value
 */
void memory_fill(uint32_t *start, uint32_t size_words, uint32_t value)
{
    for (uint32_t i = 0; i < size_words; i++) {
        start[i] = value;
    }
}

/**
 * @brief Verify memory contains expected value
 * @param start Start address
 * @param size_words Size in 32-bit words
 * @param value Expected value
 * @return true if all matches, false otherwise
 */
bool memory_verify(uint32_t *start, uint32_t size_words, uint32_t value)
{
    for (uint32_t i = 0; i < size_words; i++) {
        if (start[i] != value) {
            return false;
        }
    }
    return true;
}

/**
 * @brief Test SRAM with multiple patterns
 * @param start Start address
 * @param size_words Size in 32-bit words
 * @return Test result
 */
sram_result_t sram_test(uint32_t *start, uint32_t size_words)
{
    sram_result_t result;
    uint32_t patterns[] = {
        PATTERN_ZERO,
        PATTERN_ONES,
        PATTERN_ALT_01,
        PATTERN_ALT_10
    };

    /* Test each pattern */
    for (int i = 0; i < 4; i++) {
        result = sram_test_pattern(start, size_words, patterns[i]);
        if (!result.passed) {
            return result;
        }
    }

    /* Walking 1 test */
    result = sram_test_walking(start, size_words);
    if (!result.passed) {
        return result;
    }

    /* Address test */
    result = sram_test_address(start, size_words);
    if (!result.passed) {
        return result;
    }

    /* All tests passed */
    result.passed = true;
    result.error_addr = 0;
    result.expected = 0;
    result.actual = 0;
    return result;
}

/**
 * @brief Test SRAM with a specific pattern
 * @param start Start address
 * @param size_words Size in 32-bit words
 * @param pattern Test pattern
 * @return Test result
 */
sram_result_t sram_test_pattern(uint32_t *start, uint32_t size_words, uint32_t pattern)
{
    sram_result_t result;

    /* Write pattern */
    memory_fill(start, size_words, pattern);

    /* Verify */
    for (uint32_t i = 0; i < size_words; i++) {
        if (start[i] != pattern) {
            result.passed = false;
            result.error_addr = (uint32_t)&start[i];
            result.expected = pattern;
            result.actual = start[i];
            result.pattern = pattern;
            return result;
        }
    }

    result.passed = true;
    return result;
}

/**
 * @brief Walking 1 test
 * @param start Start address
 * @param size_words Size in 32-bit words
 * @return Test result
 */
sram_result_t sram_test_walking(uint32_t *start, uint32_t size_words)
{
    sram_result_t result;
    uint32_t pattern;

    /* Minimum test size */
    if (size_words < 32) {
        size_words = 32;
    }

    /* Walking 1 test */
    for (int bit = 0; bit < 32; bit++) {
        pattern = (1UL << bit);
        
        /* Write pattern to first word */
        start[0] = pattern;

        /* Verify */
        if (start[0] != pattern) {
            result.passed = false;
            result.error_addr = (uint32_t)&start[0];
            result.expected = pattern;
            result.actual = start[0];
            result.pattern = pattern;
            return result;
        }
    }

    result.passed = true;
    return result;
}

/**
 * @brief Address line test
 * @param start Start address
 * @param size_words Size in 32-bit words
 * @return Test result
 */
sram_result_t sram_test_address(uint32_t *start, uint32_t size_words)
{
    sram_result_t result;

    /* Write address as data */
    for (uint32_t i = 0; i < size_words; i++) {
        start[i] = (uint32_t)&start[i];
    }

    /* Verify */
    for (uint32_t i = 0; i < size_words; i++) {
        if (start[i] != (uint32_t)&start[i]) {
            result.passed = false;
            result.error_addr = (uint32_t)&start[i];
            result.expected = (uint32_t)&start[i];
            result.actual = start[i];
            result.pattern = 0;
            return result;
        }
    }

    result.passed = true;
    return result;
}

/**
 * @brief Test Flash memory (read-only test)
 * @param start Start address
 * @param size_words Size in 32-bit words
 * @return true if test passed
 */
bool flash_test(uint32_t *start, uint32_t size_words)
{
    uint32_t checksum = 0;

    /* Calculate checksum */
    for (uint32_t i = 0; i < size_words; i++) {
        checksum ^= start[i];
    }

    /* Flash is readable, just verify we can access it */
    return (checksum != 0xFFFFFFFF);
}
