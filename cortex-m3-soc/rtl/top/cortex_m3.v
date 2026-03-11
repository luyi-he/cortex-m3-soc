// ============================================================================
// 模块名   : cortex_m3
// 功能描述 : Cortex-M3 CPU 行为模型 v2.0 (用于协同仿真)
//          - 从 Flash 读取复位向量和程序
//          - 模拟 Thumb/Thumb-2 指令执行
//          - 驱动 AHB 总线访问外设
//          - 支持 GPIO 访问模拟
// 作者     : Cortex-M3 SoC RTL Team
// 创建日期 : 2026-03-11
// 版本     : v2.0 (支持指令执行)
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
    
    reg [31:0]  pc;          // 程序计数器 (Thumb 模式 bit[0]=1)
    reg [31:0]  sp;          // 栈指针 (MSP)
    reg [31:0]  lr;          // 链接寄存器
    reg [31:0]  r0, r1, r2, r3, r4, r5, r6, r7;  // 通用寄存器 r0-r7
    
    reg [31:0]  instruction; // 当前指令 (32-bit Thumb-2)
    reg [31:0]  cycle_cnt;   // 周期计数
    
    // CPU 状态机
    reg [2:0]   cpu_state;
    localparam  STATE_RESET   = 3'h0,
                STATE_FETCHSP = 3'h1,
                STATE_FETCHPC = 3'h2,
                STATE_FETCH   = 3'h3,
                STATE_DECODE  = 3'h4,
                STATE_EXECUTE = 3'h5,
                STATE_HALT    = 3'h6;
    
    // GPIO 输出寄存器 (用于模拟 blinky)
    reg [15:0]  gpio_out;
    
    //============================================================
    // 初始化
    //============================================================
    
    initial begin
        gpio_out = 16'h0;
        
        $display("");
        $display("========================================");
        $display("[CPU] Initializing Cortex-M3 v2.0...");
        $display("[CPU] Thumb-2 Instruction Set Support");
        $display("[CPU] GPIO Simulation Enabled");
        $display("========================================");
        $display("");
    end
    
    //============================================================
    // CPU 状态机
    //============================================================
    
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            // 复位
            pc <= 32'h0;
            sp <= 32'h0;
            lr <= 32'h0;
            r0 <= 32'h0; r1 <= 32'h0; r2 <= 32'h0; r3 <= 32'h0;
            r4 <= 32'h0; r5 <= 32'h0; r6 <= 32'h0; r7 <= 32'h0;
            
            HADDR <= 32'h0;
            HTRANS <= 2'b00;  // IDLE
            HBURST <= 3'b000;
            HSIZE <= 3'b010;  // Word
            HPROT <= 4'b1111;
            HWRITE <= 1'b0;
            HWDATA <= 32'h0;
            
            cycle_cnt <= 32'h0;
            cpu_state <= STATE_RESET;
            instruction <= 32'h0;
        end else begin
            cycle_cnt <= cycle_cnt + 1;
            
            case (cpu_state)
                //============================================================
                // 复位状态
                //============================================================
                STATE_RESET: begin
                    $display("[CPU] Starting reset sequence...");
                    HADDR <= 32'h0;
                    HTRANS <= 2'b10;  // NONSEQ
                    cpu_state <= STATE_FETCHSP;
                end
                
                //============================================================
                // 获取栈指针
                //============================================================
                STATE_FETCHSP: begin
                    if (HREADY) begin
                        sp <= HRDATA;
                        $display("[CPU] MSP = 0x%08h", HRDATA);
                        HADDR <= 32'h4;
                        cpu_state <= STATE_FETCHPC;
                    end
                end
                
                //============================================================
                // 获取 PC (复位向量)
                //============================================================
                STATE_FETCHPC: begin
                    if (HREADY) begin
                        pc <= HRDATA | 32'h1;  // Thumb 模式
                        $display("[CPU] Reset Vector = 0x%08h (Thumb)", HRDATA);
                        $display("[CPU] ========================================");
                        $display("[CPU] Cortex-M3 Ready!");
                        $display("[CPU] ========================================");
                        $display("");
                        
                        // 开始取指
                        HADDR <= pc & ~32'h3;
                        HTRANS <= 2'b10;
                        cpu_state <= STATE_FETCH;
                    end
                end
                
                //============================================================
                // 取指阶段
                //============================================================
                STATE_FETCH: begin
                    if (HREADY) begin
                        instruction <= HRDATA;
                        cpu_state <= STATE_DECODE;
                    end
                end
                
                //============================================================
                // 译码阶段
                //============================================================
                STATE_DECODE: begin
                    cpu_state <= STATE_EXECUTE;
                end
                
                //============================================================
                // 执行阶段
                //============================================================
                STATE_EXECUTE: begin
                    //========================================================
                    // BLX - 带链接的分支并交换
                    //========================================================
                    if (instruction[27:25] == 3'b111 && instruction[12:8] == 5'b11111) begin
                        $display("[CPU] BLX Rm");
                        lr <= pc + 32'h1;
                        pc <= pc + 32'h4;
                    end
                    
                    //========================================================
                    // MOVW - 立即数移动到寄存器 (低 16 位)
                    //========================================================
                    else if (instruction[27:24] == 4'b1111 && instruction[21:20] == 2'b00 && 
                             instruction[16:12] == 5'b01000) begin
                        r0 <= {16'h0000, instruction[15:0]};
                        $display("[CPU] MOVW r0, #0x%04h", instruction[15:0]);
                        pc <= pc + 32'h4;
                    end
                    
                    //========================================================
                    // MOVT - 立即数移动到寄存器 (高 16 位)
                    //========================================================
                    else if (instruction[27:24] == 4'b1111 && instruction[21:20] == 2'b00 && 
                             instruction[16:12] == 5'b01100) begin
                        r0 <= {instruction[15:0], r0[15:0]};
                        $display("[CPU] MOVT r0, #0x%04h", instruction[15:0]);
                        pc <= pc + 32'h4;
                    end
                    
                    //========================================================
                    // LDR - 加载寄存器 (立即数偏移)
                    //========================================================
                    else if (instruction[27:26] == 2'b01 && instruction[25] == 1'b1) begin
                        HADDR <= r0 + instruction[11:0];
                        HTRANS <= 2'b10;
                        HWRITE <= 1'b0;
                        $display("[CPU] LDR r0, [r0, #0x%03h]", instruction[11:0]);
                        pc <= pc + 32'h4;
                    end
                    
                    //========================================================
                    // STR - 存储寄存器 (立即数偏移)
                    //========================================================
                    else if (instruction[27:26] == 2'b01 && instruction[25] == 1'b0) begin
                        HADDR <= r0 + instruction[11:0];
                        HTRANS <= 2'b10;
                        HWRITE <= 1'b1;
                        HWDATA <= r0;
                        $display("[CPU] STR r0, [r0, #0x%03h], data=0x%08h", instruction[11:0], r0);
                        pc <= pc + 32'h4;
                    end
                    
                    //========================================================
                    // ADD - 加法 (寄存器)
                    //========================================================
                    else if (instruction[27:25] == 3'b001 && instruction[24] == 1'b0) begin
                        r0 <= r0 + r1;
                        $display("[CPU] ADD r0, r0, r1");
                        pc <= pc + 32'h4;
                    end
                    
                    //========================================================
                    // ADD - 加法 (立即数)
                    //========================================================
                    else if (instruction[27:25] == 3'b001 && instruction[24] == 1'b1 && 
                             instruction[20] == 1'b0) begin
                        r0 <= r0 + instruction[7:0];
                        $display("[CPU] ADD r0, r0, #0x%02h", instruction[7:0]);
                        pc <= pc + 32'h4;
                    end
                    
                    //========================================================
                    // SUB - 减法
                    //========================================================
                    else if (instruction[27:25] == 3'b001 && instruction[24] == 1'b1 && 
                             instruction[20] == 1'b1) begin
                        r0 <= r0 - instruction[7:0];
                        $display("[CPU] SUB r0, r0, #0x%02h", instruction[7:0]);
                        pc <= pc + 32'h4;
                    end
                    
                    //========================================================
                    // CMP - 比较
                    //========================================================
                    else if (instruction[27:26] == 2'b10 && instruction[25:24] == 2'b10) begin
                        $display("[CPU] CMP r0, r1");
                        pc <= pc + 32'h4;
                    end
                    
                    //========================================================
                    // B - 无条件分支
                    //========================================================
                    else if (instruction[27:24] == 4'b1110) begin
                        $display("[CPU] B offset");
                        pc <= pc + 32'h4;
                    end
                    
                    //========================================================
                    // BX - 分支并交换
                    //========================================================
                    else if (instruction[15:8] == 8'b01000111) begin
                        pc <= r0 & ~32'h1;
                        $display("[CPU] BX r0 -> 0x%08h", pc);
                    end
                    
                    //========================================================
                    // NOP - 空操作
                    //========================================================
                    else if (instruction == 32'hBF00) begin
                        $display("[CPU] NOP");
                        pc <= pc + 32'h4;
                    end
                    
                    //========================================================
                    // GPIO 访问检测
                    //========================================================
                    if ((HADDR >= 32'h50000000) && (HADDR < 32'h50001000)) begin
                        $display("[CPU] *** GPIO Access at 0x%08h ***", HADDR);
                        if (HADDR == 32'h50000014 && HWRITE) begin  // GPIO_ODR
                            gpio_out <= HWDATA[15:0];
                            if (HWDATA[5]) begin
                                $display("[CPU] *** LED ON (PA5=1) ***");
                            end else begin
                                $display("[CPU] *** LED OFF (PA5=0) ***");
                            end
                        end
                    end
                    
                    //========================================================
                    // 未知指令
                    //========================================================
                    else begin
                        $display("[CPU] Unknown: 0x%08h", instruction);
                        pc <= pc + 32'h4;
                    end
                    
                    // 继续取下一条指令
                    if (HTRANS != 2'b10) begin  // 如果不是总线访问
                        HADDR <= pc & ~32'h3;
                        HTRANS <= 2'b10;
                    end
                    cpu_state <= STATE_FETCH;
                end
                
                //============================================================
                // 停机状态
                //============================================================
                STATE_HALT: begin
                    HTRANS <= 2'b00;
                end
                
                default: begin
                    cpu_state <= STATE_RESET;
                end
            endcase
        end
    end
    
    //============================================================
    // 调试输出
    //============================================================
    
    initial begin
        $monitor("");
    end
    
    // 定期输出 CPU 状态
    always @(posedge HCLK) begin
        if ((cycle_cnt % 1000000) == 0 && cycle_cnt > 0) begin
            $display("[CPU] Heartbeat: PC=0x%08h CYCLE=%0d", pc, cycle_cnt);
        end
    end
    
    //============================================================
    // 未使用的输出
    //============================================================
    
    assign TDO = 1'b0;
    assign SWV = 1'b0;

endmodule
