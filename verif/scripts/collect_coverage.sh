#!/bin/bash

# ============================================================================
# Cortex-M3 SoC 覆盖率收集脚本
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIM_DIR="${SCRIPT_DIR}/sim"
COV_DIR="${SCRIPT_DIR}/coverage"
REPORT_DIR="${SCRIPT_DIR}/reports"

echo "==========================================="
echo "Cortex-M3 SoC Coverage Collection"
echo "==========================================="

# 创建目录
mkdir -p ${COV_DIR}
mkdir -p ${REPORT_DIR}

# 运行所有测试收集覆盖率
echo "Running tests for coverage collection..."

TESTS=(
    "test_cpu_boot"
    "test_ahb_read_write"
    "test_sram_access"
    "test_flash_access"
    "test_gpio"
    "test_apb_peripherals"
    "test_interrupt"
    "test_concurrent_access"
)

for test in "${TESTS[@]}"; do
    echo "Running ${test}..."
    make -C ${SCRIPT_DIR}/.. TEST=${test} WAVES=0 sim || {
        echo "Test ${test} failed!"
        exit 1
    }
done

# 生成覆盖率报告
echo ""
echo "Generating coverage reports..."

# Questa 覆盖率
if [ -d "${SIM_DIR}/coverage_db" ]; then
    echo "Generating Questa coverage report..."
    vcover report -html ${SIM_DIR}/coverage_db -output ${REPORT_DIR}/coverage_html
    vcover report -summary ${SIM_DIR}/coverage_db > ${REPORT_DIR}/coverage_summary.txt
fi

# VCS 覆盖率
if [ -d "${SIM_DIR}/sim.vdb" ]; then
    echo "Generating VCS coverage report..."
    urg -dir ${SIM_DIR}/sim.vdb -format both -report ${REPORT_DIR}/urgReport
fi

# 显示覆盖率摘要
echo ""
echo "==========================================="
echo "Coverage Summary"
echo "==========================================="

if [ -f "${REPORT_DIR}/coverage_summary.txt" ]; then
    cat ${REPORT_DIR}/coverage_summary.txt
fi

if [ -f "${REPORT_DIR}/urgReport/meta.html" ]; then
    echo "VCS Coverage Report: ${REPORT_DIR}/urgReport/meta.html"
fi

if [ -d "${REPORT_DIR}/coverage_html" ]; then
    echo "Questa Coverage Report: ${REPORT_DIR}/coverage_html/index.html"
fi

echo ""
echo "Coverage collection completed!"
echo "==========================================="
