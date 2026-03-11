#!/bin/bash

# ============================================================================
# Cortex-M3 SoC 回归测试脚本
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/../logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "==========================================="
echo "Cortex-M3 SoC Regression Test"
echo "Timestamp: ${TIMESTAMP}"
echo "==========================================="

# 创建日志目录
mkdir -p ${LOG_DIR}

# 测试列表
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

# 统计
TOTAL=0
PASSED=0
FAILED=0

# 运行测试
for test in "${TESTS[@]}"; do
    TOTAL=$((TOTAL + 1))
    echo ""
    echo "[$TOTAL/${#TESTS[@]}] Running ${test}..."
    
    LOG_FILE="${LOG_DIR}/${test}_${TIMESTAMP}.log"
    
    if make -C ${SCRIPT_DIR}/.. TEST=${test} WAVES=0 COVERAGE=0 sim > ${LOG_FILE} 2>&1; then
        echo "  ✓ ${test} PASSED"
        PASSED=$((PASSED + 1))
    else
        echo "  ✗ ${test} FAILED"
        FAILED=$((FAILED + 1))
        echo "  Log: ${LOG_FILE}"
        
        # 显示错误摘要
        tail -20 ${LOG_FILE}
    fi
done

# 生成报告
REPORT_FILE="${LOG_DIR}/regression_report_${TIMESTAMP}.txt"

cat > ${REPORT_FILE} << EOF
===========================================
Cortex-M3 SoC Regression Test Report
===========================================
Timestamp: ${TIMESTAMP}
Total Tests: ${TOTAL}
Passed: ${PASSED}
Failed: ${FAILED}
Pass Rate: $(echo "scale=2; ${PASSED}*100/${TOTAL}" | bc)%

Test Results:
EOF

for test in "${TESTS[@]}"; do
    LOG_FILE="${LOG_DIR}/${test}_${TIMESTAMP}.log"
    if [ -f ${LOG_FILE} ] && grep -q "PASSED" ${LOG_FILE}; then
        echo "  ✓ ${test}" >> ${REPORT_FILE}
    else
        echo "  ✗ ${test}" >> ${REPORT_FILE}
    fi
done

echo "" >> ${REPORT_FILE}
echo "===========================================" >> ${REPORT_FILE}

# 显示摘要
echo ""
echo "==========================================="
echo "Regression Test Summary"
echo "==========================================="
echo "Total:  ${TOTAL}"
echo "Passed: ${PASSED}"
echo "Failed: ${FAILED}"
echo "Pass Rate: $(echo "scale=2; ${PASSED}*100/${TOTAL}" | bc)%"
echo ""
echo "Report: ${REPORT_FILE}"
echo "==========================================="

# 如果有失败的测试，退出错误码
if [ ${FAILED} -gt 0 ]; then
    exit 1
fi

exit 0
