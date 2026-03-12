// ============================================================================
// 模块名   : gpio_ctrl
// 功能描述 : GPIO 控制器 - 4 端口 x16 引脚
//          - 符合 arch_spec_v1.0.md Section 3.1
//          - 每个端口 1KB 地址空间，10 个寄存器
// 作者     : Cortex-M3 SoC RTL Team
// 创建日期 : 2026-03-11
// 版本     : v2.0 (重构版)
// ============================================================================

module gpio_ctrl #(
    parameter   PORT_ID       = 0,          // 端口 ID: 0=A, 1=B, 2=C, 3=D
    parameter   PIN_COUNT     = 16,         // 每端口引脚数
    parameter   APB_ADDR_BASE = 32'h0000    // APB 基地址偏移
) (
    // APB 接口
    input  wire             pclk,
    input  wire             preset_n,
    input  wire             psel,
    input  wire             penable,
    input  wire             pwrite,
    input  wire [31:0]      paddr,
    input  wire [31:0]      pwdata,
    output reg              pready,
    output reg [31:0]       prdata,
    output reg              pslverr,
    
    // GPIO 外部接口 - 4 端口 x16 引脚 = 64 位
    input  wire [63:0]      gpio_i,         // GPIO 输入
    output reg  [63:0]      gpio_o,         // GPIO 输出
    output reg  [63:0]      gpio_oen,       // GPIO 输出使能
    output wire [63:0]      gpio_irq        // GPIO 中断
);

    //============================================================
    // 寄存器定义 (arch_spec_v1.0.md Section 3.1)
    //============================================================
    
    reg [63:0]  moder_reg;      // 0x00 模式寄存器
    reg [63:0]  otyper_reg;     // 0x04 输出类型
    reg [63:0]  ospeedr_reg;    // 0x08 输出速度
    reg [63:0]  pupdr_reg;      // 0x0C 上下拉
    wire [63:0] idr_wire;       // 0x10 输入数据 (组合逻辑)
    reg [63:0]  odr_reg;        // 0x14 输出数据
    reg [63:0]  bsrr_reg;       // 0x18 置位/复位 (写触发)
    reg [63:0]  lckr_reg;       // 0x1C 锁定寄存器
    reg [63:0]  afrl_reg;       // 0x20 复用功能低
    reg [63:0]  afrh_reg;       // 0x24 复用功能高
    
    // 输入数据直接映射到 IDR
    assign idr_wire = gpio_i;
    
    //============================================================
    // 中断生成 (输入变化检测)
    //============================================================
    
    reg [63:0]  gpio_i_prev;
    wire [63:0] gpio_i_edge;
    
    assign gpio_irq = gpio_i_edge;
    
    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n)
            gpio_i_prev <= 64'h0000_0000_0000_0000;
        else
            gpio_i_prev <= gpio_i;
    end
    
    assign gpio_i_edge = gpio_i ^ gpio_i_prev;
    
    //============================================================
    // APB 状态机
    //============================================================
    
    reg [1:0] apb_state;
    localparam ST_IDLE = 2'b00, ST_ACCESS = 2'b01;
    
    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n) begin
            apb_state <= ST_IDLE;
            pready <= 1'b0;
            prdata <= 32'h0;
            pslverr <= 1'b0;
        end else begin
            case (apb_state)
                ST_IDLE: begin
                    if (psel && !penable) begin
                        apb_state <= ST_ACCESS;
                        pready <= 1'b0;
                        pslverr <= 1'b0;
                    end
                end
                ST_ACCESS: begin
                    pready <= 1'b1;
                    if (pwrite) begin
                        // 写操作
                        case (paddr[7:2])
                            6'h00: moder_reg   <= pwdata;
                            6'h01: otyper_reg  <= pwdata;
                            6'h02: ospeedr_reg <= pwdata;
                            6'h03: pupdr_reg   <= pwdata;
                            6'h05: begin
                                // ODR 写
                                odr_reg <= pwdata;
                                gpio_o <= pwdata[15:0];
                            end
                            6'h06: begin
                                // BSRR 写 - 原子操作
                                if (pwdata[15:0])  gpio_o <= gpio_o | pwdata[15:0];    // 置位
                                if (pwdata[31:16]) gpio_o <= gpio_o & ~pwdata[31:16];  // 复位
                            end
                            6'h07: lckr_reg  <= pwdata;
                            6'h08: afrl_reg  <= pwdata;
                            6'h09: afrh_reg  <= pwdata;
                            default: pslverr <= 1'b1;
                        endcase
                    end else begin
                        // 读操作
                        case (paddr[7:2])
                            6'h00: prdata <= moder_reg;
                            6'h01: prdata <= otyper_reg;
                            6'h02: prdata <= ospeedr_reg;
                            6'h03: prdata <= pupdr_reg;
                            6'h04: prdata <= idr_wire;
                            6'h05: prdata <= {16'h0000, odr_reg[15:0]};
                            6'h07: prdata <= lckr_reg;
                            6'h08: prdata <= afrl_reg;
                            6'h09: prdata <= afrh_reg;
                            default: prdata <= 32'h0;
                        endcase
                    end
                    apb_state <= ST_IDLE;
                end
            endcase
        end
    end
    
    //============================================================
    // 输出使能生成
    //============================================================
    
    reg [1:0] pin_mode [15:0];
    integer i;
    
    always @(*) begin
        for (i = 0; i < 16; i = i + 1) begin
            pin_mode[i] = moder_reg[i*2 +: 2];
        end
    end
    
    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n) begin
            gpio_oen <= 16'hFFFF;  // 默认输入
        end else if (pwrite && (paddr[7:2] == 6'h00)) begin
            // MODER 更新时重新计算输出使能
            integer j;
            for (j = 0; j < 16; j = j + 1) begin
                case (pwdata[j*2 +: 2])
                    2'b00: gpio_oen[j] <= 1'b1;  // 输入
                    2'b01: gpio_oen[j] <= 1'b0;  // 输出
                    2'b10: gpio_oen[j] <= 1'b0;  // 复用
                    2'b11: gpio_oen[j] <= 1'b1;  // 模拟
                endcase
            end
        end
    end

endmodule
