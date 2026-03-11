# ============================================================================
# Cortex-M3 SoC UVM 验证环境 Makefile
# ============================================================================

# 仿真器选择 (questa/vcs/xcelium)
SIMULATOR ?= questa

# 项目目录
PROJ_DIR := $(shell pwd)
VERIF_DIR := $(PROJ_DIR)/verif
UVM_DIR := $(VERIF_DIR)/uvm
RTL_DIR := $(PROJ_DIR)/rtl
SIM_DIR := $(VERIF_DIR)/sim
WAVE_DIR := $(VERIF_DIR)/waves

# UVM 版本
UVM_VERSION ?= 1.2

# 测试名称
TEST ?= test_cpu_boot

# 种子
SEED ?= 1

# 是否开启波形
WAVES ?= 1

# 是否开启覆盖率
COVERAGE ?= 1

# 仿真时间
SIM_TIME ?= 100us

# 详细程度 (UVM_NONE/UVM_LOW/UVM_MEDIUM/UVM_HIGH/UVM_FULL)
UVM_VERBOSITY ?= UVM_MEDIUM

#============================================================
# 源文件列表
#============================================================

# RTL 文件
RTL_SRCS := \
    $(RTL_DIR)/ahb_matrix.v \
    $(RTL_DIR)/ahb2apb_bridge.v \
    $(RTL_DIR)/sram_ctrl.v \
    $(RTL_DIR)/flash_ctrl.v \
    $(RTL_DIR)/peripheral/gpio_ctrl.v

# UVM 文件
UVM_SRCS := \
    $(UVM_DIR)/agent/ahb/ahb_seq_item.sv \
    $(UVM_DIR)/agent/ahb/ahb_interface.sv \
    $(UVM_DIR)/agent/ahb/ahb_driver.sv \
    $(UVM_DIR)/agent/ahb/ahb_monitor.sv \
    $(UVM_DIR)/agent/ahb/ahb_seq_lib.sv \
    $(UVM_DIR)/agent/ahb/ahb_agent.sv \
    $(UVM_DIR)/agent/apb/apb_seq_item.sv \
    $(UVM_DIR)/agent/apb/apb_interface.sv \
    $(UVM_DIR)/agent/apb/apb_driver.sv \
    $(UVM_DIR)/agent/apb/apb_monitor.sv \
    $(UVM_DIR)/agent/apb/apb_seq_lib.sv \
    $(UVM_DIR)/agent/apb/apb_agent.sv \
    $(UVM_DIR)/vip/sram_model.sv \
    $(UVM_DIR)/vip/flash_model.sv \
    $(UVM_DIR)/vip/gpio_pad_model.sv \
    $(UVM_DIR)/env/scoreboard.sv \
    $(UVM_DIR)/env/coverage_model.sv \
    $(UVM_DIR)/env/reg_model.sv \
    $(UVM_DIR)/env/env.sv \
    $(UVM_DIR)/test/base_test.sv \
    $(UVM_DIR)/test/test_cpu_boot.sv \
    $(UVM_DIR)/test/test_ahb_read_write.sv \
    $(UVM_DIR)/test/test_sram_access.sv \
    $(UVM_DIR)/test/test_flash_access.sv \
    $(UVM_DIR)/test/test_gpio.sv \
    $(UVM_DIR)/test/test_apb_peripherals.sv \
    $(UVM_DIR)/test/test_interrupt.sv \
    $(UVM_DIR)/test/test_concurrent_access.sv \
    $(UVM_DIR)/tb/tb_top.sv

#============================================================
# Questa/ModelSim 配置
#============================================================

ifeq ($(SIMULATOR), questa)
    SIM_CMD := vsim
    COMPILE_CMD := vlog -sv +incdir+$(UVM_DIR)
    SIM_OPTS := -voptargs="+acc"
    
    ifeq ($(WAVES), 1)
        SIM_OPTS += -do "do wave.do"
    endif
    
    ifeq ($(COVERAGE), 1)
        COMPILE_CMD += -cover
        SIM_OPTS += -coverage -coveropt=3
    endif
endif

#============================================================
# VCS 配置
#============================================================

