// ============================================================================
// 文件     : apb_seq_item.sv
// 描述     : APB 协议序列项
// ============================================================================

`ifndef APB_SEQ_ITEM_SV
`define APB_SEQ_ITEM_SV

class apb_seq_item extends uvm_sequence_item;
    
    // APB 信号
    rand bit [31:0]  paddr;
    rand bit         pwrite;
    rand bit [31:0]  pwdata;
    
    // 响应
    bit [31:0]       prdata;
    bit              pready;
    bit              pslverr;
    
    // 约束
    constraint addr_align_c {
        paddr[1:0] == 2'b00;  // 字对齐
    }
    
    // UVM 宏
    `uvm_object_utils(apb_seq_item)
    `uvm_field_int(paddr, UVM_ALL_ON)
    `uvm_field_int(pwrite, UVM_ALL_ON)
    `uvm_field_int(pwdata, UVM_ALL_ON)
    `uvm_field_int(prdata, UVM_ALL_ON)
    `uvm_field_int(pready, UVM_ALL_ON)
    `uvm_field_int(pslverr, UVM_ALL_ON)
    
    // 构造函数
    function new(string name = "apb_seq_item");
        super.new(name);
    endfunction
    
    // 打印
    function string convert2string();
        return $sformatf("addr=%0h, write=%0b, wdata=%0h, rdata=%0h", 
                         paddr, pwrite, pwdata, prdata);
    endfunction
    
endclass

`endif
