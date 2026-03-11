// ============================================================================
// 模块名   : pll_28nm
// 功能描述 : PLL IP 行为模型 (简化版用于仿真)
// ============================================================================

module pll_28nm #(
    parameter   REF_FREQ    = 25,
    parameter   OUT0_FREQ   = 200,
    parameter   OUT1_FREQ   = 100,
    parameter   BW          = 3
) (
    input  wire refclk,
    input  wire rst_n,
    output wire out0,
    output wire out1,
    output wire locked
);

    reg locked_reg;
    
    // 简化模型：复位后 100ns 锁定
    always @(posedge refclk or negedge rst_n) begin
        if (!rst_n)
            locked_reg <= 1'b0;
        else
            #100 locked_reg <= 1'b1;
    end
    
    assign locked = locked_reg;
    assign out0 = refclk;  // 简化：直接传递输入时钟
    assign out1 = refclk;

endmodule
