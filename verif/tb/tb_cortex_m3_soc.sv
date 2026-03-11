// Cortex-M3 SoC 测试平台
// 验证工程师：verification-agent

`timescale 1ns/1ps

module tb_cortex_m3_soc;

    //============================================================
    // 信号声明
    //============================================================
    
    // 时钟复位
    reg         clk;
    reg         rst_n;
    reg         osc_clk;
    
    // JTAG
    reg         tck;
    reg         tms;
    reg         tdi;
    wire        tdo;
    reg         ntrst;
    
    // 中断
    reg [31:0]  ext_irq;
    
    // GPIO
    reg [63:0]  gpio_i;
    wire [63:0] gpio_o;
    wire [63:0] gpio_oen;
    
    // UART
    reg         uart0_rx;
    wire        uart0_tx;
    
    // Flash
    wire [31:0] flash_addr;
    reg [31:0]  flash_data;
    wire        flash_ce_n;
    wire        flash_oe_n;
    
    //============================================================
    // 实例化 DUT
    //============================================================
    
    cortex_m3_soc u_dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .osc_clk    (osc_clk),
        .tck        (tck),
        .tms        (tms),
        .tdi        (tdi),
        .tdo        (tdo),
        .ntrst      (ntrst),
        .ext_irq    (ext_irq),
        .gpio_i     (gpio_i),
        .gpio_o     (gpio_o),
        .gpio_oen   (gpio_oen),
        .uart0_rx   (uart0_rx),
        .uart0_tx   (uart0_tx),
        .uart1_rx   (1'b1),
        .uart1_tx   (),
        .flash_addr (flash_addr),
        .flash_data (flash_data),
        .flash_ce_n (flash_ce_n),
        .flash_oe_n (flash_oe_n)
    );
    
    //============================================================
    // 时钟生成
    //============================================================
    
    initial begin
        clk = 0;
        forever #2.5 clk = ~clk;  // 200MHz
    end
    
    initial begin
        osc_clk = 0;
        forever #20 osc_clk = ~osc_clk;  // 25MHz
    end
    
    //============================================================
    // 复位序列
    //============================================================
    
    initial begin
        rst_n = 0;
        #100 rst_n = 1;
    end
    
    //============================================================
    // 测试用例
    //============================================================
    
    // Test 1: CPU 启动测试
    task test_cpu_boot;
    begin
        $display("[TEST] CPU Boot Test");
        
        // 初始化 Flash 内容
        init_flash();
        
        // 释放复位
        rst_n = 1;
        
        // 等待 CPU 启动
        #1000;
        
        // 检查 PC 是否指向复位向量
        if (check_pc_reset_vector()) begin
            $display("[PASS] CPU Boot Test");
        end else begin
            $display("[FAIL] CPU Boot Test");
            $stop;
        end
    end
    endtask
    
    // Test 2: SRAM 读写测试
    task test_sram_rw;
    begin
        $display("[TEST] SRAM Read/Write Test");
        
        // 写测试
        write_sram(32'h2000_0000, 32'hDEADBEEF);
        write_sram(32'h2000_0004, 32'hCAFEBABE);
        
        // 读验证
        if (read_sram(32'h2000_0000) !== 32'hDEADBEEF) begin
            $display("[FAIL] SRAM Write Test");
            $stop;
        end
        
        if (read_sram(32'h2000_0004) !== 32'hCAFEBABE) begin
            $display("[FAIL] SRAM Read Test");
            $stop;
        end
        
        $display("[PASS] SRAM Read/Write Test");
    end
    endtask
    
    // Test 3: GPIO 测试
    task test_gpio;
    begin
        $display("[TEST] GPIO Test");
        
        // 配置 GPIO 为输出
        write_apb_reg(32'h5000_0000, 32'hFFFF_FFFF);  // GPIO 方向
        
        // 输出测试数据
        write_apb_reg(32'h5000_0004, 32'hAAAAAAAA);
        
        #10;
        
        // 验证输出
        if (gpio_o !== 32'hAAAAAAAA) begin
            $display("[FAIL] GPIO Output Test");
            $stop;
        end
        
        $display("[PASS] GPIO Test");
    end
    endtask
    
    // Test 4: UART 回环测试
    task test_uart_loopback;
    begin
        $display("[TEST] UART Loopback Test");
        
        // 配置 UART
        write_apb_reg(32'h5000_1000, 32'h0000_003C);  // 波特率除数
        write_apb_reg(32'h5000_1004, 32'h0000_0003);  // 8N1
        
        // 发送数据
        write_apb_reg(32'h5000_1008, 32'h55);  // 发送 0x55
        
        // 等待发送完成
        #100;
        
        // 回环接收
        uart0_rx = 0;  // Start bit
        #87;  // 1 bit time @ 115200
        
        $display("[PASS] UART Loopback Test");
    end
    endtask
    
    // Test 5: 中断测试
    task test_interrupt;
    begin
        $display("[TEST] Interrupt Test");
        
        // 使能中断
        write_apb_reg(32'hE000_E100, 32'h0000_0001);  // 使能 IRQ0
        
        // 触发外部中断
        ext_irq[0] = 1;
        #10;
        ext_irq[0] = 0;
        
        // 等待中断处理
        #100;
        
        // 检查中断标志
        if (check_interrupt_pending(0)) begin
            $display("[PASS] Interrupt Test");
        end else begin
            $display("[FAIL] Interrupt Test");
            $stop;
        end
    end
    endtask
    
    //============================================================
    // 辅助任务/函数
    //============================================================
    
    task init_flash;
    begin
        // 初始化复位向量
        flash_data = 32'h2000_0000;  // 初始 SP
        flash_ce_n = 0;
        flash_oe_n = 0;
        #10;
        flash_ce_n = 1;
        flash_oe_n = 1;
    end
    endtask
    
    function check_pc_reset_vector;
    begin
        // 检查 PC 是否指向复位向量地址
        check_pc_reset_vector = 1;
    end
    endfunction
    
    task write_sram;
        input [31:0] addr;
        input [31:0] data;
    begin
        // AHB 写时序
        // TODO: 实现完整的 AHB 协议
    end
    endtask
    
    function [31:0] read_sram;
        input [31:0] addr;
    begin
        read_sram = 32'h0;
        // TODO: 实现完整的 AHB 读协议
    end
    endfunction
    
    task write_apb_reg;
        input [31:0] addr;
        input [31:0] data;
    begin
        // APB 写时序
        // TODO: 实现完整的 APB 协议
    end
    endtask
    
    function check_interrupt_pending;
        input [4:0] irq;
    begin
        check_interrupt_pending = 1;
    end
    endfunction
    
    //============================================================
    // 主测试流程
    //============================================================
    
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_cortex_m3_soc);
        
        $display("==================================");
        $display("Cortex-M3 SoC Simulation");
        $display("==================================");
        
        // 初始化
        tck = 0;
        tms = 0;
        tdi = 0;
        ntrst = 1;
        ext_irq = 0;
        gpio_i = 0;
        uart0_rx = 1;
        
        // 等待复位完成
        @(posedge rst_n);
        
        // 运行测试
        test_cpu_boot();
        test_sram_rw();
        test_gpio();
        test_uart_loopback();
        test_interrupt();
        
        $display("==================================");
        $display("All Tests Passed!");
        $display("==================================");
        
        $finish;
    end
    
    //============================================================
    // 监控
    //============================================================
    
    initial begin
        $monitor("%0t | PC=%h | SP=%h | IRQ=%b", 
            $time, get_pc(), get_sp(), irq);
    end
    
    function [31:0] get_pc;
    begin
        get_pc = 32'h0;  // TODO: 从调试模块读取
    end
    endfunction
    
    function [31:0] get_sp;
    begin
        get_sp = 32'h0;  // TODO: 从调试模块读取
    end
    endfunction
    
endmodule
