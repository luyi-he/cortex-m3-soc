// ============================================================================
// 模块名   : tb_sram_ctrl
// 功能描述 : SRAM 控制器测试平台
// 作者     : Cortex-M3 SoC RTL Team
// 创建日期 : 2026-03-10
// 版本     : v1.0
// ============================================================================

`timescale 1ns/1ps

module tb_sram_ctrl;

    //============================================================
    // 参数定义
    //============================================================
    
    localparam  CLK_PERIOD = 5;  // 200MHz
    
    //============================================================
    // 测试信号
    //============================================================
    
    // 时钟复位
    reg  hclk;
    reg  hreset_n;
    
    // AHB-Lite 从机接口
    reg  [31:0]  haddr;
    reg  [2:0]   hburst;
    reg  [3:0]   hprot;
    reg  [2:0]   hsize;
    reg  [1:0]   htrans;
    reg          hwrite;
    reg  [31:0]  hwdata;
    wire [31:0]  hrdata;
    wire         hready;
    wire         hresp;
    reg          hsel;
    
    // ITCM SRAM 接口
    wire [15:0]  itcm_addr_o;
    wire [31:0]  itcm_wdata_o;
    reg  [31:0]  itcm_rdata_i;
    wire [3:0]   itcm_be_o;
    wire         itcm_ce_o;
    wire         itcm_we_o;
    
    // DTCM SRAM 接口
    wire [15:0]  dtcm_addr_o;
    wire [31:0]  dtcm_wdata_o;
    reg  [31:0]  dtcm_rdata_i;
    wire [3:0]   dtcm_be_o;
    wire         dtcm_ce_o;
    wire         dtcm_we_o;
    
    //============================================================
    // 实例化被测模块
    //============================================================
    
    sram_ctrl #(
        .SRAM_ADDR_WIDTH (17),
        .SRAM_DATA_WIDTH (32),
        .ITCM_SIZE       (17),
        .DTCM_SIZE       (17)
    ) u_sram_ctrl (
        .hclk        (hclk),
        .hreset_n    (hreset_n),
        
        .haddr       (haddr),
        .hburst      (hburst),
        .hprot       (hprot),
        .hsize       (hsize),
        .htrans      (htrans),
        .hwrite      (hwrite),
        .hwdata      (hwdata),
        .hrdata      (hrdata),
        .hready      (hready),
        .hresp       (hresp),
        .hsel        (hsel),
        
        .itcm_addr_o (itcm_addr_o),
        .itcm_wdata_o(itcm_wdata_o),
        .itcm_rdata_i(itcm_rdata_i),
        .itcm_be_o   (itcm_be_o),
        .itcm_ce_o   (itcm_ce_o),
        .itcm_we_o   (itcm_we_o),
        
        .dtcm_addr_o (dtcm_addr_o),
        .dtcm_wdata_o(dtcm_wdata_o),
        .dtcm_rdata_i(dtcm_rdata_i),
        .dtcm_be_o   (dtcm_be_o),
        .dtcm_ce_o   (dtcm_ce_o),
        .dtcm_we_o   (dtcm_we_o)
    );
    
    //============================================================
    // 时钟生成
    //============================================================
    
    initial begin
        hclk = 0;
        forever #(CLK_PERIOD/2) hclk = ~hclk;
    end
    
    //============================================================
    // 复位生成
    //============================================================
    
    initial begin
        hreset_n = 0;
        #20 hreset_n = 1;
    end
    
    //============================================================
    // SRAM 模型 (ITCM + DTCM)
    //============================================================
    
    reg [31:0] itcm_mem [0:16383];  // 64KB / 4 bytes
    reg [31:0] dtcm_mem [0:16383];  // 64KB / 4 bytes
    
    // ITCM 响应
    always @(posedge hclk) begin
        if (itcm_ce_o && !itcm_we_o) begin
            itcm_rdata_i <= itcm_mem[itcm_addr_o];
        end
    end
    
    always @(posedge hclk) begin
        if (itcm_ce_o && itcm_we_o) begin
            if (itcm_be_o[0]) itcm_mem[itcm_addr_o][7:0]   <= itcm_wdata_o[7:0];
            if (itcm_be_o[1]) itcm_mem[itcm_addr_o][15:8]  <= itcm_wdata_o[15:8];
            if (itcm_be_o[2]) itcm_mem[itcm_addr_o][23:16] <= itcm_wdata_o[23:16];
            if (itcm_be_o[3]) itcm_mem[itcm_addr_o][31:24] <= itcm_wdata_o[31:24];
        end
    end
    
    // DTCM 响应
    always @(posedge hclk) begin
        if (dtcm_ce_o && !dtcm_we_o) begin
            dtcm_rdata_i <= dtcm_mem[dtcm_addr_o];
        end
    end
    
    always @(posedge hclk) begin
        if (dtcm_ce_o && dtcm_we_o) begin
            if (dtcm_be_o[0]) dtcm_mem[dtcm_addr_o][7:0]   <= dtcm_wdata_o[7:0];
            if (dtcm_be_o[1]) dtcm_mem[dtcm_addr_o][15:8]  <= dtcm_wdata_o[15:8];
            if (dtcm_be_o[2]) dtcm_mem[dtcm_addr_o][23:16] <= dtcm_wdata_o[23:16];
            if (dtcm_be_o[3]) dtcm_mem[dtcm_addr_o][31:24] <= dtcm_wdata_o[31:24];
        end
    end
    
    //============================================================
    // 测试任务
    //============================================================
    
    task ahb_write;
        input [31:0] addr;
        input [31:0] data;
        begin
            @(posedge hclk);
            haddr   <= addr;
            hwdata  <= data;
            hwrite  <= 1'b1;
            htrans  <= 2'b10;
            hsize   <= 3'b010;
            hburst  <= 3'b000;
            hprot   <= 4'b1111;
            hsel    <= 1'b1;
            
            wait (hready);
            @(posedge hclk);
            htrans  <= 2'b00;
            hsel    <= 1'b0;
        end
    endtask
    
    task ahb_read;
        input [31:0] addr;
        output [31:0] data;
        begin
            @(posedge hclk);
            haddr   <= addr;
            hwrite  <= 1'b0;
            htrans  <= 2'b10;
            hsize   <= 3'b010;
            hburst  <= 3'b000;
            hprot   <= 4'b1111;
            hsel    <= 1'b1;
            
            wait (hready);
            data = hrdata;
            @(posedge hclk);
            htrans  <= 2'b00;
            hsel    <= 1'b0;
        end
    endtask
    
    //============================================================
    // 测试用例
    //============================================================
    
    reg [31:0] read_data;
    integer    errors;
    
    initial begin
        errors = 0;
        
        // 初始化信号
        haddr   = 32'h0;
        hwdata  = 32'h0;
        hwrite  = 0;
        htrans  = 2'b00;
        hsize   = 3'b010;
        hburst  = 3'b000;
        hprot   = 4'b1111;
        hsel    = 0;
        
        #50;
        
        $display("=== Test 1: ITCM Write (0x0000_0000) ===");
        ahb_write(32'h0000_0000, 32'h12345678);
        $display("ITCM Write completed");
        
        #10;
        
        $display("=== Test 2: ITCM Read (0x0000_0000) ===");
        ahb_read(32'h0000_0000, read_data);
        $display("ITCM Read data: 0x%08h", read_data);
        if (read_data != 32'h12345678) begin
            $display("ERROR: Expected 0x12345678, got 0x%08h", read_data);
            errors = errors + 1;
        end
        
        #10;
        
        $display("=== Test 3: DTCM Write (0x2000_0100) ===");
        ahb_write(32'h2000_0100, 32'hDEADBEEF);
        $display("DTCM Write completed");
        
        #10;
        
        $display("=== Test 4: DTCM Read (0x2000_0100) ===");
        ahb_read(32'h2000_0100, read_data);
        $display("DTCM Read data: 0x%08h", read_data);
        if (read_data != 32'hDEADBEEF) begin
            $display("ERROR: Expected 0xDEADBEEF, got 0x%08h", read_data);
            errors = errors + 1;
        end
        
        #10;
        
        $display("=== Test 5: Byte Access Test ===");
        ahb_write(32'h0000_0010, 32'hFFFFFFFF);
        hsize = 3'b000;  // Byte
        ahb_write(32'h0000_0010, 32'h5A);
        hsize = 3'b010;  // Word
        ahb_read(32'h0000_0010, read_data);
        $display("Byte write result: 0x%08h", read_data);
        
        #10;
        
        $display("=== Test 6: Halfword Access Test ===");
        hsize = 3'b001;  // Halfword
        ahb_write(32'h0000_0020, 32'hABCD);
        ahb_read(32'h0000_0020, read_data);
        $display("Halfword result: 0x%08h", read_data);
        hsize = 3'b010;  // Restore word
        
        #10;
        
        $display("=== Test 7: Invalid Address Test ===");
        ahb_read(32'h4000_0000, read_data);
        $display("HRESP: %b (expected 1 for error)", hresp);
        
        #50;
        
        if (errors == 0)
            $display("\n✓ All tests passed!");
        else
            $display("\n✗ %d tests failed!", errors);
        
        #100;
        $finish;
    end
    
    //============================================================
    // 波形输出
    //============================================================
    
    initial begin
        $dumpfile("tb_sram_ctrl.vcd");
        $dumpvars(0, tb_sram_ctrl);
    end

endmodule
