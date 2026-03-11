// ============================================================================
// 模块名   : tb_flash_ctrl
// 功能描述 : Flash 控制器测试平台
// 作者     : Cortex-M3 SoC RTL Team
// 创建日期 : 2026-03-10
// 版本     : v1.0
// ============================================================================

`timescale 1ns/1ps

module tb_flash_ctrl;

    //============================================================
    // 参数定义
    //============================================================
    
    localparam  CLK_PERIOD = 5;  // 200MHz
    localparam  FLASH_WAIT_STATES = 3;
    
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
    
    // 外部 Flash 接口
    wire [19:0]  flash_addr_o;
    wire [31:0]  flash_data_io;
    wire         flash_ce_n;
    wire         flash_oe_n;
    wire         flash_we_n;
    wire         flash_burst_o;
    
    // Flash 内部信号
    reg  [31:0]  flash_data_reg;
    reg          flash_data_oe;
    
    //============================================================
    // 实例化被测模块
    //============================================================
    
    flash_ctrl #(
        .FLASH_ADDR_WIDTH    (20),
        .FLASH_DATA_WIDTH    (32),
        .FLASH_WAIT_STATES   (FLASH_WAIT_STATES),
        .PREFETCH_DEPTH      (4)
    ) u_flash_ctrl (
        .hclk         (hclk),
        .hreset_n     (hreset_n),
        
        .haddr        (haddr),
        .hburst       (hburst),
        .hprot        (hprot),
        .hsize        (hsize),
        .htrans       (htrans),
        .hwrite       (hwrite),
        .hwdata       (hwdata),
        .hrdata       (hrdata),
        .hready       (hready),
        .hresp        (hresp),
        .hsel         (hsel),
        
        .flash_addr_o (flash_addr_o),
        .flash_data_io(flash_data_io),
        .flash_ce_n   (flash_ce_n),
        .flash_oe_n   (flash_oe_n),
        .flash_we_n   (flash_we_n),
        .flash_burst_o(flash_burst_o)
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
    // Flash 模型 (简化)
    //============================================================
    
    reg [2:0] flash_state;
    localparam FLASH_IDLE = 3'b000, FLASH_SETUP = 3'b001, FLASH_WAIT = 3'b010, FLASH_READ = 3'b011;
    reg [2:0] flash_wait_cnt;
    
    assign flash_data_io = flash_data_oe ? flash_data_reg : 32'hZ;
    
    always @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n) begin
            flash_state     <= FLASH_IDLE;
            flash_wait_cnt  <= 3'h0;
            flash_data_oe   <= 1'b0;
        end else begin
            case (flash_state)
                FLASH_IDLE: begin
                    flash_data_oe <= 1'b0;
                    if (!flash_ce_n && !flash_oe_n) begin
                        flash_state    <= FLASH_SETUP;
                        flash_wait_cnt <= 3'h0;
                    end
                end
                FLASH_SETUP: begin
                    flash_data_oe <= 1'b1;
                    flash_state   <= FLASH_WAIT;
                end
                FLASH_WAIT: begin
                    if (flash_wait_cnt < FLASH_WAIT_STATES)
                        flash_wait_cnt <= flash_wait_cnt + 1;
                    else begin
                        flash_state <= FLASH_READ;
                        // 返回地址作为测试数据
                        flash_data_reg <= {flash_addr_o, 12'h0};
                    end
                end
                FLASH_READ: begin
                    flash_data_oe <= 1'b1;
                    if (flash_ce_n)
                        flash_state <= FLASH_IDLE;
                end
            endcase
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
        
        $display("=== Test 1: Flash Read (0x0000_0000) ===");
        ahb_read(32'h0000_0000, read_data);
        $display("Flash Read data: 0x%08h", read_data);
        
        #20;
        
        $display("=== Test 2: Flash Read (0x0000_0010) ===");
        ahb_read(32'h0000_0010, read_data);
        $display("Flash Read data: 0x%08h", read_data);
        
        #20;
        
        $display("=== Test 3: Flash Read with Wait States ===");
        $display("Waiting for %d wait states...", FLASH_WAIT_STATES);
        ahb_read(32'h0000_0100, read_data);
        $display("Flash Read data: 0x%08h", read_data);
        
        #20;
        
        $display("=== Test 4: Flash Burst Read ===");
        hburst = 3'b101;  // INCR4
        ahb_read(32'h0000_0200, read_data);
        hburst = 3'b000;
        $display("Burst Read data: 0x%08h", read_data);
        
        #20;
        
        $display("=== Test 5: Flash Write (should fail) ===");
        ahb_write(32'h0000_0000, 32'hDEADBEEF);
        $display("HRESP: %b (expected 1 for write error)", hresp);
        
        #20;
        
        $display("=== Test 6: Byte Access ===");
        hsize = 3'b000;  // Byte
        ahb_read(32'h0000_0001, read_data);
        $display("Byte read: 0x%08h", read_data);
        hsize = 3'b010;
        
        #20;
        
        $display("=== Test 7: Halfword Access ===");
        hsize = 3'b001;  // Halfword
        ahb_read(32'h0000_0002, read_data);
        $display("Halfword read: 0x%08h", read_data);
        hsize = 3'b010;
        
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
        $dumpfile("tb_flash_ctrl.vcd");
        $dumpvars(0, tb_flash_ctrl);
    end

endmodule
