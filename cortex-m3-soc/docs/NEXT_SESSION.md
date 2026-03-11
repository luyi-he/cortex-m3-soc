# Next Session 快速上手

## 📍 当前进度 (2026-03-11 12:00)

**已完成**:
- ✅ GPIO 控制器重构 (PR #1 merged)
- ✅ 单元测试 5/6 通过
- ✅ 代码已 push: https://github.com/luyi-he/cortex-m3-soc

**待完成**:
- ⏳ 修复全芯片仿真顶层端口匹配
- ⏳ 修复 GPIO IRQ 测试时序
- ⏳ 继续开发其他 APB 外设 (UART, Timer)

---

## 🚀 快速开始

### 1. 拉取代码

```bash
git clone https://github.com/luyi-he/cortex-m3-soc.git
cd cortex-m3-soc
```

### 2. 查看项目状态

```bash
cat docs/project_status.md
```

### 3. 运行 GPIO 测试

```bash
bash sim/run_gpio_test.sh
```

预期输出：
```
Passed: 5/6
✓ MODER write/read
✓ ODR write
✓ BSRR reset/set
✓ IDR read
✗ IRQ (时序小问题)
```

### 4. 查看架构文档

```bash
cat arch/arch_spec_v1.0.md
```

---

## 📁 关键文件

| 文件 | 描述 |
|------|------|
| `rtl/peripheral/gpio_ctrl.v` | GPIO 控制器（已重构） |
| `rtl/peripheral/apb_peripherals.v` | APB 外设顶层 |
| `rtl/peripheral/uart_simple.v` | UART 简化模型 |
| `tb/tb_gpio_ctrl.sv` | GPIO 测试平台 |
| `sim/run_gpio_test.sh` | 测试脚本 |
| `docs/project_status.md` | 项目状态 |
| `arch/arch_spec_v1.0.md` | 架构规格 |

---

## 🔧 下一步任务

### 优先级 1: 修复全芯片仿真

**问题**: `cortex_m3_soc.v` 顶层模块端口和底层不匹配

**需要**:
1. 检查 `rtl/top/cortex_m3_soc.v` 的实例化
2. 对照 `flash_ctrl.v`, `sram_ctrl.v`, `ahb_matrix.v`, `ahb2apb_bridge.v` 的端口定义
3. 修正端口名称和位宽

**测试**:
```bash
bash sim/run_sim.sh
```

### 优先级 2: 继续 APB 外设开发

**待开发**:
- UART 控制器（完整实现）
- Timer 控制器
- RCC 时钟控制
- PWR 电源管理

**参考**: `arch/arch_spec_v1.0.md` Section 3.x

### 优先级 3: 固件协同仿真

**目标**: 让 blinky.elf 在 RTL 仿真中跑起来

**步骤**:
1. 修改 `flash_ctrl.v` 支持 `$readmemh` 加载固件
2. 创建简化的 Cortex-M3 行为模型
3. 运行仿真观察 UART/GPIO 输出

---

## 💡 经验教训

### 已解决的问题

1. **Icarus Verilog 数组限制**
   - 问题：不支持大型数组和变量索引
   - 解决：改用独立寄存器 + case 语句

2. **GPIO 端口驱动**
   - 问题：`output reg` 导致组合逻辑问题
   - 解决：改用 `output wire` + 内部 `reg` + `assign`

3. **Git 提交包含敏感信息**
   - 问题：TOOLS.md 包含 GitHub token 被拦截
   - 解决：创建干净分支只包含 cortex-m3-soc/ 目录

---

## 📞 联系

- GitHub: https://github.com/luyi-he/cortex-m3-soc
- 有问题查看 `docs/` 目录的文档
