// ============================================================================
// 模块名   : tb_ahb2apb_bridge
// 功能描述 : AHB2APB Bridge 测试平台
// 作者     : Cortex-M3 SoC RTL Team
// 创建日期 : 2026-03-10
// 版本     : v1.0
// ============================================================================

`timescale 1ns/1ps

module tb_ahb2apb_bridge;

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
    
    // APB 主机接口
    wire [31:0]  paddr;
    wire         psel;
    wire         penable;
    wire         pwrite;
    wire [31:0]  pwdata;
    reg  [31:0]  prdata;
    reg          pready;
    reg          pslverr;
    
    //============================================================
    // 实例化被测模块
    //============================================================
    
    ahb2apb_bridge #(
        .APB_BASE_ADDR    (32'h0000_0000),
        .APB_REGION_SIZE  (32'h0010_0000)
    ) u_ahb2apb_bridge (
        .hclk       (hclk),
        .hreset_n   (hreset_n),
        
        .haddr      (haddr),
        .hburst     (hburst),
        .hprot      (hprot),
        .hsize      (hsize),
        .htrans     (htrans),
        .hwrite     (hwrite),
        .hwdata     (hwdata),
        .hrdata     (hrdata),
        .hready     (hready),
        .hresp      (hresp),
        .hsel       (hsel),
        
        .paddr      (paddr),
        .psel       (psel),
        .penable    (penable),
        .pwrite     (pwrite),
        .pwdata     (pwdata),
        .prdata     (prdata),
        .pready     (pready),
        .pslverr    (pslverr)
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
    // APB 从机模型
    //============================================================
    
    reg [1:0] apb_state;
    localparam APB_IDLE = 2'b00, APB_SETUP = 2'b01, APB_ACCESS = 2'b10;
    
    always @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n) begin
            apb_state <= APB_IDLE;
            pready    <= 1'b0;
            pslverr   <= 1'b0;
        end else begin
            case (apb_state)
                APB_IDLE: begin
                    pready <= 1'b0;
                    if (psel && !penable)
                        apb_state <= APB_SETUP;
                end
                APB_SETUP: begin
                    if (penable) begin
                        apb_state <= APB_ACCESS;
                        pready    <= 1'b0;  // 可以延迟
                    end
                end
                APB_ACCESS: begin
                    pready  <= 1'b1;
                    pslverr <= 1'b0;
                    if (!psel)
                        apb_state <= APB_IDLE;
                end
            endcase
        end
    end
    
    always @(posedge hclk) begin
        if (penable && pready && !pwrite)
            prdata <= paddr;  // 返回地址作为测试数据
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
        
        $display("=== Test 1: APB Write (0x0000) ===");
        ahb_write(32'h0000_0000, 32'hDEADBEEF);
        $display("Write completed");
        
        #20;
        
        $display("=== Test 2: APB Read (0x0000) ===");
        ahb_read(32'h0000_0000, read_data);
        $display("Read data: 0x%08h", read_data);
        
        #20;
        
        $display("=== Test 3: APB Read (0x1000) ===");
        ahb_read(32'h0000_1000, read_data);
        $display("Read data: 0x%08h", read_data);
        if (read_data != 32'h1000) begin
            $display("ERROR: Expected 0x00001000, got 0x%08h", read_data);
            errors = errors + 1;
        end
        
        #20;
        
        $display("=== Test 4: PREADY Delay Test ===");
        // 模拟 PREADY 延迟
        pready = 0;
        ahb_read(32'h0000_2000, read_data);
        pready = 1;
        $display("Read completed after PREADY delay");
        
        #20;
        
        $display("=== Test 5: PSLVERR Test ===");
        pslverr = 1'b1;
        ahb_read(32'h0000_3000, read_data);
        pslverr = 1'b0;
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
        $dumpfile("tb_ahb2apb_bridge.vcd");
        $dumpvars(0, tb_ahb2apb_bridge);
    end

endmodule
