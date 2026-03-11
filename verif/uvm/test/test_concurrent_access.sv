// ============================================================================
// 文件     : test_concurrent_access.sv
// 描述     : 并发访问压力测试
// ============================================================================

`ifndef TEST_CONCURRENT_ACCESS_SV
`define TEST_CONCURRENT_ACCESS_SV

class test_concurrent_access extends base_test;
    
    `uvm_component_utils(test_concurrent_access)
    
    function new(string name = "test_concurrent_access", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        
        `uvm_info("TEST", "=== Concurrent Access Stress Test ===", UVM_NONE)
        
        @(posedge ahb_vif.hreset_n);
        
        // 并发 AHB 读写
        fork
            ahb_write_stress();
            ahb_read_stress();
        join
        
        // 并发 AHB 和 APB 访问
        fork
            ahb_access();
            apb_access();
        join
        
        // 多主设备压力测试
        multi_master_stress();
        
        `uvm_info("TEST", "=== Concurrent Access Stress Test PASSED ===", UVM_NONE)
    endtask
    
    task ahb_write_stress;
        ahb_write_seq w_seq;
        
        `uvm_info("TEST", "AHB write stress test...", UVM_MEDIUM)
        
        for (int i = 0; i < 100; i++) begin
            w_seq = ahb_write_seq::type_id::create("w_seq");
            w_seq.addr = 32'h2000_0000 + (i * 4);
            w_seq.data = $random;
            w_seq.start(env_inst.ahb_agent_inst.sequencer);
        end
    endtask
    
    task ahb_read_stress;
        ahb_read_seq r_seq;
        
        `uvm_info("TEST", "AHB read stress test...", UVM_MEDIUM)
        
        for (int i = 0; i < 100; i++) begin
            r_seq = ahb_read_seq::type_id::create("r_seq");
            r_seq.addr = 32'h2000_0000 + (i * 4);
            r_seq.start(env_inst.ahb_agent_inst.sequencer);
        end
    endtask
    
    task ahb_access;
        ahb_write_seq w_seq;
        ahb_read_seq  r_seq;
        
        `uvm_info("TEST", "AHB concurrent access...", UVM_MEDIUM)
        
        for (int i = 0; i < 50; i++) begin
            if (i % 2 == 0) begin
                w_seq = ahb_write_seq::type_id::create("w_seq");
                w_seq.addr = 32'h2000_0000 + (i * 4);
                w_seq.data = i;
                w_seq.start(env_inst.ahb_agent_inst.sequencer);
            end else begin
                r_seq = ahb_read_seq::type_id::create("r_seq");
                r_seq.addr = 32'h2000_0000 + (i * 4);
                r_seq.start(env_inst.ahb_agent_inst.sequencer);
            end
        end
    endtask
    
    task apb_access;
        apb_write_seq w_seq;
        apb_read_seq  r_seq;
        
        `uvm_info("TEST", "APB concurrent access...", UVM_MEDIUM)
        
        // 访问不同外设
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h5000_0000;  // GPIO
        w_seq.data = 32'hFFFF_FFFF;
        w_seq.start(env_inst.apb_agent_inst.sequencer);
        
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h5000_1000;  // UART
        w_seq.data = 32'h0000_002C;
        w_seq.start(env_inst.apb_agent_inst.sequencer);
        
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h5000_2000;  // Timer
        w_seq.data = 32'h0000_0001;
        w_seq.start(env_inst.apb_agent_inst.sequencer);
        
        for (int i = 0; i < 20; i++) begin
            r_seq = apb_read_seq::type_id::create("r_seq");
            r_seq.addr = 32'h5000_0000 + (i * 0x400);  // 不同外设
            r_seq.start(env_inst.apb_agent_inst.sequencer);
        end
    endtask
    
    task multi_master_stress;
        `uvm_info("TEST", "Multi-master stress test...", UVM_MEDIUM)
        
        // 测试 AHB 矩阵仲裁
        fork
            begin
                ahb_burst_write_seq bw_seq;
                bw_seq = ahb_burst_write_seq::type_id::create("bw_seq");
                bw_seq.start_addr = 32'h2000_0000;
                bw_seq.burst_len = 16;
                bw_seq.start(env_inst.ahb_agent_inst.sequencer);
            end
            begin
                ahb_burst_read_seq br_seq;
                br_seq = ahb_burst_read_seq::type_id::create("br_seq");
                br_seq.start_addr = 32'h0000_0000;  // Flash
                br_seq.burst_len = 16;
                br_seq.start(env_inst.ahb_agent_inst.sequencer);
            end
        join
    endtask
    
endclass

`endif
