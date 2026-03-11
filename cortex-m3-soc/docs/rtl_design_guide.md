# RTL 设计指南

**版本**: v1.0  
**适用**: Cortex-M3 SoC 项目全体 RTL 工程师

---

## 1. 编码规范

### 1.1 文件命名

```
模块名.v         - 模块实现
tb_模块名.sv     - 测试平台
inc_模块名.vh    - 头文件/参数定义
```

### 1.2 模块命名

- 小写字母 + 下划线
- 有意义的名称，避免缩写
- 示例：`ahb_matrix`, `gpio_ctrl`, `uart_top`

### 1.3 信号命名

| 类型 | 前缀 | 示例 |
|------|------|------|
| 时钟 | `clk_` | `clk_hclk`, `clk_pclk` |
| 复位 (低有效) | `rst_n` | `rst_n`, `hreset_n` |
| 使能 (低有效) | `_n` | `cs_n`, `oe_n` |
| 地址 | `addr_` | `haddr`, `paddr` |
| 数据 | `data_` | `hwdata`, `hrdata` |
| 控制 | 功能名 | `hready`, `hresp` |
| 状态 | `flag_` | `flag_tx_empty`, `flag_rx_full` |
| 计数 | `cnt_` | `cnt_baud`, `cnt_timeout` |

### 1.4 参数命名

- 全大写 + 下划线
- 示例：`ADDR_WIDTH`, `DATA_WIDTH`, `FIFO_DEPTH`

---

## 2. 代码模板

### 2.1 模块模板

```verilog
// ============================================================================
// 模块名   : <module_name>
// 功能描述 : <简短描述>
// 作者     : <作者>
// 创建日期 : <日期>
// 版本     : <版本>
// ============================================================================

module <module_name> #(
    parameter   PARAM1      = 32,
    parameter   PARAM2      = 8
) (
    // 时钟复位
    input  wire             clk,
    input  wire             rst_n,
    
    // 接口信号
    input  wire [31:0]      addr_i,
    output wire [31:0]      data_o,
    input  wire             valid_i,
    output wire             ready_o
);

    //============================================================
    // 内部信号声明
    //============================================================
    
    wire    [31:0]  data_reg;
    reg     [31:0]  data_next;
    
    //============================================================
    // 组合逻辑
    //============================================================
    
    always @(*) begin
        data_next = data_reg;
        if (valid_i) begin
            data_next = addr_i;
        end
    end
    
    //============================================================
    // 时序逻辑
    //============================================================
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 32'h0;
        end else begin
            data_reg <= data_next;
        end
    end
    
    //============================================================
    // 输出赋值
    //============================================================
    
    assign data_o = data_reg;
    assign ready_o = 1'b1;

endmodule
```

### 2.2 三段式状态机模板

```verilog
// 状态定义
localparam [1:0]  ST_IDLE   = 2'b00;
localparam [1:0]  ST_WORK   = 2'b01;
localparam [1:0]  ST_DONE   = 2'b10;

reg [1:0]  state_reg;
reg [1:0]  state_next;

// 第一段：状态寄存器
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        state_reg <= ST_IDLE;
    else
        state_reg <= state_next;
end

// 第二段：次态逻辑
always @(*) begin
    state_next = state_reg;
    case (state_reg)
        ST_IDLE: begin
            if (start_i)
                state_next = ST_WORK;
        end
        ST_WORK: begin
            if (done_flag)
                state_next = ST_DONE;
        end
        ST_DONE: begin
            if (!start_i)
                state_next = ST_IDLE;
        end
        default:
            state_next = ST_IDLE;
    endcase
end

// 第三段：输出逻辑
always @(*) begin
    done_o = 1'b0;
    case (state_next)
        ST_DONE: done_o = 1'b1;
        default: done_o = 1'b0;
    endcase
end
```

---

## 3. 时钟域交叉 (CDC) 规范

### 3.1 单比特信号 - 2 级同步器

```verilog
// 慢时钟域到快时钟域
reg [1:0]  sync_reg;

always @(posedge fast_clk or negedge rst_n) begin
    if (!rst_n)
        sync_reg <= 2'b00;
    else
        sync_reg <= {sync_reg[0], slow_signal};
end

assign synchronized_signal = sync_reg[1];
```

### 3.2 多比特信号 - FIFO

```verilog
// 使用异步 FIFO
async_fifo #(
    .DATA_WIDTH (32),
    .DATA_DEPTH (16)
) u_async_fifo (
    .wr_clk      (src_clk),
    .wr_rst_n    (src_rst_n),
    .wr_data     (src_data),
    .wr_en       (src_en),
    .wr_full     (src_full),
    
    .rd_clk      (dst_clk),
    .rd_rst_n    (dst_rst_n),
    .rd_data     (dst_data),
    .rd_en       (dst_en),
    .rd_empty    (dst_empty)
);
```

### 3.3 握手信号 - 2 相位握手

