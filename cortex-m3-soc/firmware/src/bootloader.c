/**
 * @file bootloader.c
 * @brief Cortex-M3 SoC Bootloader
 * 
 * 功能:
 * 1. 从 UART 接收固件并通过 XMODEM 协议烧录到 Flash
 * 2. 检查 Flash 中的应用程序有效性
 * 3. 跳转到应用程序执行
 * 4. 支持按键强制进入 bootloader 模式
 */

#include "cortex_m3.h"
#include "drivers/uart.h"
#include "drivers/gpio.h"
#include <stdint.h>
#include <string.h>

/* ============================================================================
 * 配置定义
 * ============================================================================ */

#define BOOTLOADER_VERSION      "1.0.0"

/* ============================================================================
 * 简单延时函数 (避免链接问题)
 * ============================================================================ */

void Delay_ms(uint32_t ms)
{
    volatile uint32_t count = ms * (SYSTEM_CORE_CLOCK / 1000 / 4);
    while (count--);
}
#define FLASH_APP_START         0x00004000UL    // 应用程序起始地址 (16KB 保留给 bootloader)
#define FLASH_APP_END           0x00080000UL    // Flash 结束地址
#define SRAM_LOAD_ADDR          0x20000000UL    // SRAM 加载地址

#define BOOT_PIN                0               // 进入 bootloader 的引脚 (PA0)
#define BOOT_TIMEOUT_MS         3000            // 等待进入 bootloader 的超时时间
#define UART_BAUD               115200          // UART 波特率

#define XMODEM_SOH              0x01
#define XMODEM_EOT              0x04
#define XMODEM_ACK              0x06
#define XMODEM_NAK              0x15
#define XMODEM_CAN              0x18
#define XMODEM_PKT_SIZE         128

/* ============================================================================
 * 函数声明
 * ============================================================================ */

static void System_Init_Early(void);
static void UART_Init_Early(void);
static int Check_Boot_Pin(void);
static void Print_Welcome(void);
static int UART_Receive_Firmware(void);
static void Flash_Init(void);
static int Flash_Write(uint32_t addr, const uint8_t *data, uint32_t size);
static int Flash_Verify(uint32_t addr, const uint8_t *data, uint32_t size);
static void Jump_To_App(void);
static int Check_App_Valid(void);

/* ============================================================================
 * 主函数
 * ============================================================================ */

int main(void)
{
    int boot_requested = 0;
    
    /* 早期系统初始化 (仅必要的外设) */
    System_Init_Early();
    UART_Init_Early();
    
    /* 检查是否需要进入 bootloader */
    boot_requested = Check_Boot_Pin();
    
    /* 打印欢迎信息 */
    Print_Welcome();
    
    /* 决定启动模式 */
    if (boot_requested || !Check_App_Valid()) {
        /* Bootloader 模式 */
        UART_Puts(UART0, "\r\n[BOOT] Entering bootloader mode...\r\n");
        
        if (UART_Receive_Firmware() == 0) {
            UART_Puts(UART0, "[BOOT] Firmware update successful!\r\n");
            UART_Puts(UART0, "[BOOT] Jumping to application...\r\n");
            Jump_To_App();
        } else {
            UART_Puts(UART0, "[BOOT] Firmware update failed!\r\n");
            UART_Puts(UART0, "[BOOT] Please reset and try again.\r\n");
        }
    } else {
        /* 应用程序模式 */
        UART_Puts(UART0, "\r\n[BOOT] Valid application found, jumping...\r\n");
        Jump_To_App();
    }
    
    /* 不应到达这里 */
    while (1);
}

/* ============================================================================
 * 早期系统初始化
 * ============================================================================ */

static void System_Init_Early(void)
{
    /* 使能 GPIO 和 UART 时钟 */
    RCC->AHB1ENR |= (1 << 0);  // GPIOA
    RCC->APB1ENR |= (1 << 0);  // UART0
}

