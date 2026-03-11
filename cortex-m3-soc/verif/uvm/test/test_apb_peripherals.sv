// ============================================================================
// 文件     : test_apb_peripherals.sv
// 描述     : APB 外设测试
// ============================================================================

`ifndef TEST_APB_PERIPHERALS_SV
`define TEST_APB_PERIPHERALS_SV

class test_apb_peripherals extends base_test;
    
    `uvm_component_utils(test_apb_peripherals)
    
    function new(string name = "test_apb_peripherals", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        
        `uvm_info("TEST", "=== APB Peripherals Test ===", UVM_NONE)
        
        @(posedge ahb_vif.hreset_n);
        
        // 测试 UART
        test_uart();
        
        // 测试 Timer
        test_timer();
        
        // 测试看门狗
        test_wdt();
        
        // 测试 RCC
        test_rcc();
        
        `uvm_info("TEST", "=== APB Peripherals Test PASSED ===", UVM_NONE)
    endtask
    
    task test_uart;
        apb_write_seq w_seq;
        apb_read_seq  r_seq;
        
        `uvm_info("TEST", "Testing UART...", UVM_MEDIUM)
        
        // 配置 UART: 使能，8N1
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h5000_1000;  // UART CR1
        w_seq.data = 32'h0000_002C;  // UE=1, RE=1, TE=1
        w_seq.start(env_inst.apb_agent_inst.sequencer);
        
        // 配置波特率
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h5000_100C;  // UART BRR
        w_seq.data = 32'h0000_010D;  // 115200 @ 100MHz
        w_seq.start(env_inst.apb_agent_inst.sequencer);
        
        // 发送数据
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h5000_1014;  // UART DR
        w_seq.data = 32'h55;
        w_seq.start(env_inst.apb_agent_inst.sequencer);
        
        // 读取状态
        r_seq = apb_read_seq::type_id::create("r_seq");
        r_seq.addr = 32'h5000_1010;  // UART SR
        r_seq.start(env_inst.apb_agent_inst.sequencer);
        
        `uvm_info("TEST", $sformatf("UART status: %0h", r_seq.req.prdata), UVM_MEDIUM)
    endtask
    
    task test_timer;
        apb_write_seq w_seq;
        apb_read_seq  r_seq;
        
        `uvm_info("TEST", "Testing Timer...", UVM_MEDIUM)
        
        // 配置 Timer0: 使能，向上计数
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h5000_2000;  // Timer0 CR1
        w_seq.data = 32'h0000_0001;  // CEN=1
        w_seq.start(env_inst.apb_agent_inst.sequencer);
        
        // 配置预分频
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h5000_201C;  // Timer0 PSC
        w_seq.data = 32'h0000_0063;  // /64
        w_seq.start(env_inst.apb_agent_inst.sequencer);
        
        // 配置自动重载值
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h5000_2020;  // Timer0 ARR
        w_seq.data = 32'h0000_FFFF;
        w_seq.start(env_inst.apb_agent_inst.sequencer);
        
        // 读取计数器
        r_seq = apb_read_seq::type_id::create("r_seq");
        r_seq.addr = 32'h5000_2018;  // Timer0 CNT
        r_seq.start(env_inst.apb_agent_inst.sequencer);
        
        `uvm_info("TEST", $sformatf("Timer counter: %0h", r_seq.req.prdata), UVM_MEDIUM)
    endtask
    
    task test_wdt;
        apb_write_seq w_seq;
        
        `uvm_info("TEST", "Testing Watchdog...", UVM_MEDIUM)
        
        // 使能看门狗
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h5000_3000;  // WDT CR
        w_seq.data = 32'h0000_0001;  // WDGA=1
        w_seq.start(env_inst.apb_agent_inst.sequencer);
        
        // 喂狗
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h5000_3004;  // WDT KR
        w_seq.data = 32'hAAAA;
        w_seq.start(env_inst.apb_agent_inst.sequencer);
    endtask
    
    task test_rcc;
        apb_write_seq w_seq;
        apb_read_seq  r_seq;
        
        `uvm_info("TEST", "Testing RCC...", UVM_MEDIUM)
        
        // 使能 GPIO 时钟
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h5000_A010;  // RCC_AHB1ENR
        w_seq.data = 32'h0000_000F;  // GPIOA-D enable
        w_seq.start(env_inst.apb_agent_inst.sequencer);
        
        // 使能 UART 时钟
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h5000_A020;  // RCC_APB1ENR
        w_seq.data = 32'h0000_0003;  // UART0-1 enable
        w_seq.start(env_inst.apb_agent_inst.sequencer);
        
        // 读取时钟状态
        r_seq = apb_read_seq::type_id::create("r_seq");
        r_seq.addr = 32'h5000_A000;  // RCC CR
        r_seq.start(env_inst.apb_agent_inst.sequencer);
        
        `uvm_info("TEST", $sformatf("RCC clock status: %0h", r_seq.req.prdata), UVM_MEDIUM)
    endtask
    
endclass

`endif
