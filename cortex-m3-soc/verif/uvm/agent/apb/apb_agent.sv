// ============================================================================
// 文件     : apb_agent.sv
// 描述     : APB Agent
// ============================================================================

`ifndef APB_AGENT_SV
`define APB_AGENT_SV

class apb_agent extends uvm_agent;
    
    // 组件
    apb_driver          driver;
    apb_monitor         monitor;
    uvm_sequencer #(apb_seq_item) sequencer;
    
    // 配置
    bit is_active = UVM_ACTIVE;
    
    // Analysis Port
    uvm_analysis_port #(apb_seq_item) analysis_port;
    
    // UVM 宏
    `uvm_component_utils(apb_agent)
    
    // 构造函数
    function new(string name = "apb_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // 构建阶段
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if (!uvm_config_db#(int)::get(this, "", "is_active", is_active)) begin
            is_active = UVM_ACTIVE;
        end
        
        monitor = apb_monitor::type_id::create("monitor", this);
        
        if (is_active == UVM_ACTIVE) begin
            driver    = apb_driver::type_id::create("driver", this);
            sequencer = uvm_sequencer#(apb_seq_item)::type_id::create("sequencer", this);
        end
    endfunction
    
    // 连接阶段
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        if (is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
        
        analysis_port = monitor.analysis_port;
    endfunction
    
endclass

`endif
