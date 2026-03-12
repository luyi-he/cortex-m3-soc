// ============================================================================
// Testbench : tb_cosim.sv
// 功能描述  : Cortex-M3 SoC 协同仿真测试平台
// ============================================================================

`timescale 1ns/1ps

module tb_cosim;

    parameter   CLK_PERIOD    = 5;
    parameter   RST_PERIOD    = 100;
    parameter   SIM_TIME      = 10000000;
    
    reg         clk;
    reg         rst_n;
    reg [63:0]  gpio_i;
    wire [63:0] gpio_o;
    wire [63:0] gpio_oen;
    wire        uart0_tx;
    wire        uart1_tx;
    
    reg [63:0]  gpio_o_prev;
    reg [31:0]  gpio_toggle_cnt;
    
    initial begin
        $display("");
        $display("========================================");
        $display("  Cortex-M3 SoC Co-Simulation");
        $display("  Firmware: firmware/build/cortex-m3-firmware.hex");
        $display("========================================");
        $display("");
    end
    
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end
    
    initial begin
        rst_n = 1'b0;
        #RST_PERIOD;
        rst_n = 1'b1;
        $display("[TB] Release reset at %0t", $time);
    end
    
    initial begin
        gpio_i = 64'b0;
    end
    
    always @(posedge clk) begin
        if (!rst_n) begin
            gpio_o_prev <= 64'b0;
            gpio_toggle_cnt <= 32'd0;
        end else begin
            if (gpio_o !== gpio_o_prev) begin
                gpio_toggle_cnt <= gpio_toggle_cnt + 1;
                $display("[GPIO] Toggle #%0d at %0t: 0x%016h", 
                        gpio_toggle_cnt, $time, gpio_o);
                gpio_o_prev <= gpio_o;
            end
        end
    end
    
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_cosim);
    end
    
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
    
    wire [31:0] flash_data_io;
    
    cortex_m3_soc u_soc (
        .clk        (clk),
        .rst_n      (rst_n),
        .osc_clk    (1'b1),
        .gpio_i     (gpio_i),
        .gpio_o     (gpio_o),
        .gpio_oen   (gpio_oen),
        .uart0_rx   (1'b1),
        .uart0_tx   (uart0_tx),
        .uart1_rx   (1'b1),
        .uart1_tx   (uart1_tx),
        .flash_addr_o (),
        .flash_data_io (flash_data_io),
        .flash_ce_n (),
        .flash_oe_n (),
        .tck        (1'b0),
        .tms        (1'b0),
        .tdi        (1'b0),
        .tdo        (),
        .ntrst      (1'b1),
        .ext_irq    (32'h0)
    );

endmodule
