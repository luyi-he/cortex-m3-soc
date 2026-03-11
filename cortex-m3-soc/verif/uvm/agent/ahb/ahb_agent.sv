// ============================================================================
// 文件     : ahb_agent.sv
// 描述     : AHB-Lite Agent (包含 Driver, Monitor, Sequencer)
// ============================================================================

`ifndef AHB_AGENT_SV
`define AHB_AGENT_SV

class ahb_agent extends uvm_agent;
    
    // 组件
    ahb_driver    driver;
    ahb_monitor   monitor;
    uvm_sequencer #(ahb_seq_item) sequencer;
    
    // 配置
    bit is_active = UVM_ACTIVE;
    
    // Analysis Port (从 monitor 透出)
    uvm_analysis_port #(ahb_seq_item) analysis_port;
    
    // UVM 宏
    `uvm_component_utils(ahb_agent)
    
    // 构造函数
    function new(string name = "ahb_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // 构建阶段
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // 获取配置
        if (!uvm_config_db#(int)::get(this, "", "is_active", is_active)) begin
            is_active = UVM_ACTIVE;
        end
        
        // 创建 Monitor (总是激活)
        monitor = ahb_monitor::type_id::create("monitor", this);
        
        // 如果是 Active，创建 Driver 和 Sequencer
        if (is_active == UVM_ACTIVE) begin
            driver    = ahb_driver::type_id::create("driver", this);
            sequencer = uvm_sequencer#(ahb_seq_item)::type_id::create("sequencer", this);
        end
    endfunction
    
    // 连接阶段
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // 连接 Driver 到 Sequencer
        if (is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
        
        // 透出 Monitor 的 Analysis Port
        analysis_port = monitor.analysis_port;
    endfunction
    
    // 运行阶段
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
    endtask
    
endclass

`endif
