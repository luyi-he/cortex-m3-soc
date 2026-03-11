// ============================================================================
// 文件     : tb_top.sv
// 描述     : UVM 顶层 Testbench
// ============================================================================

`timescale 1ns/1ps

module tb_top;
    
    //============================================================
    // 时钟复位
    //============================================================
    
    logic hclk;
    logic hreset_n;
    logic pclk;
    logic preset_n;
    
    // 时钟生成
    initial begin
        hclk = 0;
        forever #2.5 hclk = ~hclk;  // 200MHz
    end
    
    initial begin
        pclk = 0;
        forever #5 pclk = ~pclk;  // 100MHz
    end
    
    // 复位生成
    initial begin
        hreset_n = 0;
        preset_n = 0;
        #100 hreset_n = 1;
        #10  preset_n = 1;
    end
    
    //============================================================
    // 虚拟接口
    //============================================================
    
    ahb_intf ahb_vif (.hclk(hclk), .hreset_n(hreset_n));
    apb_intf apb_vif (.pclk(pclk), .preset_n(preset_n));
    
    //============================================================
    // DUT 实例化
    //============================================================
    
    // AHB 信号
    wire [31:0]  haddr_m;
    wire [2:0]   hburst_m;
    wire [3:0]   hprot_m;
    wire [2:0]   hsize_m;
    wire [1:0]   htrans_m;
    wire         hwrite_m;
    wire [31:0]  hwdata_m;
    wire [31:0]  hrdata_m;
    wire         hready_m;
    wire         hresp_m;
    
    // SRAM 接口
    wire         hsel_sram;
    wire         hready_sram;
    wire         hresp_sram;
    wire [31:0]  hrdata_sram;
    
    // Flash 接口
    wire         hsel_flash;
    wire         hready_flash;
    wire         hresp_flash;
    wire [31:0]  hrdata_flash;
    
    // APB Bridge 接口
    wire         hsel_apb;
    wire         hready_apb;
    wire         hresp_apb;
    wire [31:0]  hrdata_apb;
    wire [31:0]  paddr;
    wire         psel;
    wire         penable;
    wire         pwrite;
    wire [31:0]  pwdata;
    wire [31:0]  prdata;
    wire         pready;
    wire         pslverr;
    
    //============================================================
    // 连接 DUT
    //============================================================
    
    // AHB Matrix
    ahb_matrix u_ahb_matrix (
        .hclk       (hclk),
        .hreset_n   (hreset_n),
        
        // Master (CPU)
        .haddr_m    (haddr_m),
        .hburst_m   (hburst_m),
        .hprot_m    (hprot_m),
        .hsize_m    (hsize_m),
        .htrans_m   (htrans_m),
        .hwrite_m   (hwrite_m),
        .hwdata_m   (hwdata_m),
        .hrdata_m   (hrdata_m),
        .hready_m   (hready_m),
        .hresp_m    (hresp_m),
        
        // Slave 0 - Flash
        .haddr_s0   (ahb_vif.haddr),
        .hburst_s0  (ahb_vif.hburst),
        .hprot_s0   (ahb_vif.hprot),
        .hsize_s0   (ahb_vif.hsize),
        .htrans_s0  (ahb_vif.htrans),
        .hwrite_s0  (ahb_vif.hwrite),
        .hwdata_s0  (ahb_vif.hwdata),
        .hrdata_s0  (hrdata_flash),
        .hready_s0  (hready_flash),
        .hresp_s0   (hresp_flash),
        .hsel_s0    (hsel_flash),
        
        // Slave 1 - SRAM
        .haddr_s1   (ahb_vif.haddr),
        .hburst_s1  (ahb_vif.hburst),
        .hprot_s1   (ahb_vif.hprot),
        .hsize_s1   (ahb_vif.hsize),
        .htrans_s1  (ahb_vif.htrans),
        .hwrite_s1  (ahb_vif.hwrite),
        .hwdata_s1  (ahb_vif.hwdata),
        .hrdata_s1  (hrdata_sram),
        .hready_s1  (hready_sram),
        .hresp_s1   (hresp_sram),
        .hsel_s1    (hsel_sram),
        
        // Slave 2 - APB Bridge
        .haddr_s2   (ahb_vif.haddr),
        .hburst_s2  (ahb_vif.hburst),
        .hprot_s2   (ahb_vif.hprot),
        .hsize_s2   (ahb_vif.hsize),
        .htrans_s2  (ahb_vif.htrans),
        .hwrite_s2  (ahb_vif.hwrite),
        .hwdata_s2  (ahb_vif.hwdata),
        .hrdata_s2  (hrdata_apb),
        .hready_s2  (hready_apb),
        .hresp_s2   (hresp_apb),
        .hsel_s2    (hsel_apb)
    );
    
    // SRAM Model
    sram_model u_sram (
        .hclk       (hclk),
        .hreset_n   (hreset_n),
        .hsel       (hsel_sram),
        .hready_in  (hready_m),
        .haddr      (haddr_m),
        .hsize      (hsize_m),
        .hwrite     (hwrite_m),
        .hwdata     (hwdata_m),
        .hrdata     (hrdata_sram),
        .hready_out (hready_sram),
        .hresp      (hresp_sram)
    );
    
    // Flash Model
    flash_model u_flash (
        .hclk       (hclk),
        .hreset_n   (hreset_n),
        .hsel       (hsel_flash),
        .hready_in  (hready_m),
        .haddr      (haddr_m),
        .hsize      (hsize_m),
        .hwrite     (hwrite_m),
        .hwdata     (hwdata_m),
        .hrdata     (hrdata_flash),
        .hready_out (hready_flash),
        .hresp      (hresp_flash)
    );
    
    // APB Bridge
    ahb2apb_bridge u_apb_bridge (
        .hclk       (hclk),
        .hreset_n   (hreset_n),
        
        // AHB Slave
        .haddr      (haddr_m),
        .hburst     (hburst_m),
        .hprot      (hprot_m),
        .hsize      (hsize_m),
        .htrans     (htrans_m),
        .hwrite     (hwrite_m),
        .hwdata     (hwdata_m),
        .hrdata     (hrdata_apb),
        .hready     (hready_apb),
        .hresp      (hresp_apb),
        .hsel       (hsel_apb),
        
        // APB Master
        .paddr      (paddr),
        .psel       (psel),
        .penable    (penable),
        .pwrite     (pwrite),
        .pwdata     (pwdata),
        .prdata     (prdata),
        .pready     (pready),
        .pslverr    (pslverr)
    );
    
    //============================================================
    // 连接虚拟接口到 DUT 信号
    //============================================================
    
    assign ahb_vif.haddr   = haddr_m;
    assign ahb_vif.hburst  = hburst_m;
    assign ahb_vif.hprot   = hprot_m;
    assign ahb_vif.hsize   = hsize_m;
    assign ahb_vif.htrans  = htrans_m;
    assign ahb_vif.hwrite  = hwrite_m;
    assign ahb_vif.hwdata  = hwdata_m;
    assign haddr_m         = ahb_vif.haddr;
    assign hburst_m        = ahb_vif.hburst;
    assign hprot_m         = ahb_vif.hprot;
    assign hsize_m         = ahb_vif.hsize;
    assign htrans_m        = ahb_vif.htrans;
    assign hwrite_m        = ahb_vif.hwrite;
    assign hwdata_m        = ahb_vif.hwdata;
    
    assign apb_vif.paddr   = paddr;
    assign apb_vif.psel    = psel;
    assign apb_vif.penable = penable;
    assign apb_vif.pwrite  = pwrite;
    assign apb_vif.pwdata  = pwdata;
    assign paddr           = apb_vif.paddr;
    assign psel            = apb_vif.psel;
    assign penable         = apb_vif.penable;
    assign pwrite          = apb_vif.pwrite;
    assign pwdata          = apb_vif.pwdata;
    
    //============================================================
    // UVM 配置
    //============================================================
    
    initial begin
        uvm_config_db#(virtual ahb_intf)::set(null, "uvm_test_top", "ahb_vif", ahb_vif);
        uvm_config_db#(virtual apb_intf)::set(null, "uvm_test_top", "apb_vif", apb_vif);
    end
    
    //============================================================
    // 实例化 UVM Test
    //============================================================
    
    initial begin
        run_test();
    end
    
    //============================================================
    // 波形输出
    //============================================================
    
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_top);
    end
    
    //============================================================
    // 断言实例化
    //============================================================
    
    ahb_assertions u_ahb_assert (
        .hclk      (hclk),
        .hreset_n  (hreset_n),
        .hready    (ahb_vif.hready),
        .htrans    (ahb_vif.htrans)
    );
    
endmodule
