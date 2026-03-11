// ============================================================================
// 模块名   : cortex_m3_soc_sim
// 功能描述 : Cortex-M3 SoC 简化版本 (用于协同仿真)
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

    reg         hclk;
    reg         pclk;
    reg         hreset_n;
    reg         preset_n;
    
    reg [31:0]  haddr;
    reg [31:0]  hwdata;
    reg [31:0]  hrdata;
    reg         hready;
    reg [1:0]   htrans;
    reg         hwrite;
    
    reg [31:0]  paddr;
    reg         psel;
    reg         penable;
    reg         pwrite;
    reg [31:0]  pwdata;
    reg [31:0]  prdata;
    reg         pready;
    
    reg [31:0]  irq;
    reg [31:0]  flash_data;
    reg [31:0]  flash_mem [0:131071];
    
    initial begin
        $display("[SOC] Loading firmware...");
        if (!$readmemh("firmware/build/cortex-m3-firmware.hex", flash_mem)) begin
            $display("[SOC] Warning: Could not load firmware");
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hclk <= 1'b0;
            pclk <= 1'b0;
            hreset_n <= 1'b0;
            preset_n <= 1'b0;
        end else begin
            hclk <= ~hclk;
            pclk <= (hclk == 1'b0) ? ~pclk : pclk;
            hreset_n <= 1'b1;
            preset_n <= hreset_n;
        end
    end
    
    always @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n) begin
            flash_data <= 32'h0;
            haddr <= 32'h0;
            htrans <= 2'b00;
            hwrite <= 1'b0;
            hwdata <= 32'h0;
            hrdata <= 32'h0;
            hready <= 1'b1;
        end else begin
            if (htrans == 2'b10 && hready) begin
                if (haddr < 32'h00080000) begin
                    flash_data <= flash_mem[haddr[19:2]];
                    hrdata <= flash_data;
                end
                htrans <= 2'b00;
            end
        end
    end
    
    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n) begin
            psel <= 1'b0;
            penable <= 1'b0;
            pwrite <= 1'b0;
            paddr <= 32'h0;
            pwdata <= 32'h0;
            prdata <= 32'h0;
            pready <= 1'b1;
        end else if (psel && !penable) begin
            penable <= 1'b1;
            pready <= 1'b1;
        end else if (penable) begin
            psel <= 1'b0;
            penable <= 1'b0;
        end
    end
    
    wire [31:0] cpu_haddr;
    wire [31:0] cpu_hwdata;
    wire [31:0] cpu_hrdata;
    wire        cpu_hready;
    wire        cpu_hresp;
    wire [1:0]  cpu_htrans;
    wire        cpu_hwrite;
    
    cortex_m3 u_cpu (
        .HCLK       (hclk),
        .HRESETn    (hreset_n),
        .HADDR      (cpu_haddr),
        .HBURST     (3'b000),
        .HMASTLOCK  (1'b0),
        .HPROT      (4'b1111),
        .HSIZE      (3'b010),
        .HTRANS     (cpu_htrans),
        .HWRITE     (cpu_hwrite),
        .HREADY     (cpu_hready),
        .HRESP      (cpu_hresp),
        .HRDATA     (cpu_hrdata),
        .HWDATA     (cpu_hwdata),
        .IRQ        (irq),
        .NMI        (1'b0),
        .TCK        (1'b0),
        .TMS        (1'b0),
        .TDI        (1'b0),
        .TDO        (),
        .nTRST      (1'b1),
        .SWV        ()
    );
    
    assign haddr = cpu_haddr;
    assign hwdata = cpu_hwdata;
    assign htrans = cpu_htrans;
    assign hwrite = cpu_hwrite;
    assign hrdata = cpu_hrdata;
    assign hready = cpu_hready;
    assign hresp = cpu_hresp;
    
    assign cpu_hready = pready;
    assign cpu_hresp = 1'b0;
    
    assign psel = (htrans == 2'b10) && (haddr[31:24] == 8'h40);
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