```verilog
// 发送端
reg  req_reg;
wire ack_sync;

always @(posedge src_clk or negedge rst_n) begin
    if (!rst_n)
        req_reg <= 1'b0;
    else if (send_data && !ack_sync)
        req_reg <= ~req_reg;
end

// 接收端
reg [1:0]  req_sync;
reg        ack_reg;

always @(posedge dst_clk or negedge rst_n) begin
    if (!rst_n)
        req_sync <= 2'b00;
    else
        req_sync <= {req_sync[0], req_reg};
end

always @(posedge dst_clk or negedge rst_n) begin
    if (!rst_n)
        ack_reg <= 1'b0;
    else if (req_sync[1] != ack_reg)
        ack_reg <= ~ack_reg;
end
```

---

## 4. 可综合代码指南

### 4.1 允许的结构

✅ 总是块 (`always @(posedge clk)`)
✅ 组合逻辑 (`always @(*)`)
✅ 连续赋值 (`assign`)
✅ for 循环 (固定次数，综合时可展开)
✅ 条件语句 (`if-else`, `case`)

### 4.2 禁止的结构

❌ 初始块 (`initial`)
❌ 延时控制 (`#10`)
❌ 事件控制 (`@(posedge sig)`)
❌ 实数类型 (`real`)
❌ 动态数组
❌ while 循环 (除非可转换为 for)

### 4.3 锁存器预防

```verilog
// 错误：组合逻辑中未覆盖所有分支
always @(*) begin
    if (enable)
        out = in;
    // 缺少 else，会推断锁存器
end

// 正确：覆盖所有分支
always @(*) begin
    out = default_value;  // 默认值
    if (enable)
        out = in;
end
```

---

## 5. 时序约束注释

### 5.1 关键路径标记

```verilog
// @TIMING_CRITICAL: 此路径为关键路径，时序约束 5ns
assign critical_output = critical_logic;
```

### 5.2 虚假路径标记

```verilog
// @FALSE_PATH: 配置寄存器到数据路径，可忽略时序
always @(posedge clk) begin
    if (config_mode)
        config_reg <= config_data;
end
```

### 5.3 多周期路径标记

```verilog
// @MULTICYCLE: 此路径为 2 周期路径
always @(posedge clk) begin
    slow_result <= slow_calculation;
end
```

---

## 6. 模块接口标准

### 6.1 AHB-Lite 从机接口

```verilog
module ahb_slave (
    // AHB 时钟复位
    input  wire        hclk,
    input  wire        hreset_n,
    
    // AHB 地址控制
    input  wire [31:0] haddr,
    input  wire [2:0]  hburst,
    input  wire        hmasterlock,
    input  wire [3:0]  hprot,
    input  wire [2:0]  hsize,
    input  wire [1:0]  htrans,
    input  wire        hwrite,
    
    // AHB 数据
    input  wire [31:0] hwdata,
    output wire [31:0] hrdata,
    
    // AHB 响应
    output wire        hready,
    output wire        hresp,
    
    // 片选 (来自矩阵)
    input  wire        hsel
);
```

### 6.2 APB 从机接口

```verilog
module apb_slave (
    // APB 时钟复位
    input  wire        pclk,
    input  wire        preset_n,
    
    // APB 控制
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [31:0] paddr,
    input  wire [31:0] pwdata,
    
    // APB 响应
    output wire        pready,
    output wire [31:0] prdata,
    output wire        pslverr
);
```

---

## 7. 综合指南

### 7.1 面积优化

```tcl
# 综合脚本示例
set_max_area 0
compile_ultra -gate_clock -retime
```

### 7.2 时序优化

```tcl
# 时序驱动综合
set_max_delay 5.0 -from [get_ports clk_*] -to [get_outputs]
compile_ultra -timing_high_effort_script
```

### 7.3 功耗优化

```tcl
# 时钟门控插入
set_clock_gating_style -sequential_cell latch -positive_edge_logic {and}
compile_ultra -gate_clock
```

---

## 8. 检查清单

### 8.1 代码提交前检查

- [ ] 语法检查通过
- [ ] Lint 检查 0 错误
- [ ] 功能仿真通过
- [ ] 代码审查完成
- [ ] 文档更新完成

### 8.2 综合前检查

- [ ] 所有模块连接完整
- [ ] 顶层端口定义正确
- [ ] 参数配置正确
- [ ] 无未驱动信号
- [ ] 无悬空输出

### 8.3 CDC 检查

- [ ] 所有跨时钟域信号已识别
- [ ] 同步器/FIFO 已正确实例化
- [ ] CDC 工具检查通过
- [ ] 假路径已标记

---

## 9. 版本控制

### 9.1 Git 提交规范

```
<type>(<scope>): <subject>

type: feat, fix, docs, style, refactor, test, chore
scope: 模块名
subject: 简短描述

示例:
feat(gpio): 添加 GPIO 中断功能
fix(uart): 修复波特率计算错误
```

### 9.2 分支策略

```
main        - 稳定版本，可综合
dev         - 开发分支
feature/xxx - 功能分支
```

---

**最后更新**: 2026-03-10  
**维护**: RTL 团队
