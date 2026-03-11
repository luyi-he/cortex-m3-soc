// ============================================================================
// 文件     : env.sv
// 描述     : UVM 顶层环境
// ============================================================================

`ifndef ENV_SV
`define ENV_SV

class env extends uvm_env;
    
    // 组件
    ahb_agent       ahb_agent_inst;
    apb_agent       apb_agent_inst;
    scoreboard      sb;
    coverage_model  cov;
    soc_reg_model   reg_model;
    
    // 配置
    bit has_scoreboard = 1;
    bit has_coverage   = 1;
    
    // UVM 宏
    `uvm_component_utils(env)
    
    // 构造函数
    function new(string name = "env", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // 构建阶段
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // 获取配置
        uvm_config_db#(int)::get(this, "", "has_scoreboard", has_scoreboard);
        uvm_config_db#(int)::get(this, "", "has_coverage", has_coverage);
        
        // 创建 Agent
        ahb_agent_inst = ahb_agent::type_id::create("ahb_agent_inst", this);
        apb_agent_inst = apb_agent::type_id::create("apb_agent_inst", this);
        
        // 创建 Scoreboard
        if (has_scoreboard) begin
            sb = scoreboard::type_id::create("sb", this);
        end
        
        // 创建 Coverage
        if (has_coverage) begin
            cov = coverage_model::type_id::create("cov", this);
        end
        
        // 创建寄存器模型
        reg_model = soc_reg_model::type_id::create("reg_model", this);
        reg_model.build();
        reg_model.lock_model();
    endfunction
    
    // 连接阶段
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // 连接 Agent 到 Scoreboard
        if (has_scoreboard) begin
            ahb_agent_inst.analysis_port.connect(sb.ahb_actual_fifo.analysis_export);
        end
        
        // 连接 Agent 到 Coverage
        if (has_coverage) begin
            ahb_agent_inst.analysis_port.connect(cov.analysis_export);
            apb_agent_inst.analysis_port.connect(cov.analysis_export_apb);
        end
    endfunction
    
    // 运行阶段
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
    endtask
    
    // 报告阶段
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        if (has_coverage) begin
            cov.report_coverage();
        end
    endfunction
    
endclass

`endif
