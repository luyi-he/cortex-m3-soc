// ============================================================================
// 文件     : ahb_interface.sv
// 描述     : AHB-Lite 虚拟接口
// ============================================================================

`ifndef AHB_INTERFACE_SV
`define AHB_INTERFACE_SV

interface ahb_intf (input hclk, input hreset_n);
    
    // 主机输出 (从 DUT 输入)
    logic [31:0]  haddr;
    logic [2:0]   hburst;
    logic [2:0]   hsize;
    logic [1:0]   htrans;
    logic         hwrite;
    logic [31:0]  hwdata;
    
    // 主机输入 (从 DUT 输出)
    logic [31:0]  hrdata;
    logic         hready;
    logic         hresp;
    
    // 时钟复位已经作为端口参数
    
    // 默认值
    initial begin
        haddr   = 32'b0;
        hburst  = 3'b0;
        hsize   = 3'b0;
        htrans  = 2'b0;
        hwrite  = 1'b0;
        hwdata  = 32'b0;
    end
    
    // 时钟块
    clocking drv_cb @(posedge hclk);
        default input #1ns output #1ns;
        output haddr;
        output hburst;
        output hsize;
        output htrans;
        output hwrite;
        output hwdata;
        input  hrdata;
        input  hready;
        input  hresp;
    endclocking
    
    clocking mon_cb @(posedge hclk);
        default input #1ns output #1ns;
        input haddr;
        input hburst;
        input hsize;
        input htrans;
        input hwrite;
        input hwdata;
        input hrdata;
        input hready;
        input hresp;
    endclocking
    
    // 覆盖
    covergroup ahb_cov;
        option.per_instance = 1;
        cp_htrans: coverpoint htrans;
        cp_hsize:  coverpoint hsize;
        cp_hburst: coverpoint hburst;
        cp_hwrite: coverpoint hwrite;
    endgroup
    
    ahb_cov cov = new();
    
endinterface

`endif
