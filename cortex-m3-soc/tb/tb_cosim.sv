// ============================================================================
// Testbench : tb_cosim.sv  
// 功能描述  : 简化测试 - 只测试 CPU 从 Flash 读取
// ============================================================================

`timescale 1ns/1ps

module tb_cosim;

    reg         clk;
    reg         rst_n;
    
    reg [31:0]  flash_mem [0:131071];
    reg [31:0]  flash_data;
    reg [31:0]  haddr;
    wire [31:0] hrdata;
    wire        hready;
    reg [1:0]   htrans;
    wire        hwrite;
    wire [31:0] hwdata;
    
    wire [2:0]  hburst;
    wire        hmastlock;
    wire [3:0]  hprot;
    wire [2:0]  hsize;
    wire        hresp;
    wire [31:0] irq;
    
    reg [31:0]  cycle_count;
    
    assign hburst = 3'b000;
    assign hmastlock = 1'b0;
    assign hprot = 4'b1111;
    assign hsize = 3'b010;
    assign hresp = 1'b0;
    assign irq = 32'b0;
    
    initial begin
        $display("");
        $display("========================================");
        $display("  Cortex-M3 Simple Test");
        $display("========================================");
    end
    
    initial begin
        clk = 0;
        forever #2.5 clk = ~clk;
    end
    
    initial begin
        rst_n = 0;
        #50;
        rst_n = 1;
        $display("[TB] Reset released at %0t", $time);
    end
    
    initial begin
        $display("[TB] Loading firmware from firmware_pure.hex...");
        $readmemh("../firmware/build/firmware_pure.hex", flash_mem);
        $display("[TB] Firmware loaded! %0d words", $size(flash_mem));
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            flash_data <= 32'h0;
        end else if (hready && htrans == 2'b10) begin
            if (haddr[19:2] < 481)  // 固件大小
                flash_data <= flash_mem[haddr[19:2]];
            else
                flash_data <= 32'h0;  // 空 Flash 返回 0
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_count <= 0;
        end else begin
            cycle_count <= cycle_count + 1;
        end
    end
    
    initial begin
        #10000000;
        $display("");
        $display("========================================");
        $display("[TB] Simulation ended at cycle %0d", cycle_count);
        $display("========================================");
        $finish;
    end
    
    cortex_m3 u_cpu (
        .HCLK       (clk),
        .HRESETn    (rst_n),
        .HADDR      (haddr),
        .HBURST     (hburst),
        .HMASTLOCK  (hmastlock),
        .HPROT      (hprot),
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
    
    assign hrdata = flash_data;
    assign hready = 1'b1;
    
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_cosim);
    end

endmodule
