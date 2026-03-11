// ============================================================================
// 文件     : ahb_seq_lib.sv
// 描述     : AHB-Lite 序列库
// ============================================================================

`ifndef AHB_SEQ_LIB_SV
`define AHB_SEQ_LIB_SV

// 基础序列
class ahb_base_seq extends uvm_sequence #(ahb_seq_item);
    
    `uvm_object_utils(ahb_base_seq)
    
    function new(string name = "ahb_base_seq");
        super.new(name);
    endfunction
    
    virtual task body();
        `uvm_fatal("NOT_IMPLEMENTED", "body() not implemented")
    endtask
    
endclass

// 单次读序列
class ahb_read_seq extends ahb_base_seq;
    
    rand bit [31:0] addr;
    
    constraint addr_c {
        addr[1:0] == 2'b00;
    }
    
    `uvm_object_utils(ahb_read_seq)
    
    function new(string name = "ahb_read_seq");
        super.new(name);
    endfunction
    
    virtual task body();
        req = ahb_seq_item::type_id::create("req");
        
        start_item(req);
        assert(req.randomize() with {
            haddr == addr;
            hwrite == 1'b0;
            htrans == 2'b10;
        });
        finish_item(req);
        
        `uvm_info(get_type_name(), $sformatf("Read addr=%0h, data=%0h", req.haddr, req.hrdata), UVM_MEDIUM)
    endtask
    
endclass

// 单次写序列
class ahb_write_seq extends ahb_base_seq;
    
    rand bit [31:0] addr;
    rand bit [31:0] data;
    
    constraint addr_c {
        addr[1:0] == 2'b00;
    }
    
    `uvm_object_utils(ahb_write_seq)
    
    function new(string name = "ahb_write_seq");
        super.new(name);
    endfunction
    
    virtual task body();
        req = ahb_seq_item::type_id::create("req");
        
        start_item(req);
        assert(req.randomize() with {
            haddr == addr;
            hwrite == 1'b1;
            htrans == 2'b10;
            hwdata == data;
        });
        finish_item(req);
        
        `uvm_info(get_type_name(), $sformatf("Write addr=%0h, data=%0h", req.haddr, req.hwdata), UVM_MEDIUM)
    endtask
    
endclass

// 突发读序列
class ahb_burst_read_seq extends ahb_base_seq;
    
    rand bit [31:0] start_addr;
    rand int        burst_len;
    
    constraint burst_c {
        burst_len inside {[4:16]};
        start_addr[3:0] == 4'b0000;
    }
    
    `uvm_object_utils(ahb_burst_read_seq)
    
    function new(string name = "ahb_burst_read_seq");
        super.new(name);
    endfunction
    
    virtual task body();
        for (int i = 0; i < burst_len; i++) begin
            req = ahb_seq_item::type_id::create("req");
            
            start_item(req);
            assert(req.randomize() with {
                haddr == start_addr + (i * 4);
                hwrite == 1'b0;
                htrans == (i == 0) ? 2'b10 : 2'b11;  // First NONSEQ, rest SEQ
                hburst == (i == 0) ? 3'b011 : 3'b000;  // INCR4 on first
            });
            finish_item(req);
        end
    endtask
    
endclass

// 突发写序列
class ahb_burst_write_seq extends ahb_base_seq;
    
    rand bit [31:0] start_addr;
    rand int        burst_len;
    rand bit [31:0] data[];
    
    constraint burst_c {
        burst_len inside {[4:16]};
        data.size() == burst_len;
        start_addr[3:0] == 4'b0000;
    }
    
    `uvm_object_utils(ahb_burst_write_seq)
    
    function new(string name = "ahb_burst_write_seq");
        super.new(name);
    endfunction
    
    virtual task body();
        for (int i = 0; i < burst_len; i++) begin
            req = ahb_seq_item::type_id::create("req");
            
            start_item(req);
            assert(req.randomize() with {
                haddr == start_addr + (i * 4);
                hwrite == 1'b1;
                htrans == (i == 0) ? 2'b10 : 2'b11;
                hburst == (i == 0) ? 3'b011 : 3'b000;
                hwdata == data[i];
            });
            finish_item(req);
        end
    endtask
    
endclass

`endif
