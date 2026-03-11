# Cortex-M3 SoC AI 团队

**项目**: Cortex-M3 SoC @ 28nm  
**创建日期**: 2026-03-10  
**团队状态**: 🟢 活跃

---

## 团队成员

| 角色 | Agent ID | 会话 Key | 状态 | 职责 |
|------|----------|----------|------|------|
| 🏗️ 架构师 | architect | `agent:main:subagent:dd1d94b7-...` | 🟢 活跃 | 架构规格、地址映射、评审 |
| 🔧 RTL 工程师 | rtl-designer | `agent:main:subagent:98c74a54-...` | 🟢 活跃 | Verilog 编码、模块集成 |
| 🔬 验证工程师 | verification-engineer | `agent:main:subagent:52316b6c-...` | 🟢 活跃 | 测试平台、覆盖率、回归 |
| 📐 后端工程师 | backend-engineer | `agent:main:subagent:9575d2ae-...` | 🟢 活跃 | 综合、布局布线、时序签核 |
| ✅ Sign-off 工程师 | signoff-engineer | `agent:main:subagent:e988d1ea-...` | 🟢 活跃 | DRC/LVS、功耗签核 |

---

## 如何与团队成员沟通

### 方式 1：通过主 agent 转发

```
告诉 main agent："让架构师检查地址映射"
main agent → sessions_send → architect
```

### 方式 2：直接会话 ID

每个子 agent 有独立的会话 key，可以直接发送消息：
```
sessions_send(sessionKey="<agent 的会话 key>", message="...")
```

### 方式 3：任务分配

```
sessions_spawn 创建新任务 → 子 agent 执行 → 结果返回
```

---

## 团队协作流程

```
┌─────────────────────────────────────────────────────────────┐
│                      Main Agent (协调者)                      │
│                         🦞 小龙虾                              │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐   ┌─────────────────┐   ┌───────────────┐
│   架构师       │──▶│   RTL 工程师     │──▶│  验证工程师    │
│  (architect)  │   │ (rtl-designer)  │   │(verification) │
└───────────────┘   └─────────────────┘   └───────────────┘
                           │                     │
                           ▼                     ▼
                  ┌─────────────────┐   ┌───────────────┐
                  │   后端工程师     │──▶│ Sign-off 工程师 │
                  │(backend-engineer)│   │ (signoff)     │
                  └─────────────────┘   └───────────────┘
```

---

## 当前任务分配

### 架构师 (architect)
- ✅ 架构规格 v1.0 完成
- ⏳ 等待 RTL 评审请求
- ⏳ 协助后端评估面积预算

### RTL 工程师 (rtl-designer)
- ✅ 基础模块完成 (clk_gen, rst_gen, gpio_ctrl)
- 🔄 开发中：AHB Matrix, AHB2APB Bridge
- ⏳ 待开发：SRAM/Flash 控制器、UART、Timer、NVIC

### 验证工程师 (verification-engineer)
- ✅ 测试平台框架完成
- ⏳ 待编写：clk_gen/rst_gen/gpio_ctrl 测试用例
- ⏳ 待搭建：UVM 环境

### 后端工程师 (backend-engineer)
- ✅ 约束文档完成
- ⏳ 待评估：clk_gen/rst_gen/gpio_ctrl 综合
- ⏳ 待输出：Floorplan、综合脚本

### Sign-off 工程师 (signoff-engineer)
- ⏳ 早期阶段，待 RTL 冻结后介入
- 📚 熟悉项目规格和签核要求

---

## 会话管理

### 查看子 agent 状态
```bash
subagents action=list
```

### 给子 agent 发送消息
```bash
sessions_send label="architect" message="请检查 AHB 地址映射"
```

### 创建新任务
```bash
sessions_spawn agentId="main" label="new-task" task="..."
```

### 结束子 agent 会话
```bash
subagents action=kill target="<session-key>"
```

---

## 项目工作区

**根目录**: `~/.openclaw/workspace/cortex-m3-soc/`

```
cortex-m3-soc/
├── arch/                    # 架构文档 (架构师负责)
│   └── arch_spec_v1.0.md
├── rtl/                     # RTL 代码 (RTL 工程师负责)
│   ├── base/
│   │   ├── clk_gen.v
│   │   └── rst_gen.v
│   ├── peripheral/
│   │   └── gpio_ctrl.v
│   └── top/
│       └── cortex_m3_soc.v
├── verif/                   # 验证环境 (验证工程师负责)
│   └── tb/
│       └── tb_cortex_m3_soc.sv
├── backend/                 # 后端约束 (后端工程师负责)
│   └── backend_constraints.md
└── docs/                    # 项目文档 (共同维护)
    ├── project_plan.md
    ├── rtl_design_guide.md
    ├── project_status.md
    └── team.md
```

---

## 沟通记录

| 时间 | 发起者 | 接收者 | 内容 | 状态 |
|------|--------|--------|------|------|
| 2026-03-10 21:00 | Main | All | 团队组建完成 | ✅ |

---

**团队规模**: 5 个子 agent  
**总会话数**: 5  
**活跃会话**: 5