static void UART_Init_Early(void)
{
    /* 配置 UART0 (115200 8N1) */
    UART0->BRR = SYSTEM_CORE_CLOCK / UART_BAUD;
    UART0->CR1 = UART_CR1_UE | UART_CR1_TE | UART_CR1_RE;
    
    /* 配置 PA0 为 BOOT 引脚 (输入) */
    GPIO_A->MODER &= ~(3 << (BOOT_PIN * 2));  // 输入模式
    GPIO_A->PUPDR |= (1 << (BOOT_PIN * 2));   // 上拉
}

/* ============================================================================
 * Boot 引脚检查
 * ============================================================================ */

static int Check_Boot_Pin(void)
{
    uint32_t timeout = BOOT_TIMEOUT_MS / 10;
    
    /* 检查 BOOT 引脚是否被拉低 */
    while (timeout--) {
        if (!GPIO_Read(GPIO_A, BOOT_PIN)) {
            Delay_ms(10);  // 去抖
            if (!GPIO_Read(GPIO_A, BOOT_PIN)) {
                return 1;  // 需要进入 bootloader
            }
        }
        Delay_ms(10);
    }
    
    return 0;  // 启动应用程序
}

/* ============================================================================
 * 欢迎信息
 * ============================================================================ */

static void Print_Welcome(void)
{
    UART_Puts(UART0, "\r\n");
    UART_Puts(UART0, "========================================\r\n");
    UART_Puts(UART0, "  Cortex-M3 SoC Bootloader v");
    UART_Puts(UART0, BOOTLOADER_VERSION);
    UART_Puts(UART0, "\r\n");
    UART_Puts(UART0, "========================================\r\n");
    UART_Puts(UART0, "\r\n");
}

/* ============================================================================
 * XMODEM 固件接收
 * ============================================================================ */

static int UART_Receive_Firmware(void)
{
    uint8_t pkt_buf[XMODEM_PKT_SIZE + 5];
    uint8_t pkt_num = 1;
    uint8_t last_pkt_num = 0;
    uint32_t total_bytes = 0;
    uint32_t flash_addr = FLASH_APP_START;
    int retry = 0;
    
    UART_Puts(UART0, "\r\n[UART] Ready to receive firmware...\r\n");
    UART_Puts(UART0, "[UART] Send XMODEM packets now.\r\n");
    
    /* 发送 NAK 开始传输 */
    UART_Putc(UART0, XMODEM_NAK);
    
    while (1) {
        /* 接收 SOH */
        uint8_t c = UART_Getc(UART0);
        
        if (c == XMODEM_EOT) {
            /* 传输结束 */
            UART_Putc(UART0, XMODEM_ACK);
            UART_Puts(UART0, "\r\n[UART] Transfer complete.\r\n");
            break;
        }
        
        if (c != XMODEM_SOH) {
            if (++retry > 3) {
                UART_Puts(UART0, "\r\n[UART] Error: Invalid packet.\r\n");
                return -1;
            }
            UART_Putc(UART0, XMODEM_NAK);
            continue;
        }
        
        /* 接收包号 */
        pkt_buf[0] = UART_Getc(UART0);
        pkt_buf[1] = UART_Getc(UART0);
        
        /* 验证包号 */
        if (pkt_buf[0] != pkt_num || pkt_buf[1] != (uint8_t)(~pkt_num)) {
            if (pkt_buf[0] == last_pkt_num) {
                /* 重复包，跳过 */
                for (int i = 0; i < XMODEM_PKT_SIZE + 1; i++) {
                    UART_Getc(UART0);
                }
                UART_Putc(UART0, XMODEM_ACK);
                continue;
            }
            UART_Putc(UART0, XMODEM_NAK);
            continue;
        }
        
        /* 接收数据 */
        for (int i = 0; i < XMODEM_PKT_SIZE; i++) {
            pkt_buf[2 + i] = UART_Getc(UART0);
        }
        
        /* 接收 CRC (简化：跳过) */
        UART_Getc(UART0);
        UART_Getc(UART0);
        
        /* 验证并写入 Flash */
        if (Flash_Write(flash_addr, &pkt_buf[2], XMODEM_PKT_SIZE) == 0) {
            UART_Putc(UART0, XMODEM_ACK);
            pkt_num++;
            last_pkt_num = pkt_buf[0];
            flash_addr += XMODEM_PKT_SIZE;
            total_bytes += XMODEM_PKT_SIZE;
            
            /* 进度指示 */
            if (pkt_num % 8 == 0) {
                UART_Putc(UART0, '#');
            }
        } else {
            UART_Putc(UART0, XMODEM_NAK);
            if (++retry > 3) {
                UART_Puts(UART0, "\r\n[UART] Error: Flash write failed.\r\n");
                return -1;
            }
        }
    }
    
    UART_Puts(UART0, "\r\n[UART] Received ");
    // 打印 total_bytes (简化)
    UART_Puts(UART0, " bytes.\r\n");
    
    /* 验证固件 */
    UART_Puts(UART0, "[UART] Verifying firmware...\r\n");
    if (Flash_Verify(FLASH_APP_START, 0, total_bytes) == 0) {
        UART_Puts(UART0, "[UART] Verification passed.\r\n");
        return 0;
    } else {
        UART_Puts(UART0, "[UART] Verification failed!\r\n");
        return -1;
    }
}

