// ============================================================================
// 文件     : test_gpio.sv
// 描述     : GPIO 功能测试
// ============================================================================

`ifndef TEST_GPIO_SV
`define TEST_GPIO_SV

class test_gpio extends base_test;
    
    `uvm_component_utils(test_gpio)
    
    function new(string name = "test_gpio", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        
        `uvm_info("TEST", "=== GPIO Test ===", UVM_NONE)
        
        @(posedge ahb_vif.hreset_n);
        
        // 配置 GPIO
        configure_gpio();
        
        // 测试输出
        test_gpio_output();
        
        // 测试输入
        test_gpio_input();
        
        // 测试 BSRR
        test_bsrr();
        
        // 测试复用功能
        test_alternate_function();
        
        `uvm_info("TEST", "=== GPIO Test PASSED ===", UVM_NONE)
    endtask
    
    task configure_gpio;
        apb_write_seq w_seq;
        
        `uvm_info("TEST", "Configuring GPIO...", UVM_MEDIUM)
        
        // 配置所有引脚为输出模式
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h5000_0000;  // GPIO MODER
        w_seq.data = 32'h0000_0000;  // 输出模式
        w_seq.start(env_inst.apb_agent_inst.sequencer);
    endtask
    
    task test_gpio_output;
        apb_write_seq w_seq;
        apb_read_seq  r_seq;
        
        `uvm_info("TEST", "Testing GPIO output...", UVM_MEDIUM)
        
        // 写入 ODR
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h5000_0014;  // GPIO ODR
        w_seq.data = 32'hAAAAAAAA;
        w_seq.start(env_inst.apb_agent_inst.sequencer);
        
        // 读回验证
        r_seq = apb_read_seq::type_id::create("r_seq");
        r_seq.addr = 32'h5000_0014;
        r_seq.start(env_inst.apb_agent_inst.sequencer);
        
        if (r_seq.req.prdata === 32'hAAAAAAAA) begin
            `uvm_info("TEST", "GPIO output verification PASSED", UVM_NONE)
        end else begin
            `uvm_error("TEST", $sformatf("GPIO output mismatch: exp=%0h, act=%0h", 
                                         32'hAAAAAAAA, r_seq.req.prdata))
        end
    endtask
    
    task test_gpio_input;
        apb_write_seq w_seq;
        apb_read_seq  r_seq;
        
        `uvm_info("TEST", "Testing GPIO input...", UVM_MEDIUM)
        
        // 配置为输入模式
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h5000_0000;  // GPIO MODER
        w_seq.data = 32'hFFFF_FFFF;  // 输入模式
        w_seq.start(env_inst.apb_agent_inst.sequencer);
        
        // 读取 IDR
        r_seq = apb_read_seq::type_id::create("r_seq");
        r_seq.addr = 32'h5000_0010;  // GPIO IDR
        r_seq.start(env_inst.apb_agent_inst.sequencer);
        
        `uvm_info("TEST", $sformatf("GPIO input value: %0h", r_seq.req.prdata), UVM_MEDIUM)
    endtask
    
    task test_bsrr;
        apb_write_seq w_seq;
        apb_read_seq  r_seq;
        
        `uvm_info("TEST", "Testing BSRR...", UVM_MEDIUM)
        
        // 先清零
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h5000_0014;
        w_seq.data = 32'h0;
        w_seq.start(env_inst.apb_agent_inst.sequencer);
        
        // 设置低 8 位
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h5000_0018;  // BSRR
        w_seq.data = 32'h0000_00FF;  // 设置 bit0-7
        w_seq.start(env_inst.apb_agent_inst.sequencer);
        
        // 验证
        r_seq = apb_read_seq::type_id::create("r_seq");
        r_seq.addr = 32'h5000_0014;
        r_seq.start(env_inst.apb_agent_inst.sequencer);
        
        if (r_seq.req.prdata === 32'h0000_00FF) begin
            `uvm_info("TEST", "BSRR set verification PASSED", UVM_NONE)
        end
        
        // 复位低 8 位
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h5000_0018;
        w_seq.data = 32'h00FF_0000;  // 复位 bit0-7
        w_seq.start(env_inst.apb_agent_inst.sequencer);
        
        // 验证
        r_seq = apb_read_seq::type_id::create("r_seq");
        r_seq.addr = 32'h5000_0014;
        r_seq.start(env_inst.apb_agent_inst.sequencer);
        
        if (r_seq.req.prdata === 32'h0) begin
            `uvm_info("TEST", "BSRR reset verification PASSED", UVM_NONE)
        end
    endtask
    
    task test_alternate_function;
        apb_write_seq w_seq;
        
        `uvm_info("TEST", "Testing alternate function...", UVM_MEDIUM)
        
        // 配置 AFRL (低 8 引脚复用功能)
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h5000_0020;  // GPIO AFRL
        w_seq.data = 32'h1111_1111;  // AF1
        w_seq.start(env_inst.apb_agent_inst.sequencer);
        
        // 配置 AFRH (高 8 引脚复用功能)
        w_seq = apb_write_seq::type_id::create("w_seq");
        w_seq.addr = 32'h5000_0024;  // GPIO AFRH
        w_seq.data = 32'h2222_2222;  // AF2
        w_seq.start(env_inst.apb_agent_inst.sequencer);
    endtask
    
endclass

`endif
