# Cortex-M3 SoC UVM 验证环境文件列表

# 编译选项
+incdir+${UVM_DIR}
+incdir+${UVM_DIR}/agent/ahb
+incdir+${UVM_DIR}/agent/apb
+incdir+${UVM_DIR}/env
+incdir+${UVM_DIR}/test
+incdir+${UVM_DIR}/vip

# UVM 库 (由仿真器自动加载)
# -uvmhome $UVM_HOME
# -f $UVM_HOME/src/uvm.sv

#============================================================
# UVM Agent - AHB
#============================================================
${UVM_DIR}/agent/ahb/ahb_seq_item.sv
${UVM_DIR}/agent/ahb/ahb_interface.sv
${UVM_DIR}/agent/ahb/ahb_driver.sv
${UVM_DIR}/agent/ahb/ahb_monitor.sv
${UVM_DIR}/agent/ahb/ahb_seq_lib.sv
${UVM_DIR}/agent/ahb/ahb_agent.sv

#============================================================
# UVM Agent - APB
#============================================================
${UVM_DIR}/agent/apb/apb_seq_item.sv
${UVM_DIR}/agent/apb/apb_interface.sv
${UVM_DIR}/agent/apb/apb_driver.sv
${UVM_DIR}/agent/apb/apb_monitor.sv
${UVM_DIR}/agent/apb/apb_seq_lib.sv
${UVM_DIR}/agent/apb/apb_agent.sv

#============================================================
# UVM VIP Models
#============================================================
${UVM_DIR}/vip/sram_model.sv
${UVM_DIR}/vip/flash_model.sv
${UVM_DIR}/vip/gpio_pad_model.sv

#============================================================
# UVM Environment
#============================================================
${UVM_DIR}/env/scoreboard.sv
${UVM_DIR}/env/coverage_model.sv
${UVM_DIR}/env/reg_model.sv
${UVM_DIR}/env/env.sv

#============================================================
# UVM Tests
#============================================================
${UVM_DIR}/test/base_test.sv
${UVM_DIR}/test/test_cpu_boot.sv
${UVM_DIR}/test/test_ahb_read_write.sv
${UVM_DIR}/test/test_sram_access.sv
${UVM_DIR}/test/test_flash_access.sv
${UVM_DIR}/test/test_gpio.sv
${UVM_DIR}/test/test_apb_peripherals.sv
${UVM_DIR}/test/test_interrupt.sv
${UVM_DIR}/test/test_concurrent_access.sv

#============================================================
# RTL Modules
#============================================================
${RTL_DIR}/ahb_matrix.v
${RTL_DIR}/ahb2apb_bridge.v
${RTL_DIR}/sram_ctrl.v
${RTL_DIR}/flash_ctrl.v
${RTL_DIR}/peripheral/gpio_ctrl.v

#============================================================
# Testbench
#============================================================
${UVM_DIR}/tb/tb_top.sv
