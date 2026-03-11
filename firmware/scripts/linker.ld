/* ============================================================================
 * Cortex-M3 SoC 链接脚本
 * 根据 arch_spec_v1.0.md 定义
 * ============================================================================ */

/* 入口点 */
ENTRY(Reset_Handler)

/* 内存布局 */
MEMORY
{
    FLASH (rx)  : ORIGIN = 0x00000000, LENGTH = 512K
    SRAM_ITCM (rwx) : ORIGIN = 0x20000000, LENGTH = 64K
    SRAM_DTCM (rwx) : ORIGIN = 0x20010000, LENGTH = 64K
}

/* 栈大小 */
_Min_Heap_Size = 0x200;
_Min_Stack_Size = 0x400;

/* 段定义 */
SECTIONS
{
    /* 中断向量表 */
    .isr_vector :
    {
        . = ALIGN(4);
        KEEP(*(.isr_vector))
        . = ALIGN(4);
    } >FLASH

    /* 代码段 */
    .text :
    {
        . = ALIGN(4);
        *(.text)
        *(.text*)
        *(.rodata)
        *(.rodata*)
        . = ALIGN(4);
        _etext = .;
    } >FLASH

    /* 初始化数据段 */
    _sidata = LOADADDR(.data);
    
    .data :
    {
        . = ALIGN(4);
        _sdata = .;
        *(.data)
        *(.data*)
        . = ALIGN(4);
        _edata = .;
    } >SRAM_ITCM AT> FLASH

    /* 未初始化数据段 */
    .bss :
    {
        . = ALIGN(4);
        _sbss = .;
        __bss_start__ = _sbss;
        *(.bss)
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;
        __bss_end__ = _ebss;
    } >SRAM_ITCM

    /* 堆栈检查 */
    ._user_heap_stack :
    {
        . = ALIGN(8);
        PROVIDE(end = .);
        PROVIDE(_end = .);
        . = . + _Min_Heap_Size;
        . = . + _Min_Stack_Size;
        . = ALIGN(8);
    } >SRAM_DTCM

    /* 移除不需要的段 */
    /DISCARD/ :
    {
        libc.a(*)
        libm.a(*)
        libgcc.a(*)
    }

    /* ARM 异常处理 */
    .ARM.attributes 0 : { *(.ARM.attributes) }
}

/* 栈底地址 (栈向下增长) */
_estack = ORIGIN(SRAM_DTCM) + LENGTH(SRAM_DTCM);
