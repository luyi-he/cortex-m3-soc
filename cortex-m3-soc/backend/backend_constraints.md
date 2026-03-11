# 后端设计约束

**版本**: v1.0  
**创建**: 2026-03-10  
**适用**: Cortex-M3 SoC 项目

---

## 1. 时钟约束 (clock_constraints.sdc)

```tcl
# ============================================================================
# 时钟定义
# ============================================================================

# 主时钟 HCLK 200MHz (周期 5ns)
create_clock -period 5.0 -name HCLK [get_ports clk]
create_clock -period 5.0 -name PCLK [get_clocks clk]

# 生成时钟关系
# PCLK = HCLK / 2
set_clock_groups -physically_exclusive -group [get_clocks HCLK] -group [get_clocks PCLK]

# ============================================================================
# 输入延迟
# ============================================================================

# GPIO 输入延迟 (假设外部器件 3ns)
set_input_delay -clock HCLK -max 3.0 [get_ports gpio_i[*]]
set_input_delay -clock HCLK -min 0.5 [get_ports gpio_i[*]]

# UART 输入延迟 (波特率相关)
set_input_delay -clock PCLK -max 5.0 [get_ports uart*_rx]
set_input_delay -clock PCLK -min 1.0 [get_ports uart*_rx]

# JTAG 输入延迟
set_input_delay -clock HCLK -max 5.0 [get_ports tck]
set_input_delay -clock HCLK -max 5.0 [get_ports tms]
set_input_delay -clock HCLK -max 5.0 [get_ports tdi]
set_input_delay -clock HCLK -max 5.0 [get_ports ntrst]

# ============================================================================
# 输出延迟
# ============================================================================

# GPIO 输出延迟
set_output_delay -clock HCLK -max 3.0 [get_ports gpio_o[*]]
set_output_delay -clock HCLK -min 0.5 [get_ports gpio_o[*]]

# UART 输出延迟
set_output_delay -clock PCLK -max 5.0 [get_ports uart*_tx]

# Flash 接口输出延迟
set_output_delay -clock HCLK -max 2.0 [get_ports flash_*]

# ============================================================================
# 时序例外
# ============================================================================

# 配置寄存器路径 - 虚假路径
set_false_path -from [get_pins */config_reg*/D] -to [get_pins */data_path*/D]

# 中断异步路径 - 虚假路径
set_false_path -from [get_pins */irq_sync*/D] -to [get_pins */cpu/irq*]

# 调试路径 - 多周期路径 (2 周期)
set_multicycle_path -setup 2 -from [get_pins */jtag*/TDO] -to [get_pins */jtag*/TDI]
set_multicycle_path -hold 1 -from [get_pins */jtag*/TDO] -to [get_pins */jtag*/TDI]

# ============================================================================
# 驱动强度和负载
# ============================================================================

# 输入端口驱动
set_driving_cell -lib_cell IO_PAD_IN [get_ports gpio_i[*]]
set_driving_cell -lib_cell IO_PAD_IN [get_ports uart*_rx]

# 输出端口负载
set_load -pin_load 0.5 [get_ports gpio_o[*]]
set_load -pin_load 0.3 [get_ports uart*_tx]
set_load -pin_load 0.5 [get_ports flash_*]

# ============================================================================
# 时序预算
# ============================================================================

# 建立时间余量
set_timing_budget -setup 0.5

# 保持时间余量
set_timing_budget -hold 0.2
```

---

## 2. 物理设计指南

### 2.1 Floorplan 建议

```
芯片尺寸：1.5mm x 1.5mm (28nm)

+--------------------------------------------------+
|  PAD: GPIO[63:32]                                |
|  +--------------------------------------------+  |
|  |  SRAM_DTCM (64KB)                          |  |
|  |  +----------------------------------------+|  |
|  |  |  CPU Core                              ||  |
|  |  |  +------------------------------------+||  |
|  |  |  |  NVIC                              |||  |
|  |  |  +------------------------------------+||  |
|  |  +----------------------------------------+|  |
|  |  SRAM_ITCM (64KB)                          |  |
|  +--------------------------------------------+  |
|  +--------------------------------------------+  |
|  |  AHB Matrix  |  Flash Ctrl  |  APB Bridge |  |
|  +--------------------------------------------+  |
|  +--------------------------------------------+  |
|  |  GPIO_CTRL  |  UART  |  Timer  |  Others  |  |
|  +--------------------------------------------+  |
|                                                  |
|  PAD: GPIO[31:0], UART, JTAG, Flash              |
+--------------------------------------------------+
```

### 2.2 模块摆放优先级

| 优先级 | 模块 | 位置建议 | 原因 |
|--------|------|----------|------|
| P0 | CPU | 中心偏上 | 连接最多模块 |
| P0 | SRAM | 靠近 CPU | 时序关键 |
| P1 | NVIC | 紧邻 CPU | 中断低延迟 |
| P1 | AHB Matrix | CPU 下方 | 总线枢纽 |
| P2 | Flash Ctrl | 靠近 Flash PAD | 减少走线 |
| P2 | GPIO_CTRL | 靠近 GPIO PAD | 减少走线 |
| P3 | APB 外设 | 下方区域 | 时序宽松 |

### 2.3 电源网络规划

```
VDD1.0 (核心电源)
├── CPU 域
├── SRAM 域
├── AHB 域
└── APB 域

VDD1.8 (IO 电源)
├── GPIO PAD
├── UART PAD
├── JTAG PAD
└── Flash PAD

VSS (地)
└── 全局地平面
```

**电源网络规格**:
- 核心电源网格：8 层金属，M7-M8
- IO 电源网格：6 层金属，M5-M6
- 去耦电容：每 100μm 一个 decap 单元
- IR drop 目标：< 5% @ 满载

