// Cortex-M3 SoC 顶层模块
// 架构师：architect-agent
// RTL 开发：rtl-design-agent

module cortex_m3_soc (
    // 时钟复位
    input  wire        clk,
    input  wire        rst_n,
    input  wire        osc_clk,
    
    // JTAG 调试
    input  wire        tck,
    input  wire        tms,
    input  wire        tdi,
    output wire        tdo,
    input  wire        ntrst,
    
    // 外部中断
    input  wire [31:0] ext_irq,
    
    // GPIO
    input  wire [63:0] gpio_i,
    output wire [63:0] gpio_o,
    output wire [63:0] gpio_oen,
    
    // UART
    input  wire        uart0_rx,
    output wire        uart0_tx,
    input  wire        uart1_rx,
    output wire        uart1_tx,
    
    // Flash 接口
    output wire [19:0] flash_addr_o,
    inout  wire [31:0] flash_data_io,
    output wire        flash_ce_n,
    output wire        flash_oe_n
);

    //============================================================
    // 内部信号
    //============================================================
    
    // AHB-Lite 信号
    wire        hclk;
    wire        hreset_n;
    wire [31:0] haddr;
    wire [2:0]  hburst;
    wire        hmastlock;
    wire [3:0]  hprot;
    wire [2:0]  hsize;
    wire [1:0]  htrans;
    wire        hwrite;
    wire [31:0] hwdata;
    wire [31:0] hrdata;
    wire        hready;
    wire        hresp;
    
    // AHB 从机信号 - Flash
    wire        flash_hsel;
    wire [31:0] flash_haddr;
    wire        flash_hwrite;
    wire [1:0]  flash_htrans;
    wire [2:0]  flash_hsize;
    wire [31:0] flash_hwdata;
    wire [31:0] flash_hrdata;
    wire        flash_hready;
    wire        flash_hresp;
    
    // AHB 从机信号 - SRAM
    wire        sram_hsel;
    wire [31:0] sram_haddr;
    wire        sram_hwrite;
    wire [1:0]  sram_htrans;
    wire [2:0]  sram_hsize;
    wire [31:0] sram_hwdata;
    wire [31:0] sram_hrdata;
    wire        sram_hready;
    wire        sram_hresp;
    
    // AHB 从机信号 - AHB2APB Bridge
    wire        bridge_hsel;
    wire [31:0] bridge_haddr;
    wire        bridge_hwrite;
    wire [1:0]  bridge_htrans;
    wire [2:0]  bridge_hsize;
    wire [31:0] bridge_hwdata;
    wire [31:0] bridge_hrdata;
    wire        bridge_hready;
    wire        bridge_hresp;
    
    // APB 信号
    wire        pclk;
    wire        preset_n;
    wire        psel;
    wire        penable;
    wire        pwrite;
    wire [31:0] paddr;
    wire [31:0] pwdata;
    wire        pready;
    wire [31:0] prdata;
    wire        pslverr;
    
    // 中断信号
    wire [31:0] irq;
    
    //============================================================
    // 时钟分频
    //============================================================
    
    clk_gen u_clk_gen (
        .osc_clk    (osc_clk),
        .rst_n      (rst_n),
        .hclk       (hclk),      // 200MHz
        .pclk       (pclk),      // 100MHz
        .hreset_n   (hreset_n),
        .preset_n   (preset_n)
    );
    
    //============================================================
    // Cortex-M3 CPU
    //============================================================
    
    cortex_m3 u_cpu (
        .HCLK       (hclk),
        .HRESETn    (hreset_n),
        
        // AHB-Lite 主机接口
        .HADDR      (haddr),
        .HBURST     (hburst),
        .HMASTLOCK  (hmastlock),
        .HPROT      (hprot),
        .HSIZE      (hsize),
        .HTRANS     (htrans),
        .HWRITE     (hwrite),
        .HREADY     (hready),
        .HRESP      (hresp),
        .HRDATA     (hrdata),
        .HWDATA     (hwdata),
        
        // 中断
        .IRQ        (irq),
        .NMI        (1'b0),
        
        // 调试
        .TCK        (tck),
        .TMS        (tms),
        .TDI        (tdi),
        .TDO        (tdo),
        .nTRST      (ntrst),
        
        // 跟踪
        .SWV        ()
    );
    
    //============================================================
    // AHB 总线矩阵
    //============================================================
    
    ahb_matrix u_ahb_matrix (
        // AHB 时钟复位
        .hclk       (hclk),
        .hreset_n   (hreset_n),
        
        // AHB 主机接口 (CPU)
        .haddr_m    (haddr),
        .hburst_m   (hburst),
        .hprot_m    (hprot),
        .hsize_m    (hsize),
        .htrans_m   (htrans),
        .hwrite_m   (hwrite),
        .hwdata_m   (hwdata),
        .hrdata_m   (hrdata),
        .hready_m   (hready),
        .hresp_m    (hresp),
        
        // AHB 从机接口 0 - Flash
        .haddr_s0   (flash_haddr),
        .hburst_s0  (hburst),
        .hprot_s0   (hprot),
        .hsize_s0   (hsize),
        .htrans_s0  (htrans),
        .hwrite_s0  (flash_hwrite),
        .hwdata_s0  (flash_hwdata),
        .hrdata_s0  (flash_hrdata),
        .hready_s0  (flash_hready),
        .hresp_s0   (flash_hresp),
        .hsel_s0    (flash_hsel),
        
        // AHB 从机接口 1 - SRAM
        .haddr_s1   (sram_haddr),
        .hburst_s1  (hburst),
        .hprot_s1   (hprot),
        .hsize_s1   (hsize),
        .htrans_s1  (htrans),
        .hwrite_s1  (sram_hwrite),
        .hwdata_s1  (sram_hwdata),
        .hrdata_s1  (sram_hrdata),
        .hready_s1  (sram_hready),
        .hresp_s1   (sram_hresp),
        .hsel_s1    (sram_hsel),
        
        // AHB 从机接口 2 - AHB2APB Bridge
        .haddr_s2   (bridge_haddr),
        .hburst_s2  (hburst),
        .hprot_s2   (hprot),
        .hsize_s2   (hsize),
        .htrans_s2  (htrans),
        .hwrite_s2  (bridge_hwrite),
        .hwdata_s2  (bridge_hwdata),
        .hrdata_s2  (bridge_hrdata),
        .hready_s2  (bridge_hready),
        .hresp_s2   (bridge_hresp),
        .hsel_s2    (bridge_hsel)
    );
    
    //============================================================
    // Flash 控制器
    //============================================================
    
    flash_ctrl u_flash_ctrl (
        .hclk       (hclk),
        .hreset_n   (hreset_n),
        
        // AHB 接口
        .haddr      (flash_haddr),
        .hburst     (hburst),
        .hprot      (hprot),
        .hsize      (hsize),
        .htrans     (htrans),
        .hwrite     (flash_hwrite),
        .hwdata     (flash_hwdata),
        .hrdata     (flash_hrdata),
        .hready     (flash_hready),
        .hresp      (flash_hresp),
        .hsel       (flash_hsel),
        
        // 外部 Flash 接口
        .flash_addr_o   (flash_addr_o),
        .flash_data_io  (flash_data_io),
        .flash_ce_n     (flash_ce_n),
        .flash_oe_n     (flash_oe_n)
    );
    
    //============================================================
    // SRAM (ITCM + DTCM)
    //============================================================
    
    sram_ctrl u_sram_ctrl (
        .hclk       (hclk),
        .hreset_n   (hreset_n),
        
        // AHB 接口
        .haddr      (sram_haddr),
        .hburst     (hburst),
        .hprot      (hprot),
        .hsize      (hsize),
        .htrans     (htrans),
        .hwrite     (sram_hwrite),
        .hwdata     (sram_hwdata),
        .hrdata     (sram_hrdata),
        .hready     (sram_hready),
        .hresp      (sram_hresp),
        .hsel       (sram_hsel)
    );
    
    //============================================================
    // AHB2APB Bridge
    //============================================================
    
    ahb2apb_bridge u_ahb2apb (
        .hclk       (hclk),
        .hreset_n   (hreset_n),
        
        // AHB 接口
        .haddr      (bridge_haddr),
        .hburst     (hburst),
        .hprot      (hprot),
        .hsize      (hsize),
        .htrans     (htrans),
        .hwrite     (bridge_hwrite),
        .hwdata     (bridge_hwdata),
        .hrdata     (bridge_hrdata),
        .hready     (bridge_hready),
        .hresp      (bridge_hresp),
        .hsel       (bridge_hsel),
        
        // APB 接口
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
    // APB 外设
    //============================================================
    
    apb_peripherals u_apb_peripherals (
        .PCLK       (pclk),
        .PRESETn    (preset_n),
        
        // APB 接口
        .PSEL       (psel),
        .PENABLE    (penable),
        .PWRITE     (pwrite),
        .PADDR      (paddr),
        .PWDATA     (pwdata),
        .PREADY     (pready),
        .PRDATA     (prdata),
        
        // 中断输出
        .irq        (irq),
        
        // GPIO
        .gpio_i     (gpio_i),
        .gpio_o     (gpio_o),
        .gpio_oen   (gpio_oen),
        
        // UART
        .uart0_rx   (uart0_rx),
        .uart0_tx   (uart0_tx),
        .uart1_rx   (uart1_rx),
        .uart1_tx   (uart1_tx)
    );
    
endmodule
