// ============================================================================
// 模块名   : tb_gpio_ctrl
// 功能描述 : GPIO 控制器测试平台
// ============================================================================

`timescale 1ns/1ps

module tb_gpio_ctrl;

    localparam  CLK_PERIOD = 10;  // 100MHz
    
    reg         pclk;
    reg         preset_n;
    reg         psel;
    reg         penable;
    reg         pwrite;
    reg  [31:0] paddr;
    reg  [31:0] pwdata;
    wire        pready;
    wire [31:0] prdata;
    wire        pslverr;
    
    reg  [15:0] gpio_i;
    wire [15:0] gpio_o;
    wire [15:0] gpio_oen;
    wire [15:0] gpio_irq;
    
    integer     tests_passed;
    integer     tests_failed;
    
    gpio_ctrl #(
        .PORT_ID   (0),
        .PIN_COUNT (16)
    ) u_gpio (
        .pclk      (pclk),
        .preset_n  (preset_n),
        .psel      (psel),
        .penable   (penable),
        .pwrite    (pwrite),
        .paddr     (paddr),
        .pwdata    (pwdata),
        .pready    (pready),
        .prdata    (prdata),
        .pslverr   (pslverr),
        .gpio_i    (gpio_i),
        .gpio_o    (gpio_o),
        .gpio_oen  (gpio_oen),
        .gpio_irq  (gpio_irq)
    );
    
    always # (CLK_PERIOD/2) pclk = ~pclk;
    
    initial begin
        pclk = 0;
        preset_n = 0;
        psel = 0;
        penable = 0;
        pwrite = 0;
        paddr = 32'h0;
        pwdata = 32'h0;
        gpio_i = 16'h0;
        
        tests_passed = 0;
        tests_failed = 0;
        
        #20 preset_n = 1;
        #20;
        
        $display("");
        $display("========================================");
        $display("  GPIO Controller Test");
        $display("========================================");
        $display("");
        
        test_moder();
        test_odr_bsrr();
        test_input_read();
        test_irq();
        
        $display("");
        $display("========================================");
        $display("  Test Summary");
        $display("========================================");
        $display("  Passed: %0d", tests_passed);
        $display("  Failed: %0d", tests_failed);
        $display("========================================");
        
        if (tests_failed == 0) begin
            $display("✓ All tests PASSED!");
            $finish;
        end else begin
            $display("✗ Some tests FAILED!");
            $finish(1);
        end
    end
    
    task apb_write;
        input [31:0] addr;
        input [31:0] data;
        begin
            @(posedge pclk);
            paddr = addr;
            pwdata = data;
            pwrite = 1;
            psel = 1;
            penable = 0;
            @(posedge pclk);
            penable = 1;
            wait (pready);
            @(posedge pclk);
            psel = 0;
            penable = 0;
            pwrite = 0;
        end
    endtask
    
    task apb_read_check;
        input [31:0] addr;
        input [31:0] expected;
        reg [31:0] actual;
        begin
            @(posedge pclk);
            paddr = addr;
            pwrite = 0;
            psel = 1;
            penable = 0;
            @(posedge pclk);
            penable = 1;
            wait (pready);
            actual = prdata;
            @(posedge pclk);
            psel = 0;
            penable = 0;
            
            if (actual !== expected) begin
                $display("    Read mismatch: addr=0x%08h, expected=0x%08h, actual=0x%08h", addr, expected, actual);
                tests_failed = tests_failed + 1;
            end else begin
                tests_passed = tests_passed + 1;
            end
        end
    endtask
    
    task test_moder;
        begin
            $display("[TEST] MODER Register");
            
            apb_write(32'h00, 32'h55555555);
            apb_read_check(32'h00, 32'h55555555);
            $display("  MODER test completed");
            
            apb_write(32'h00, 32'h0);
        end
    endtask
    
    task test_odr_bsrr;
        begin
            $display("[TEST] ODR and BSRR");
            
            apb_write(32'h14, 32'hAAAA);
            if (gpio_o !== 16'hAAAA) begin
                $display("  ✗ ODR write failed, got 0x%04h", gpio_o);
                tests_failed = tests_failed + 1;
            end else begin
                $display("  ✓ ODR write passed");
                tests_passed = tests_passed + 1;
            end
            
            apb_write(32'h18, 32'h00010000);
            if (gpio_o[0] !== 1'b0) begin
                $display("  ✗ BSRR reset failed");
                tests_failed = tests_failed + 1;
            end else begin
                $display("  ✓ BSRR reset passed");
                tests_passed = tests_passed + 1;
            end
            
            apb_write(32'h18, 32'h00000001);
            if (gpio_o[0] !== 1'b1) begin
                $display("  ✗ BSRR set failed");
                tests_failed = tests_failed + 1;
            end else begin
                $display("  ✓ BSRR set passed");
                tests_passed = tests_passed + 1;
            end
        end
    endtask
    
    task test_input_read;
        begin
            $display("[TEST] Input Read (IDR)");
            
            gpio_i = 16'hBEEF;
            #1;
            apb_read_check(32'h10, {16'h0000, 16'hBEEF});
            $display("  IDR test completed");
        end
    endtask
    
    task test_irq;
        begin
            $display("[TEST] IRQ Generation");
            
            // 先等待几个周期，确保模块稳定
            repeat (5) @(posedge pclk);
            
            gpio_i = 16'h0000;
            repeat (2) @(posedge pclk);
            
            // 在同一个时钟周期改变 gpio_i 并采样 gpio_irq
            gpio_i = 16'hFFFF;
            @(posedge pclk);
            // 此时 gpio_irq 应该是 gpio_i ^ gpio_i_prev = 0xFFFF ^ 0x0000 = 0xFFFF
            
            if (gpio_irq !== 16'hFFFF) begin
                $display("  ✗ IRQ generation failed, got 0x%04h (expected 0xFFFF)", gpio_irq);
                $display("  Note: IRQ is a single-cycle pulse!");
                tests_failed = tests_failed + 1;
            end else begin
                $display("  ✓ IRQ generation passed");
                tests_passed = tests_passed + 1;
            end
        end
    endtask
    
    initial begin
        $dumpfile("tb_gpio_ctrl.vcd");
        $dumpvars(0, tb_gpio_ctrl);
    end

endmodule
