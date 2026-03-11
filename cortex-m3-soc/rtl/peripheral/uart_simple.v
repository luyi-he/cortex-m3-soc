// ============================================================================
// 模块名   : uart_simple
// 功能描述 : 简化 UART 模型 - 用于协同仿真
//          - 支持 TX 发送（输出到 console）
//          - 支持 RX 接收（简化）
// 作者     : Cortex-M3 SoC RTL Team
// 创建日期 : 2026-03-11
// 版本     : v1.0
// ============================================================================

module uart_simple #(
    parameter   APB_ADDR_OFFSET = 32'h0000
) (
    input  wire             pclk,
    input  wire             preset_n,
    input  wire             psel,
    input  wire             penable,
    input  wire             pwrite,
    input  wire [31:0]      paddr,
    input  wire [31:0]      pwdata,
    output reg              pready,
    output reg [31:0]       prdata,
    output wire             pslverr,
    input  wire             rx,
    output reg              tx,
    output wire             irq
);

    // 寄存器偏移
    localparam  UART_DR   = 32'h00;  // 数据寄存器
    localparam  UART_SR   = 32'h04;  // 状态寄存器
    localparam  UART_CR   = 32'h08;  // 控制寄存器
    localparam  UART_BRR  = 32'h0C;  // 波特率寄存器
    
    reg [31:0]  dr_reg;
    reg [31:0]  sr_reg;
    reg [31:0]  cr_reg;
    reg [31:0]  brr_reg;
    
    reg         tx_busy;
    reg [3:0]   tx_bit_cnt;
    reg [7:0]   tx_shift_reg;
    
    assign pslverr = 1'b0;
    assign irq = 1'b0;
    
    // 状态寄存器位定义
    localparam SR_TXE = 1 << 7;  // TX 空
    localparam SR_TC  = 1 << 6;  // 发送完成
    localparam SR_RXNE = 1 << 5; // RX 非空
    
    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n) begin
            pready <= 1'b0;
            prdata <= 32'h0;
            tx <= 1'b1;  // 空闲状态为高
            tx_busy <= 1'b0;
            sr_reg <= {SR_TXE, SR_TC};  // 初始 TX 空且完成
        end else if (psel && !penable) begin
            pready <= 1'b0;
        end else if (penable && !pready) begin
            pready <= 1'b1;
            
            if (pwrite) begin
                case (paddr[7:2])
                    2'h0: begin  // DR 写
                        dr_reg <= pwdata[7:0];
                        // 开始发送
                        tx_shift_reg <= pwdata[7:0];
                        tx_bit_cnt <= 4'd10;  // 1 start + 8 data + 1 stop
                        tx <= 1'b0;  // Start bit
                        tx_busy <= 1'b1;
                        sr_reg <= sr_reg & ~{SR_TXE, SR_TC};
                    end
                    2'h2: cr_reg <= pwdata;
                    2'h3: brr_reg <= pwdata;
                endcase
            end else begin
                case (paddr[7:2])
                    2'h0: prdata <= dr_reg;
                    2'h1: prdata <= sr_reg;
                    2'h2: prdata <= cr_reg;
                    2'h3: prdata <= brr_reg;
                    default: prdata <= 32'h0;
                endcase
            end
        end
    end
    
    // UART 发送状态机
    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n) begin
            tx_bit_cnt <= 4'd0;
            tx_shift_reg <= 8'h0;
        end else if (tx_busy) begin
            tx_bit_cnt <= tx_bit_cnt - 1'b1;
            if (tx_bit_cnt > 4'd1) begin
                tx <= tx_shift_reg[0];
                tx_shift_reg <= {1'b0, tx_shift_reg[7:1]};
            end else if (tx_bit_cnt == 4'd1) begin
                tx <= 1'b1;  // Stop bit
                $write("%c", dr_reg);
                $fflush;
            end else begin
                tx_busy <= 1'b0;
                sr_reg <= sr_reg | {SR_TXE, SR_TC};
            end
        end
    end

endmodule