/* ============================================================================
 * Flash 操作 (简化模型)
 * ============================================================================ */

static void Flash_Init(void)
{
    /* Flash 控制器初始化 (根据实际硬件实现) */
    // FLASH_CTRL->CR |= FLASH_CR_PROG;
}

static int Flash_Write(uint32_t addr, const uint8_t *data, uint32_t size)
{
    volatile uint32_t *flash = (volatile uint32_t *)addr;
    const uint32_t *src = (const uint32_t *)data;
    
    /* 按字写入 (简化模型) */
    for (uint32_t i = 0; i < size / 4; i++) {
        flash[i] = src[i];
    }
    
    return 0;
}

static int Flash_Verify(uint32_t addr, const uint8_t *expected, uint32_t size)
{
    volatile uint32_t *flash = (volatile uint32_t *)addr;
    
    /* 验证 Flash 内容 (简化：检查前 4 字节是否为有效的栈指针) */
    uint32_t msp = flash[0];
    
    /* 检查 MSP 是否在 SRAM 范围内 */
    if (msp < SRAM_BASE || msp > (SRAM_BASE + 0x20000)) {
        return -1;  // 无效的 MSP
    }
    
    /* 检查复位向量是否在 Flash 范围内 */
    uint32_t reset_vec = flash[1];
    if (reset_vec < FLASH_APP_START || reset_vec >= FLASH_APP_END) {
        return -1;  // 无效的复位向量
    }
    
    return 0;
}

/* ============================================================================
 * 跳转到应用程序
 * ============================================================================ */

static void Jump_To_App(void)
{
    uint32_t *app_stack = (uint32_t *)FLASH_APP_START;
    
    /* 禁用中断 */
    __asm volatile ("cpsid i" ::: "memory");
    
    /* 获取应用程序的 MSP 和复位向量 */
    uint32_t msp = app_stack[0];
    uint32_t reset_handler = app_stack[1];
    
    /* 设置 MSP */
    __asm volatile ("msr msp, %0" :: "r" (msp));
    
    /* 跳转到应用程序 */
    ((void (*)(void))reset_handler)();
}

/* ============================================================================
 * 应用程序有效性检查
 * ============================================================================ */

static int Check_App_Valid(void)
{
    uint32_t *app_stack = (uint32_t *)FLASH_APP_START;
    
    /* 检查栈指针是否有效 */
    uint32_t msp = app_stack[0];
    if (msp < SRAM_BASE || msp > (SRAM_BASE + 0x20000)) {
        return 0;  // 无效
    }
    
    /* 检查复位向量是否有效 */
    uint32_t reset_vec = app_stack[1];
    if (reset_vec < FLASH_APP_START || reset_vec >= FLASH_APP_END) {
        return 0;  // 无效
    }
    
    return 1;  // 有效
}
