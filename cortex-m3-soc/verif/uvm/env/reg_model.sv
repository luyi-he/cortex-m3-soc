// ============================================================================
// 文件     : reg_model.sv
// 描述     : 寄存器模型 (Register Abstraction Layer)
// ============================================================================

`ifndef REG_MODEL_SV
`define REG_MODEL_SV

// GPIO 寄存器
class gpio_moder_reg extends uvm_reg;
    `uvm_object_utils(gpio_moder_reg)
    
    uvm_reg_field mode;
    
    function new(string name = "gpio_moder_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction
    
    virtual function void build();
        mode = uvm_reg_field::type_id::create("mode");
        mode.configure(this, 32, 0, "RW", 0, 32'h0, 1, 1, 1);
    endfunction
endclass

// GPIO 输出数据寄存器
class gpio_odr_reg extends uvm_reg;
    `uvm_object_utils(gpio_odr_reg)
    
    uvm_reg_field odr;
    
    function new(string name = "gpio_odr_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction
    
    virtual function void build();
        odr = uvm_reg_field::type_id::create("odr");
        odr.configure(this, 32, 0, "RW", 0, 32'h0, 1, 1, 1);
    endfunction
endclass

// GPIO 输入数据寄存器
class gpio_idr_reg extends uvm_reg;
    `uvm_object_utils(gpio_idr_reg)
    
    uvm_reg_field idr;
    
    function new(string name = "gpio_idr_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction
    
    virtual function void build();
        idr = uvm_reg_field::type_id::create("idr");
        idr.configure(this, 32, 0, "RO", 0, 32'h0, 1, 1, 1);
    endfunction
endclass

// UART 控制寄存器
class uart_cr1_reg extends uvm_reg;
    `uvm_object_utils(uart_cr1_reg)
    
    uvm_reg_field ue;    // UART enable
    uvm_reg_field re;    // Receiver enable
    uvm_reg_field te;    // Transmitter enable
    
    function new(string name = "uart_cr1_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction
    
    virtual function void build();
        ue = uvm_reg_field::type_id::create("ue");
        ue.configure(this, 1, 0, "RW", 0, 1'h0, 1, 1, 1);
        
        re = uvm_reg_field::type_id::create("re");
        re.configure(this, 1, 1, "RW", 0, 1'h0, 1, 1, 1);
        
        te = uvm_reg_field::type_id::create("te");
        te.configure(this, 1, 2, "RW", 0, 1'h0, 1, 1, 1);
    endfunction
endclass

// UART 数据寄存器
class uart_dr_reg extends uvm_reg;
    `uvm_object_utils(uart_dr_reg)
    
    uvm_reg_field dr;
    
    function new(string name = "uart_dr_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction
    
    virtual function void build();
        dr = uvm_reg_field::type_id::create("dr");
        dr.configure(this, 8, 0, "RW", 0, 8'h0, 1, 1, 1);
    endfunction
endclass

// 外设块
class peripheral_block extends uvm_reg_block;
    `uvm_object_utils(peripheral_block)
    
    // GPIO 寄存器
    gpio_moder_reg gpio_moder;
    gpio_odr_reg   gpio_odr;
    gpio_idr_reg   gpio_idr;
    
    // UART 寄存器
    uart_cr1_reg uart_cr1;
    uart_dr_reg  uart_dr;
    
    // 映射
    uvm_reg_map ahb_map;
    
    function new(string name = "peripheral_block");
        super.new(name, UVM_NO_COVERAGE);
    endfunction
    
    virtual function void build();
        // 创建寄存器
        gpio_moder = gpio_moder_reg::type_id::create("gpio_moder");
        gpio_moder.configure(this);
        gpio_moder.build();
        
        gpio_odr = gpio_odr_reg::type_id::create("gpio_odr");
        gpio_odr.configure(this);
        gpio_odr.build();
        
        gpio_idr = gpio_idr_reg::type_id::create("gpio_idr");
        gpio_idr.configure(this);
        gpio_idr.build();
        
        uart_cr1 = uart_cr1_reg::type_id::create("uart_cr1");
        uart_cr1.configure(this);
        uart_cr1.build();
        
        uart_dr = uart_dr_reg::type_id::create("uart_dr");
        uart_dr.configure(this);
        uart_dr.build();
        
        // 创建映射
        ahb_map = uvm_reg_map::type_id::create("ahb_map");
        ahb_map.configure(this, null, 0, 0);
        
        // 添加寄存器到映射
        ahb_map.add_reg(gpio_moder, 32'h5000_0000, "RW");
        ahb_map.add_reg(gpio_odr,   32'h5000_0014, "RW");
        ahb_map.add_reg(gpio_idr,   32'h5000_0010, "RO");
        ahb_map.add_reg(uart_cr1,   32'h5000_1000, "RW");
        ahb_map.add_reg(uart_dr,    32'h5000_1014, "RW");
    endfunction
    
endclass

// 顶层寄存器模型
class soc_reg_model extends uvm_reg_block;
    `uvm_object_utils(soc_reg_model)
    
    peripheral_block peripherals;
    
    function new(string name = "soc_reg_model");
        super.new(name, UVM_NO_COVERAGE);
    endfunction
    
    virtual function void build();
        peripherals = peripheral_block::type_id::create("peripherals");
        peripherals.configure(this);
        peripherals.build();
    endfunction
    
endclass

`endif
