// ============================================================================
// 文件     : test_ahb_read_write.sv
// 描述     : AHB 读写测试
// ============================================================================

`ifndef TEST_AHB_READ_WRITE_SV
`define TEST_AHB_READ_WRITE_SV

class test_ahb_read_write extends base_test;
    
    `uvm_component_utils(test_ahb_read_write)
    
    function new(string name = "test_ahb_read_write", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        
        `uvm_info("TEST", "=== AHB Read/Write Test ===", UVM_NONE)
        
        // 等待复位
        @(posedge ahb_vif.hreset_n);
        
        // 创建序列
        ahb_write_seq write_seq;
        ahb_read_seq  read_seq;
        
        // 测试 SRAM 写入
        `uvm_info("TEST", "Writing to SRAM...", UVM_MEDIUM)
        write_seq = ahb_write_seq::type_id::create("write_seq");
        write_seq.addr = 32'h2000_0000;
        write_seq.data = 32'hDEADBEEF;
        write_seq.start(env_inst.ahb_agent_inst.sequencer);
        
        // 测试 SRAM 读取
        `uvm_info("TEST", "Reading from SRAM...", UVM_MEDIUM)
        read_seq = ahb_read_seq::type_id::create("read_seq");
        read_seq.addr = 32'h2000_0000;
        read_seq.start(env_inst.ahb_agent_inst.sequencer);
        
        // 验证数据
        if (read_seq.req.hrdata === 32'hDEADBEEF) begin
            `uvm_info("TEST", "SRAM data verification PASSED", UVM_NONE)
        end else begin
            `uvm_error("TEST", $sformatf("SRAM data mismatch: exp=%0h, act=%0h", 
                                         32'hDEADBEEF, read_seq.req.hrdata))
        end
        
        // 测试多个地址
        for (int i = 0; i < 10; i++) begin
            write_seq = ahb_write_seq::type_id::create("write_seq");
            write_seq.addr = 32'h2000_0000 + (i * 4);
            write_seq.data = i * 32'h1111_1111;
            write_seq.start(env_inst.ahb_agent_inst.sequencer);
        end
        
        // 读回验证
        for (int i = 0; i < 10; i++) begin
            read_seq = ahb_read_seq::type_id::create("read_seq");
            read_seq.addr = 32'h2000_0000 + (i * 4);
            read_seq.start(env_inst.ahb_agent_inst.sequencer);
            
            if (read_seq.req.hrdata !== i * 32'h1111_1111) begin
                `uvm_error("TEST", $sformatf("Data mismatch at addr %0h", 32'h2000_0000 + (i * 4)))
            end
        end
        
        `uvm_info("TEST", "=== AHB Read/Write Test PASSED ===", UVM_NONE)
    endtask
    
endclass

`endif
