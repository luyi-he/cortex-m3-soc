// ============================================================================
// 文件     : ahb_monitor.sv
// 描述     : AHB-Lite 协议监控器 (带功能覆盖和断言)
// ============================================================================

`ifndef AHB_MONITOR_SV
`define AHB_MONITOR_SV

class ahb_monitor extends uvm_monitor;
    
    // Virtual Interface
    virtual ahb_intf vif;
    
    // Analysis Port
    uvm_analysis_port #(ahb_seq_item) analysis_port;
    
    // 覆盖率
    covergroup ahb_cg;
        option.per_instance = 1;
        
        // 传输类型覆盖
        HTRANS_CP: coverpoint vif.htrans {
            bins idle    = {2'b00};
            bins busy    = {2'b01};
            bins nonseq  = {2'b10};
            bins seq     = {2'b11};
        }
        
        // 传输大小覆盖
        HSIZE_CP: coverpoint vif.hsize {
            bins byte    = {3'b000};
            bins half    = {3'b001};
            bins word    = {3'b010};
        }
        
        // 突发类型覆盖
        HBURST_CP: coverpoint vif.hburst {
            bins single  = {3'b000};
            bins incr    = {3'b001};
            bins wrap4   = {3'b010};
            bins incr4   = {3'b011};
        }
        
        // 读写覆盖
        HWRITE_CP: coverpoint vif.hwrite {
            bins read    = {0};
            bins write   = {1};
        }
        
        // 交叉覆盖
        TRANS_X: cross HTRANS_CP, HWRITE_CP;
        SIZE_X:  cross HSIZE_CP, HWRITE_CP;
    endgroup
    
    // UVM 宏
    `uvm_component_utils(ahb_monitor)
    
    // 构造函数
    function new(string name = "ahb_monitor", uvm_component parent = null);
        super.new(name, parent);
        ahb_cg = new();
    endfunction
    
    // 获取接口
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ahb_intf)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "virtual interface must be set")
        end
        analysis_port = new("analysis_port", this);
    endfunction
    
    // 主循环
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            @(posedge vif.hclk);
            if (vif.hready && vif.htrans != 2'b00) begin
                sample_coverage();
                send_analysis_port();
            end
        end
    endtask
    
    // 采样覆盖率
    function void sample_coverage();
        ahb_cg.sample();
    endfunction
    
    // 发送到分析端口
    task send_analysis_port();
        ahb_seq_item tr;
        tr = ahb_seq_item::type_id::create("tr");
        tr.haddr  = vif.haddr;
        tr.hburst = vif.hburst;
        tr.hsize  = vif.hsize;
        tr.htrans = vif.htrans;
        tr.hwrite = vif.hwrite;
        tr.hwdata = vif.hwdata;
        tr.hrdata = vif.hrdata;
        tr.hready = vif.hready;
        tr.hresp  = vif.hresp;
        analysis_port.write(tr);
    endtask
    
endclass

// SVA 断言
module ahb_assertions (input hclk, input hreset_n, input hready, input [1:0] htrans);
    
    property p_htrans_valid;
        @(posedge hclk) disable iff (!hreset_n)
        hready |-> htrans != 2'b01;  // BUSY 不支持
    endproperty
    
    property p_haddr_stable;
        @(posedge hclk) disable iff (!hreset_n)
        (htrans == 2'b10 || htrans == 2'b11) && hready |-> 
        $stable(haddr);
    endproperty
    
    assert property (p_htrans_valid)
        else `uvm_error("AHB_ASSERT", "Invalid HTRANS detected")
    
    assert property (p_haddr_stable)
        else `uvm_error("AHB_ASSERT", "HADDR not stable during transfer")
    
endmodule

`endif
