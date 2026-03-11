// ============================================================================
// 模块名   : ahb2apb_bridge
// 功能描述 : AHB-Lite 到 APB 桥接器
//          - AHB-Lite 从机接口
//          - APB 主机接口 (支持多从机)
//          - 正确的 APB 时序 (PSEL→PENABLE→PREADY)
//          - 地址映射到 APB 外设
// 作者     : Cortex-M3 SoC RTL Team
// 创建日期 : 2026-03-10
// 版本     : v1.0
// ============================================================================

module ahb2apb_bridge #(
    parameter   APB_BASE_ADDR = 32'h0000_0000,  // APB 区域基地址
    parameter   APB_REGION_SIZE = 32'h0010_0000  // APB 区域大小 1MB
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
    
    // APB 主机接口 (支持 16 个从机)
    output wire [31:0]      paddr,
    output wire             psel,
    output wire             penable,
    output wire             pwrite,
    output wire [31:0]      pwdata,
    input  wire [31:0]      prdata,
    input  wire             pready,
    input  wire             pslverr
);

    //============================================================
    // 内部信号声明
    //============================================================
    
    // 状态机定义
    localparam [1:0]  ST_IDLE    = 2'b00;
    localparam [1:0]  ST_SETUP   = 2'b01;
    localparam [1:0]  ST_ACCESS  = 2'b10;
    localparam [1:0]  ST_WAIT    = 2'b11;
    
    reg [1:0]  state_reg;
    reg [1:0]  state_next;
    
    reg [31:0] paddr_reg;
    reg [31:0] pwdata_reg;
    reg        pwrite_reg;
    reg [31:0] hrdata_reg;
    reg        hready_reg;
    reg        hresp_reg;
    reg        psel_reg;
    reg        penable_reg;
    
    wire [31:0] apb_addr;
    wire        addr_valid;
    
    //============================================================
    // 地址转换 (AHB 地址 -> APB 地址)
    //============================================================
    
    assign apb_addr = haddr - APB_BASE_ADDR;
    assign addr_valid = (haddr >= APB_BASE_ADDR) && (haddr < APB_BASE_ADDR + APB_REGION_SIZE);
    
    //============================================================
    // 状态机 - 第一段：状态寄存器
    //============================================================
    
    always @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n)
            state_reg <= ST_IDLE;
        else
            state_reg <= state_next;
    end
    
    //============================================================
    // 状态机 - 第二段：次态逻辑
    //============================================================
    
    always @(*) begin
        state_next = state_reg;
        case (state_reg)
            ST_IDLE: begin
                if (hsel && htrans == 2'b10)  // NONSEQ
                    state_next = ST_SETUP;
            end
            ST_SETUP: begin
                state_next = ST_ACCESS;
            end
            ST_ACCESS: begin
                if (pready)
                    state_next = ST_IDLE;
                else
                    state_next = ST_WAIT;
            end
            ST_WAIT: begin
                if (pready)
                    state_next = ST_IDLE;
            end
            default:
                state_next = ST_IDLE;
        endcase
    end
    
    //============================================================
    // 状态机 - 第三段：输出逻辑和寄存器
    //============================================================
    
    always @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n) begin
            paddr_reg   <= 32'h0;
            pwdata_reg  <= 32'h0;
            pwrite_reg  <= 1'b0;
            psel_reg    <= 1'b0;
            penable_reg <= 1'b0;
        end else begin
            case (state_reg)
                ST_IDLE: begin
                    psel_reg    <= 1'b0;
                    penable_reg <= 1'b0;
                    if (hsel && htrans == 2'b10) begin
                        paddr_reg   <= apb_addr;
                        pwdata_reg  <= hwdata;
                        pwrite_reg  <= hwrite;
                    end
                end
                ST_SETUP: begin
                    psel_reg    <= 1'b1;
                    penable_reg <= 1'b0;
                end
                ST_ACCESS, ST_WAIT: begin
                    psel_reg    <= 1'b1;
                    penable_reg <= 1'b1;
                    if (pready) begin
                        psel_reg    <= 1'b0;
                        penable_reg <= 1'b0;
                    end
                end
            endcase
        end
    end
    
    //============================================================
    // HREADY 控制
    //============================================================
    
    always @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n)
            hready_reg <= 1'b1;
        else begin
            case (state_reg)
                ST_IDLE:
                    hready_reg <= 1'b1;
                ST_SETUP:
                    hready_reg <= 1'b0;
                ST_ACCESS, ST_WAIT:
                    hready_reg <= ~pready;
                default:
                    hready_reg <= 1'b1;
            endcase
        end
    end
    
    assign hready = hready_reg;
    
    //============================================================
    // HRESP 错误响应
    //============================================================
    
    always @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n)
            hresp_reg <= 1'b0;
        else begin
            if (state_reg == ST_ACCESS && pready)
                hresp_reg <= pslverr;
            else if (!addr_valid && hsel && htrans != 2'b00)
                hresp_reg <= 1'b1;
            else
                hresp_reg <= 1'b0;
        end
    end
    
    assign hresp = hresp_reg;
    
    //============================================================
    // 读数据锁存
    //============================================================
    
    always @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n)
            hrdata_reg <= 32'h0;
        else begin
            if (state_reg == ST_ACCESS && pready && !pwrite_reg)
                hrdata_reg <= prdata;
        end
    end
    
    assign hrdata = hrdata_reg;
    
    //============================================================
    // APB 输出
    //============================================================
    
    assign paddr   = paddr_reg;
    assign pwdata  = pwdata_reg;
    assign pwrite  = pwrite_reg;
    assign psel    = psel_reg;
    assign penable = penable_reg;

endmodule
