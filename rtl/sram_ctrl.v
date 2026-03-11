// ============================================================================
// 模块名   : sram_ctrl
// 功能描述 : SRAM 控制器 (128KB)
//          - AHB-Lite 从机接口
//          - 64KB ITCM + 64KB DTCM
//          - 支持字节/半字/字访问
//          - 单周期访问时序
// 作者     : Cortex-M3 SoC RTL Team
// 创建日期 : 2026-03-10
// 版本     : v1.0
// ============================================================================

module sram_ctrl #(
    parameter   SRAM_ADDR_WIDTH = 17,  // 128KB = 2^17 bytes
    parameter   SRAM_DATA_WIDTH = 32,
    parameter   ITCM_SIZE       = 17,  // 64KB
    parameter   DTCM_SIZE       = 17   // 64KB
) (
    // AHB 时钟复位
    input  wire             hclk,
    input  wire             hreset_n,
    
    // AHB-Lite 从机接口
    input  wire [31:0]      haddr,
    input  wire [2:0]       hburst,
    input  wire [3:0]       hprot,
    input  wire [2:0]       hsize,
    input  wire [1:0]       htrans,
    input  wire             hwrite,
    input  wire [31:0]      hwdata,
    output wire [31:0]      hrdata,
    output wire             hready,
    output wire             hresp,
    input  wire             hsel,
    
    // SRAM 接口 (ITCM)
    output wire [15:0]      itcm_addr_o,
    output wire [31:0]      itcm_wdata_o,
    input  wire [31:0]      itcm_rdata_i,
    output wire [3:0]       itcm_be_o,
    output wire             itcm_ce_o,
    output wire             itcm_we_o,
    
    // SRAM 接口 (DTCM)
    output wire [15:0]      dtcm_addr_o,
    output wire [31:0]      dtcm_wdata_o,
    input  wire [31:0]      dtcm_rdata_i,
    output wire [3:0]       dtcm_be_o,
    output wire             dtcm_ce_o,
    output wire             dtcm_we_o
);

    //============================================================
    // 内部信号声明
    //============================================================
    
    reg [31:0]  hrdata_reg;
    reg         hready_reg;
    reg         hresp_reg;
    
    wire [16:0] byte_addr;
    wire [15:0] word_addr;
    wire        is_itcm_access;
    wire        is_dtcm_access;
    
    reg [3:0]   be_reg;
    reg [31:0]  wdata_reg;
    reg [15:0]  addr_reg;
    reg         we_reg;
    reg         access_itcm;
    
    //============================================================
    // 地址解析
    //============================================================
    
    assign byte_addr = haddr[16:0];
    assign word_addr = haddr[17:1];
    
    // ITCM: 0x0000_0000 - 0x0000_FFFF (64KB)
    // DTCM: 0x0001_0000 - 0x0001_FFFF (64KB)
    assign is_itcm_access = (haddr < 17'h1_0000);
    assign is_dtcm_access = (haddr >= 17'h1_0000) && (haddr < 17'h2_0000);
    
    //============================================================
    // 字节使能生成
    //============================================================
    
    reg [3:0] be_next;
    
    always @(*) begin
        be_next = 4'b0000;
        case (hsize)
            3'b000: begin  // 8-bit access
                case (haddr[1:0])
                    2'b00: be_next = 4'b0001;
                    2'b01: be_next = 4'b0010;
                    2'b10: be_next = 4'b0100;
                    2'b11: be_next = 4'b1000;
                endcase
            end
            3'b001: begin  // 16-bit access
                if (haddr[1])
                    be_next = 4'b1100;
                else
                    be_next = 4'b0011;
            end
            3'b010: begin  // 32-bit access
                be_next = 4'b1111;
            end
            default: be_next = 4'b1111;
        endcase
    end
    
    //============================================================
    // 控制逻辑 (单周期访问)
    //============================================================
    
    always @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n) begin
            be_reg       <= 4'b0000;
            wdata_reg    <= 32'h0;
            addr_reg     <= 16'h0;
            we_reg       <= 1'b0;
            access_itcm  <= 1'b0;
            hrdata_reg   <= 32'h0;
            hready_reg   <= 1'b1;
            hresp_reg    <= 1'b0;
        end else begin
            if (hsel && htrans != 2'b00 && htrans != 2'b01) begin
                // 新的访问请求
                be_reg      <= be_next;
                wdata_reg   <= hwdata;
                addr_reg    <= word_addr;
                we_reg      <= hwrite;
                access_itcm <= is_itcm_access;
                hready_reg  <= 1'b0;  // 拉低 HREADY 表示忙
                
                if (hwrite) begin
                    hready_reg <= 1'b1;  // 写操作单周期完成
                end else begin
                    // 读操作需要等待下一个周期
                    hready_reg <= 1'b0;
                end
            end else begin
                hready_reg <= 1'b1;
            end
            
            // 读数据锁存
            if (hsel && !hwrite && htrans != 2'b00 && htrans != 2'b01) begin
                if (is_itcm_access)
                    hrdata_reg <= itcm_rdata_i;
                else if (is_dtcm_access)
                    hrdata_reg <= dtcm_rdata_i;
            end
            
            // 错误检测
            if (hsel && htrans != 2'b00 && !is_itcm_access && !is_dtcm_access)
                hresp_reg <= 1'b1;
            else
                hresp_reg <= 1'b0;
        end
    end
    
    //============================================================
    // 读数据对齐
    //============================================================
    
    reg [31:0] hrdata_aligned;
    
    always @(*) begin
        case (hsize)
            3'b000: begin  // 8-bit
                case (haddr[1:0])
                    2'b00: hrdata_aligned = {{24{hrdata_reg[7]}}, hrdata_reg[7:0]};
                    2'b01: hrdata_aligned = {{24{hrdata_reg[15]}}, hrdata_reg[15:8]};
                    2'b10: hrdata_aligned = {{24{hrdata_reg[23]}}, hrdata_reg[23:16]};
                    2'b11: hrdata_aligned = {{24{hrdata_reg[31]}}, hrdata_reg[31:24]};
                endcase
            end
            3'b001: begin  // 16-bit
                if (haddr[1])
                    hrdata_aligned = {{16{hrdata_reg[31]}}, hrdata_reg[31:16]};
                else
                    hrdata_aligned = {{16{hrdata_reg[15]}}, hrdata_reg[15:0]};
            end
            default: hrdata_aligned = hrdata_reg;
        endcase
    end
    
    assign hrdata = hrdata_aligned;
    assign hready = hready_reg;
    assign hresp  = hresp_reg;
    
    //============================================================
    // ITCM 接口
    //============================================================
    
    assign itcm_addr_o  = access_itcm ? addr_reg : 16'h0;
    assign itcm_wdata_o = wdata_reg;
    assign itcm_be_o    = access_itcm ? be_reg : 4'b0000;
    assign itcm_ce_o    = hsel && access_itcm && (htrans != 2'b00);
    assign itcm_we_o    = we_reg && access_itcm;
    
    //============================================================
    // DTCM 接口
    //============================================================
    
    assign dtcm_addr_o  = (!access_itcm && is_dtcm_access) ? addr_reg : 16'h0;
    assign dtcm_wdata_o = wdata_reg;
    assign dtcm_be_o    = (!access_itcm && is_dtcm_access) ? be_reg : 4'b0000;
    assign dtcm_ce_o    = hsel && (!access_itcm) && is_dtcm_access && (htrans != 2'b00);
    assign dtcm_we_o    = we_reg && (!access_itcm) && is_dtcm_access;

endmodule
