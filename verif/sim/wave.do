# Questa/ModelSim 波形脚本

onerror {resume}

quietly WaveActivateNextPane {} 0

# 时钟和复位
add wave -noupdate -divider {Clock & Reset}
add wave -noupdate -format Logic /tb_top/hclk
add wave -noupdate -format Logic /tb_top/hreset_n
add wave -noupdate -format Logic /tb_top/pclk
add wave -noupdate -format Logic /tb_top/preset_n

# AHB 接口
add wave -noupdate -divider {AHB Interface}
add wave -noupdate -format Logic /tb_top/ahb_vif/haddr
add wave -noupdate -format Logic /tb_top/ahb_vif/htrans
add wave -noupdate -format Logic /tb_top/ahb_vif/hwrite
add wave -noupdate -format Logic /tb_top/ahb_vif/hsize
add wave -noupdate -format Logic /tb_top/ahb_vif/hburst
add wave -noupdate -format Logic /tb_top/ahb_vif/hwdata
add wave -noupdate -format Logic /tb_top/ahb_vif/hrdata
add wave -noupdate -format Logic /tb_top/ahb_vif/hready
add wave -noupdate -format Logic /tb_top/ahb_vif/hresp

# APB 接口
add wave -noupdate -divider {APB Interface}
add wave -noupdate -format Logic /tb_top/apb_vif/paddr
add wave -noupdate -format Logic /tb_top/apb_vif/psel
add wave -noupdate -format Logic /tb_top/apb_vif/penable
add wave -noupdate -format Logic /tb_top/apb_vif/pwrite
add wave -noupdate -format Logic /tb_top/apb_vif/pwdata
add wave -noupdate -format Logic /tb_top/apb_vif/prdata
add wave -noupdate -format Logic /tb_top/apb_vif/pready
add wave -noupdate -format Logic /tb_top/apb_vif/pslverr

# SRAM 接口
add wave -noupdate -divider {SRAM Interface}
add wave -noupdate -format Logic /tb_top/hsel_sram
add wave -noupdate -format Logic /tb_top/hready_sram
add wave -noupdate -format Logic /tb_top/hrdata_sram

# Flash 接口
add wave -noupdate -divider {Flash Interface}
add wave -noupdate -format Logic /tb_top/hsel_flash
add wave -noupdate -format Logic /tb_top/hready_flash
add wave -noupdate -format Logic /tb_top/hrdata_flash

# APB Bridge 接口
add wave -noupdate -divider {APB Bridge}
add wave -noupdate -format Logic /tb_top/hsel_apb
add wave -noupdate -format Logic /tb_top/hready_apb
add wave -noupdate -format Logic /tb_top/hrdata_apb

# UVM 信息
add wave -noupdate -divider {UVM Environment}
add wave -noupdate -format Logic /tb_top/uvm_test_top/env_inst/ahb_agent_inst/sequencer/curr_seq

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {100 ns}
