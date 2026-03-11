#!/bin/bash
# GPIO 控制器单元测试

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RTL_DIR="$SCRIPT_DIR/../rtl"
TB_DIR="$SCRIPT_DIR/../tb"

echo "========================================"
echo "  GPIO Controller Unit Test"
echo "========================================"
echo ""

cd "$SCRIPT_DIR"

echo "Compiling..."
iverilog -g2012 \
    -o "$SCRIPT_DIR/tb_gpio.vvp" \
    "$RTL_DIR/peripheral/gpio_ctrl.v" \
    "$TB_DIR/tb_gpio_ctrl.sv"

echo "✓ Compilation successful!"
echo ""

echo "Running simulation..."
vvp -n "$SCRIPT_DIR/tb_gpio.vvp"

echo ""
if [ -f "$SCRIPT_DIR/tb_gpio_ctrl.vcd" ]; then
    echo "✓ Waveform: tb_gpio_ctrl.vcd"
fi
