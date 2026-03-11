// ============================================================================
// 文件     : apb_driver.sv
// 描述     : APB 协议驱动器
// ============================================================================

`ifndef APB_DRIVER_SV
`define APB_DRIVER_SV

class apb_driver extends uvm_driver #(apb_seq_item);
    
    // Virtual Interface
    virtual apb_intf vif;
    
    // UVM 宏
    `uvm_component_utils(apb_driver)
    
    // 构造函数
    function new(string name = "apb_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // 获取接口
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb_intf)::get(this, "", "vif", vif)) begin
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
    task drive_transfer(apb_seq_item tr);
        // Setup 相位
        @(posedge vif.pclk);
        vif.paddr   <= tr.paddr;
        vif.psel    <= 1'b1;
        vif.penable <= 1'b0;
        vif.pwrite  <= tr.pwrite;
        vif.pwdata  <= tr.pwdata;
        
        // Access 相位
        @(posedge vif.pclk);
        vif.penable <= 1'b1;
        
        // 等待 PREADY
        while (!vif.pready) begin
            @(posedge vif.pclk);
        end
        
        // 采样响应
        tr.prdata  = vif.prdata;
        tr.pready  = vif.pready;
        tr.pslverr = vif.pslverr;
        
        // 返回 IDLE
        @(posedge vif.pclk);
        vif.psel    <= 1'b0;
        vif.penable <= 1'b0;
    endtask
    
endclass

`endif
