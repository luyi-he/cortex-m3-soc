// ============================================================================
// 模块名   : clk_gen
// 功能描述 : 时钟生成模块 - 从外部 OSC 生成 HCLK(200MHz) 和 PCLK(100MHz)
//           简化版本用于协同仿真
// 作者     : RTL 团队
// 创建日期 : 2026-03-10
// 版本     : v1.0 (simplified for simulation)
// ============================================================================

module clk_gen #(
    parameter   CLKIN_FREQ  = 25,
    parameter   CLKOUT1_FREQ = 200,
    parameter   CLKOUT2_FREQ = 100
) (
    input  wire             osc_clk,
    input  wire             rst_n,
    output wire             hclk,
    output wire             pclk,
    output wire             hreset_n,
    output wire             preset_n,
    output wire             clk_locked,
    output wire             rst_active
);

    reg         hclk_reg;
    reg         pclk_reg;
    reg         pll_locked_reg;
    
    // 简化：直接使用输入时钟分频
    // HCLK = 2 * osc_clk (假设 osc_clk 是 100MHz)
    // PCLK = HCLK / 2
    
    always @(posedge osc_clk or negedge rst_n) begin
        if (!rst_n) begin
            hclk_reg <= 1'b0;
            pclk_reg <= 1'b0;
            pll_locked_reg <= 1'b0;
        end else begin
            hclk_reg <= ~hclk_reg;
            pclk_reg <= (hclk_reg == 1'b0) ? ~pclk_reg : pclk_reg;
            pll_locked_reg <= 1'b1;
        end
    end
    
    assign hclk = hclk_reg;
    assign pclk = pclk_reg;
    assign clk_locked = pll_locked_reg;
    
    // 复位同步
    reg [3:0] rst_sync_reg;
    
    always @(posedge hclk or negedge rst_n) begin
        if (!rst_n)
            rst_sync_reg <= 4'b0000;
        else if (!pll_locked_reg)
            rst_sync_reg <= 4'b0000;
        else
            rst_sync_reg <= {rst_sync_reg[2:0], 1'b1};
    end
    
    assign hreset_n = &rst_sync_reg;
    
    reg [1:0] preset_sync;
    always @(posedge pclk or negedge rst_n) begin
        if (!rst_n)
            preset_sync <= 2'b00;
        else
            preset_sync <= {preset_sync[0], hreset_n};
    end
    
    assign preset_n = preset_sync[1];
    assign rst_active = !(&rst_sync_reg);

endmodule
