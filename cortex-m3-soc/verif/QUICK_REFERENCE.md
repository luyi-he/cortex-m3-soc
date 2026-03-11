# UVM 验证环境快速参考

## 常用命令

```bash
# 编译
make compile

# 运行测试
make TEST=<test_name>

# 运行所有回归测试
make regress

# 查看波形
make waves

# 生成覆盖率报告
make coverage

# 清理
make clean
```

## 测试用例列表

| 测试 | 命令 |
|-----|------|
| CPU 启动 | `make TEST=test_cpu_boot` |
| AHB 读写 | `make TEST=test_ahb_read_write` |
| SRAM 访问 | `make TEST=test_sram_access` |
| Flash 访问 | `make TEST=test_flash_access` |
| GPIO 功能 | `make TEST=test_gpio` |
| APB 外设 | `make TEST=test_apb_peripherals` |
| 中断测试 | `make TEST=test_interrupt` |
| 并发压力 | `make TEST=test_concurrent_access` |

## AHB 序列使用示例

```systemverilog
// 单次写
ahb_write_seq w_seq = ahb_write_seq::type_id::create("w_seq");
w_seq.addr = 32'h2000_0000;
w_seq.data = 32'hDEADBEEF;
w_seq.start(env_inst.ahb_agent_inst.sequencer);

// 单次读
ahb_read_seq r_seq = ahb_read_seq::type_id::create("r_seq");
r_seq.addr = 32'h2000_0000;
r_seq.start(env_inst.ahb_agent_inst.sequencer);

// 突发读
ahb_burst_read_seq br_seq = ahb_burst_read_seq::type_id::create("br_seq");
br_seq.start_addr = 32'h0000_0000;
br_seq.burst_len = 8;
br_seq.start(env_inst.ahb_agent_inst.sequencer);
```

## APB 序列使用示例

```systemverilog
// 写寄存器
apb_write_seq w_seq = apb_write_seq::type_id::create("w_seq");
w_seq.addr = 32'h5000_0000;  // GPIO MODER
w_seq.data = 32'hFFFF_FFFF;  // 输入模式
w_seq.start(env_inst.apb_agent_inst.sequencer);

// 读寄存器
apb_read_seq r_seq = apb_read_seq::type_id::create("r_seq");
r_seq.addr = 32'h5000_0010;  // GPIO IDR
r_seq.start(env_inst.apb_agent_inst.sequencer);
```

## 寄存器模型使用示例

```systemverilog
// 写寄存器
reg_model.peripherals.gpio_moder.write(status, 32'hFFFF_FFFF);

// 读寄存器
reg_model.peripherals.gpio_idr.read(status);

// 预测
reg_model.peripherals.gpio_odr.predict(32'hAAAAAAAA);
```

## 覆盖率收集

```bash
# 运行所有测试收集覆盖率
./scripts/collect_coverage.sh

# 查看覆盖率摘要
cat reports/coverage_summary.txt

# 查看 HTML 报告
open reports/coverage_html/index.html
```

## 调试技巧

### 1. 增加 UVM 详细程度

```bash
make TEST=test_gpio UVM_VERBOSITY=UVM_HIGH
```

### 2. 查看特定模块波形

编辑 `sim/wave.do` 添加：

```tcl
add wave /tb_top/u_dut/ahb_matrix/*
```

### 3. 添加 UVM 打印

```systemverilog
`uvm_info("MY_TEST", $sformatf("addr=%0h, data=%0h", addr, data), UVM_HIGH)
`uvm_warning("MY_TEST", "Something suspicious")
`uvm_error("MY_TEST", "Test failed!")
`uvm_fatal("MY_TEST", "Unrecoverable error")
```

### 4. 使用断言

AHB 断言已在 `ahb_monitor.sv` 中定义：

```systemverilog
// HTRANS 有效性检查
assert property (p_htrans_valid)
// HADDR 稳定性检查
assert property (p_haddr_stable)
```

## 文件位置

| 文件类型 | 路径 |
|---------|------|
| Agent | `verif/uvm/agent/{ahb,apb}/` |
| 测试用例 | `verif/uvm/test/` |
| 环境 | `verif/uvm/env/` |
| VIP 模型 | `verif/uvm/vip/` |
| Testbench | `verif/uvm/tb/` |
| 脚本 | `verif/scripts/` |
| 报告 | `verif/reports/` |
| 日志 | `verif/logs/` |
| 波形 | `verif/waves/` |

## 仿真器切换

```bash
# Questa (默认)
make SIMULATOR=questa

# VCS
make SIMULATOR=vcs

# Xcelium
make SIMULATOR=xcelium
```
