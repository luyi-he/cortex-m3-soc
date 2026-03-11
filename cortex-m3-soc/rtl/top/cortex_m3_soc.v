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
    output wire [31:0] flash_addr,
    input  wire [31:0] flash_data,
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
    wire        htrans;
    wire        hwrite;
    wire        hready;
    wire        hresp;
    wire [31:0] hrdata;
    wire [31:0] hwdata;
    wire        hsel;
    
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
        .HCLK       (hclk),
        .HRESETn    (hreset_n),
        
        // 主机端口 (CPU)
        .m0_HADDR   (haddr),
        .m0_HBURST  (hburst),
        .m0_HMASTLOCK(hmastlock),
        .m0_HPROT   (hprot),
        .m0_HSIZE   (hsize),
        .m0_HTRANS  (htrans),
        .m0_HWRITE  (hwrite),
        .m0_HWDATA  (hwdata),
        .m0_HREADY  (hready),
        .m0_HRESP   (hresp),
        .m0_HRDATA  (hrdata),
        
        // 从机端口 0 - Flash
        .s0_HSEL    (flash_hsel),
        .s0_HADDR   (flash_haddr),
        .s0_HWRITE  (flash_hwrite),
        .s0_HTRANS  (flash_htrans),
        .s0_HSIZE   (flash_hsize),
        .s0_HWDATA  (flash_hwdata),
        .s0_HREADY  (flash_hready),
        .s0_HRESP   (flash_hresp),
        .s0_HRDATA  (flash_hrdata),
        
        // 从机端口 1 - SRAM
        .s1_HSEL    (sram_hsel),
        .s1_HADDR   (sram_haddr),
        .s1_HWRITE  (sram_hwrite),
        .s1_HTRANS  (sram_htrans),
        .s1_HSIZE   (sram_hsize),
        .s1_HWDATA  (sram_hwdata),
        .s1_HREADY  (sram_hready),
        .s1_HRESP   (sram_hresp),
        .s1_HRDATA  (sram_hrdata),
        
        // 从机端口 2 - AHB2APB Bridge
        .s2_HSEL    (bridge_hsel),
        .s2_HADDR   (bridge_haddr),
        .s2_HWRITE  (bridge_hwrite),
        .s2_HTRANS  (bridge_htrans),
        .s2_HSIZE   (bridge_hsize),
        .s2_HWDATA  (bridge_hwdata),
        .s2_HREADY  (bridge_hready),
        .s2_HRESP   (bridge_hresp),
        .s2_HRDATA  (bridge_hrdata)
    );
    
    //============================================================
    // Flash 控制器
    //============================================================
    
    flash_ctrl u_flash_ctrl (
        .HCLK       (hclk),
        .HRESETn    (hreset_n),
        
        // AHB 接口
        .HSEL       (flash_hsel),
        .HADDR      (flash_haddr),
        .HWRITE     (flash_hwrite),
        .HTRANS     (flash_htrans),
        .HSIZE      (flash_hsize),
        .HWDATA     (flash_hwdata),
        .HREADY     (flash_hready),
        .HRESP      (flash_hresp),
        .HRDATA     (flash_hrdata),
        
        // 外部 Flash 接口
        .flash_addr (flash_addr),
        .flash_data (flash_data),
        .flash_ce_n (flash_ce_n),
        .flash_oe_n (flash_oe_n)
    );
    
    //============================================================
    // SRAM (ITCM + DTCM)
    //============================================================
    
    sram_ctrl u_sram_ctrl (
        .HCLK       (hclk),
        .HRESETn    (hreset_n),
        
        // AHB 接口
        .HSEL       (sram_hsel),
        .HADDR      (sram_haddr),
        .HWRITE     (sram_hwrite),
        .HTRANS     (sram_htrans),
        .HSIZE      (sram_hsize),
        .HWDATA     (sram_hwdata),
        .HREADY     (sram_hready),
        .HRESP      (sram_hresp),
        .HRDATA     (sram_hrdata)
    );
    
    //============================================================
    // AHB2APB Bridge
    //============================================================
    
    ahb2apb_bridge u_ahb2apb (
        .HCLK       (hclk),
        .HRESETn    (hreset_n),
        .PCLK       (pclk),
        .PRESETn    (preset_n),
        
        // AHB 接口
        .HSEL       (bridge_hsel),
        .HADDR      (bridge_haddr),
        .HWRITE     (bridge_hwrite),
        .HTRANS     (bridge_htrans),
        .HSIZE      (bridge_hsize),
        .HWDATA     (bridge_hwdata),
        .HREADY     (bridge_hready),
        .HRESP      (bridge_hresp),
        .HRDATA     (bridge_hrdata),
        
        // APB 接口
        .PSEL       (psel),
        .PENABLE    (penable),
        .PWRITE     (pwrite),
        .PADDR      (paddr),
        .PWDATA     (pwdata),
        .PREADY     (pready),
        .PRDATA     (prdata),
        .PSLVERR    (pslverr)
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