ifeq ($(SIMULATOR), vcs)
    SIM_CMD := ./simv
    COMPILE_CMD := vcs -sverilog +incdir+$(UVM_DIR) -full64
    
    ifeq ($(WAVES), 1)
        COMPILE_CMD += +v2k
        SIM_OPTS := +fsdb+autoflush
    endif
    
    ifeq ($(COVERAGE), 1)
        COMPILE_CMD += -cm line+cond+fsm+tgl
    endif
endif

#============================================================
# Xcelium 配置
#============================================================

ifeq ($(SIMULATOR), xcelium)
    SIM_CMD := irun
    COMPILE_CMD := xrun -sv +incdir+$(UVM_DIR)
    
    ifeq ($(WAVES), 1)
        SIM_OPTS := -access +rwc
    endif
    
    ifeq ($(COVERAGE), 1)
        COMPILE_CMD += -coverage all
    endif
endif

#============================================================
# 编译规则
#============================================================

.PHONY: all compile sim clean waves coverage regress

all: compile sim

compile:
	@echo "==========================================="
	@echo "Compiling Cortex-M3 SoC UVM Environment"
	@echo "==========================================="
	@mkdir -p $(SIM_DIR)
	@mkdir -p $(WAVE_DIR)
	$(COMPILE_CMD) $(UVM_SRCS) $(RTL_SRCS)
	@echo "Compilation completed!"

sim: compile
	@echo "==========================================="
	@echo "Running simulation: $(TEST)"
	@echo "==========================================="
	cd $(SIM_DIR) && $(SIM_CMD) tb_top \
		+UVM_TESTNAME=$(TEST) \
		+UVM_VERBOSITY=$(UVM_VERBOSITY) \
		+ntb_random_seed=$(SEED) \
		$(SIM_OPTS)

waves:
	@echo "Opening waveform viewer..."
ifeq ($(SIMULATOR), questa)
	vsim -view $(WAVE_DIR)/waveform.vcd
else ifeq ($(SIMULATOR), vcs)
	dve -full64 -vpd waves/sim.vpd
endif

coverage:
	@echo "Generating coverage report..."
ifeq ($(SIMULATOR), questa)
	vcover report -html coverage_db
else ifeq ($(SIMULATOR), vcs)
	urg -dir sim.vdb -format both
endif
	@echo "Coverage report generated in $(SIM_DIR)/html"

# 回归测试
regress:
	@echo "==========================================="
	@echo "Running Regression Tests"
	@echo "==========================================="
	@for test in test_cpu_boot test_ahb_read_write test_sram_access \
	             test_flash_access test_gpio test_apb_peripherals \
	             test_interrupt test_concurrent_access; do \
		echo "Running $$test..."; \
		make TEST=$$test WAVES=0 sim || exit 1; \
	done
	@echo "==========================================="
	@echo "All regression tests passed!"
	@echo "==========================================="

# 清理
clean:
	@echo "Cleaning up..."
	rm -rf $(SIM_DIR)/*
	rm -rf $(WAVE_DIR)/*
	rm -rf work/
	rm -rf vsim.wlf
	rm -rf transcript
	rm -rf coverage_db/
	@echo "Cleanup completed!"

# 帮助
help:
	@echo "Cortex-M3 SoC UVM Verification Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make [TARGET] [OPTIONS]"
	@echo ""
	@echo "Targets:"
	@echo "  all        - Compile and simulate (default)"
	@echo "  compile    - Compile only"
	@echo "  sim        - Run simulation"
	@echo "  waves      - Open waveform viewer"
	@echo "  coverage   - Generate coverage report"
	@echo "  regress    - Run all regression tests"
	@echo "  clean      - Clean up generated files"
	@echo "  help       - Show this help"
	@echo ""
	@echo "Options:"
	@echo "  SIMULATOR=questa|vcs|xcelium  (default: questa)"
	@echo "  TEST=<test_name>              (default: test_cpu_boot)"
	@echo "  SEED=<number>                 (default: 1)"
	@echo "  WAVES=0|1                     (default: 1)"
	@echo "  COVERAGE=0|1                  (default: 1)"
	@echo "  SIM_TIME=<time>               (default: 100us)"
	@echo ""
	@echo "Available tests:"
	@echo "  test_cpu_boot"
	@echo "  test_ahb_read_write"
	@echo "  test_sram_access"
	@echo "  test_flash_access"
	@echo "  test_gpio"
	@echo "  test_apb_peripherals"
	@echo "  test_interrupt"
	@echo "  test_concurrent_access"
