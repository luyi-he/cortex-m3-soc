#!/bin/bash
# Cortex-M3 SoC 综合脚本 (Yosys)

cd ~/.openclaw/workspace/cortex-m3-soc

# 创建输出目录
mkdir -p synth/openpdk/output

yosys << 'EOF'
# 读取所有 RTL 模块 (使用黑盒版本)
read_verilog rtl/base/clk_gen.v
read_verilog rtl/base/rst_gen.v
read_verilog rtl/base/pll_28nm.v
read_verilog rtl/ahb_matrix.v
read_verilog rtl/ahb2apb_bridge.v
read_verilog rtl/sram_ctrl.v
read_verilog rtl/peripheral/gpio_ctrl.v
read_verilog rtl/peripheral/uart_simple.v
read_verilog rtl/peripheral/apb_peripherals.v
read_verilog rtl/flash_ctrl_blackbox.v
read_verilog rtl/top/cortex_m3_blackbox.v
read_verilog rtl/top/cortex_m3_soc.v

# 综合
hierarchy -check -top cortex_m3_soc
proc
opt_clean
opt_expr
opt_merge
opt_muxtree
opt_reduce
opt_rmdff
opt_clean

techmap -map +/adff2dff.v
techmap -map +/muxmap.v
techmap -map +/arith_map.v

opt_clean
opt_expr
opt_merge
opt_reduce
opt_rmdff
opt_clean

# 输出
write_verilog -noattr synth/openpdk/output/cortex_m3_soc_gate.v
write_json synth/openpdk/output/cortex_m3_soc.json
EOF

# 显示统计
echo ""
echo "========================================"
echo "  Synthesis Report"
echo "========================================"
echo ""
ls -lh synth/openpdk/output/
echo ""
echo "Output files:"
echo "  - synth/openpdk/output/cortex_m3_soc_gate.v"
echo "  - synth/openpdk/output/cortex_m3_soc.json"
echo ""
