// ============================================================================
// 文件     : apb_interface.sv
// 描述     : APB 虚拟接口
// ============================================================================

`ifndef APB_INTERFACE_SV
`define APB_INTERFACE_SV

interface apb_intf (input pclk, input preset_n);
    
    // 主机输出
    logic [31:0]  paddr;
    logic         psel;
    logic         penable;
    logic         pwrite;
    logic [31:0]  pwdata;
    
    // 主机输入
    logic [31:0]  prdata;
    logic         pready;
    logic         pslverr;
    
    // 默认值
    initial begin
        paddr   = 32'b0;
        psel    = 1'b0;
        penable = 1'b0;
        pwrite  = 1'b0;
        pwdata  = 32'b0;
    end
    
    // 时钟块
    clocking drv_cb @(posedge pclk);
        default input #1ns output #1ns;
        output paddr;
        output psel;
        output penable;
        output pwrite;
        output pwdata;
        input  prdata;
        input  pready;
        input  pslverr;
    endclocking
    
    clocking mon_cb @(posedge pclk);
        default input #1ns output #1ns;
        input paddr;
        input psel;
        input penable;
        input pwrite;
        input pwdata;
        input prdata;
        input pready;
        input pslverr;
    endclocking
    
endinterface

`endif
