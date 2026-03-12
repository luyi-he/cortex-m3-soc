# ============================================================================
# Yosys 综合脚本：Cortex-M3 SoC
# 工艺：SkyWater 130nm (开源 PDK)
# 目标：验证综合流程 (非最终 28nm 实现)
# ============================================================================

# 输出设置
log "Starting synthesis for Cortex-M3 SoC..."
yosys -import

# 设置顶层模块
set top_module cortex_m3_soc

# ============================================================================
# 1. 读取 RTL 源文件
# ============================================================================

log "Reading RTL source files..."

# 基础模块
read_verilog rtl/base/clk_gen.v
read_verilog rtl/base/rst_gen.v
read_verilog rtl/base/pll_28nm.v
read_verilog rtl/base/rst_gen.v

# 总线模块
read_verilog rtl/ahb_matrix.v
read_verilog rtl/ahb2apb_bridge.v

# 存储模块
read_verilog rtl/sram_ctrl.v
read_verilog rtl/flash_ctrl.v

# 外设模块
read_verilog rtl/peripheral/gpio_ctrl.v
read_verilog rtl/peripheral/uart_simple.v
read_verilog rtl/peripheral/apb_peripherals.v

# 顶层模块
read_verilog rtl/top/cortex_m3_soc.v
read_verilog rtl/top/cortex_m3.v

# ============================================================================
# 2. 处理未实例化的模块 (Cortex-M3 CPU)
# ============================================================================

log "Handling Cortex-M3 CPU (blackbox)..."

# Cortex-M3 是 ARM IP，这里用黑盒处理
chtype -set blackbox cortex_m3

# ============================================================================
# 3. 综合流程
# ============================================================================

log "Running synthesis..."

# 预处理
hierarchy -check -top $top_module
proc

# 优化
opt_clean
opt_expr
opt_merge
opt_muxtree
opt_reduce
opt_rmdff
opt_clean

# 映射到基本门
techmap -map +/adff2dff.v
techmap -map +/muxmap.v
techmap -map +/arith_map.v

# 再次优化
opt_clean
opt_expr
opt_merge
opt_reduce
opt_rmdff
opt_clean

# ============================================================================
# 4. 映射到 SkyWater 130nm PDK
# ============================================================================

log "Mapping to SkyWater 130nm PDK..."

# 注意：这里只是演示流程，实际需要加载 SkyWater PDK 库
# abc -liberty ${PDK_ROOT}/sky130_fd_sc_hd.lib.json
abc -liberty +/sky130_fd_sc_hd.lib.json

# 输出映射后的网表
techmap
opt_clean

# ============================================================================
# 5. 时序约束 (示例)
# ============================================================================

log "Applying timing constraints..."

# 时钟约束：200MHz (5ns 周期) - 这里只是示例，实际需要 SDC 文件
# set_driving_cell -max IOPAD
# set_load -max 10.0 [all_outputs]

# ============================================================================
# 6. 输出结果
# ============================================================================

log "Writing output files..."

# 输出门级网表
write_verilog -noattr synth/openpdk/output/cortex_m3_soc_gate.v
log "✓ Gate-level netlist: synth/openpdk/output/cortex_m3_soc_gate.v"

# 输出统计报告
tee synth/openpdk/output/report.txt stat

# 输出详细报告
log "" >> synth/openpdk/output/report.txt
log "=== Synthesis Summary ===" >> synth/openpdk/output/report.txt
log "" >> synth/openpdk/output/report.txt

# 面积统计
select -module $top_module
stats -json >> synth/openpdk/output/report.json

log ""
log "========================================"
log "  Synthesis Report"
log "========================================"
log ""

# 显示统计信息
stats

log ""
log "========================================"
log "  Synthesis Complete!"
log "========================================"
log ""
