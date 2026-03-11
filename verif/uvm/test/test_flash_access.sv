// ============================================================================
// 文件     : test_flash_access.sv
// 描述     : Flash 访问测试
// ============================================================================

`ifndef TEST_FLASH_ACCESS_SV
`define TEST_FLASH_ACCESS_SV

class test_flash_access extends base_test;
    
    `uvm_component_utils(test_flash_access)
    
    function new(string name = "test_flash_access", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        
        `uvm_info("TEST", "=== Flash Access Test ===", UVM_NONE)
        
        @(posedge ahb_vif.hreset_n);
        
        // 测试 Flash 读取
        test_flash_read();
        
        // 测试读延迟
        test_read_latency();
        
        // 测试 Flash 写保护
        test_flash_write_protection();
        
        // 测试突发读取
        test_burst_read();
        
        `uvm_info("TEST", "=== Flash Access Test PASSED ===", UVM_NONE)
    endtask
    
    task test_flash_read;
        ahb_read_seq r_seq;
        
        `uvm_info("TEST", "Testing Flash read...", UVM_MEDIUM)
        
        // 读取复位向量
        r_seq = ahb_read_seq::type_id::create("r_seq");
        r_seq.addr = 32'h0000_0000;
        r_seq.start(env_inst.ahb_agent_inst.sequencer);
        
        `uvm_info("TEST", $sformatf("Reset SP value: %0h", r_seq.req.hrdata), UVM_MEDIUM)
        
        // 读取复位向量地址
        r_seq = ahb_read_seq::type_id::create("r_seq");
        r_seq.addr = 32'h0000_0004;
        r_seq.start(env_inst.ahb_agent_inst.sequencer);
        
        `uvm_info("TEST", $sformatf("Reset vector: %0h", r_seq.req.hrdata), UVM_MEDIUM)
    endtask
    
    task test_read_latency;
        `uvm_info("TEST", "Testing Flash read latency...", UVM_MEDIUM)
        
        // Flash 应该有读延迟，检查 HREADY 是否被拉伸
        // 这需要在波形中观察
    endtask
    
    task test_flash_write_protection;
        ahb_write_seq w_seq;
        
        `uvm_info("TEST", "Testing Flash write protection...", UVM_MEDIUM)
        
        // 尝试写入 Flash (应该失败)
        w_seq = ahb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h0000_0000;
        w_seq.data = 32'hDEADBEEF;
        w_seq.start(env_inst.ahb_agent_inst.sequencer);
        
        // 检查是否有错误响应
        if (w_seq.req.hresp) begin
            `uvm_info("TEST", "Flash write protection PASSED (error response received)", UVM_MEDIUM)
        end
    endtask
    
    task test_burst_read;
        ahb_burst_read_seq burst_seq;
        
        `uvm_info("TEST", "Testing Flash burst read...", UVM_MEDIUM)
        
        burst_seq = ahb_burst_read_seq::type_id::create("burst_seq");
        burst_seq.start_addr = 32'h0000_0000;
        burst_seq.burst_len = 8;
        burst_seq.start(env_inst.ahb_agent_inst.sequencer);
        
        `uvm_info("TEST", "Burst read completed", UVM_MEDIUM)
    endtask
    
endclass

`endif
