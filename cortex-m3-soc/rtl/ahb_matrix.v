// ============================================================================
// 模块名   : ahb_matrix
// 功能描述 : AHB-Lite 矩阵交换机 (1 主 3 从)
//          - 主机：CPU
//          - 从机 0: Flash 控制器 (0x0000_0000-0x0007_FFFF)
//          - 从机 1: SRAM (0x2000_0000-0x2001_FFFF)
//          - 从机 2: AHB2APB Bridge (0x4000_0000+)
//          - 支持 HREADY 拉伸、HRESP 错误响应
// 作者     : Cortex-M3 SoC RTL Team
// 创建日期 : 2026-03-10
// 版本     : v1.0
// ============================================================================

module ahb_matrix #(
    parameter   FLASH_BASE  = 32'h0000_0000,
    parameter   FLASH_SIZE  = 32'h0008_0000,  // 512KB
    parameter   SRAM_BASE   = 32'h2000_0000,
    parameter   SRAM_SIZE   = 32'h0002_0000,  // 128KB
    parameter   APB_BASE    = 32'h4000_0000,
    parameter   APB_SIZE    = 32'h0010_0000   // 1MB
) (
    // AHB 时钟复位
    input  wire             hclk,
    input  wire             hreset_n,
    
    // AHB 主机接口 (CPU)
    input  wire [31:0]      haddr_m,
    input  wire [2:0]       hburst_m,
    input  wire [3:0]       hprot_m,
    input  wire [2:0]       hsize_m,
    input  wire [1:0]       htrans_m,
    input  wire             hwrite_m,
    input  wire [31:0]      hwdata_m,
    output wire [31:0]      hrdata_m,
    output wire             hready_m,
    output wire             hresp_m,
    
    // AHB 从机接口 0 - Flash
    output wire [31:0]      haddr_s0,
    output wire [2:0]       hburst_s0,
    output wire [3:0]       hprot_s0,
    output wire [2:0]       hsize_s0,
    output wire [1:0]       htrans_s0,
    output wire             hwrite_s0,
    output wire [31:0]      hwdata_s0,
    input  wire [31:0]      hrdata_s0,
    input  wire             hready_s0,
    input  wire             hresp_s0,
    output wire             hsel_s0,
    
    // AHB 从机接口 1 - SRAM
    output wire [31:0]      haddr_s1,
    output wire [2:0]       hburst_s1,
    output wire [3:0]       hprot_s1,
    output wire [2:0]       hsize_s1,
    output wire [1:0]       htrans_s1,
    output wire             hwrite_s1,
    output wire [31:0]      hwdata_s1,
    input  wire [31:0]      hrdata_s1,
    input  wire             hready_s1,
    input  wire             hresp_s1,
    output wire             hsel_s1,
    
    // AHB 从机接口 2 - APB Bridge
    output wire [31:0]      haddr_s2,
    output wire [2:0]       hburst_s2,
    output wire [3:0]       hprot_s2,
    output wire [2:0]       hsize_s2,
    output wire [1:0]       htrans_s2,
    output wire             hwrite_s2,
    output wire [31:0]      hwdata_s2,
    input  wire [31:0]      hrdata_s2,
    input  wire             hready_s2,
    input  wire             hresp_s2,
    output wire             hsel_s2
);

    //============================================================
    // 内部信号声明
    //============================================================
    
    wire [1:0]  slave_sel;
    wire        slave_ready;
    wire        slave_resp;
    
    reg  [31:0] hrdata_reg;
    reg         hready_reg;
    reg         hresp_reg;
    reg         hready_q;
    
    //============================================================
    // 地址解码逻辑
    //============================================================
    
    wire slave_sel_0, slave_sel_1, slave_sel_2;
    assign slave_sel_0 = (haddr_m >= FLASH_BASE) && (haddr_m < FLASH_BASE + FLASH_SIZE);
    assign slave_sel_1 = (haddr_m >= SRAM_BASE)  && (haddr_m < SRAM_BASE + SRAM_SIZE);
    assign slave_sel_2 = (haddr_m >= APB_BASE)   && (haddr_m < APB_BASE + APB_SIZE);
    
    // 片选输出
    assign hsel_s0 = slave_sel_0;
    assign hsel_s1 = slave_sel_1;
    assign hsel_s2 = slave_sel_2;
    
    //============================================================
    // 地址重映射 (减去基地址)
    //============================================================
    
    assign haddr_s0 = slave_sel_0 ? (haddr_m - FLASH_BASE) : 32'h0;
    assign haddr_s1 = slave_sel_1 ? (haddr_m - SRAM_BASE)  : 32'h0;
    assign haddr_s2 = slave_sel_2 ? (haddr_m - APB_BASE)   : 32'h0;
    
    //============================================================
    // 控制信号广播
    //============================================================
    
    assign hburst_s0  = hburst_m;
    assign hburst_s1  = hburst_m;
    assign hburst_s2  = hburst_m;
    
    assign hprot_s0   = hprot_m;
    assign hprot_s1   = hprot_m;
    assign hprot_s2   = hprot_m;
    
    assign hsize_s0   = hsize_m;
    assign hsize_s1   = hsize_m;
    assign hsize_s2   = hsize_m;
    
    assign htrans_s0  = slave_sel_0 ? htrans_m : 2'b00;
    assign htrans_s1  = slave_sel_1 ? htrans_m : 2'b00;
    assign htrans_s2  = slave_sel_2 ? htrans_m : 2'b00;
    
    assign hwrite_s0  = hwrite_m;
    assign hwrite_s1  = hwrite_m;
    assign hwrite_s2  = hwrite_m;
    
    assign hwdata_s0  = hwdata_m;
    assign hwdata_s1  = hwdata_m;
    assign hwdata_s2  = hwdata_m;
    
    //============================================================
    // 从机响应选择
    //============================================================
    
    assign slave_ready = (slave_sel[0] && hready_s0) ||
                         (slave_sel[1] && hready_s1) ||
                         (slave_sel[2] && hready_s2) ||
                         (!slave_sel[0] && !slave_sel[1] && !slave_sel[2]);
    
    assign slave_resp = (slave_sel[0] && hresp_s0) ||
                        (slave_sel[1] && hresp_s1) ||
                        (slave_sel[2] && hresp_s2);
    
    //============================================================
    // HREADY 拉伸控制
    //============================================================
    
    // HREADY 低电平表示从机需要等待
    // 当 HTRANS=IDLE 时，强制 HREADY 高
    always @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n) begin
            hready_q <= 1'b1;
        end else begin
            if (htrans_m == 2'b00) begin  // IDLE
                hready_q <= 1'b1;
            end else begin
                hready_q <= slave_ready;
            end
        end
    end
    
    assign hready_m = hready_q;
    
    //============================================================
    // HRESP 错误响应
    //============================================================
    
    always @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n) begin
            hresp_reg <= 1'b0;
        end else begin
            if (htrans_m != 2'b00) begin
                // 无效地址访问返回错误
                if (!slave_sel[0] && !slave_sel[1] && !slave_sel[2])
                    hresp_reg <= 1'b1;
                else
                    hresp_reg <= slave_resp;
            end
        end
    end
    
    assign hresp_m = hresp_reg;
    
    //============================================================
    // 读数据多路选择
    //============================================================
    
    always @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n) begin
            hrdata_reg <= 32'h0;
        end else begin
            if (hready_q && htrans_m != 2'b00 && htrans_m != 2'b01) begin
                case (slave_sel)
                    3'b001: hrdata_reg <= hrdata_s0;
                    3'b010: hrdata_reg <= hrdata_s1;
                    3'b100: hrdata_reg <= hrdata_s2;
                    default: hrdata_reg <= 32'h0;
                endcase
            end
        end
    end
    
    assign hrdata_m = hrdata_reg;

endmodule
