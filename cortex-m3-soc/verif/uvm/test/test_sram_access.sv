// ============================================================================
// 文件     : test_sram_access.sv
// 描述     : SRAM 访问测试
// ============================================================================

`ifndef TEST_SRAM_ACCESS_SV
`define TEST_SRAM_ACCESS_SV

class test_sram_access extends base_test;
    
    `uvm_component_utils(test_sram_access)
    
    function new(string name = "test_sram_access", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        
        `uvm_info("TEST", "=== SRAM Access Test ===", UVM_NONE)
        
        @(posedge ahb_vif.hreset_n);
        
        // 测试不同大小的访问
        test_byte_access();
        test_halfword_access();
        test_word_access();
        
        // 测试边界对齐
        test_alignment();
        
        // 测试全 SRAM 范围
        test_full_range();
        
        `uvm_info("TEST", "=== SRAM Access Test PASSED ===", UVM_NONE)
    endtask
    
    task test_byte_access;
        ahb_write_seq w_seq;
        ahb_read_seq  r_seq;
        
        `uvm_info("TEST", "Testing byte access...", UVM_MEDIUM)
        
        w_seq = ahb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h2000_0000;
        w_seq.data = 32'h0000_00FF;
        w_seq.start(env_inst.ahb_agent_inst.sequencer);
        
        r_seq = ahb_read_seq::type_id::create("r_seq");
        r_seq.addr = 32'h2000_0000;
        r_seq.start(env_inst.ahb_agent_inst.sequencer);
    endtask
    
    task test_halfword_access;
        ahb_write_seq w_seq;
        ahb_read_seq  r_seq;
        
        `uvm_info("TEST", "Testing halfword access...", UVM_MEDIUM)
        
        w_seq = ahb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h2000_0000;
        w_seq.data = 32'h0000_FFFF;
        w_seq.start(env_inst.ahb_agent_inst.sequencer);
        
        r_seq = ahb_read_seq::type_id::create("r_seq");
        r_seq.addr = 32'h2000_0000;
        r_seq.start(env_inst.ahb_agent_inst.sequencer);
    endtask
    
    task test_word_access;
        ahb_write_seq w_seq;
        ahb_read_seq  r_seq;
        
        `uvm_info("TEST", "Testing word access...", UVM_MEDIUM)
        
        w_seq = ahb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h2000_0000;
        w_seq.data = 32'hFFFF_FFFF;
        w_seq.start(env_inst.ahb_agent_inst.sequencer);
        
        r_seq = ahb_read_seq::type_id::create("r_seq");
        r_seq.addr = 32'h2000_0000;
        r_seq.start(env_inst.ahb_agent_inst.sequencer);
    endtask
    
    task test_alignment;
        `uvm_info("TEST", "Testing alignment...", UVM_MEDIUM)
        
        // 测试 SRAM 起始地址
        test_addr(32'h2000_0000);
        
        // 测试 SRAM 中间地址
        test_addr(32'h2001_0000);
        
        // 测试 SRAM 结束地址
        test_addr(32'h2001_FFFC);
    endtask
    
    task test_addr(bit [31:0] addr);
        ahb_write_seq w_seq;
        ahb_read_seq  r_seq;
        
        w_seq = ahb_write_seq::type_id::create("w_seq");
        w_seq.addr = addr;
        w_seq.data = addr;  // 写入地址作为数据
        w_seq.start(env_inst.ahb_agent_inst.sequencer);
        
        r_seq = ahb_read_seq::type_id::create("r_seq");
        r_seq.addr = addr;
        r_seq.start(env_inst.ahb_agent_inst.sequencer);
        
        if (r_seq.req.hrdata !== addr) begin
            `uvm_error("TEST", $sformatf("Addr %0h: exp=%0h, act=%0h", addr, addr, r_seq.req.hrdata))
        end
    endtask
    
    task test_full_range;
        `uvm_info("TEST", "Testing full SRAM range...", UVM_MEDIUM)
        
        // 简化测试：只测试几个关键点
        test_addr(32'h2000_0000);
        test_addr(32'h2000_4000);
        test_addr(32'h2000_8000);
        test_addr(32'h2000_C000);
        test_addr(32'h2001_0000);
        test_addr(32'h2001_4000);
        test_addr(32'h2001_8000);
        test_addr(32'h2001_C000);
        test_addr(32'h2001_FFFC);
    endtask
    
endclass

`endif
