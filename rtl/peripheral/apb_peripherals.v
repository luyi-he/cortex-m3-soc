// ============================================================================
// 模块名   : apb_peripherals
// 功能描述 : APB 外设集合 - 包含 GPIO 和 UART
// 作者     : Cortex-M3 SoC RTL Team
// 创建日期 : 2026-03-11
// 版本     : v1.0
// ============================================================================

module apb_peripherals (
    // APB 时钟复位
    input  wire             PCLK,
    input  wire             PRESETn,
    
    // APB 接口
    input  wire             PSEL,
    input  wire             PENABLE,
    input  wire             PWRITE,
    input  wire [31:0]      PADDR,
    input  wire [31:0]      PWDATA,
    output wire             PREADY,
    output wire [31:0]      PRDATA,
    
    // 中断输出汇总
    output wire [31:0]      irq,
    
    // GPIO 接口
    input  wire [63:0]      gpio_i,
    output wire [63:0]      gpio_o,
    output wire [63:0]      gpio_oen,
    
    // UART 接口
    input  wire             uart0_rx,
    output wire             uart0_tx,
    input  wire             uart1_rx,
    output wire             uart1_tx
);

    //============================================================
    // 地址解码
    //============================================================
    
    // 地址映射:
    // GPIO:   0x5000_0000 - 0x5000_0FFF
    // UART0:  0x5000_1000 - 0x5000_13FF
    // UART1:  0x5000_1400 - 0x5000_17FF
    
    wire [31:0] apb_addr_offset;
    wire        gpio_psel;
    wire        uart0_psel;
    wire        uart1_psel;
    
    // 地址解码 (假设 PADDR 已经是相对于 0x5000_0000 的偏移)
    assign apb_addr_offset = PADDR;
    
    assign gpio_psel   = PSEL & (apb_addr_offset[31:12] == 12'h0);
    assign uart0_psel  = PSEL & (apb_addr_offset[31:12] == 12'h1);
    assign uart1_psel  = PSEL & (apb_addr_offset[31:12] == 12'h1);
    
    //============================================================
    // APB 总线仲裁
    //============================================================
    
    wire        gpio_ready;
    wire        uart0_ready;
    wire        uart1_ready;
    
    wire [31:0] gpio_rdata;
    wire [31:0] uart0_rdata;
    wire [31:0] uart1_rdata;
    
    // PREADY - 任一设备就绪即可
    assign PREADY = gpio_ready | uart0_ready | uart1_ready;
    
    // PRDATA 多路选择器
    assign PRDATA = gpio_psel ? gpio_rdata :
                    uart0_psel ? uart0_rdata :
                    uart1_rdata;
    
    //============================================================
    // GPIO 控制器实例化
    //============================================================
    
    wire [63:0] gpio_irq;
    
    gpio_ctrl #(
        .PORT_COUNT   (4),
        .PIN_COUNT    (16),
        .APB_ADDR_BASE(32'h0000)
    ) u_gpio_ctrl (
        .pclk       (PCLK),
        .preset_n   (PRESETn),
        .psel       (gpio_psel),
        .penable    (PENABLE),
        .pwrite     (PWRITE),
        .paddr      (apb_addr_offset[11:0]),
        .pwdata     (PWDATA),
        .pready     (gpio_ready),
        .prdata     (gpio_rdata),
        .pslverr    (),
        .gpio_i     (gpio_i),
        .gpio_o     (gpio_o),
        .gpio_oen   (gpio_oen),
        .gpio_irq   (gpio_irq)
    );
    
    //============================================================
    // UART0 实例化
    //============================================================
    
    wire        uart0_irq;
    
    uart_simple #(
        .APB_ADDR_OFFSET(32'h1000)
    ) u_uart0 (
        .pclk       (PCLK),
        .preset_n   (PRESETn),
        .psel       (uart0_psel),
        .penable    (PENABLE),
        .pwrite     (PWRITE),
        .paddr      (apb_addr_offset[11:0]),
        .pwdata     (PWDATA),
        .pready     (uart0_ready),
        .prdata     (uart0_rdata),
        .pslverr    (),
        .rx         (uart0_rx),
        .tx         (uart0_tx),
        .irq        (uart0_irq)
    );
    
    //============================================================
    // UART1 实例化
    //============================================================
    
    wire        uart1_irq;
    
    uart_simple #(
        .APB_ADDR_OFFSET(32'h1400)
    ) u_uart1 (
        .pclk       (PCLK),
        .preset_n   (PRESETn),
        .psel       (uart1_psel),
        .penable    (PENABLE),
        .pwrite     (PWRITE),
        .paddr      (apb_addr_offset[11:0]),
        .pwdata     (PWDATA),
        .pready     (uart1_ready),
        .prdata     (uart1_rdata),
        .pslverr    (),
        .rx         (uart1_rx),
        .tx         (uart1_tx),
        .irq        (uart1_irq)
    );
    
    //============================================================
    // 中断汇总
    //============================================================
    
    assign irq[0] = |gpio_irq[15:0];
    assign irq[1] = |gpio_irq[31:16];
    assign irq[2] = |gpio_irq[47:32];
    assign irq[3] = |gpio_irq[63:48];
    assign irq[4] = uart0_irq;
    assign irq[5] = uart1_irq;
    assign irq[31:6] = 26'b0;
    
endmodule


// ============================================================================
// 模块名   : uart_simple
// 功能描述 : 简化 UART 模型 - 支持 TX 输出到 console
// 作者     : Cortex-M3 SoC RTL Team
// 创建日期 : 2026-03-11
// 版本     : v1.0
// ============================================================================

module uart_simple #(
    parameter   APB_ADDR_OFFSET = 32'h0000
) (
    input  wire             pclk,
    input  wire             preset_n,
    input  wire             psel,
    input  wire             penable,
    input  wire             pwrite,
    input  wire [31:0]      paddr,
    input  wire [31:0]      pwdata,
    output reg              pready,
    output reg [31:0]       prdata,
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
    
    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n) begin
            pready   <= 1'b0;
            prdata   <= 32'h0;
            tx       <= 1'b1;
            tx_busy  <= 1'b0;
        end else if (psel && !penable) begin
            pready <= 1'b0;
        end else if (penable && !pready) begin
            pready <= 1'b1;
            
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
