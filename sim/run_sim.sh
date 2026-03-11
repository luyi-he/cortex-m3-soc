#!/bin/bash
# ============================================================================
# 脚本名   : run_sim.sh
# 功能描述 : Cortex-M3 SoC 协同仿真脚本
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RTL_DIR="$PROJECT_ROOT/rtl"
TB_DIR="$PROJECT_ROOT/tb"
FW_DIR="$PROJECT_ROOT/firmware/build"
SIM_WORK_DIR="$SCRIPT_DIR"

FIRMWARE_HEX="$FW_DIR/cortex-m3-firmware.hex"

echo "========================================"
echo "  Cortex-M3 SoC Simulation"
echo "========================================"
echo ""

if [ ! -f "$FIRMWARE_HEX" ]; then
    echo "Error: Firmware not found at $FIRMWARE_HEX"
    exit 1
fi

echo "✓ Firmware found: $FIRMWARE_HEX"

if ! command -v iverilog &> /dev/null; then
    echo "Error: Icarus Verilog not found"
    exit 1
fi

echo "✓ Icarus Verilog found"

RTL_FILES="
$RTL_DIR/base/pll_28nm.v
$RTL_DIR/base/clk_buf.v
$RTL_DIR/base/clk_gen.v
$RTL_DIR/ahb2apb_bridge.v
$RTL_DIR/ahb_matrix.v
$RTL_DIR/flash_ctrl.v
$RTL_DIR/sram_ctrl.v
$RTL_DIR/peripheral/gpio_ctrl.v
$RTL_DIR/peripheral/uart_simple.v
$RTL_DIR/peripheral/apb_peripherals.v
$RTL_DIR/top/cortex_m3.v
$RTL_DIR/top/cortex_m3_soc.v
"

TB_FILE="$TB_DIR/tb_cosim.sv"

cd "$SIM_WORK_DIR"

echo "========================================"
echo "  Compiling..."
echo "========================================"

iverilog -g2012 \
    -o "$SIM_WORK_DIR/cosim.vvp" \
    $RTL_FILES \
    "$TB_FILE"

if [ $? -eq 0 ]; then
    echo "✓ Compilation successful!"
else
    echo "✗ Compilation failed!"
    exit 1
fi
echo ""

echo "========================================"
echo "  Running Simulation..."
echo "========================================"
echo ""

vvp -n "$SIM_WORK_DIR/cosim.vvp"

SIM_RESULT=$?

echo ""
echo "========================================"
if [ $SIM_RESULT -eq 0 ]; then
    echo "✓ Simulation completed successfully!"
else
    echo "✗ Simulation failed with code: $SIM_RESULT"
fi
echo "========================================"

if [ -f "$SIM_WORK_DIR/waveform.vcd" ]; then
    echo "✓ Waveform saved: waveform.vcd"
fi

exit $SIM_RESULT
