// ============================================================================
// 模块名   : apb_peripherals
// 功能描述 : APB 外设集合 - 包含 GPIO 和 UART
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

    wire [31:0] apb_addr_offset;
    wire        gpio_psel;
    wire        uart0_psel;
    wire        uart1_psel;
    
    assign apb_addr_offset = PADDR;
    assign gpio_psel   = PSEL & (apb_addr_offset[31:12] == 12'h0);
    assign uart0_psel  = PSEL & (apb_addr_offset[31:12] == 12'h1);
    assign uart1_psel  = PSEL & (apb_addr_offset[31:12] == 12'h1);
    
    wire        gpio_ready;
    wire        uart0_ready;
    wire        uart1_ready;
    wire [31:0] gpio_rdata;
    wire [31:0] uart0_rdata;
    wire [31:0] uart1_rdata;
    
    assign PREADY = gpio_ready | uart0_ready | uart1_ready;
    assign PRDATA = gpio_psel ? gpio_rdata : uart0_psel ? uart0_rdata : uart1_rdata;
    
    wire [63:0] gpio_irq;
    wire [31:0] uart_irq;
    
    gpio_ctrl #(
        .PORT_ID      (0),
        .PIN_COUNT    (64),
        .APB_ADDR_BASE(32'h0000)
    ) u_gpio_ctrl (
        .pclk       (PCLK),
        .preset_n   (PRESETn),
        .psel       (gpio_psel),
        .penable    (PENABLE),
        .pwrite     (PWRITE),
        .paddr      (apb_addr_offset),
        .pwdata     (PWDATA),
        .pready     (gpio_ready),
        .prdata     (gpio_rdata),
        .pslverr    (),
        .gpio_i     (gpio_i),
        .gpio_o     (gpio_o),
        .gpio_oen   (gpio_oen),
        .gpio_irq   (gpio_irq)
    );
    
    uart_simple u_uart0 (
        .pclk       (PCLK),
        .preset_n   (PRESETn),
        .psel       (uart0_psel),
        .penable    (PENABLE),
        .pwrite     (PWRITE),
        .paddr      (apb_addr_offset),
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
        .paddr      (apb_addr_offset),
        .pwdata     (PWDATA),
        .pready     (uart1_ready),
        .prdata     (uart1_rdata),
        .pslverr    (),
        .rx         (uart1_rx),
        .tx         (uart1_tx),
        .irq        (uart_irq[1])
    );
    
    assign irq[0] = |gpio_irq[15:0];
    assign irq[1] = |gpio_irq[31:16];
    assign irq[2] = |gpio_irq[47:32];
    assign irq[3] = |gpio_irq[63:48];
    assign irq[4] = uart_irq[0];
    assign irq[5] = uart_irq[1];
    assign irq[31:6] = 26'b0;
    
endmodule

// ============================================================================
// 模块名   : uart_tx
// 功能描述 : UART 发送模块
// ============================================================================

module uart_tx (
    input  wire             pclk,
    input  wire             preset_n,
    input  wire             psel,
    input  wire             penable,
    input  wire             pwrite,
    input  wire [31:0]      paddr,
    input  wire [31:0]      pwdata,
    output wire             pready,
    output wire [31:0]      prdata,
    output wire             pslverr,
    input  wire             rx,
    output reg              tx,
    output wire             irq
);

    localparam  UART_TX_HOLD    = 32'h00;
    localparam  UART_STATUS     = 32'h04;
    localparam  UART_CTRL       = 32'h08;
    
    reg [31:0]  tx_hold_reg;
    reg [31:0]  status_reg;
    reg [31:0]  ctrl_reg;
    reg         tx_busy;
    reg [3:0]   tx_bit_cnt;
    reg [7:0]   tx_shift_reg;
    reg         apb_ready_reg;
    reg [31:0]  prdata_reg;
    
    assign pready  = apb_ready_reg;
    assign prdata  = prdata_reg;
    assign pslverr = 1'b0;
    assign irq     = 1'b0;
    assign status_reg[0] = ~tx_busy;
    assign status_reg[1] = ~tx_busy;
    assign status_reg[5] = 1'b0;
    
    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n) begin
            apb_ready_reg <= 1'b0;
            prdata_reg    <= 32'h0;
            tx            <= 1'b1;
            tx_busy       <= 1'b0;
        end else if (psel && !penable) begin
            apb_ready_reg <= 1'b0;
        end else if (penable && !apb_ready_reg) begin
            apb_ready_reg <= 1'b1;
            if (pwrite) begin
                if (paddr == UART_TX_HOLD) begin
                    tx_hold_reg <= pwdata;
                    tx_shift_reg <= pwdata[7:0];
                    tx_bit_cnt <= 4'd10;
                    tx_busy <= 1'b1;
                    $write("%c", pwdata[7:0]);
                end else if (paddr == UART_CTRL) begin
                    ctrl_reg <= pwdata;
                end
            end else begin
                case (paddr)
                    UART_TX_HOLD: prdata_reg <= tx_hold_reg;
                    UART_STATUS:  prdata_reg <= status_reg;
                    UART_CTRL:    prdata_reg <= ctrl_reg;
                    default:      prdata_reg <= 32'h0;
                endcase
            end
        end else begin
            apb_ready_reg <= 1'b0;
        end
    end
    
    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n) begin
            tx_busy <= 1'b0;
            tx_bit_cnt <= 4'd0;
        end else if (tx_busy) begin
            case (tx_bit_cnt)
                4'd10: begin
                    tx <= 1'b0;
                    tx_bit_cnt <= 4'd9;
                end
                4'd9, 4'd8, 4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 4'd2: begin
                    tx <= tx_shift_reg[tx_bit_cnt - 4'd2];
                    tx_bit_cnt <= tx_bit_cnt - 4'd1;
                end
                4'd1: begin
                    tx <= 1'b1;
                    tx_bit_cnt <= 4'd0;
                    tx_busy <= 1'b0;
                end
                default: begin
                    tx_busy <= 1'b0;
                end
            endcase
        end
    end
    
endmodule
