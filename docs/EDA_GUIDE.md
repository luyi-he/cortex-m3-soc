# EDA 工具使用指南

本目录包含 Cortex-M3 SoC 项目的 Formal 验证和逻辑综合脚本。

---

## 📁 目录结构

```
cortex-m3-soc/
├── formal/                 # Formal 验证
│   ├── sva/               # SystemVerilog 断言
│   │   ├── clk_gen_sva.sv
│   │   ├── rst_gen_sva.sv
│   │   └── ahb_protocol_sva.sv
│   ├── cdc_check.sby      # CDC 验证配置
│   ├── reset_check.sby    # 复位验证配置
│   ├── ahb_protocol.sby   # AHB 协议验证配置
│   └── run_formal.sh      # 运行 Formal 验证
│
├── synth/                  # 逻辑综合
│   ├── openpdk/           # 开源 PDK (SkyWater 130nm)
│   │   └── synth.tcl      # Yosys 综合脚本
│   └── run_synth.sh       # 运行综合
│
└── constraints/            # 时序约束 (待添加)
    └── timing.sdc         # SDC 约束文件
```

---

## 🔧 工具安装

### 必需工具

```bash
# macOS (Homebrew)
brew install yosys
brew install icarus-verilog
brew install verilator

# Python 包 (可选，用于 SymbiYosys)
pip3 install symbiyosys
```

### 可选工具 (商业 EDA)

如果有商业授权，可以使用：
- **Synopsys Design Compiler** - 逻辑综合
- **Synopsys PrimeTime** - 静态时序分析
- **Cadence JasperGold** - Formal 验证

---

## ✅ Formal 验证

### 验证内容

| 模块 | 验证内容 | 工具 | 状态 |
|------|---------|------|------|
| `clk_gen.v` | CDC (跨时钟域) 检查 | SymbiYosys | 🔄 待运行 |
| `rst_gen.v` | 异步复位同步释放 | SymbiYosys | 🔄 待运行 |
| `ahb_matrix.v` | AHB-Lite 协议合规 | SymbiYosys | 🔄 待运行 |

### 运行验证

```bash
cd formal

# 运行所有验证
./run_formal.sh

# 或单独运行
sby -f cdc_check.sby
sby -f reset_check.sby
sby -f ahb_protocol.sby
```

### 查看结果

```bash
# 查看验证报告
cat cdc_check/PROVE/results.txt
cat reset_check/PROVE/results.txt
cat ahb_protocol/BMC/results.txt

# 查看波形 (如果有反例)
gtkwave cdc_check/engine_0/witness.vcd
```

### 预期结果

```
✅ CDC Check PASSED
✅ Reset Check PASSED
✅ AHB Protocol Check PASSED
```

---

## 🔬 逻辑综合

### 综合目标

| 指标 | 目标 | 工艺 |
|------|------|------|
| 时钟频率 | 200MHz (5ns) | SkyWater 130nm (验证流程) |
| 面积 | <50K gates | - |
| 功耗 | <50mW | - |

**注意**: SkyWater 130nm 仅用于验证综合流程，最终目标是 TSMC 28nm HPC+

### 运行综合

```bash
cd synth

# 运行综合
./run_synth.sh
```

### 查看结果

```bash
# 查看综合报告
cat openpdk/output/report.txt

# 查看门级网表
head -100 openpdk/output/cortex_m3_soc_gate.v

# 查看日志
tail -50 openpdk/output/synth.log
```

### 输出文件

- `cortex_m3_soc_gate.v` - 门级网表
- `report.txt` - 综合报告 (面积/利用率)
- `report.json` - JSON 格式统计
- `synth.log` - 完整日志

---

## 📊 时序约束 (待添加)

### SDC 约束文件

```tcl
# constraints/timing.sdc

# 时钟定义
create_clock -period 5.0 -name hclk [get_ports hclk]
create_clock -period 10.0 -name pclk [get_ports pclk]

# 输入延迟
set_input_delay -clock hclk 1.0 [all_inputs]

# 输出延迟
set_output_delay -clock hclk 2.0 [all_outputs]

# 虚假路径
set_false_path -from [get_cells -hierarchical *debug*]

# 多周期路径
set_multicycle_path -setup 2 -from [get_cells -hierarchical *slow_path*]
```

---

## 🐛 故障排查

### SymbiYosys 验证失败

**问题**: `assertion failed`

**解决**:
1. 检查 `results.txt` 中的反例 (counter-example)
2. 查看 `witness.vcd` 波形
3. 修复 RTL 代码或调整断言

### Yosys 综合失败

**问题**: `module not found`

**解决**:
```bash
# 检查 RTL 文件路径
ls rtl/base/*.v
ls rtl/peripheral/*.v

# 检查模块名是否匹配
grep "module cortex_m3_soc" rtl/top/cortex_m3_soc.v
```

### 面积过大

**问题**: 综合后门数超过目标

**解决**:
1. 优化 RTL 代码 (减少寄存器/组合逻辑)
2. 调整综合策略 (`opt` 选项)
3. 使用更激进的优化 (`opt -fast`)

---

## 📚 参考资料

### 开源工具
- [Yosys Documentation](http://www.clifford.at/yosys/)
- [SymbiYosys Guide](https://symbiyosys.readthedocs.io/)
- [SkyWater 130nm PDK](https://github.com/google/skywater-pdk)

### Formal 验证
- [Formal Verification Wikipedia](https://en.wikipedia.org/wiki/Formal_verification)
- [Model Checking](https://en.wikipedia.org/wiki/Model_checking)
- [SystemVerilog Assertions](https://www.systemverilog.io/)

### 逻辑综合
- [Logic Synthesis Wikipedia](https://en.wikipedia.org/wiki/Logic_synthesis)
- [Static Timing Analysis](https://en.wikipedia.org/wiki/Static_timing_analysis)

---

## 📝 下一步

1. **完善 SVA 断言** - 添加更多模块的断言 (UART/Timer/Flash)
2. **运行 Formal 验证** - 执行所有验证任务
3. **添加时序约束** - 创建完整的 SDC 文件
4. **优化综合结果** - 调整策略达到 200MHz 目标
5. **迁移到 28nm PDK** - 如果有 TSMC 28nm 授权

---

**状态**: 🔄 Formal 验证环境搭建完成，待运行  
**最后更新**: 2026-03-12
