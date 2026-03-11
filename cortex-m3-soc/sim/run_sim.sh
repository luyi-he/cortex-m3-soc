#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RTL_DIR="$PROJECT_ROOT/rtl"
TB_DIR="$PROJECT_ROOT/tb"

echo "========================================"
echo "  Cortex-M3 Simple Simulation"
echo "========================================"

cd "$SCRIPT_DIR"

echo "Compiling..."
iverilog -g2012 \
    -o "$SCRIPT_DIR/cosim.vvp" \
    "$RTL_DIR/top/cortex_m3.v" \
    "$TB_DIR/tb_cosim.sv"

echo "Running..."
vvp -n "$SCRIPT_DIR/cosim.vvp"

echo "Done!"
[ -f "$SCRIPT_DIR/waveform.vcd" ] && echo "Waveform: waveform.vcd"
