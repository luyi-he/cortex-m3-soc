// ============================================================================
// 文件     : sram_model.sv
// 描述     : SRAM 行为模型 (128KB)
// ============================================================================

`ifndef SRAM_MODEL_SV
`define SRAM_MODEL_SV

module sram_model #(
    parameter SIZE_BYTES = 131072,  // 128KB
    parameter ADDR_WIDTH = 17,
    parameter DATA_WIDTH = 32
) (
    input  wire                 hclk,
    input  wire                 hreset_n,
    input  wire                 hsel,
    input  wire                 hready_in,
    input  wire [31:0]          haddr,
    input  wire [2:0]           hsize,
    input  wire                 hwrite,
    input  wire [31:0]          hwdata,
    output reg [31:0]           hrdata,
    output reg                  hready_out,
    output reg                  hresp
);
    
    // 存储阵列
    reg [7:0] mem [0:SIZE_BYTES-1];
    
    // 内部信号
    reg [ADDR_WIDTH-1:0] addr_reg;
    reg write_reg;
    reg [31:0] wdata_reg;
    reg [31:0] rdata_next;
    
    // 初始化文件
    initial begin
        $readmemh("sram_init.hex", mem);
    end
    
    // 地址锁存
    always @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n) begin
            addr_reg  <= '0;
            write_reg <= 1'b0;
            wdata_reg <= '0;
        end else if (hsel && hready_in && hready_out) begin
            addr_reg  <= haddr[ADDR_WIDTH-1:0];
            write_reg <= hwrite;
            wdata_reg <= hwdata;
        end
    end
    
    // 读操作 - 单周期
    always @(*) begin
        if (write_reg) begin
            rdata_next = 32'h0;
        end else begin
            rdata_next = {mem[addr_reg+3], mem[addr_reg+2], mem[addr_reg+1], mem[addr_reg]};
        end
    end
    
    // 写操作
    always @(posedge hclk) begin
        if (hsel && hready_in && hready_out && write_reg) begin
            case (hsize)
                3'b000: begin  // Byte
                    mem[addr_reg] <= hwdata[7:0];
                end
                3'b001: begin  // Halfword
                    mem[addr_reg+1] <= hwdata[15:8];
                    mem[addr_reg]   <= hwdata[7:0];
                end
                3'b010, 3'b011: begin  // Word
                    mem[addr_reg+3] <= hwdata[31:24];
                    mem[addr_reg+2] <= hwdata[23:16];
                    mem[addr_reg+1] <= hwdata[15:8];
                    mem[addr_reg]   <= hwdata[7:0];
                end
            endcase
        end
    end
    
    // 输出逻辑
    always @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n) begin
            hrdata     <= '0;
            hready_out <= 1'b1;
            hresp      <= 1'b0;
        end else if (hsel && hready_in) begin
            hready_out <= 1'b1;  // SRAM 无等待
            hresp      <= 1'b0;  // 无错误
            if (!write_reg) begin
                hrdata <= rdata_next;
            end
        end
    end
    
    // 覆盖率
    `ifdef COVERAGE
    covergroup sram_cg;
        cp_hsize: coverpoint hsize;
        cp_hwrite: coverpoint hwrite;
        cp_addr_range: coverpoint addr_reg[16:14];
    endgroup
    sram_cg cov = new();
    
    always @(posedge hclk) begin
        if (hsel && hready_in && hready_out) begin
            cov.sample();
        end
    end
    `endif
    
endmodule

`endif