---

## 3. 密度控制

### 3.1 模块密度目标

| 模块 | 目标密度 | 最大密度 | 预警阈值 |
|------|----------|----------|----------|
| CPU | 60% | 70% | 65% |
| SRAM 控制器 | 70% | 80% | 75% |
| AHB Matrix | 50% | 60% | 55% |
| APB 外设 | 40% | 50% | 45% |
| GPIO | 30% | 40% | 35% |
| **整体** | **55%** | **65%** | **60%** |

### 3.2 拥堵缓解策略

**如果密度超标**:

1. **早期预防**
   - 模块间预留 20% 走线通道
   - 高密度模块分散摆放

2. **中期优化**
   - 调整标准单元行高
   - 插入缓冲区

3. **后期修复**
   - 单元分散 (spread)
   - 逻辑重组

---

## 4. 时钟树规划

### 4.1 时钟树架构

```
                    PLL Output (200MHz)
                           |
                    +------v------+
                    |  Clock Buf  |
                    +------+------+
                           |
         +-----------------+-----------------+
         |                                   |
+--------v--------+                 +--------v--------+
|  CPU Clock Tree |                 |  System CTS     |
|  (专用网络)     |                 |  (AHB+APB)      |
+-----------------+                 +-----------------+
                                             |
                              +--------------+--------------+
                              |                             |
                    +---------v---------+         +---------v---------+
                    |  AHB CTS          |         |  APB CTS          |
                    |  (skew < 50ps)    |         |  (skew < 100ps)   |
                    +-------------------+         +-------------------+
```

### 4.2 时钟树规格

| 参数 | CPU CTS | AHB CTS | APB CTS |
|------|---------|---------|---------|
| 频率 | 200MHz | 200MHz | 100MHz |
| Skew | < 30ps | < 50ps | < 100ps |
| Insertion Delay | < 1ns | < 1.5ns | < 2ns |
| Duty Cycle | 45-55% | 45-55% | 40-60% |

### 4.3 时钟门控策略

```verilog
// 自动时钟门控插入
// 综合工具会识别以下模式并插入 ICG

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        data_reg <= '0;
    else if (enable)  // 使能信号会触发 ICG 插入
        data_reg <= data_in;
end
```

**时钟门控单元**:
- 类型：ICG (Integrated Clock Gating)
- 最小脉冲宽度：1ns
- 功耗节省：动态功耗降低 20-30%

---

## 5. 时序收敛检查点

### 5.1 综合后检查

| 指标 | 目标 | 测量 |
|------|------|------|
| WNS | >= 0ns | PrimeTime |
| TNS | < 100ps | PrimeTime |
| 违例路径数 | 0 | PrimeTime |
| 时钟树 skew | < 100ps | CCD |

### 5.2 布局后检查

| 指标 | 目标 | 测量 |
|------|------|------|
| WNS | >= 0ns | PrimeTime |
| TNS | < 50ps | PrimeTime |
| 保持违例 | 0 | PrimeTime |
| 过渡违例 | < 10 | PrimeTime |
| 电容违例 | < 10 | PrimeTime |

### 5.3 签核检查

| 指标 | 目标 | 测量 |
|------|------|------|
| WNS (signoff) | >= 0ns | PrimeTime |
| TNS (signoff) | 0ps | PrimeTime |
| 保持余量 | > 50ps | PrimeTime |
| 噪声余量 | > 100mV | StarRC |

---

## 6. DFM 检查清单

### 6.1 物理验证

- [ ] DRC 清洁 (0 违例)
- [ ] LVS 清洁 (匹配)
- [ ] ERC 清洁 (电气规则)
- [ ] Antenna 检查 (0 违例)

### 6.2 可制造性

- [ ] 通孔密度均匀
- [ ] 金属密度符合 CMP 要求 (40-60%)
- [ ] 天线效应修复
- [ ] 冗余通孔插入

### 6.3 良率优化

- [ ] 关键网络加宽
- [ ] 敏感单元添加保护环
- [ ] 测试点插入
- [ ] 冗余逻辑修复

---

## 7. 功耗分析

### 7.1 功耗预算

| 模块 | 动态功耗 | 静态功耗 | 总计 |
|------|----------|----------|------|
| CPU | 20mW | 3mW | 23mW |
| SRAM | 10mW | 2mW | 12mW |
| AHB | 5mW | 1mW | 6mW |
| APB | 5mW | 2mW | 7mW |
| GPIO | 3mW | 1mW | 4mW |
| 其他 | 2mW | 1mW | 3mW |
| **总计** | **45mW** | **10mW** | **55mW** |

### 7.2 功耗优化措施

1. **时钟门控**: 未使用模块关闭时钟
2. **电源门控**: 睡眠模式关闭电源域
3. **多阈值电压**: 非关键路径用 HVT
4. **操作数隔离**: 减少毛刺功耗

---

## 8. 与 RTL 团队协同

### 8.1 RTL 交付物检查

RTL 团队完成每个模块后，提供以下文件给后端：

- [ ] RTL 代码 (.v)
- [ ] 模块约束 (.sdc)
- [ ] 面积预估报告
- [ ] 关键路径说明

### 8.2 后端反馈流程

```
RTL 完成 → 综合评估 → 反馈报告 → RTL 优化 (如需要) → 重新综合
                              ↓
                        通过 → 进入下一步
```

### 8.3 迭代阈值

**需要 RTL 优化的情况**:

- WNS < -0.5ns
- 面积超标 > 20%
- 密度超标 > 10%
- 关键路径无法修复

---

**维护**: 后端团队  
**最后更新**: 2026-03-10
