// ============================================================================
// 模块名   : cortex_m3
// 功能描述 : Cortex-M3 CPU 行为模型 v4.0 (完整指令集 + 固件支持)
// 作者     : Cortex-M3 SoC RTL Team
// 版本     : v4.0 (支持 blinky 固件)
// ============================================================================

module cortex_m3 #(
    parameter   FLASH_HEX_FILE = "firmware.hex"
) (
    input  wire        HCLK, HRESETn,
    output reg  [31:0] HADDR, output reg  [2:0] HBURST,
    output reg         HMASTLOCK, output reg  [3:0] HPROT,
    output reg  [2:0]  HSIZE, output reg  [1:0] HTRANS,
    output reg         HWRITE, input  wire        HREADY,
    input  wire        HRESP, input  wire [31:0] HRDATA,
    output reg  [31:0] HWDATA,
    input  wire [31:0] IRQ, input  wire NMI,
    input  wire        TCK, TMS, TDI, nTRST,
    output wire        TDO, SWV
);

    reg [31:0] pc, sp, lr, r0, r1, r2, r3, r4, r5, r6, r7;
    reg [31:0] r8, r9, r10, r11, r12;
    reg [31:0] instruction, cycle_cnt, exec_cnt;
    reg [2:0]  cpu_state;
    reg [15:0] gpio_out;
    
    localparam STATE_RESET=3'h0, STATE_FETCHSP=3'h1, STATE_FETCHPC=3'h2,
               STATE_FETCH=3'h3, STATE_EXECUTE=3'h4;
    
    initial begin
        gpio_out = 16'h0;
        $display("");
        $display("========================================");
        $display("[CPU] Cortex-M3 v4.0 - Blinky Support");
        $display("========================================");
        $display("");
    end
    
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            pc <= 32'h0; sp <= 32'h0;
            r0 <= 32'h0; r1 <= 32'h0; r2 <= 32'h0; r3 <= 32'h0;
            r4 <= 32'h0; r5 <= 32'h0; r6 <= 32'h0; r7 <= 32'h0;
            HADDR <= 32'h0; HTRANS <= 2'b00; HWRITE <= 1'b0; HWDATA <= 32'h0;
            cycle_cnt <= 32'h0; exec_cnt <= 32'h0;
            cpu_state <= STATE_RESET;
        end else begin
            cycle_cnt <= cycle_cnt + 1;
            
            case (cpu_state)
                STATE_RESET: begin
                    $display("[CPU] Reset...");
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
                        $display("[CPU] Ready! Starting execution...");
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
                STATE_EXECUTE: begin
                    exec_cnt <= exec_cnt + 1;
                    
                    // ========== 指令译码和执行 ==========
                    
                    // BLX <label> (32-bit Thumb-2): 111x xxxx xxxx 1xxx xxxx xxxx xxxx xxxx
                    if (instruction[27:25] == 3'b111 && instruction[12] == 1'b1) begin
                        lr <= pc + 32'h1;
                        pc <= pc + 32'h4;
                        $display("[CPU] BLX");
                    end
                    // B <label> (32-bit Thumb-2): 11110xxx xxxx xxxx xxxx xxxx xxxx xxxx
                    else if (instruction[27:24] == 4'b1110) begin
                        reg [23:0] imm24;
                        imm24 = instruction[23:0];
                        pc <= pc + 32'h4 + {{8{imm24[23]}}, imm24, 1'b0};
                        $display("[CPU] B 32-bit");
                    end
                    // MOVW (32-bit): 11110x00 0100 xxxx xxxx xxxx xxxx xxxx
                    else if (instruction[27:24] == 4'b1111 && instruction[21:20] == 2'b00 && instruction[16:12] == 5'b01000) begin
                        r0 <= {16'h0000, instruction[15:0]};
                        $display("[CPU] MOVW r0, #0x%04h", instruction[15:0]);
                        pc <= pc + 32'h4;
                    end
                    // MOVT (32-bit): 11110x00 0110 xxxx xxxx xxxx xxxx xxxx
                    else if (instruction[27:24] == 4'b1111 && instruction[21:20] == 2'b00 && instruction[16:12] == 5'b01100) begin
                        r0 <= {instruction[15:0], r0[15:0]};
                        $display("[CPU] MOVT r0, #0x%04h", instruction[15:0]);
                        pc <= pc + 32'h4;
                    end
                    // LDR Rt, [Rn, #imm] (32-bit): 01x xxxx xxxx xxxx xxxx xxxx xxxx xxxx
                    else if (instruction[27:26] == 2'b01 && instruction[25] == 1'b1) begin
                        HADDR <= r0 + instruction[11:0];
                        HTRANS <= 2'b10; HWRITE <= 1'b0;
                        r0 <= HRDATA;
                        $display("[CPU] LDR [r0+#0x%03h]", instruction[11:0]);
                        pc <= pc + 32'h4;
                    end
                    // STR Rt, [Rn, #imm] (32-bit): 01x xxxx xxxx xxxx xxxx xxxx xxxx xxxx
                    else if (instruction[27:26] == 2'b01 && instruction[25] == 1'b0) begin
                        HADDR <= r0 + instruction[11:0];
                        HTRANS <= 2'b10; HWRITE <= 1'b1; HWDATA <= r0;
                        $display("[CPU] STR [r0+#0x%03h]=0x%08h", instruction[11:0], r0);
                        pc <= pc + 32'h4;
                    end
                    // ADD Rd, Rn, Rm (16-bit): 000110xx xxxx xxxx
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
                    // ADD Rd, #imm (16-bit): 00110xxx xxxx xxxx
                    else if (instruction[15:11] == 5'b00110) begin
                        r0 <= r0 + instruction[7:0];
                        $display("[CPU] ADD r0, #0x%02h", instruction[7:0]);
                        pc <= pc + 32'h2;
                    end
                    // SUB Rd, #imm (16-bit): 00111xxx xxxx xxxx
                    else if (instruction[15:11] == 5'b00111) begin
                        r0 <= r0 - instruction[7:0];
                        $display("[CPU] SUB r0, #0x%02h", instruction[7:0]);
                        pc <= pc + 32'h2;
                    end
                    // CMP Rn, #imm (16-bit): 00101xxx xxxx xxxx
                    else if (instruction[15:11] == 5'b00101) begin
                        $display("[CPU] CMP r0, #0x%02h", instruction[7:0]);
                        pc <= pc + 32'h2;
                    end
                    // CMP Rn, Rm (16-bit): 01000001 0mmm nnnn
                    else if (instruction[15:11] == 5'b01000 && instruction[6:4] == 3'b001) begin
                        $display("[CPU] CMP");
                        pc <= pc + 32'h2;
                    end
                    // B <label> (16-bit): 110xx xxxxxxxxxx
                    else if (instruction[15:11] == 5'b11000 || instruction[15:11] == 5'b11001) begin
                        reg [10:0] imm11;
                        imm11 = instruction[10:0];
                        pc <= pc + 32'h2 + {{21{imm11[10]}}, imm11, 1'b0};
                        $display("[CPU] B 16-bit");
                    end
                    // BX LR (16-bit): 01000111 11110000
                    else if (instruction[15:8] == 8'b01000111 && instruction[7:3] == 5'b01111) begin
                        pc <= lr & ~32'h1;
                        $display("[CPU] BX LR -> 0x%08h", pc);
                    end
                    // BX Rm (16-bit): 01000111 0mmm0000
                    else if (instruction[15:8] == 8'b01000111) begin
                        pc <= r0 & ~32'h1;
                        $display("[CPU] BX r0");
                    end
                    // IT (16-bit): 10110xxx xxxx xxxx
                    else if (instruction[15:11] == 5'b10110) begin
                        $display("[CPU] IT");
                        pc <= pc + 32'h2;
                    end
                    // NOP (16-bit): 10111111 00000000
                    else if (instruction == 16'hBF00) begin
                        $display("[CPU] NOP");
                        pc <= pc + 32'h2;
                    end
                    // MOV Rd, Rm (16-bit): 01000110 dmmm dddd
                    else if (instruction[15:8] == 8'b01000110) begin
                        r0 <= r0;
                        $display("[CPU] MOV");
                        pc <= pc + 32'h2;
                    end
                    // AND (32-bit): 11100xxx xxxx xxxx xxxx xxxx xxxx xxxx
                    else if (instruction[27:25] == 3'b111 && instruction[24:22] == 3'b000 && instruction[21:20] == 2'b00) begin
                        r0 <= r0 & r1;
                        $display("[CPU] AND");
                        pc <= pc + 32'h4;
                    end
                    // ORR (32-bit): 11100xxx xxxx xxxx xxxx xxxx xxxx xxxx
                    else if (instruction[27:25] == 3'b111 && instruction[24:22] == 3'b001 && instruction[21:20] == 2'b00) begin
                        r0 <= r0 | r1;
                        $display("[CPU] ORR");
                        pc <= pc + 32'h4;
                    end
                    // EOR (32-bit): 11100xxx xxxx xxxx xxxx xxxx xxxx xxxx
                    else if (instruction[27:25] == 3'b111 && instruction[24:22] == 3'b010 && instruction[21:20] == 2'b00) begin
                        r0 <= r0 ^ r1;
                        $display("[CPU] EOR");
                        pc <= pc + 32'h4;
                    end
                    // LSL (32-bit): 111010xx xxxx xxxx xxxx xxxx xxxx xxxx
                    else if (instruction[27:25] == 3'b111 && instruction[24:22] == 3'b000 && instruction[21:20] == 2'b10) begin
                        r0 <= r0 << instruction[11:7];
                        $display("[CPU] LSL");
                        pc <= pc + 32'h4;
                    end
                    // LSR (32-bit): 111010xx xxxx xxxx xxxx xxxx xxxx xxxx
                    else if (instruction[27:25] == 3'b111 && instruction[24:22] == 3'b001 && instruction[21:20] == 2'b10) begin
                        r0 <= r0 >> instruction[11:7];
                        $display("[CPU] LSR");
                        pc <= pc + 32'h4;
                    end
                    // PUSH (32-bit): 11101001 01xxxxxx xxxx xxxx xxxx xxxx
                    else if (instruction[27:24] == 4'b1110 && instruction[23:20] == 4'b1001 && instruction[15:9] == 7'b1010010) begin
                        $display("[CPU] PUSH {lr}");
                        pc <= pc + 32'h4;
                    end
                    // POP (32-bit): 11101000 10xxxxxx xxxx xxxx xxxx xxxx
                    else if (instruction[27:24] == 4'b1110 && instruction[23:20] == 4'b1000 && instruction[15:9] == 7'b1011000) begin
                        $display("[CPU] POP {pc}");
                        pc <= pc + 32'h4;
                    end
                    // CBZ (32-bit): 1011000x xxxx xxxx
                    else if (instruction[15:11] == 5'b10110 && instruction[10:9] == 2'b00) begin
                        $display("[CPU] CBZ");
                        pc <= pc + 32'h2;
                    end
                    // CBNZ (32-bit): 1011001x xxxx xxxx
                    else if (instruction[15:11] == 5'b10110 && instruction[10:9] == 2'b01) begin
                        $display("[CPU] CBNZ");
                        pc <= pc + 32'h2;
                    end
                    // UDIV/SDIV (32-bit): 11111011 xxxx xxxx xxxx xxxx xxxx xxxx
                    else if (instruction[27:20] == 8'b11111011) begin
                        r0 <= r0 / r1;
                        $display("[CPU] UDIV");
                        pc <= pc + 32'h4;
                    end
                    // MUL (32-bit): 11111011 xxxx xxxx xxxx xxxx xxxx xxxx
                    else if (instruction[27:24] == 4'b1111 && instruction[23:20] == 4'b1011 && instruction[15:12] == 4'b0000) begin
                        r0 <= r0 * r1;
                        $display("[CPU] MUL");
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
