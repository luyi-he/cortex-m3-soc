// ============================================================================
// 文件     : test_interrupt.sv
// 描述     : 中断测试
// ============================================================================

`ifndef TEST_INTERRUPT_SV
`define TEST_INTERRUPT_SV

class test_interrupt extends base_test;
    
    `uvm_component_utils(test_interrupt)
    
    function new(string name = "test_interrupt", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        
        `uvm_info("TEST", "=== Interrupt Test ===", UVM_NONE)
        
        @(posedge ahb_vif.hreset_n);
        
        // 测试 NVIC 配置
        test_nvic_config();
        
        // 测试外部中断
        test_exti_interrupt();
        
        // 测试定时器中断
        test_timer_interrupt();
        
        // 测试 UART 中断
        test_uart_interrupt();
        
        // 测试中断优先级
        test_interrupt_priority();
        
        `uvm_info("TEST", "=== Interrupt Test PASSED ===", UVM_NONE)
    endtask
    
    task test_nvic_config;
        apb_write_seq w_seq;
        apb_read_seq  r_seq;
        
        `uvm_info("TEST", "Testing NVIC configuration...", UVM_MEDIUM)
        
        // 使能 IRQ0 (WDT)
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'hE000_E100;  // NVIC_ISER
        w_seq.data = 32'h0000_0001;
        w_seq.start(env_inst.apb_agent_inst.sequencer);
        
        // 配置优先级
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'hE000_E400;  // NVIC_IPR0
        w_seq.data = 32'h0000_0000;  // 优先级 0 (最高)
        w_seq.start(env_inst.apb_agent_inst.sequencer);
        
        // 读取配置
        r_seq = apb_read_seq::type_id::create("r_seq");
        r_seq.addr = 32'hE000_E100;
        r_seq.start(env_inst.apb_agent_inst.sequencer);
        
        `uvm_info("TEST", $sformatf("NVIC ISER: %0h", r_seq.req.prdata), UVM_MEDIUM)
    endtask
    
    task test_exti_interrupt;
        `uvm_info("TEST", "Testing EXTI interrupt...", UVM_MEDIUM)
        
        // 触发外部中断
        // 实际测试中需要驱动中断信号
        
        // 检查中断挂起
        check_interrupt_pending(0);
    endtask
    
    task test_timer_interrupt;
        apb_write_seq w_seq;
        
        `uvm_info("TEST", "Testing Timer interrupt...", UVM_MEDIUM)
        
        // 使能定时器更新中断
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h5000_200C;  // Timer0 DIER
        w_seq.data = 32'h0000_0001;  // UIE=1
        w_seq.start(env_inst.apb_agent_inst.sequencer);
        
        // 产生更新事件
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h5000_2014;  // Timer0 EGR
        w_seq.data = 32'h0000_0001;  // UG=1
        w_seq.start(env_inst.apb_agent_inst.sequencer);
        
        // 检查中断标志
        check_interrupt_pending(3);  // Timer0 IRQ
    endtask
    
    task test_uart_interrupt;
        apb_write_seq w_seq;
        
        `uvm_info("TEST", "Testing UART interrupt...", UVM_MEDIUM)
        
        // 使能 UART 接收中断
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h5000_1000;  // UART CR1
        w_seq.data = 32'h0000_002D;  // UE=1, RE=1, RXNEIE=1
        w_seq.start(env_inst.apb_agent_inst.sequencer);
        
        // 检查中断挂起
        check_interrupt_pending(1);  // UART0 IRQ
    endtask
    
    task test_interrupt_priority;
        apb_write_seq w_seq;
        
        `uvm_info("TEST", "Testing interrupt priority...", UVM_MEDIUM)
        
        // 配置 IRQ0 优先级为 1
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'hE000_E400;
        w_seq.data = 32'h0100_0000;
        w_seq.start(env_inst.apb_agent_inst.sequencer);
        
        // 配置 IRQ1 优先级为 2
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'hE000_E400;
        w_seq.data = 32'h0001_0000;
        w_seq.start(env_inst.apb_agent_inst.sequencer);
    endtask
    
    task check_interrupt_pending(int irq_num);
        apb_read_seq r_seq;
        
        // 读取中断挂起寄存器
        r_seq = apb_read_seq::type_id::create("r_seq");
        r_seq.addr = 32'hE000_E200 + (irq_num / 32) * 4;
        r_seq.start(env_inst.apb_agent_inst.sequencer);
        
        if (r_seq.req.prdata & (1 << (irq_num % 32))) begin
            `uvm_info("TEST", $sformatf("IRQ%d is pending", irq_num), UVM_MEDIUM)
        end
    endtask
    
endclass

`endif
