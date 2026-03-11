// ============================================================================
// 模块名   : cortex_m3_soc_sim
// 功能描述 : Cortex-M3 SoC 简化版本 (用于协同仿真)
//           - 简化的时钟生成
//           - 简化的 AHB 总线
//           - 基本的外设支持
// 作者     : Cortex-M3 SoC RTL Team
// 创建日期 : 2026-03-11
// 版本     : v1.0 (simplified for simulation)
// ============================================================================

module cortex_m3_soc_sim (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [63:0] gpio_i,
    output wire [63:0] gpio_o,
    output wire [63:0] gpio_oen,
    output wire        uart0_tx,
    output wire        uart1_tx
);

    wire        hclk;
    wire        pclk;
    wire        hreset_n;
    wire        preset_n;
    
    wire [31:0] haddr;
    wire [2:0]  hsize;
    wire [1:0]  htrans;
    wire        hwrite;
    wire [31:0] hwdata;
    wire [31:0] hrdata;
    wire        hready;
    wire        hresp;
    
    wire [31:0] paddr;
    wire        psel;
    wire        penable;
    wire        pwrite;
    wire [31:0] pwdata;
    wire [31:0] prdata;
    wire        pready;
    
    wire [31:0] irq;
    
    wire [31:0] flash_data;
    reg [31:0]  flash_mem [0:131071];
    
    initial begin
        $display("[SOC] Loading firmware...");
        if (!$readmemh("firmware/build/cortex-m3-firmware.hex", flash_mem)) begin
            $display("[SOC] Warning: Could not load firmware");
        end
    end
    
    always @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n)
            flash_data <= 32'h0;
        else if (hready && haddr < 32'h00080000)
            flash_data <= flash_mem[haddr[19:2]];
    end
    
    clk_gen u_clk (
        .osc_clk    (clk),
        .rst_n      (rst_n),
        .hclk       (hclk),
        .pclk       (pclk),
        .hreset_n   (hreset_n),
        .preset_n   (preset_n),
        .clk_locked (),
        .rst_active ()
    );
    
    cortex_m3 u_cpu (
        .HCLK       (hclk),
        .HRESETn    (hreset_n),
        .HADDR      (haddr),
        .HBURST     (),
        .HMASTLOCK  (),
        .HPROT      (),
        .HSIZE      (hsize),
        .HTRANS     (htrans),
        .HWRITE     (hwrite),
        .HREADY     (hready),
        .HRESP      (hresp),
        .HRDATA     (hrdata),
        .HWDATA     (hwdata),
        .IRQ        (irq),
        .NMI        (1'b0),
        .TCK        (1'b0),
        .TMS        (1'b0),
        .TDI        (1'b0),
        .TDO        (),
        .nTRST      (1'b1),
        .SWV        ()
    );
    
    assign hready = 1'b1;
    assign hresp = 1'b0;
    
    always @(*) begin
        if (haddr[31:24] == 8'h00) begin
            hrdata = flash_data;
        end else if (haddr[31:24] == 8'h40) begin
            hrdata = prdata;
            hready = pready;
        end else begin
            hrdata = 32'h0;
        end
    end
    
    assign psel = (haddr[31:24] == 8'h40);
    assign penable = psel;
    assign pwrite = hwrite;
    assign paddr = haddr;
    assign pwdata = hwdata;
    
    apb_peripherals u_apb (
        .PCLK       (pclk),
        .PRESETn    (preset_n),
        .PSEL       (psel),
        .PENABLE    (penable),
        .PWRITE     (pwrite),
        .PADDR      (paddr),
        .PWDATA     (pwdata),
        .PREADY     (pready),
        .PRDATA     (prdata),
        .irq        (irq),
        .gpio_i     (gpio_i),
        .gpio_o     (gpio_o),
        .gpio_oen   (gpio_oen),
        .uart0_rx   (1'b1),
        .uart0_tx   (uart0_tx),
        .uart1_rx   (1'b1),
        .uart1_tx   (uart1_tx)
    );

endmodule
