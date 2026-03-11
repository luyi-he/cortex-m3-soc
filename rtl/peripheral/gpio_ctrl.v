// ============================================================================
// 模块名   : gpio_ctrl
// 功能描述 : GPIO 控制器 - 简化版用于协同仿真
// ============================================================================

module gpio_ctrl #(
    parameter   PORT_COUNT    = 4,
    parameter   PIN_COUNT     = 16,
    parameter   APB_ADDR_BASE = 32'h0000
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
    output reg              pslverr,
    
    input  wire [63:0]      gpio_i,
    output reg  [63:0]      gpio_o,
    output reg  [63:0]      gpio_oen,
    output wire [63:0]      gpio_irq
);

    reg [31:0] moder_reg[3:0];
    reg [31:0] odr_reg[3:0];
    
    assign gpio_irq = 64'h0;
    
    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n) begin
            pready <= 1'b0;
            prdata <= 32'h0;
            pslverr <= 1'b0;
            gpio_o <= 64'h0;
            gpio_oen <= 64'hffff_ffff;
        end else if (psel && penable) begin
            pready <= 1'b1;
            if (pwrite) begin
                if (paddr[11:8] < 4) begin
                    if (paddr[7:4] == 4'h0)
                        moder_reg[paddr[11:8]] <= pwdata;
                    else if (paddr[7:4] == 4'h5) begin
                        odr_reg[paddr[11:8]] <= pwdata;
                        gpio_o[paddr[11:8]*16 +: 16] <= pwdata[15:0];
                        gpio_oen[paddr[11:8]*16 +: 16] <= 16'h0;
                    end
                end
            end else begin
                if (paddr[7:4] == 4'h0)
                    prdata <= moder_reg[paddr[11:8]];
                else if (paddr[7:4] == 4'h5)
                    prdata <= {16'h0, odr_reg[paddr[11:8]]};
                else
                    prdata <= 32'h0;
            end
        end else begin
            pready <= 1'b0;
        end
    end

endmodule
