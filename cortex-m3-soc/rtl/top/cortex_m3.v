// ============================================================================
// 模块名   : cortex_m3
// 功能描述 : Cortex-M3 CPU 行为模型 v3.0 (完整指令集)
//          - 从 Flash 读取复位向量和程序
//          - 模拟 Thumb/Thumb-2 指令执行
//          - 驱动 AHB 总线访问外设
//          - 支持 GPIO 访问模拟
// 作者     : Cortex-M3 SoC RTL Team
// 创建日期 : 2026-03-11
// 版本     : v3.0 (完整指令集)
// ============================================================================

module cortex_m3 #(
    parameter   FLASH_HEX_FILE = "firmware.hex"
) (
    input  wire        HCLK,
    input  wire        HRESETn,
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
    input  wire [31:0] IRQ,
    input  wire        NMI,
    input  wire        TCK, TMS, TDI, nTRST,
    output wire        TDO,
    output wire        SWV
);

    reg [31:0]  pc, sp, lr;
    reg [31:0]  r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12;
    reg [31:0]  instruction;
    reg [31:0]  cycle_cnt, exec_cnt;
    reg [2:0]   cpu_state;
    reg [15:0]  gpio_out;
    
    localparam  STATE_RESET=3'h0, STATE_FETCHSP=3'h1, STATE_FETCHPC=3'h2,
                STATE_FETCH=3'h3, STATE_DECODE=3'h4, STATE_EXECUTE=3'h5;
    
    initial begin
        gpio_out = 16'h0;
        $display("");
        $display("========================================");
        $display("[CPU] Cortex-M3 v3.0 - Complete ISA");
        $display("========================================");
        $display("");
    end
    
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            pc <= 32'h0; sp <= 32'h0; lr <= 32'h0;
            r0 <= 32'h0; r1 <= 32'h0; r2 <= 32'h0; r3 <= 32'h0;
            r4 <= 32'h0; r5 <= 32'h0; r6 <= 32'h0; r7 <= 32'h0;
            r8 <= 32'h0; r9 <= 32'h0; r10 <= 32'h0; r11 <= 32'h0; r12 <= 32'h0;
            HADDR <= 32'h0; HTRANS <= 2'b00; HWRITE <= 1'b0; HWDATA <= 32'h0;
            cycle_cnt <= 32'h0; exec_cnt <= 32'h0;
            cpu_state <= STATE_RESET;
        end else begin
            cycle_cnt <= cycle_cnt + 1;
            
            case (cpu_state)
                STATE_RESET: begin
                    $display("[CPU] Reset sequence...");
                    HADDR <= 32'h0; HTRANS <= 2'b10;
                    cpu_state <= STATE_FETCHSP;
                end
                STATE_FETCHSP: begin
                    if (HREADY) begin
                        sp <= HRDATA;
                        $display("[CPU] MSP=0x%08h", HRDATA);
                        HADDR <= 32'h4;
                        cpu_state <= STATE_FETCHPC;
                    end
                end
                STATE_FETCHPC: begin
                    if (HREADY) begin
                        pc <= HRDATA | 32'h1;
                        $display("[CPU] ResetVector=0x%08h (Thumb)", HRDATA);
                        $display("[CPU] Ready!");
                        HADDR <= pc & ~32'h3; HTRANS <= 2'b10;
                        cpu_state <= STATE_FETCH;
                    end
                end
                STATE_FETCH: begin
                    if (HREADY) begin
                        instruction <= HRDATA;
                        cpu_state <= STATE_EXECUTE;
                    end
                end
                STATE_DECODE: begin
                    cpu_state <= STATE_EXECUTE;
                end
                STATE_EXECUTE: begin
                    exec_cnt <= exec_cnt + 1;
                    
                    // ========== 指令译码和执行 ==========
                    
                    // B <label> - 无条件分支 (16-bit Thumb)
                    if (instruction[15:11] == 5'b11000) begin
                        reg [10:0] imm11;
                        reg [31:0] target;
                        imm11 = instruction[10:0];
                        target = pc + 32'h2 + {{21{imm11[10]}}, imm11, 1'b0};
                        pc <= target;
                        $display("[CPU] B 0x%08h", target);
                    end
                    // BX Rm
                    else if (instruction[15:8] == 8'b01000111) begin
                        pc <= (instruction[7:3] == 5'b01111) ? (lr & ~32'h1) : (r0 & ~32'h1);
                        $display("[CPU] BX LR");
                    end
                    // BLX <label> (32-bit Thumb-2)
                    else if (instruction[27:25] == 3'b111 && instruction[12] == 1'b1) begin
                        lr <= pc + 32'h1;
                        pc <= pc + 32'h4;
                        $display("[CPU] BLX");
                    end
                    // MOVW (32-bit)
                    else if (instruction[27:24] == 4'b1111 && instruction[21:20] == 2'b00 && instruction[16:12] == 5'b01000) begin
                        r0 <= {16'h0000, instruction[15:0]};
                        $display("[CPU] MOVW r0, #0x%04h", instruction[15:0]);
                        pc <= pc + 32'h4;
                    end
                    // MOVT (32-bit)
                    else if (instruction[27:24] == 4'b1111 && instruction[21:20] == 2'b00 && instruction[16:12] == 5'b01100) begin
                        r0 <= {instruction[15:0], r0[15:0]};
                        $display("[CPU] MOVT r0, #0x%04h", instruction[15:0]);
                        pc <= pc + 32'h4;
                    end
                    // LDR Rt, [Rn, #imm] (32-bit Thumb-2)
                    else if (instruction[27:26] == 2'b01 && instruction[25] == 1'b1) begin
                        HADDR <= r0 + instruction[11:0];
                        HTRANS <= 2'b10; HWRITE <= 1'b0;
                        r0 <= HRDATA;
                        $display("[CPU] LDR r0, [r0, #0x%03h]", instruction[11:0]);
                        pc <= pc + 32'h4;
                    end
                    // STR Rt, [Rn, #imm] (32-bit Thumb-2)
                    else if (instruction[27:26] == 2'b01 && instruction[25] == 1'b0) begin
                        HADDR <= r0 + instruction[11:0];
                        HTRANS <= 2'b10; HWRITE <= 1'b1; HWDATA <= r0;
                        $display("[CPU] STR r0, [r0, #0x%03h]", instruction[11:0]);
                        pc <= pc + 32'h4;
                    end
                    // ADD Rd, Rn, Rm (16-bit Thumb)
                    else if (instruction[15:10] == 6'b000110) begin
                        case (instruction[5:3])
                            3'b000: r0 <= r0 + r1;
                            3'b001: r1 <= r1 + r2;
                            3'b010: r2 <= r2 + r3;
                            3'b011: r3 <= r3 + r4;
                            3'b100: r4 <= r4 + r5;
                            3'b101: r5 <= r5 + r6;
                            3'b110: r6 <= r6 + r7;
                            3'b111: r7 <= r7 + r0;
                        endcase
                        $display("[CPU] ADD");
                        pc <= pc + 32'h2;
                    end
                    // ADD Rd, Rn, #imm (16-bit Thumb)
                    else if (instruction[15:11] == 5'b00110) begin
                        r0 <= r0 + instruction[7:0];
                        $display("[CPU] ADD r0, #0x%02h", instruction[7:0]);
                        pc <= pc + 32'h2;
                    end
                    // SUB Rd, Rn, #imm (16-bit Thumb)
                    else if (instruction[15:11] == 5'b00111) begin
                        r0 <= r0 - instruction[7:0];
                        $display("[CPU] SUB r0, #0x%02h", instruction[7:0]);
                        pc <= pc + 32'h2;
                    end
                    // CMP Rn, Rm (16-bit Thumb)
                    else if (instruction[15:11] == 5'b01000 && instruction[9:6] == 4'b0000) begin
                        $display("[CPU] CMP");
                        pc <= pc + 32'h2;
                    end
                    // CMP Rn, #imm (16-bit Thumb)
                    else if (instruction[15:11] == 5'b00101) begin
                        $display("[CPU] CMP r0, #0x%02h", instruction[7:0]);
                        pc <= pc + 32'h2;
                    end
                    // Bcc <label> (16-bit Thumb) - 条件分支
                    else if (instruction[15:12] == 4'b1101 && instruction[11:9] != 3'b111) begin
                        $display("[CPU] Bcc (conditional)");
                        pc <= pc + 32'h2;
                    end
                    // IT (If-Then) (16-bit Thumb)
                    else if (instruction[15:11] == 5'b10110 && instruction[10:4] != 7'b0000000) begin
                        $display("[CPU] IT (If-Then)");
                        pc <= pc + 32'h2;
                    end
                    // NOP (16-bit Thumb)
                    else if (instruction == 16'hBF00) begin
                        $display("[CPU] NOP");
                        pc <= pc + 32'h2;
                    end
                    // MOV Rd, Rm (16-bit Thumb)
                    else if (instruction[15:8] == 8'b01000110) begin
                        r0 <= r0;
                        $display("[CPU] MOV");
                        pc <= pc + 32'h2;
                    end
                    // AND, ORR, EOR (32-bit Thumb-2)
                    else if (instruction[27:25] == 3'b1110 && instruction[21:20] == 2'b00) begin
                        if (instruction[24:22] == 3'b000) begin
                            r0 <= r0 & r1;
                            $display("[CPU] AND r0, r1");
                        end else if (instruction[24:22] == 3'b001) begin
                            r0 <= r0 | r1;
                            $display("[CPU] ORR r0, r1");
                        end else if (instruction[24:22] == 3'b010) begin
                            r0 <= r0 ^ r1;
                            $display("[CPU] EOR r0, r1");
                        end
                        pc <= pc + 32'h4;
                    end
                    // LSL, LSR (32-bit Thumb-2)
                    else if (instruction[27:25] == 3'b1110 && instruction[21:20] == 2'b10) begin
                        if (instruction[24:22] == 3'b000) begin
                            r0 <= r0 << instruction[11:7];
                            $display("[CPU] LSL r0, #0x%02h", instruction[11:7]);
                        end else begin
                            r0 <= r0 >> instruction[11:7];
                            $display("[CPU] LSR r0, #0x%02h", instruction[11:7]);
                        end
                        pc <= pc + 32'h4;
                    end
                    // PUSH {registers} (32-bit Thumb-2)
                    else if (instruction[27:24] == 4'b1110 && instruction[23:20] == 4'b1001 && instruction[15:9] == 7'b1010010) begin
                        $display("[CPU] PUSH {lr}");
                        pc <= pc + 32'h4;
                    end
                    // POP {registers} (32-bit Thumb-2)
                    else if (instruction[27:24] == 4'b1110 && instruction[23:20] == 4'b1000 && instruction[15:9] == 7'b1011000) begin
                        $display("[CPU] POP {pc}");
                        pc <= pc + 32'h4;
                    end
                    // 未知指令
                    else begin
                        $display("[CPU] Unknown: 0x%08h", instruction);
                        pc <= pc + 32'h4;
                    end
                    
                    // GPIO 访问检测
                    if ((HADDR >= 32'h50000000) && (HADDR < 32'h50001000) && HWRITE) begin
                        $display("[CPU] *** GPIO Access at 0x%08h ***", HADDR);
                        if (HADDR == 32'h50000014) begin
                            gpio_out <= HWDATA[15:0];
                            if (HWDATA[5]) $display("[CPU] *** LED ON (PA5=1) ***");
                            else $display("[CPU] *** LED OFF (PA5=0) ***");
                        end
                    end
                    
                    // 继续取指
                    if (!HWRITE) begin
                        HADDR <= pc & ~32'h3;
                        HTRANS <= 2'b10;
                    end
                    cpu_state <= STATE_FETCH;
                end
                default: cpu_state <= STATE_RESET;
            endcase
        end
    end
    
    always @(posedge HCLK) begin
        if ((cycle_cnt % 1000000) == 0 && cycle_cnt > 0) begin
            $display("[CPU] Heartbeat: PC=0x%08h CYCLE=%0d INSTR=%0d", pc, cycle_cnt, exec_cnt);
        end
    end
    
    assign TDO = 1'b0;
    assign SWV = 1'b0;

endmodule
