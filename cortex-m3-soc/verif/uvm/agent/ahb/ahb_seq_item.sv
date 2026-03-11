// ============================================================================
// 文件     : ahb_seq_item.sv
// 描述     : AHB-Lite 协议序列项
// ============================================================================

`ifndef AHB_SEQ_ITEM_SV
`define AHB_SEQ_ITEM_SV

class ahb_seq_item extends uvm_sequence_item;
    
    // AHB 信号
    rand bit [31:0]  haddr;
    rand bit [2:0]   hburst;
    rand bit [2:0]   hsize;
    rand bit [1:0]   htrans;
    rand bit         hwrite;
    rand bit [31:0]  hwdata;
    
    // 响应
    bit [31:0]       hrdata;
    bit              hready;
    bit              hresp;
    
    // 约束
    constraint addr_align_c {
        haddr[1:0] == 2'b00;  // 字对齐
    }
    
    constraint size_c {
        hsize inside {3'b010, 3'b011};  // 4 字节或 8 字节
    }
    
    constraint trans_c {
        htrans inside {2'b10, 2'b11};  // NONSEQ or SEQ
    }
    
    // UVM 宏
    `uvm_object_utils(ahb_seq_item)
    `uvm_field_int(haddr, UVM_ALL_ON)
    `uvm_field_int(hburst, UVM_ALL_ON)
    `uvm_field_int(hsize, UVM_ALL_ON)
    `uvm_field_int(htrans, UVM_ALL_ON)
    `uvm_field_int(hwrite, UVM_ALL_ON)
    `uvm_field_int(hwdata, UVM_ALL_ON)
    `uvm_field_int(hrdata, UVM_ALL_ON)
    `uvm_field_int(hready, UVM_ALL_ON)
    `uvm_field_int(hresp, UVM_ALL_ON)
    
    // 构造函数
    function new(string name = "ahb_seq_item");
        super.new(name);
    endfunction
    
    // 打印
    function string convert2string();
        return $sformatf("addr=%0h, write=%0b, wdata=%0h, rdata=%0h", 
                         haddr, hwrite, hwdata, hrdata);
    endfunction
    
endclass

`endif
