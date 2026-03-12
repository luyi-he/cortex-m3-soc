# Yosys 综合脚本：Cortex-M3 SoC
# 工艺：SkyWater 130nm (开源 PDK，用于验证流程)
# 注意：Flash/SRAM 用黑盒处理 (需要 memory 库)

# ============================================================================
# 1. 读取 RTL 源文件
# ============================================================================

read_verilog rtl/base/clk_gen.v
read_verilog rtl/base/rst_gen.v
read_verilog rtl/base/pll_28nm.v
read_verilog rtl/ahb_matrix.v
read_verilog rtl/ahb2apb_bridge.v
read_verilog rtl/sram_ctrl.v
read_verilog rtl/flash_ctrl.v
read_verilog rtl/peripheral/gpio_ctrl.v
read_verilog rtl/peripheral/uart_simple.v
read_verilog rtl/peripheral/apb_peripherals.v
read_verilog rtl/top/cortex_m3_soc.v
read_verilog rtl/top/cortex_m3.v

# ============================================================================
# 2. 处理黑盒模块 (Cortex-M3 CPU + Flash/SRAM)
# ============================================================================

chtype -set blackbox cortex_m3
chtype -set blackbox sram_ctrl
chtype -set blackbox flash_ctrl

# ============================================================================
# 3. 综合流程
# ============================================================================

hierarchy -check -top cortex_m3_soc
proc
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
# 4. 输出结果
# ============================================================================

mkdir -p synth/openpdk/output
write_verilog -noattr synth/openpdk/output/cortex_m3_soc_gate.v
tee synth/openpdk/output/report.txt stat
write_json synth/openpdk/output/cortex_m3_soc.json

# 显示统计信息
stats
