#!/bin/bash
# ============================================================================
# 脚本名   : run_formal.sh
# 功能描述 : 运行 Formal 验证
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================"
echo "  Cortex-M3 SoC Formal Verification"
echo "========================================"
echo ""

# 检查 SymbiYosys 是否安装
if ! command -v sby &> /dev/null; then
    echo "❌ SymbiYosys not found. Install with:"
    echo "   pip3 install symbiyosys"
    echo ""
    exit 1
fi

echo "✓ SymbiYosys found: $(which sby)"
echo ""

# 清理旧的验证结果
echo "Cleaning up old results..."
rm -rf cdc_check_reset/ reset_check_proof/ ahb_protocol_bmc/ 2>/dev/null || true
echo ""

# 运行 CDC 验证
echo "========================================"
echo "  [1/3] CDC Check (Clock Domain Crossing)"
echo "========================================"
if sby -f cdc_check.sby; then
    echo "✅ CDC Check PASSED"
else
    echo "❌ CDC Check FAILED"
    echo "   Check cdc_check/PROVE/results.txt for details"
fi
echo ""

# 运行复位验证
echo "========================================"
echo "  [2/3] Reset Check (Async Reset Sync Release)"
echo "========================================"
if sby -f reset_check.sby; then
    echo "✅ Reset Check PASSED"
else
    echo "❌ Reset Check FAILED"
    echo "   Check reset_check/PROVE/results.txt for details"
fi
echo ""

# 运行 AHB 协议验证
echo "========================================"
echo "  [3/3] AHB Protocol Check"
echo "========================================"
if sby -f ahb_protocol.sby; then
    echo "✅ AHB Protocol Check PASSED"
else
    echo "❌ AHB Protocol Check FAILED"
    echo "   Check ahb_protocol/BMC/results.txt for details"
fi
echo ""

echo "========================================"
echo "  Formal Verification Summary"
echo "========================================"
echo ""
echo "Results:"
echo "  - CDC Check:        cdc_check/PROVE/"
echo "  - Reset Check:      reset_check/PROVE/"
echo "  - AHB Protocol:     ahb_protocol/BMC/"
echo ""
echo "Waveforms:"
echo "  - Open with: gtkwave <task>/engine_0/witness.vcd"
echo ""
