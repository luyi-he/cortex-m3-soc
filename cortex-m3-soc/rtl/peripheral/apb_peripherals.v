// ============================================================================
// 模块名   : apb_peripherals
// 功能描述 : APB 外设集合 - 包含 GPIO(4 端口) 和 UART(2 个)
// ============================================================================

module apb_peripherals (
    input  wire             PCLK,
    input  wire             PRESETn,
    input  wire             PSEL,
    input  wire             PENABLE,
    input  wire             PWRITE,
    input  wire [31:0]      PADDR,
    input  wire [31:0]      PWDATA,
    output wire             PREADY,
    output wire [31:0]      PRDATA,
    output wire [31:0]      irq,
    input  wire [63:0]      gpio_i,
    output wire [63:0]      gpio_o,
    output wire [63:0]      gpio_oen,
    input  wire             uart0_rx,
    output wire             uart0_tx,
    input  wire             uart1_rx,
    output wire             uart1_tx
);

    wire        gpio_psel;
    wire        uart0_psel;
    wire        uart1_psel;
    
    assign gpio_psel   = PSEL & (PADDR[31:12] == 12'h0);
    assign uart0_psel  = PSEL & (PADDR[31:12] == 12'h1);
    assign uart1_psel  = PSEL & (PADDR[31:12] == 12'h1);
    
    wire        gpio_ready;
    wire        uart0_ready;
    wire        uart1_ready;
    wire [31:0] gpio_rdata;
    wire [31:0] uart0_rdata;
    wire [31:0] uart1_rdata;
    
    assign PREADY = gpio_ready | uart0_ready | uart1_ready;
    assign PRDATA = gpio_psel ? gpio_rdata : uart0_psel ? uart0_rdata : uart1_rdata;
    
    wire [15:0] gpio_irq_a, gpio_irq_b, gpio_irq_c, gpio_irq_d;
    wire [1:0]  uart_irq;
    
    gpio_ctrl #(
        .PORT_ID      (0),
        .PIN_COUNT    (16),
        .APB_ADDR_BASE(32'h0000)
    ) u_gpio_a (
        .pclk       (PCLK),
        .preset_n   (PRESETn),
        .psel       (gpio_psel && (PADDR[11:10] == 2'b00)),
        .penable    (PENABLE),
        .pwrite     (PWRITE),
        .paddr      (PADDR[9:0]),
        .pwdata     (PWDATA),
        .pready     (gpio_ready),
        .prdata     (gpio_rdata),
        .pslverr    (),
        .gpio_i     (gpio_i[15:0]),
        .gpio_o     (gpio_o[15:0]),
        .gpio_oen   (gpio_oen[15:0]),
        .gpio_irq   (gpio_irq_a)
    );
    
    gpio_ctrl #(
        .PORT_ID      (1),
        .PIN_COUNT    (16),
        .APB_ADDR_BASE(32'h0100)
    ) u_gpio_b (
        .pclk       (PCLK),
        .preset_n   (PRESETn),
        .psel       (gpio_psel && (PADDR[11:10] == 2'b01)),
        .penable    (PENABLE),
        .pwrite     (PWRITE),
        .paddr      (PADDR[9:0]),
        .pwdata     (PWDATA),
        .pready     (gpio_ready),
        .prdata     (gpio_rdata),
        .pslverr    (),
        .gpio_i     (gpio_i[31:16]),
        .gpio_o     (gpio_o[31:16]),
        .gpio_oen   (gpio_oen[31:16]),
        .gpio_irq   (gpio_irq_b)
    );
    
    gpio_ctrl #(
        .PORT_ID      (2),
        .PIN_COUNT    (16),
        .APB_ADDR_BASE(32'h0200)
    ) u_gpio_c (
        .pclk       (PCLK),
        .preset_n   (PRESETn),
        .psel       (gpio_psel && (PADDR[11:10] == 2'b10)),
        .penable    (PENABLE),
        .pwrite     (PWRITE),
        .paddr      (PADDR[9:0]),
        .pwdata     (PWDATA),
        .pready     (gpio_ready),
        .prdata     (gpio_rdata),
        .pslverr    (),
        .gpio_i     (gpio_i[47:32]),
        .gpio_o     (gpio_o[47:32]),
        .gpio_oen   (gpio_oen[47:32]),
        .gpio_irq   (gpio_irq_c)
    );
    
    gpio_ctrl #(
        .PORT_ID      (3),
        .PIN_COUNT    (16),
        .APB_ADDR_BASE(32'h0300)
    ) u_gpio_d (
        .pclk       (PCLK),
        .preset_n   (PRESETn),
        .psel       (gpio_psel && (PADDR[11:10] == 2'b11)),
        .penable    (PENABLE),
        .pwrite     (PWRITE),
        .paddr      (PADDR[9:0]),
        .pwdata     (PWDATA),
        .pready     (gpio_ready),
        .prdata     (gpio_rdata),
        .pslverr    (),
        .gpio_i     (gpio_i[63:48]),
        .gpio_o     (gpio_o[63:48]),
        .gpio_oen   (gpio_oen[63:48]),
        .gpio_irq   (gpio_irq_d)
    );
    
    uart_simple u_uart0 (
        .pclk       (PCLK),
        .preset_n   (PRESETn),
        .psel       (uart0_psel),
        .penable    (PENABLE),
        .pwrite     (PWRITE),
        .paddr      (PADDR),
        .pwdata     (PWDATA),
        .pready     (uart0_ready),
        .prdata     (uart0_rdata),
        .pslverr    (),
        .rx         (uart0_rx),
        .tx         (uart0_tx),
        .irq        (uart_irq[0])
    );
    
    uart_simple u_uart1 (
        .pclk       (PCLK),
        .preset_n   (PRESETn),
        .psel       (uart1_psel),
        .penable    (PENABLE),
        .pwrite     (PWRITE),
        .paddr      (PADDR),
        .pwdata     (PWDATA),
        .pready     (uart1_ready),
        .prdata     (uart1_rdata),
        .pslverr    (),
        .rx         (uart1_rx),
        .tx         (uart1_tx),
        .irq        (uart_irq[1])
    );
    
    assign irq[0] = |gpio_irq_a;
    assign irq[1] = |gpio_irq_b;
    assign irq[2] = |gpio_irq_c;
    assign irq[3] = |gpio_irq_d;
    assign irq[4] = uart_irq[0];
    assign irq[5] = uart_irq[1];
    assign irq[31:6] = 26'b0;
    
endmodule
