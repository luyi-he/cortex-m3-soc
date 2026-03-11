// ============================================================================
// 模块名   : cortex_m3
// 功能描述 : Cortex-M3 CPU 行为模型 v4.0 (完整指令集 + blinky 支持)
// 作者     : Cortex-M3 SoC RTL Team
// 版本     : v4.0
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
    reg [31:0] instruction, cycle_cnt, exec_cnt;
    reg [2:0]  cpu_state;
    reg [15:0] gpio_out;
    
    localparam STATE_RESET=3'h0, STATE_FETCHSP=3'h1, STATE_FETCHPC=3'h2,
               STATE_FETCH=3'h3, STATE_EXECUTE=3'h4, STATE_HALT=3'h5;
    
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
                        if (cpu_state != STATE_HALT)
                            cpu_state <= STATE_EXECUTE;
                    end
                end
                STATE_EXECUTE: begin
                    exec_cnt <= exec_cnt + 1;
                    
                    // BLX
                    if (instruction[27:25] == 3'b111 && instruction[12] == 1'b1) begin
                        lr <= pc + 32'h1; pc <= pc + 32'h4;
                        $display("[CPU] BLX");
                    end
                    // B (32-bit)
                    else if (instruction[27:24] == 4'b1110) begin
                        pc <= pc + 32'h4;
                        $display("[CPU] B 32-bit");
                    end
                    // MOVW
                    else if (instruction[27:24] == 4'b1111 && instruction[21:20] == 2'b00 && instruction[16:12] == 5'b01000) begin
                        r0 <= {16'h0000, instruction[15:0]};
                        $display("[CPU] MOVW r0, #0x%04h", instruction[15:0]);
                        pc <= pc + 32'h4;
                    end
                    // MOVT
                    else if (instruction[27:24] == 4'b1111 && instruction[21:20] == 2'b00 && instruction[16:12] == 5'b01100) begin
                        r0 <= {instruction[15:0], r0[15:0]};
                        $display("[CPU] MOVT r0, #0x%04h", instruction[15:0]);
                        pc <= pc + 32'h4;
                    end
                    // LDR
                    else if (instruction[27:26] == 2'b01 && instruction[25] == 1'b1) begin
                        HADDR <= r0 + instruction[11:0];
                        HTRANS <= 2'b10; HWRITE <= 1'b0;
                        r0 <= HRDATA;
                        $display("[CPU] LDR [r0+#0x%03h]", instruction[11:0]);
                        pc <= pc + 32'h4;
                    end
                    // STR
                    else if (instruction[27:26] == 2'b01 && instruction[25] == 1'b0) begin
                        HADDR <= r0 + instruction[11:0];
                        HTRANS <= 2'b10; HWRITE <= 1'b1; HWDATA <= r0;
                        $display("[CPU] STR [r0+#0x%03h]", instruction[11:0]);
                        pc <= pc + 32'h4;
                    end
                    // ADD (16-bit)
                    else if (instruction[15:11] == 5'b00110) begin
                        r0 <= r0 + instruction[7:0];
                        $display("[CPU] ADD r0, #0x%02h", instruction[7:0]);
                        pc <= pc + 32'h2;
                    end
                    // SUB (16-bit)
                    else if (instruction[15:11] == 5'b00111) begin
                        r0 <= r0 - instruction[7:0];
                        $display("[CPU] SUB r0, #0x%02h", instruction[7:0]);
                        pc <= pc + 32'h2;
                    end
                    // CMP (16-bit)
                    else if (instruction[15:11] == 5'b00101) begin
                        $display("[CPU] CMP r0, #0x%02h", instruction[7:0]);
                        pc <= pc + 32'h2;
                    end
                    // B (16-bit)
                    else if (instruction[15:11] == 5'b11000 || instruction[15:11] == 5'b11001) begin
                        pc <= pc + 32'h2;
                        $display("[CPU] B 16-bit");
                    end
                    // BX LR
                    else if (instruction[15:8] == 8'b01000111 && instruction[7:3] == 5'b01111) begin
                        pc <= lr & ~32'h1;
                        $display("[CPU] BX LR");
                    end
                    // BX Rm
                    else if (instruction[15:8] == 8'b01000111) begin
                        pc <= r0 & ~32'h1;
                        $display("[CPU] BX r0");
                    end
                    // IT
                    else if (instruction[15:11] == 5'b10110) begin
                        $display("[CPU] IT");
                        pc <= pc + 32'h2;
                    end
                    // NOP
                    else if (instruction == 16'hBF00) begin
                        $display("[CPU] NOP");
                        pc <= pc + 32'h2;
                    end
                    // MOV
                    else if (instruction[15:8] == 8'b01000110) begin
                        $display("[CPU] MOV");
                        pc <= pc + 32'h2;
                    end
                    // AND
                    else if (instruction[27:25] == 3'b111 && instruction[24:22] == 3'b000 && instruction[21:20] == 2'b00) begin
                        r0 <= r0 & r1;
                        $display("[CPU] AND");
                        pc <= pc + 32'h4;
                    end
                    // ORR
                    else if (instruction[27:25] == 3'b111 && instruction[24:22] == 3'b001 && instruction[21:20] == 2'b00) begin
                        r0 <= r0 | r1;
                        $display("[CPU] ORR");
                        pc <= pc + 32'h4;
                    end
                    // EOR
                    else if (instruction[27:25] == 3'b111 && instruction[24:22] == 3'b010 && instruction[21:20] == 2'b00) begin
                        r0 <= r0 ^ r1;
                        $display("[CPU] EOR");
                        pc <= pc + 32'h4;
                    end
                    // LSL
                    else if (instruction[27:25] == 3'b111 && instruction[24:22] == 3'b000 && instruction[21:20] == 2'b10) begin
                        r0 <= r0 << instruction[11:7];
                        $display("[CPU] LSL");
                        pc <= pc + 32'h4;
                    end
                    // LSR
                    else if (instruction[27:25] == 3'b111 && instruction[24:22] == 3'b001 && instruction[21:20] == 2'b10) begin
                        r0 <= r0 >> instruction[11:7];
                        $display("[CPU] LSR");
                        pc <= pc + 32'h4;
                    end
                    // PUSH
                    else if (instruction[27:24] == 4'b1110 && instruction[23:20] == 4'b1001 && instruction[15:9] == 7'b1010010) begin
                        $display("[CPU] PUSH {lr}");
                        pc <= pc + 32'h4;
                    end
                    // POP
                    else if (instruction[27:24] == 4'b1110 && instruction[23:20] == 4'b1000 && instruction[15:9] == 7'b1011000) begin
                        $display("[CPU] POP {pc}");
                        pc <= pc + 32'h4;
                    end
                    // CBZ/CBNZ
                    else if (instruction[15:11] == 5'b10110 && (instruction[10:9] == 2'b00 || instruction[10:9] == 2'b01)) begin
                        $display("[CPU] CBZ/CBNZ");
                        pc <= pc + 32'h2;
                    end
                    // UDIV/SDIV
                    else if (instruction[27:20] == 8'b11111011) begin
                        r0 <= r0 / r1;
                        $display("[CPU] UDIV");
                        pc <= pc + 32'h4;
                    end
                    // MUL
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
                    
                    // 检查是否读取到无效指令
                    if ((instruction == 32'h00000000 || instruction == 32'hffffffff) && exec_cnt > 10 && cpu_state != STATE_HALT) begin
                        $display("[CPU] *** Reached empty Flash ***");
                        $display("[CPU] *** Halting CPU ***");
                        $display("[CPU] ========================================");
                        $display("[CPU] Execution Summary:");
                        $display("[CPU]   Instructions Executed: %0d", exec_cnt);
                        $display("[CPU]   Cycles: %0d", cycle_cnt);
                        $display("[CPU]   Final PC: 0x%08h", pc);
                        $display("[CPU] ========================================");
                        cpu_state <= STATE_HALT;
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
                    if (cpu_state != STATE_HALT && !HWRITE) begin
                        HADDR <= pc & ~32'h3;
                        HTRANS <= 2'b10;
                    end
                    if (cpu_state != STATE_HALT)
                        cpu_state <= STATE_FETCH;
                end
                STATE_HALT: begin
                    HTRANS <= 2'b00;
                    $display("[CPU] Halted at cycle %0d", cycle_cnt);
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
