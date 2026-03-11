// ============================================================================
// Testbench : tb_cosim.sv
// 功能描述  : Cortex-M3 SoC 协同仿真测试平台
//           - 加载固件到 Flash
//           - 生成时钟和复位
//           - 监控 UART TX 和 GPIO 输出
//           - 生成 VCD 波形
// 作者      : Cortex-M3 SoC RTL Team
// 创建日期  : 2026-03-11
// 版本      : v1.0
// ============================================================================

`timescale 1ns/1ps

module tb_cosim;

    //============================================================
    // 参数定义
    //============================================================
    
    parameter   CLK_PERIOD_OSC  = 5;      // 200MHz (5ns)
    parameter   RST_PERIOD      = 100;    // 复位保持 100ns
    parameter   SIM_TIME        = 100000000; // 仿真时间 100ms
    
    // 固件路径
    parameter   FIRMWARE_HEX    = "firmware/build/cortex-m3-firmware.hex";
    
    //============================================================
    // 测试信号
    //============================================================
    
    // 时钟和复位
    reg         osc_clk;
    reg         rst_n;
    
    // JTAG 调试 (未使用，接地)
    reg         tck;
    reg         tms;
    reg         tdi;
    wire        tdo;
    reg         ntrst;
    
    // 外部中断 (未使用，接地)
    wire [31:0] ext_irq = 32'b0;
    
    // GPIO
    reg [63:0]  gpio_i;
    wire [63:0] gpio_o;
    wire [63:0] gpio_oen;
    
    // UART
    reg         uart0_rx;
    wire        uart0_tx;
    reg         uart1_rx;
    wire        uart1_tx;
    
    // Flash 接口
    wire [31:0] flash_addr;
    reg [31:0]  flash_data;
    wire        flash_ce_n;
    wire        flash_oe_n;
    
    //============================================================
    // Flash 存储模型
    //============================================================
    
    reg [7:0]   flash_mem [0:2097151];  // 16MB Flash
    reg [31:0]  flash_size;
    
    // 初始化 Flash
    initial begin
        $display("[TB] Initializing Flash memory...");
        flash_size = 0;
        
        // 读取 hex 文件并加载到 Flash
        if ($test$plusargs("FIRMWARE")) begin
            $value$plusargs("FIRMWARE=%s", FIRMWARE_HEX);
        end
        
        $display("[TB] Loading firmware from %s...", FIRMWARE_HEX);
        
        // 使用 $readmemh 加载 (需要是纯 hex 格式)
        // 如果是 Intel HEX 格式，需要先转换
        if (!$readmemh(FIRMWARE_HEX, flash_mem)) begin
            $display("[TB] Warning: Could not load %s", FIRMWARE_HEX);
            $display("[TB] Using default blinky pattern...");
            // 填充一些测试数据
            flash_mem[0] = 8'h20;  // 初始 SP 低字节
            flash_mem[1] = 8'h00;
            flash_mem[2] = 8'h01;
            flash_mem[3] = 8'h20;
            // 复位向量
            flash_mem[4] = 8'h01;
            flash_mem[5] = 8'h00;
            flash_mem[6] = 8'h00;
            flash_mem[7] = 8'h08;
        end else begin
            $display("[TB] Firmware loaded successfully!");
        end
    end
    
    // Flash 读操作
    always @(flash_addr or flash_oe_n or flash_ce_n) begin
        if (!flash_ce_n && !flash_oe_n) begin
            #1 flash_data = {flash_mem[flash_addr + 3], 
                            flash_mem[flash_addr + 2],
                            flash_mem[flash_addr + 1], 
                            flash_mem[flash_addr + 0]};
        end else begin
            #1 flash_data = 32'hZZZZ_ZZZZ;
        end
    end
    
    //============================================================
    // 时钟生成
    //============================================================
    
    initial begin
        osc_clk = 1'b0;
        forever #(CLK_PERIOD_OSC / 2) osc_clk = ~osc_clk;
    end
    
    //============================================================
    // 复位生成
    //============================================================
    
    initial begin
        rst_n = 1'b0;
        #RST_PERIOD;
        rst_n = 1'b1;
        $display("[TB] Release reset at %0t", $time);
    end
    
    //============================================================
    // JTAG 信号初始化
    //============================================================
    
    initial begin
        tck = 1'b0;
        tms = 1'b0;
        tdi = 1'b0;
        ntrst = 1'b1;
    end
    
    //============================================================
    // UART RX 初始化
    //============================================================
    
    initial begin
        uart0_rx = 1'b1;  // 空闲状态
        uart1_rx = 1'b1;
    end
    
    //============================================================
    // GPIO 输入初始化
    //============================================================
    
    initial begin
        gpio_i = 64'b0;
    end
    
    //============================================================
    // 监控 UART TX 输出
    //============================================================
    
    reg [7:0] uart_rx_shift;
    reg [3:0] uart_rx_cnt;
    reg       uart_rx_busy;
    reg       uart_rx_start;
    
    // UART0 RX 采样 (115200 baud @ 200MHz = ~1736 cycles/bit)
    parameter UART_RX_CYCLES = 1736;
    reg [15:0] uart_rx_timer;
    
    always @(posedge osc_clk) begin
        if (!rst_n) begin
            uart_rx_shift <= 8'h0;
            uart_rx_cnt <= 4'd0;
            uart_rx_busy <= 1'b0;
            uart_rx_timer <= 16'd0;
        end else if (uart0_tx === 1'b0 && !uart_rx_busy) begin
            // 检测起始位
            uart_rx_busy <= 1'b1;
            uart_rx_timer <= UART_RX_CYCLES / 2;  // 采样到中间
        end else if (uart_rx_busy) begin
            if (uart_rx_timer == 0) begin
                uart_rx_timer <= UART_RX_CYCLES;
                if (uart_rx_cnt == 4'd0) begin
                    // 验证起始位
                    if (uart0_tx !== 1'b0) begin
                        uart_rx_busy <= 1'b0;
                    end else begin
                        uart_rx_cnt <= 4'd1;
                    end
                end else if (uart_rx_cnt < 4'd9) begin
                    // 采样数据位
                    uart_rx_shift[uart_rx_cnt - 4'd1] <= uart0_tx;
                    uart_rx_cnt <= uart_rx_cnt + 4'd1;
                end else begin
                    // 停止位
                    $write("[UART0] %c", uart_rx_shift);
                    $fflush;
                    uart_rx_busy <= 1'b0;
                    uart_rx_cnt <= 4'd0;
                end
            end else begin
                uart_rx_timer <= uart_rx_timer - 16'd1;
            end
        end
    end
    
    //============================================================
    // 监控 GPIO 翻转
    //============================================================
    
    reg [63:0] gpio_o_prev;
    reg [31:0] gpio_toggle_cnt;
    
    always @(posedge osc_clk) begin
        if (!rst_n) begin
            gpio_o_prev <= 64'b0;
            gpio_toggle_cnt <= 32'd0;
        end else begin
            if (gpio_o !== gpio_o_prev) begin
                gpio_toggle_cnt <= gpio_toggle_cnt + 1;
                $display("[GPIO] Toggle #%0d at %0t: 0x%016h (oen: 0x%016h)", 
                        gpio_toggle_cnt, $time, gpio_o, gpio_oen);
                gpio_o_prev <= gpio_o;
            end
        end
    end
    
    //============================================================
    // VCD 波形生成
    //============================================================
    
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_cosim);
    end
    
    //============================================================
    // 仿真结束控制
    //============================================================
    
    initial begin
        #SIM_TIME;
        $display("");
        $display("========================================");
        $display("[TB] Simulation completed!");
        $display("[TB] Total GPIO toggles: %0d", gpio_toggle_cnt);
        $display("[TB] Waveform saved to waveform.vcd");
        $display("========================================");
        $finish;
    end
    
    //============================================================
    // 实例化 DUT
    //============================================================
    
    cortex_m3_soc u_soc (
        // 时钟复位
        .clk        (osc_clk),
        .rst_n      (rst_n),
        .osc_clk    (osc_clk),
        
        // JTAG
        .tck        (tck),
        .tms        (tms),
        .tdi        (tdi),
        .tdo        (tdo),
        .ntrst      (ntrst),
        
        // 中断
        .ext_irq    (ext_irq),
        
        // GPIO
        .gpio_i     (gpio_i),
        .gpio_o     (gpio_o),
        .gpio_oen   (gpio_oen),
        
        // UART
        .uart0_rx   (uart0_rx),
        .uart0_tx   (uart0_tx),
        .uart1_rx   (uart1_rx),
        .uart1_tx   (uart1_tx),
        
        // Flash
        .flash_addr (flash_addr),
        .flash_data (flash_data),
        .flash_ce_n (flash_ce_n),
        .flash_oe_n (flash_oe_n)
    );
    
    //============================================================
    // 初始信息输出
    //============================================================
    
    initial begin
        $display("");
        $display("========================================");
        $display("  Cortex-M3 SoC Co-Simulation");
        $display("  Firmware: %s", FIRMWARE_HEX);
        $display("========================================");
        $display("");
    end

endmodule
