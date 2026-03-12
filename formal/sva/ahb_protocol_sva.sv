// ============================================================================
// 模块名   : ahb_protocol_sva.sv
// 功能描述 : AHB-Lite 协议的形式验证断言
// 验证内容 : 协议合规性检查
// ============================================================================

`timescale 1ns/1ps

module ahb_protocol_sva (
    // AHB 时钟复位
    input  wire        hclk,
    input  wire        hreset_n,
    
    // AHB 主机接口信号
    input  wire [31:0] haddr,
    input  wire [2:0]  hburst,
    input  wire [3:0]  hprot,
    input  wire [2:0]  hsize,
    input  wire [1:0]  htrans,
    input  wire        hwrite,
    input  wire [31:0] hwdata,
    output wire        hready,
    output wire        hresp,
    output wire [31:0] hrdata
);

    //============================================================================
    // 本地参数
    //============================================================================
    
    localparam [1:0] HTRANS_IDLE = 2'b00;
    localparam [1:0] HTRANS_BUSY  = 2'b01;
    localparam [1:0] HTRANS_NONSEQ = 2'b10;
    localparam [1:0] HTRANS_SEQ   = 2'b11;
    
    localparam HRESP_OKAY = 1'b0;
    localparam HRESP_ERROR = 1'b1;
    
    //============================================================================
    // 属性：HRESETn 低电平时 HREADY 必须为低
    //============================================================================
    
    property p_ready_on_reset;
        @(posedge hclk)
        !hreset_n |-> !hready;
    endproperty
    
    a_ready_on_reset: assert property (p_ready_on_reset)
        else $error("HREADY not low during reset");
    
    //============================================================================
    // 属性：HTRANS 状态机
    //============================================================================
    
    // IDLE 之后可以是任意状态
    property p_idle_next;
        @(posedge hclk) disable iff (!hreset_n)
        (htrans == HTRANS_IDLE) |-> ##1 htrans inside {HTRANS_IDLE, HTRANS_NONSEQ, HTRANS_SEQ};
    endproperty
    
    // BUSY 之后必须是非顺序或顺序传输
    property p_busy_next;
        @(posedge hclk) disable iff (!hreset_n)
        (htrans == HTRANS_BUSY) |-> ##1 htrans inside {HTRANS_NONSEQ, HTRANS_SEQ};
    endproperty
    
    // NONSEQ 之后可以是任意状态
    property p_nonseq_next;
        @(posedge hclk) disable iff (!hreset_n)
        (htrans == HTRANS_NONSEQ) |-> ##1 htrans inside {HTRANS_IDLE, HTRANS_BUSY, HTRANS_NONSEQ, HTRANS_SEQ};
    endproperty
    
    // SEQ 之后必须是非顺序、顺序或 IDLE
    property p_seq_next;
        @(posedge hclk) disable iff (!hreset_n)
        (htrans == HTRANS_SEQ) |-> ##1 htrans inside {HTRANS_IDLE, HTRANS_NONSEQ, HTRANS_SEQ};
    endproperty
    
    a_idle_next: assert property (p_idle_next);
    a_busy_next: assert property (p_busy_next);
    a_nonseq_next: assert property (p_nonseq_next);
    a_seq_next: assert property (p_seq_next);
    
    //============================================================================
    // 属性：HREADY 低电平时从机可以拉伸
    //============================================================================
    
    // HREADY 低电平后可以变高
    property p_ready_stretch;
        @(posedge hclk) disable iff (!hreset_n)
        !hready |-> ##1 hready || !hready;
    endproperty
    
    a_ready_stretch: assert property (p_ready_stretch);
    
    //============================================================================
    // 属性：HRESP 响应
    //============================================================================
    
    // HREADY 高电平时 HRESP 必须稳定
    property p_resp_stable;
        @(posedge hclk) disable iff (!hreset_n)
        hready |-> ##1 $stable(hresp);
    endproperty
    
    a_resp_stable: assert property (p_resp_stable);
    
    // OKAY 响应是默认值
    property p_resp_okay_default;
        @(posedge hclk) disable iff (!hreset_n)
        hready |-> hresp == HRESP_OKAY;
    endproperty
    
    a_resp_okay_default: assert property (p_resp_okay_default);
    
    //============================================================================
    // 属性：地址对齐
    //============================================================================
    
    // HADDR 应该根据 HSIZE 对齐
    property p_addr_alignment;
        @(posedge hclk) disable iff (!hreset_n)
        (htrans == HTRANS_NONSEQ || htrans == HTRANS_SEQ) && hready |->
        (hsize == 3'd0) || (haddr[0] == 1'b0) ||  // BYTE: 任意对齐
        (hsize == 3'd1) || (haddr[1:0] == 2'b00) ||  // HALFWORD: 2 字节对齐
        (hsize == 3'd2) || (haddr[2:0] == 3'b000) ||  // WORD: 4 字节对齐
        (hsize == 3'd3) || (haddr[3:0] == 4'b0000);   // DOUBLEWORD: 8 字节对齐
    endproperty
    
    a_addr_alignment: assert property (p_addr_alignment)
        else $error("Address alignment violation");
    
    //============================================================================
    // 属性：写数据在 HREADY 期间稳定
    //============================================================================
    
    property p_wdata_stable;
        @(posedge hclk) disable iff (!hreset_n)
        (hwrite && htrans == HTRANS_NONSEQ && !hready) |-> ##1 $stable(hwdata);
    endproperty
    
    a_wdata_stable: assert property (p_wdata_stable);
    
    //============================================================================
    // Cover 点
    //============================================================================
    
    c_idle: cover property (@(posedge hclk) htrans == HTRANS_IDLE);
    c_busy: cover property (@(posedge hclk) htrans == HTRANS_BUSY);
    c_nonseq: cover property (@(posedge hclk) htrans == HTRANS_NONSEQ);
    c_seq: cover property (@(posedge hclk) htrans == HTRANS_SEQ);
    c_write: cover property (@(posedge hclk) hwrite && hready);
    c_read: cover property (@(posedge hclk) !hwrite && hready);
    c_ready_stretch: cover property (@(posedge hclk) !hready && ##1 hready);
    
endmodule
