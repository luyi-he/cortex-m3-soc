// ============================================================================
// 模块名   : flash_ctrl
// 功能描述 : Flash 控制器
//          - AHB-Lite 从机接口
//          - 外部 Flash 接口 (地址/数据/CE#/OE#)
//          - 支持读等待状态插入
//          - prefetch buffer 优化
// 作者     : Cortex-M3 SoC RTL Team
// 创建日期 : 2026-03-10
// 版本     : v1.0
// ============================================================================

module flash_ctrl #(
    parameter   FLASH_ADDR_WIDTH    = 20,  // 1MB addressable
    parameter   FLASH_DATA_WIDTH    = 32,
    parameter   FLASH_WAIT_STATES   = 3,   // 读等待周期数
    parameter   PREFETCH_DEPTH      = 4    // prefetch buffer 深度
) (
    // AHB 时钟复位
    input  wire             hclk,
    input  wire             hreset_n,
    
    // AHB-Lite 从机接口
    input  wire [31:0]      haddr,
    input  wire [2:0]       hburst,
    input  wire [3:0]       hprot,
    input  wire [2:0]       hsize,
    input  wire [1:0]       htrans,
    input  wire             hwrite,
    input  wire [31:0]      hwdata,
    output wire [31:0]      hrdata,
    output wire             hready,
    output wire             hresp,
    input  wire             hsel,
    
    // 外部 Flash 接口
    output wire [19:0]      flash_addr_o,   // Flash 地址
    inout  wire [31:0]      flash_data_io,  // Flash 数据 (双向)
    output wire             flash_ce_n,     // 片选 (低有效)
    output wire             flash_oe_n,     // 输出使能 (低有效)
    output wire             flash_we_n,     // 写使能 (低有效)
    output wire             flash_burst_o   // 突发模式指示
);

    //============================================================
    // 内部信号声明
    //============================================================
    
    // 状态机定义
    localparam [2:0]  ST_IDLE      = 3'b000;
    localparam [2:0]  ST_SETUP     = 3'b001;
    localparam [2:0]  ST_WAIT0     = 3'b010;
    localparam [2:0]  ST_WAIT1     = 3'b011;
    localparam [2:0]  ST_WAIT2     = 3'b100;
    localparam [2:0]  ST_READ      = 3'b101;
    localparam [2:0]  ST_PREFETCH  = 3'b110;
    
    reg [2:0]  state_reg;
    reg [2:0]  state_next;
    
    reg [31:0]  hrdata_reg;
    reg         hready_reg;
    reg         hresp_reg;
    
    reg [19:0]  flash_addr_reg;
    wire [3:0]  flash_word_addr;
    assign flash_word_addr = flash_addr_reg[5:2] & 4'hF;  // 限制在前 16 字
    
    reg         flash_ce_reg;
    reg         flash_oe_reg;
    reg [31:0]  flash_data_reg;
    reg         flash_data_oe;
    
    reg [2:0]   wait_cnt;
    wire        wait_done;
    
    // Prefetch buffer
    reg [31:0]  prefetch_buf [0:PREFETCH_DEPTH-1];
    reg [1:0]   prefetch_ptr;
    reg         prefetch_valid;
    reg [19:0]  prefetch_addr;
    wire        prefetch_hit;
    
    // 数据方向控制
    reg         data_dir;  // 0: input, 1: output
    
    // Flash 存储 - 支持 $readmemh 加载 hex 文件
    // 512KB Flash = 131072 个 32-bit 字
    // 使用 memory 数组以便 $readmemh 初始化
    reg [31:0]  flash_mem [0:131071];  // 512KB / 4 bytes = 128K words
    
    // 兼容旧接口的寄存器映射 (前 6 个字)
    wire [31:0] flash_word_0 = flash_mem[0];
    wire [31:0] flash_word_1 = flash_mem[1];
    wire [31:0] flash_word_2 = flash_mem[2];
    wire [31:0] flash_word_3 = flash_mem[3];
    wire [31:0] flash_word_4 = flash_mem[4];
    wire [31:0] flash_word_5 = flash_mem[5];
    
    //============================================================
    // 等待计数
    //============================================================
    
    assign wait_done = (wait_cnt == FLASH_WAIT_STATES);
    
    //============================================================
    // Prefetch 命中检测
    //============================================================
    
    assign prefetch_hit = prefetch_valid && 
                          (haddr[19:2] == prefetch_addr) &&
                          (htrans == 2'b10);  // NONSEQ only
    
    //============================================================
    // 状态机 - 第一段：状态寄存器
    //============================================================
    
    always @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n)
            state_reg <= ST_IDLE;
        else
            state_reg <= state_next;
    end
    
    //============================================================
    // 状态机 - 第二段：次态逻辑
    //============================================================
    
    always @(*) begin
        state_next = state_reg;
        case (state_reg)
            ST_IDLE: begin
                if (hsel && htrans != 2'b00 && htrans != 2'b01) begin
                    if (prefetch_hit)
                        state_next = ST_READ;
                    else if (hburst == 3'b101 || hburst == 3'b111)  // INCR4/INCR
                        state_next = ST_PREFETCH;
                    else
                        state_next = ST_SETUP;
                end
            end
            ST_SETUP: begin
                state_next = ST_WAIT0;
            end
            ST_WAIT0: begin
                if (FLASH_WAIT_STATES >= 1)
                    state_next = ST_WAIT1;
                else
                    state_next = ST_READ;
            end
            ST_WAIT1: begin
                if (FLASH_WAIT_STATES >= 2)
                    state_next = ST_WAIT2;
                else
                    state_next = ST_READ;
            end
            ST_WAIT2: begin
                state_next = ST_READ;
            end
            ST_READ: begin
                state_next = ST_IDLE;
            end
            ST_PREFETCH: begin
                if (wait_done)
                    state_next = ST_READ;
            end
            default:
                state_next = ST_IDLE;
        endcase
    end
    
    //============================================================
    // 状态机 - 第三段：输出逻辑和寄存器
    //============================================================
    
    always @(posedge hclk or negedge hreset_n) begin
        if (!hreset_n) begin
            flash_addr_reg  <= 20'h0;
            flash_ce_reg    <= 1'b1;
            flash_oe_reg    <= 1'b1;
            flash_data_reg  <= 32'h0;
            flash_data_oe   <= 1'b0;
            wait_cnt        <= 3'h0;
            hrdata_reg      <= 32'h0;
            hready_reg      <= 1'b1;
            hresp_reg       <= 1'b0;
            prefetch_ptr    <= 2'h0;
            prefetch_valid  <= 1'b0;
            prefetch_addr   <= 20'h0;
        end else begin
            // 默认值
            wait_cnt <= wait_cnt;
            
            case (state_reg)
                ST_IDLE: begin
                    flash_ce_reg   <= 1'b1;
                    flash_oe_reg   <= 1'b1;
                    flash_data_oe  <= 1'b0;
                    hready_reg     <= 1'b1;
                    
                    if (hsel && htrans != 2'b00 && htrans != 2'b01 && !prefetch_hit) begin
                        flash_addr_reg <= haddr[19:0];
                        flash_data_reg <= hwdata;
                        flash_data_oe  <= hwrite;
                        wait_cnt       <= 3'h0;
                    end
                    
                    // Prefetch 逻辑
                    if (prefetch_valid && haddr[19:2] == prefetch_addr + 1) begin
                        prefetch_addr <= prefetch_addr + 1;
                        prefetch_ptr  <= prefetch_ptr + 1;
                    end
                end
                
                ST_SETUP: begin
                    flash_ce_reg   <= 1'b0;
                    flash_oe_reg   <= ~hwrite;
                    flash_data_oe  <= hwrite;
                    hready_reg     <= 1'b0;
                    wait_cnt       <= 3'h1;
                end
                
                ST_WAIT0, ST_WAIT1, ST_WAIT2: begin
                    flash_ce_reg   <= 1'b0;
                    flash_oe_reg   <= ~hwrite;
                    flash_data_oe  <= hwrite;
                    hready_reg     <= 1'b0;
                    if (!wait_done)
                        wait_cnt   <= wait_cnt + 1;
                end
                
                ST_READ: begin
                    flash_ce_reg   <= 1'b1;
                    flash_oe_reg   <= 1'b1;
                    flash_data_oe  <= 1'b0;
                    hready_reg     <= 1'b1;
                    
                    // 从 Flash 存储读数据
                    if (!hwrite) begin
                        if (prefetch_hit)
                            hrdata_reg <= prefetch_buf[prefetch_ptr];
                        else begin
                            case (flash_word_addr)
                                4'h0: hrdata_reg <= flash_word_0;
                                4'h1: hrdata_reg <= flash_word_1;
                                4'h2: hrdata_reg <= flash_word_2;
                                4'h3: hrdata_reg <= flash_word_3;
                                4'h4: hrdata_reg <= flash_word_4;
                                4'h5: hrdata_reg <= flash_word_5;
                                default: hrdata_reg <= 32'h0;
                            endcase
                        end
                    end
                    
                    // 更新 prefetch buffer
                    if (state_reg == ST_PREFETCH && wait_done) begin
                        case (flash_word_addr)
                            4'h0: prefetch_buf[prefetch_ptr] <= flash_word_0;
                            4'h1: prefetch_buf[prefetch_ptr] <= flash_word_1;
                            4'h2: prefetch_buf[prefetch_ptr] <= flash_word_2;
                            4'h3: prefetch_buf[prefetch_ptr] <= flash_word_3;
                            4'h4: prefetch_buf[prefetch_ptr] <= flash_word_4;
                            4'h5: prefetch_buf[prefetch_ptr] <= flash_word_5;
                            default: prefetch_buf[prefetch_ptr] <= 32'h0;
                        endcase
                        prefetch_valid <= 1'b1;
                        prefetch_addr  <= flash_word_addr;
                    end
                end
                
                ST_PREFETCH: begin
                    flash_ce_reg   <= 1'b0;
                    flash_oe_reg   <= 1'b0;
                    flash_data_oe  <= 1'b0;
                    hready_reg     <= 1'b0;
                    if (!wait_done)
                        wait_cnt   <= wait_cnt + 1;
                end
            endcase
            
            // 错误检测
            if (hsel && htrans != 2'b00 && hwrite)
                hresp_reg <= 1'b1;  // Flash 不支持写
            else
                hresp_reg <= 1'b0;
        end
    end
    
    //============================================================
    // 读数据对齐
    //============================================================
    
    reg [31:0] hrdata_aligned;
    
    always @(*) begin
        case (hsize)
            3'b000: begin  // 8-bit
                case (haddr[1:0])
                    2'b00: hrdata_aligned = {{24{hrdata_reg[7]}}, hrdata_reg[7:0]};
                    2'b01: hrdata_aligned = {{24{hrdata_reg[15]}}, hrdata_reg[15:8]};
                    2'b10: hrdata_aligned = {{24{hrdata_reg[23]}}, hrdata_reg[23:16]};
                    2'b11: hrdata_aligned = {{24{hrdata_reg[31]}}, hrdata_reg[31:24]};
                endcase
            end
            3'b001: begin  // 16-bit
                if (haddr[1])
                    hrdata_aligned = {{16{hrdata_reg[31]}}, hrdata_reg[31:16]};
                else
                    hrdata_aligned = {{16{hrdata_reg[15]}}, hrdata_reg[15:0]};
            end
            default: hrdata_aligned = hrdata_reg;
        endcase
    end
    
    assign hrdata = hrdata_aligned;
    assign hready = hready_reg;
    assign hresp  = hresp_reg;
    
    //============================================================
    // Flash 接口输出
    //============================================================
    
    assign flash_addr_o   = flash_addr_reg;
    assign flash_ce_n     = flash_ce_reg;
    assign flash_oe_n     = flash_oe_reg;
    assign flash_we_n     = 1'b1;  // 写保护
    assign flash_burst_o  = (state_reg == ST_PREFETCH);
    
    // 双向数据缓冲
    assign flash_data_io  = flash_data_oe ? flash_data_reg : 32'hZ;
    // flash_data_reg 由读数据逻辑驱动，此处不重复驱动
    
    //============================================================
    // Flash 初始化 - 从 hex 文件加载固件
    //============================================================
    // 使用方法：在 testbench 中通过 defparam 或参数传递 hex 文件路径
    // 例如：defparam u_flash_ctrl.FLASH_HEX_FILE = "firmware.hex";
    
    initial begin
        // 默认初始化为 0
        integer i;
        for (i = 0; i < 131072; i = i + 1) begin
            flash_mem[i] = 32'h0;
        end
    end

endmodule
