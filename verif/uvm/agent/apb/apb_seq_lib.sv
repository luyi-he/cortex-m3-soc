// ============================================================================
// 文件     : apb_seq_lib.sv
// 描述     : APB 序列库
// ============================================================================

`ifndef APB_SEQ_LIB_SV
`define APB_SEQ_LIB_SV

// 基础序列
class apb_base_seq extends uvm_sequence #(apb_seq_item);
    
    `uvm_object_utils(apb_base_seq)
    
    function new(string name = "apb_base_seq");
        super.new(name);
    endfunction
    
    virtual task body();
        `uvm_fatal("NOT_IMPLEMENTED", "body() not implemented")
    endtask
    
endclass

// 读寄存器序列
class apb_read_seq extends apb_base_seq;
    
    rand bit [31:0] addr;
    
    `uvm_object_utils(apb_read_seq)
    
    function new(string name = "apb_read_seq");
        super.new(name);
    endfunction
    
    virtual task body();
        req = apb_seq_item::type_id::create("req");
        
        start_item(req);
        assert(req.randomize() with {
            paddr == addr;
            pwrite == 1'b0;
        });
        finish_item(req);
        
        `uvm_info(get_type_name(), $sformatf("APB Read addr=%0h, data=%0h", req.paddr, req.prdata), UVM_MEDIUM)
    endtask
    
endclass

// 写寄存器序列
class apb_write_seq extends apb_base_seq;
    
    rand bit [31:0] addr;
    rand bit [31:0] data;
    
    `uvm_object_utils(apb_write_seq)
    
    function new(string name = "apb_write_seq");
        super.new(name);
    endfunction
    
    virtual task body();
        req = apb_seq_item::type_id::create("req");
        
        start_item(req);
        assert(req.randomize() with {
            paddr == addr;
            pwrite == 1'b1;
            pwdata == data;
        });
        finish_item(req);
        
        `uvm_info(get_type_name(), $sformatf("APB Write addr=%0h, data=%0h", req.paddr, req.pwdata), UVM_MEDIUM)
    endtask
    
endclass

// 配置序列
class apb_config_seq extends apb_base_seq;
    
    bit [31:0] addr;
    bit [31:0] data;
    
    `uvm_object_utils(apb_config_seq)
    
    function new(string name = "apb_config_seq");
        super.new(name);
    endfunction
    
    virtual task body();
        req = apb_seq_item::type_id::create("req");
        
        start_item(req);
        assert(req.randomize() with {
            paddr == addr;
            pwrite == 1'b1;
            pwdata == data;
        });
        finish_item(req);
    endtask
    
endclass

`endif
