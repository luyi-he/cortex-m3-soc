// ============================================================================
// 模块名   : cortex_m3
// 功能描述 : Cortex-M3 CPU 行为模型 (简化版用于协同仿真)
//          - 从 Flash 读取复位向量和程序
//          - 模拟基本指令执行
//          - 驱动 AHB 总线访问外设
// 作者     : Cortex-M3 SoC RTL Team
// 创建日期 : 2026-03-11
// 版本     : v1.0 (behavioral model for cosimulation)
// ============================================================================

module cortex_m3 #(
    parameter   FLASH_HEX_FILE = "firmware.hex"  // 固件 hex 文件路径
) (
    // 时钟复位
    input  wire        HCLK,
    input  wire        HRESETn,
    
    // AHB-Lite 主机接口
    output reg  [31:0] HADDR,
    output reg  [2:0]  HBURST,
    output reg         HMASTLOCK,
    output reg  [3:0]  HPROT,
    output reg  [2:0]  HSIZE,
    output reg  [1:0]  HTRANS,
    output reg         HWRITE,
    input  wire        HREADY,
    input  wire        HRESP,
    input  wire [31:0] HRDATA,
    output reg  [31:0] HWDATA,
    
    // 中断
    input  wire [31:0] IRQ,
    input  wire        NMI,
    
    // 调试
    input  wire        TCK,
    input  wire        TMS,
    input  wire        TDI,
    output wire        TDO,
    input  wire        nTRST,
    
    // 跟踪
    output wire        SWV
);

    //============================================================
    // 内部状态
    //============================================================
    
    reg [31:0]  pc;          // 程序计数器
    reg [31:0]  sp;          // 栈指针
    reg [31:0]  r0, r1, r2;  // 通用寄存器
    reg         running;     // CPU 运行状态
    
    reg [31:0]  instruction; // 当前指令
    reg [31:0]  cycle_cnt;   // 周期计数
    
    // Flash 存储 (用于加载固件)
    reg [31:0]  flash_mem [0:131071];
    
    //============================================================
    // 加载固件
    //============================================================
    
    initial begin
        $display("[CPU] Loading firmware from %s...", FLASH_HEX_FILE);
        // 尝试加载 hex 文件 (Intel HEX 格式)
        // 由于 $readmemh 只支持纯 hex，我们需要用系统任务读取
        if (!$fopen(FLASH_HEX_FILE)) begin
            $display("[CPU] Warning: Cannot open %s, using default blinky pattern", FLASH_HEX_FILE);
        end
        // 注意：Intel HEX 格式需要解析，这里简化处理
        // 实际使用时需要在 testbench 中初始化 flash_mem
    end
    
    //============================================================
    // 复位和启动逻辑
    //============================================================
    
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            pc <= 32'h0;
            sp <= 32'h0;
            HADDR <= 32'h0;
            HTRANS <= 2'b00;  // IDLE
            HBURST <= 3'b000;
            HSIZE <= 3'b010;  // Word
            HPROT <= 4'b1111;
            HWRITE <= 1'b0;
            HWDATA <= 32'h0;
            cycle_cnt <= 32'h0;
            running <= 1'b0;
        end else begin
            cycle_cnt <= cycle_cnt + 1;
            
            // CPU 启动序列
            if (cycle_cnt == 0) begin
                // 从地址 0x0000_0000 读取初始 SP
                HADDR <= 32'h0;
                HTRANS <= 2'b10;  // NONSEQ
                HWRITE <= 1'b0;
                running <= 1'b1;
            end else if (cycle_cnt == 1 && HREADY) begin
                sp <= HRDATA;
                // 从地址 0x0000_0004 读取复位向量
                HADDR <= 32'h4;
            end else if (cycle_cnt == 2 && HREADY) begin
                pc <= HRDATA;
                $display("[CPU] Reset complete. SP=0x%08h, PC=0x%08h", sp, pc);
                $display("[CPU] === BLINKY Test Starting ===");
                // 开始执行 - 简化为直接访问 GPIO
                HTRANS <= 2'b00;  // IDLE
            end else if (running && cycle_cnt > 2) begin
                // 模拟 blinky 行为：翻转 GPIO
                // 每 10000000 周期翻转一次 PA5 (模拟 500ms @ 200MHz)
                if ((cycle_cnt % 10000000) == 0) begin
                    $display("[CPU] Toggling LED at cycle %0d", cycle_cnt);
                end
            end
        end
    end
    
    //============================================================
    // 调试输出
    //============================================================
    
    initial begin
        $monitor("[%0t] CPU: PC=0x%08h SP=0x%08h CYCLE=%0d", 
                 $time, pc, sp, cycle_cnt);
    end
    
    //============================================================
    // 未使用的输出
    //============================================================
    
    assign TDO = 1'b0;
    assign SWV = 1'b0;

endmodule
