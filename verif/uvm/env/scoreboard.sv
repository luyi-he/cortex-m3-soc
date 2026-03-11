// ============================================================================
// 文件     : scoreboard.sv
// 描述     : Scoreboard - 验证数据完整性
// ============================================================================

`ifndef SCOREBOARD_SV
`define SCOREBOARD_SV

class scoreboard extends uvm_scoreboard;
    
    // 期望 FIFO
    uvm_tlm_analysis_fifo #(ahb_seq_item) ahb_expected_fifo;
    
    // 实际 FIFO
    uvm_tlm_analysis_fifo #(ahb_seq_item) ahb_actual_fifo;
    
    // 错误计数
    int error_count = 0;
    
    // UVM 宏
    `uvm_component_utils(scoreboard)
    
    // 构造函数
    function new(string name = "scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // 构建阶段
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ahb_expected_fifo = new("ahb_expected_fifo", this);
        ahb_actual_fifo   = new("ahb_actual_fifo", this);
    endfunction
    
    // 运行阶段
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        fork
            check_ahb_trans();
        join
    endtask
    
    // 检查 AHB 传输
    task check_ahb_trans();
        ahb_seq_item expected_tr;
        ahb_seq_item actual_tr;
        
        forever begin
            // 获取期望和实际传输
            ahb_expected_fifo.get(expected_tr);
            ahb_actual_fifo.get(actual_tr);
            
            // 比较
            if (expected_tr.haddr !== actual_tr.haddr) begin
                `uvm_error("SB", $sformatf("Address mismatch: exp=%0h, act=%0h", 
                                           expected_tr.haddr, actual_tr.haddr))
                error_count++;
            end
            
            if (expected_tr.hwrite) begin
                // 写操作：比较写数据
                if (expected_tr.hwdata !== actual_tr.hwdata) begin
                    `uvm_error("SB", $sformatf("Write data mismatch: addr=%0h, exp=%0h, act=%0h",
                                               actual_tr.haddr, expected_tr.hwdata, actual_tr.hwdata))
                    error_count++;
                end
            end else begin
                // 读操作：比较读数据
                if (expected_tr.hrdata !== actual_tr.hrdata) begin
                    `uvm_error("SB", $sformatf("Read data mismatch: addr=%0h, exp=%0h, act=%0h",
                                               actual_tr.haddr, expected_tr.hrdata, actual_tr.hrdata))
                    error_count++;
                end
            end
            
            if (expected_tr.hresp !== actual_tr.hresp) begin
                `uvm_error("SB", $sformatf("Response mismatch: addr=%0h, exp=%0b, act=%0b",
                                           actual_tr.haddr, expected_tr.hresp, actual_tr.hresp))
                error_count++;
            end
        end
    endtask
    
    // 报告阶段
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        if (error_count == 0) begin
            `uvm_info("SB", "Scoreboard check PASSED", UVM_NONE)
        end else begin
            `uvm_error("SB", $sformatf("Scoreboard check FAILED with %0d errors", error_count))
        end
    endfunction
    
endclass

`endif
