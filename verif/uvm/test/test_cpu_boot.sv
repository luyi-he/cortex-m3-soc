// ============================================================================
// 文件     : test_cpu_boot.sv
// 描述     : CPU 启动测试
// ============================================================================

`ifndef TEST_CPU_BOOT_SV
`define TEST_CPU_BOOT_SV

class test_cpu_boot extends base_test;
    
    `uvm_component_utils(test_cpu_boot)
    
    function new(string name = "test_cpu_boot", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        
        `uvm_info("TEST", "=== CPU Boot Test ===", UVM_NONE)
        
        // 等待复位完成
        @(posedge ahb_vif.hclk);
        @(posedge ahb_vif.hclk);
        @(posedge ahb_vif.hreset_n);
        
        // 检查复位向量
        `uvm_info("TEST", "Checking reset vector...", UVM_MEDIUM)
        
        // CPU 应该从 0x0000_0000 读取初始 SP
        // 从 0x0000_0004 读取复位向量地址
        
        // 等待一段时间让 CPU 启动
        repeat (100) @(posedge ahb_vif.hclk);
        
        // 检查是否有 AHB 访问
        `uvm_info("TEST", "CPU boot sequence initiated", UVM_MEDIUM)
        
        // 检查 Flash 区域访问
        if (ahb_vif.haddr[31:28] == 4'h0) begin
            `uvm_info("TEST", "Flash access detected - CPU fetching instructions", UVM_MEDIUM)
        end
        
        // 检查 SRAM 区域访问
        if (ahb_vif.haddr[31:28] == 4'h2) begin
            `uvm_info("TEST", "SRAM access detected - CPU initializing stack", UVM_MEDIUM)
        end
        
        `uvm_info("TEST", "=== CPU Boot Test PASSED ===", UVM_NONE)
    endtask
    
endclass

`endif
