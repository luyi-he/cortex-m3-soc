# Cortex-M3 SoC UVM 验证环境

## 📋 目录结构

```
verif/
├── uvm/                    # UVM 验证环境
│   ├── agent/              # UVM Agent
│   │   ├── ahb/           # AHB-Lite Agent
│   │   │   ├── ahb_seq_item.sv    # 序列项
│   │   │   ├── ahb_interface.sv   # 虚拟接口
│   │   │   ├── ahb_driver.sv      # 驱动器
│   │   │   ├── ahb_monitor.sv     # 监控器 (带覆盖率)
│   │   │   ├── ahb_seq_lib.sv     # 序列库
│   │   │   └── ahb_agent.sv       # Agent 顶层
│   │   └── apb/           # APB Agent
│   │       ├── apb_seq_item.sv
│   │       ├── apb_interface.sv
│   │       ├── apb_driver.sv
│   │       ├── apb_monitor.sv
│   │       ├── apb_seq_lib.sv
│   │       └── apb_agent.sv
│   ├── vip/               # 验证 IP
│   │   ├── sram_model.sv  # SRAM 行为模型
│   │   ├── flash_model.sv # Flash 行为模型 (带读延迟)
│   │   └── gpio_pad_model.sv  # GPIO PAD 模型
│   ├── env/               # 环境
│   │   ├── scoreboard.sv  # 比分板
│   │   ├── coverage_model.sv  # 覆盖率模型
│   │   ├── reg_model.sv   # 寄存器模型 (RAL)
│   │   └── env.sv         # 环境顶层
│   ├── test/              # 测试用例
│   │   ├── base_test.sv               # 基础测试类
│   │   ├── test_cpu_boot.sv           # CPU 启动测试
│   │   ├── test_ahb_read_write.sv     # AHB 读写测试
│   │   ├── test_sram_access.sv        # SRAM 访问测试
│   │   ├── test_flash_access.sv       # Flash 访问测试
│   │   ├── test_gpio.sv               # GPIO 功能测试
│   │   ├── test_apb_peripherals.sv    # APB 外设测试
│   │   ├── test_interrupt.sv          # 中断测试
│   │   └── test_concurrent_access.sv  # 并发访问压力测试
│   └── tb/
│       └── tb_top.sv      # 顶层 Testbench
├── sim/                   # 仿真目录
│   ├── Makefile
│   ├── filelist.f         # 文件列表
│   └── wave.do            # 波形脚本
├── scripts/               # 脚本
│   ├── collect_coverage.sh  # 覆盖率收集脚本
│   └── regression.sh        # 回归测试脚本
├── logs/                  # 日志目录 (自动生成)
├── waves/                 # 波形目录 (自动生成)
├── coverage/              # 覆盖率数据库 (自动生成)
├── reports/               # 报告目录 (自动生成)
└── Makefile               # 主 Makefile
```

## 🚀 快速开始

### 1. 环境准备

确保已安装以下工具之一：
- Mentor Questa/ModelSim
- Synopsys VCS
- Cadence Xcelium

### 2. 运行单个测试

```bash
# 使用默认仿真器 (Questa)
make TEST=test_cpu_boot

# 指定仿真器
make SIMULATOR=vcs TEST=test_ahb_read_write

# 不生成波形
make TEST=test_gpio WAVES=0

# 指定随机种子
make TEST=test_sram_access SEED=12345
```

### 3. 运行回归测试

```bash
# 运行所有测试
./scripts/regression.sh

# 或手动运行
make regress
```

### 4. 收集覆盖率

```bash
./scripts/collect_coverage.sh
```

### 5. 查看波形

```bash
# Questa
make waves

# VCS
dve -full64 -vpd waves/sim.vpd
```

### 6. 查看覆盖率报告

```bash
make coverage
```

## 📊 测试用例说明

| 测试名称 | 描述 | 覆盖率目标 |
|---------|------|-----------|
| test_cpu_boot | CPU 启动测试，验证复位向量和初始 SP | AHB 协议 20% |
| test_ahb_read_write | AHB 总线读写测试 | AHB 协议 80% |
| test_sram_access | SRAM 访问测试 (byte/half/word) | SRAM 覆盖率 90% |
| test_flash_access | Flash 读取和写保护测试 | Flash 覆盖率 85% |
| test_gpio | GPIO 配置和输入输出测试 | GPIO 寄存器 100% |
| test_apb_peripherals | UART/Timer/RCC 等外设测试 | APB 协议 90% |
| test_interrupt | NVIC 和外部中断测试 | 中断覆盖率 95% |
| test_concurrent_access | 并发访问压力测试 | 总线仲裁覆盖率 100% |

## 📈 覆盖率目标

- **代码覆盖率**: >95%
- **功能覆盖率**: >95%
- **断言覆盖率**: >90%

## 🔧 配置选项

### Makefile 变量

| 变量 | 默认值 | 说明 |
|-----|--------|------|
| SIMULATOR | questa | 仿真器 (questa/vcs/xcelium) |
| TEST | test_cpu_boot | 测试名称 |
| SEED | 1 | 随机种子 |
| WAVES | 1 | 是否生成波形 (0/1) |
| COVERAGE | 1 | 是否收集覆盖率 (0/1) |
| SIM_TIME | 100us | 仿真时间 |
| UVM_VERBOSITY | UVM_MEDIUM | UVM 详细程度 |

### UVM 配置

在 test 中可以覆盖以下配置：

```systemverilog
uvm_config_db#(int)::set(this, "env_inst", "has_scoreboard", 1);
uvm_config_db#(int)::set(this, "env_inst", "has_coverage", 1);
uvm_config_db#(int)::set(this, "env_inst.ahb_agent_inst", "is_active", UVM_ACTIVE);
```

## 🏗️ UVM 架构

```
tb_top
├── ahb_intf (virtual interface)
├── apb_intf (virtual interface)
├── DUT (cortex_m3_soc)
└── uvm_test_top
    └── env_inst
        ├── ahb_agent_inst
        │   ├── driver
        │   ├── monitor (→ coverage, scoreboard)
        │   └── sequencer
        ├── apb_agent_inst
        │   ├── driver
        │   ├── monitor (→ coverage)
        │   └── sequencer
        ├── scoreboard (检查数据完整性)
        ├── coverage_model (功能覆盖率)
        └── reg_model (寄存器抽象层)
```

## 📝 添加新测试

1. 在 `uvm/test/` 目录创建新的测试文件：

```systemverilog
class test_my_feature extends base_test;
    `uvm_component_utils(test_my_feature)
    
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        
        // 创建并运行序列
        my_seq seq = my_seq::type_id::create("seq");
        seq.start(env_inst.ahb_agent_inst.sequencer);
    endtask
endclass
```

2. 在 Makefile 的 TESTS 列表中添加测试名称

3. 运行测试：`make TEST=test_my_feature`

## ⚠️ 常见问题

### Q: 仿真器找不到 UVM 库
A: 确保设置了 `UVM_HOME` 环境变量，或在 Makefile 中添加 `-uvmhome $UVM_HOME`

### Q: 波形文件太大
A: 设置 `WAVES=0` 或限制 dump 深度：`$dumpvars(1, tb_top)`

### Q: 覆盖率收集失败
A: 确保编译时添加了 `-cover` 选项，并且所有测试都成功运行

### Q: 随机测试不稳定
A: 使用固定的 SEED 值复现问题：`make SEED=12345`

## 📄 License

Internal Use Only - Cortex-M3 SoC Project
