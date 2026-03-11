// ============================================================================
// 文件     : base_test.sv
// 描述     : 基础测试类
// ============================================================================

`ifndef BASE_TEST_SV
`define BASE_TEST_SV

class base_test extends uvm_test;
    
    // 环境
    env env_inst;
    
    // 虚拟接口
    virtual ahb_intf ahb_vif;
    virtual apb_intf apb_vif;
    
    // UVM 宏
    `uvm_component_utils(base_test)
    
    // 构造函数
    function new(string name = "base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // 构建阶段
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // 获取接口
        if (!uvm_config_db#(virtual ahb_intf)::get(this, "", "ahb_vif", ahb_vif)) begin
            `uvm_fatal("NOVIF", "AHB virtual interface must be set")
        end
        
        if (!uvm_config_db#(virtual apb_intf)::get(this, "", "apb_vif", apb_vif)) begin
            `uvm_fatal("NOVIF", "APB virtual interface must be set")
        end
        
        // 设置接口到配置数据库
        uvm_config_db#(virtual ahb_intf)::set(this, "env_inst.ahb_agent_inst*", "vif", ahb_vif);
        uvm_config_db#(virtual apb_intf)::set(this, "env_inst.apb_agent_inst*", "vif", apb_vif);
        
        // 创建环境
        env_inst = env::type_id::create("env_inst", this);
    endfunction
    
    // 运行阶段
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
    endtask
    
    // 报告阶段
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("TEST", "Test completed", UVM_NONE)
    endfunction
    
endclass

`endif
