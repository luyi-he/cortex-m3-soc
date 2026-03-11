// ============================================================================
// 文件     : flash_model.sv
// 描述     : Flash 行为模型 (512KB，支持读延迟)
// ============================================================================

`ifndef FLASH_MODEL_SV
`define FLASH_MODEL_SV

module flash_model #(
    parameter SIZE_BYTES = 524288,  // 512KB
    parameter ADDR_WIDTH = 19,
    parameter DATA_WIDTH = 32,
    parameter READ_LATENCY = 3  // 读等待周期
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
    
    // 状态机
    localparam [1:0] ST_IDLE   = 2'b00;
    localparam [1:0] ST_READ   = 2'b01;
    localparam [1:0] ST_WAIT   = 2'b10;
    
    reg [1:0] state_reg;
    reg [1:0] state_next;
    
    // 计数器
    reg [3:0] latency_cnt;
    
    // 寄存器
    reg [ADDR_WIDTH-1:0] addr_reg;
    reg [31:0] rdata_reg;
    
    // 初始化文件
    initial begin
        $readmemh("flash_init.hex", mem);
    end
    
    // 状态机 - 时序逻辑
    always @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n) begin
            state_reg   <= ST_IDLE;
            latency_cnt <= '0;
            addr_reg    <= '0;
        end else begin
            state_reg   <= state_next;
            if (state_reg == ST_READ || state_reg == ST_WAIT) begin
                latency_cnt <= latency_cnt + 1'b1;
            end else begin
                latency_cnt <= '0;
            end
            if (hsel && hready_in && hready_out && !hwrite) begin
                addr_reg <= haddr[ADDR_WIDTH-1:0];
            end
        end
    end
    
    // 状态机 - 组合逻辑
    always @(*) begin
        state_next = state_reg;
        case (state_reg)
            ST_IDLE: begin
                if (hsel && hready_in && !hwrite) begin
                    state_next = ST_READ;
                end
            end
            ST_READ: begin
                if (latency_cnt >= READ_LATENCY - 1) begin
                    state_next = ST_IDLE;
                end else begin
                    state_next = ST_WAIT;
                end
            end
            ST_WAIT: begin
                if (latency_cnt >= READ_LATENCY - 1) begin
                    state_next = ST_IDLE;
                end else begin
                    state_next = ST_WAIT;
                end
            end
        endcase
    end
    
    // 读数据锁存
    always @(posedge hclk) begin
        if (hsel && hready_in && !hwrite) begin
            case (hsize)
                3'b000: begin
                    rdata_reg <= {24'h0, mem[haddr[ADDR_WIDTH-1:0]]};
                end
                3'b001: begin
                    rdata_reg <= {16'h0, mem[haddr[ADDR_WIDTH-1:0]+1], mem[haddr[ADDR_WIDTH-1:0]]};
                end
                default: begin
                    rdata_reg <= {mem[haddr[ADDR_WIDTH-1:0]+3], mem[haddr[ADDR_WIDTH-1:0]+2], 
                                  mem[haddr[ADDR_WIDTH-1:0]+1], mem[haddr[ADDR_WIDTH-1:0]]};
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
        end else begin
            case (state_reg)
                ST_IDLE: begin
                    hready_out <= 1'b1;
                    hresp      <= 1'b0;
                end
                ST_READ, ST_WAIT: begin
                    hready_out <= 1'b0;  // 拉伸 HREADY
                    hresp      <= 1'b0;
                    if (state_next == ST_IDLE) begin
                        hrdata <= rdata_reg;
                    end
                end
            endcase
        end
    end
    
    // 写保护 (Flash 只能通过特殊控制器写入)
    always @(posedge hclk) begin
        if (hsel && hready_in && hwrite) begin
            hresp <= 1'b1;  // 错误响应
        end
    end
    
endmodule

`endif
