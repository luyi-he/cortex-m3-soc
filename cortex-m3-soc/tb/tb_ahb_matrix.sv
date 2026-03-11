// ============================================================================
// 模块名   : tb_ahb_matrix
// 功能描述 : AHB Matrix 测试平台
// 作者     : Cortex-M3 SoC RTL Team
// 创建日期 : 2026-03-10
// 版本     : v1.0
// ============================================================================

`timescale 1ns/1ps

module tb_ahb_matrix;

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
    
    // AHB 主机接口 (CPU)
    reg  [31:0]  haddr_m;
    reg  [2:0]   hburst_m;
    reg  [3:0]   hprot_m;
    reg  [2:0]   hsize_m;
    reg  [1:0]   htrans_m;
    reg          hwrite_m;
    reg  [31:0]  hwdata_m;
    wire [31:0]  hrdata_m;
    wire         hready_m;
    wire         hresp_m;
    
    // AHB 从机接口 0 - Flash (模拟)
    wire [31:0]  haddr_s0;
    wire [2:0]   hburst_s0;
    wire [3:0]   hprot_s0;
    wire [2:0]   hsize_s0;
    wire [1:0]   htrans_s0;
    wire         hwrite_s0;
    wire [31:0]  hwdata_s0;
    reg  [31:0]  hrdata_s0;
    reg          hready_s0;
    reg          hresp_s0;
    wire         hsel_s0;
    
    // AHB 从机接口 1 - SRAM (模拟)
    wire [31:0]  haddr_s1;
    wire [2:0]   hburst_s1;
    wire [3:0]   hprot_s1;
    wire [2:0]   hsize_s1;
    wire [1:0]   htrans_s1;
    wire         hwrite_s1;
    wire [31:0]  hwdata_s1;
    reg  [31:0]  hrdata_s1;
    reg          hready_s1;
    reg          hresp_s1;
    wire         hsel_s1;
    
    // AHB 从机接口 2 - APB Bridge (模拟)
    wire [31:0]  haddr_s2;
    wire [2:0]   hburst_s2;
    wire [3:0]   hprot_s2;
    wire [2:0]   hsize_s2;
    wire [1:0]   htrans_s2;
    wire         hwrite_s2;
    wire [31:0]  hwdata_s2;
    reg  [31:0]  hrdata_s2;
    reg          hready_s2;
    reg          hresp_s2;
    wire         hsel_s2;
    
    //============================================================
    // 实例化被测模块
    //============================================================
    
    ahb_matrix #(
        .FLASH_BASE (32'h0000_0000),
        .FLASH_SIZE (32'h0008_0000),
        .SRAM_BASE  (32'h2000_0000),
        .SRAM_SIZE  (32'h0002_0000),
        .APB_BASE   (32'h4000_0000),
        .APB_SIZE   (32'h0010_0000)
    ) u_ahb_matrix (
        .hclk       (hclk),
        .hreset_n   (hreset_n),
        
        .haddr_m    (haddr_m),
        .hburst_m   (hburst_m),
        .hprot_m    (hprot_m),
        .hsize_m    (hsize_m),
        .htrans_m   (htrans_m),
        .hwrite_m   (hwrite_m),
        .hwdata_m   (hwdata_m),
        .hrdata_m   (hrdata_m),
        .hready_m   (hready_m),
        .hresp_m    (hresp_m),
        
        .haddr_s0   (haddr_s0),
        .hburst_s0  (hburst_s0),
        .hprot_s0   (hprot_s0),
        .hsize_s0   (hsize_s0),
        .htrans_s0  (htrans_s0),
        .hwrite_s0  (hwrite_s0),
        .hwdata_s0  (hwdata_s0),
        .hrdata_s0  (hrdata_s0),
        .hready_s0  (hready_s0),
        .hresp_s0   (hresp_s0),
        .hsel_s0    (hsel_s0),
        
        .haddr_s1   (haddr_s1),
        .hburst_s1  (hburst_s1),
        .hprot_s1   (hprot_s1),
        .hsize_s1   (hsize_s1),
        .htrans_s1  (htrans_s1),
        .hwrite_s1  (hwrite_s1),
        .hwdata_s1  (hwdata_s1),
        .hrdata_s1  (hrdata_s1),
        .hready_s1  (hready_s1),
        .hresp_s1   (hresp_s1),
        .hsel_s1    (hsel_s1),
        
        .haddr_s2   (haddr_s2),
        .hburst_s2  (hburst_s2),
        .hprot_s2   (hprot_s2),
        .hsize_s2   (hsize_s2),
        .htrans_s2  (htrans_s2),
        .hwrite_s2  (hwrite_s2),
        .hwdata_s2  (hwdata_s2),
        .hrdata_s2  (hrdata_s2),
        .hready_s2  (hready_s2),
        .hresp_s2   (hresp_s2),
        .hsel_s2    (hsel_s2)
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
    // 从机模型 (简单响应)
    //============================================================
    
    always @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n) begin
            hready_s0 <= 1'b1;
            hready_s1 <= 1'b1;
            hready_s2 <= 1'b1;
            hresp_s0  <= 1'b0;
            hresp_s1  <= 1'b0;
            hresp_s2  <= 1'b0;
        end else begin
            // Flash 从机
            if (hsel_s0 && htrans_s0 != 2'b00) begin
                hready_s0 <= 1'b1;
                hresp_s0  <= 1'b0;
                if (!hwrite_s0)
                    hrdata_s0 <= haddr_s0;  // 返回地址作为测试数据
            end else begin
                hready_s0 <= 1'b1;
            end
            
            // SRAM 从机
            if (hsel_s1 && htrans_s1 != 2'b00) begin
                hready_s1 <= 1'b1;
                hresp_s1  <= 1'b0;
                if (!hwrite_s1)
                    hrdata_s1 <= haddr_s1;
            end else begin
                hready_s1 <= 1'b1;
            end
            
            // APB Bridge 从机
            if (hsel_s2 && htrans_s2 != 2'b00) begin
                hready_s2 <= 1'b1;
                hresp_s2  <= 1'b0;
                if (!hwrite_s2)
                    hrdata_s2 <= haddr_s2;
            end else begin
                hready_s2 <= 1'b1;
            end
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
            haddr_m   <= addr;
            hwdata_m  <= data;
            hwrite_m  <= 1'b1;
            htrans_m  <= 2'b10;  // NONSEQ
            hsize_m   <= 3'b010; // WORD
            hburst_m  <= 3'b000; // SINGLE
            hprot_m   <= 4'b1111;
            
            wait (hready_m);
            @(posedge hclk);
            htrans_m  <= 2'b00;  // IDLE
        end
    endtask
    
    task ahb_read;
        input [31:0] addr;
        output [31:0] data;
        begin
            @(posedge hclk);
            haddr_m   <= addr;
            hwrite_m  <= 1'b0;
            htrans_m  <= 2'b10;  // NONSEQ
            hsize_m   <= 3'b010; // WORD
            hburst_m  <= 3'b000; // SINGLE
            hprot_m   <= 4'b1111;
            
            wait (hready_m);
            data = hrdata_m;
            @(posedge hclk);
            htrans_m  <= 2'b00;  // IDLE
        end
    endtask
    
    //============================================================
    // 测试用例
    //============================================================
    
    reg [31:0] read_data;
    integer    errors;
    
    initial begin
        errors = 0;
        
        // 初始化主机信号
        haddr_m   = 32'h0;
        hwdata_m  = 32'h0;
        hwrite_m  = 0;
        htrans_m  = 2'b00;
        hsize_m   = 3'b010;
        hburst_m  = 3'b000;
        hprot_m   = 4'b1111;
        
        #50;
        
        $display("=== Test 1: Flash Read (0x0000_0000) ===");
        ahb_read(32'h0000_0000, read_data);
        $display("Read data: 0x%08h", read_data);
        if (read_data != 32'h0) begin
            $display("ERROR: Expected 0x00000000, got 0x%08h", read_data);
            errors = errors + 1;
        end
        
        #20;
        
        $display("=== Test 2: Flash Read (0x0000_0010) ===");
        ahb_read(32'h0000_0010, read_data);
        $display("Read data: 0x%08h", read_data);
        if (read_data != 32'h10) begin
            $display("ERROR: Expected 0x00000010, got 0x%08h", read_data);
            errors = errors + 1;
        end
        
        #20;
        
        $display("=== Test 3: SRAM Read (0x2000_0000) ===");
        ahb_read(32'h2000_0000, read_data);
        $display("Read data: 0x%08h", read_data);
        if (read_data != 32'h0) begin
            $display("ERROR: Expected 0x00000000, got 0x%08h", read_data);
            errors = errors + 1;
        end
        
        #20;
        
        $display("=== Test 4: SRAM Write/Read (0x2000_0100) ===");
        ahb_write(32'h2000_0100, 32'hDEADBEEF);
        ahb_read(32'h2000_0100, read_data);
        $display("Read data: 0x%08h", read_data);
        
        #20;
        
        $display("=== Test 5: APB Bridge Read (0x4000_0000) ===");
        ahb_read(32'h4000_0000, read_data);
        $display("Read data: 0x%08h", read_data);
        
        #20;
        
        $display("=== Test 6: Invalid Address (0x8000_0000) ===");
        ahb_read(32'h8000_0000, read_data);
        $display("HRESP: %b (expected 1 for error)", hresp_m);
        
        #20;
        
        $display("=== Test 7: HREADY Stretch Test ===");
        // 模拟从机延迟
        hready_s0 = 0;
        ahb_read(32'h0000_0020, read_data);
        hready_s0 = 1;
        $display("Read completed after HREADY stretch");
        
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
        $dumpfile("tb_ahb_matrix.vcd");
        $dumpvars(0, tb_ahb_matrix);
    end

endmodule
