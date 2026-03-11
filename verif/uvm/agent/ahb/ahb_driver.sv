// ============================================================================
// 文件     : ahb_driver.sv
// 描述     : AHB-Lite 协议驱动器
// ============================================================================

`ifndef AHB_DRIVER_SV
`define AHB_DRIVER_SV

class ahb_driver extends uvm_driver #(ahb_seq_item);
    
    // Virtual Interface
    virtual ahb_intf vif;
    
    // UVM 宏
    `uvm_component_utils(ahb_driver)
    
    // 构造函数
    function new(string name = "ahb_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // 从配置数据库获取接口
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ahb_intf)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "virtual interface must be set")
        end
    endfunction
    
    // 主循环
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            seq_item_port.get_next_item(req);
            drive_transfer(req);
            seq_item_port.item_done();
        end
    endtask
    
    // 驱动单次传输
    task drive_transfer(ahb_seq_item tr);
        @(posedge vif.hclk);
        vif.haddr   <= tr.haddr;
        vif.hburst  <= tr.hburst;
        vif.hsize   <= tr.hsize;
        vif.htrans  <= tr.htrans;
        vif.hwrite  <= tr.hwrite;
        vif.hwdata  <= tr.hwdata;
        
        // 等待 HREADY
        while (!vif.hready) begin
            @(posedge vif.hclk);
        end
        
        // 采样响应
        @(posedge vif.hclk);
        tr.hrdata = vif.hrdata;
        tr.hready = vif.hready;
        tr.hresp  = vif.hresp;
        
        // 返回 IDLE
        vif.htrans <= 2'b00;
    endtask
    
endclass

`endif
