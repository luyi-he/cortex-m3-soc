#!/bin/bash
# ============================================================================
# 脚本名   : run_synth.sh
# 功能描述 : 运行逻辑综合 (使用 Yosys + openPDKs)
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================"
echo "  Cortex-M3 SoC Logic Synthesis"
echo "  Tool: Yosys + SkyWater 130nm PDK"
echo "========================================"
echo ""

# 检查 Yosys 是否安装
if ! command -v yosys &> /dev/null; then
    echo "❌ Yosys not found. Install with:"
    echo "   brew install yosys"
    echo ""
    exit 1
fi

echo "✓ Yosys found: $(yosys --version)"
echo ""

# 创建输出目录
mkdir -p synth/openpdk/output
echo "✓ Output directory: synth/openpdk/output"
echo ""

# 运行综合
echo "========================================"
echo "  Running Synthesis..."
echo "========================================"
yosys -l synth/openpdk/output/synth.log synth/openpdk/synth.tcl

echo ""
echo "========================================"
echo "  Synthesis Complete!"
echo "========================================"
echo ""
echo "Output files:"
echo "  - Netlist:  synth/openpdk/output/cortex_m3_soc.v"
echo "  - Report:   synth/openpdk/output/report.txt"
echo "  - Log:      synth/openpdk/output/synth.log"
echo ""
echo "To view report:"
echo "  cat synth/openpdk/output/report.txt"
echo ""
