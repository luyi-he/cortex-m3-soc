// ============================================================================
// 文件     : apb_monitor.sv
// 描述     : APB 协议监控器
// ============================================================================

`ifndef APB_MONITOR_SV
`define APB_MONITOR_SV

class apb_monitor extends uvm_monitor;
    
    // Virtual Interface
    virtual apb_intf vif;
    
    // Analysis Port
    uvm_analysis_port #(apb_seq_item) analysis_port;
    
    // 覆盖率
    covergroup apb_cg;
        option.per_instance = 1;
        
        PWRITE_CP: coverpoint vif.pwrite {
            bins read  = {0};
            bins write = {1};
        }
        
        PADDR_CP: coverpoint vif.paddr[11:8] {
            bins gpio     = {4'h0};
            bins uart     = {4'h1};
            bins timer    = {4'h2};
            bins wdt_rtc  = {4'h3};
            bins i2c_spi  = {4'h5};
            bins adc_dac  = {4'h7};
            bins ctrl     = {4'hA};
        }
        
        cross PWRITE_CP, PADDR_CP;
    endgroup
    
    // UVM 宏
    `uvm_component_utils(apb_monitor)
    
    // 构造函数
    function new(string name = "apb_monitor", uvm_component parent = null);
        super.new(name, parent);
        apb_cg = new();
    endfunction
    
    // 获取接口
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb_intf)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "virtual interface must be set")
        end
        analysis_port = new("analysis_port", this);
    endfunction
    
    // 主循环
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            @(posedge vif.pclk);
            if (vif.psel && vif.penable && vif.pready) begin
                sample_coverage();
                send_analysis_port();
            end
        end
    endtask
    
    // 采样覆盖率
    function void sample_coverage();
        apb_cg.sample();
    endfunction
    
    // 发送到分析端口
    task send_analysis_port();
        apb_seq_item tr;
        tr = apb_seq_item::type_id::create("tr");
        tr.paddr  = vif.paddr;
        tr.pwrite = vif.pwrite;
        tr.pwdata = vif.pwdata;
        tr.prdata = vif.prdata;
        tr.pready = vif.pready;
        tr.pslverr = vif.pslverr;
        analysis_port.write(tr);
    endtask
    
endclass

`endif
