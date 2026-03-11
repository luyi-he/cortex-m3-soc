// ============================================================================
// 文件     : coverage_model.sv
// 描述     : 功能覆盖率模型
// ============================================================================

`ifndef COVERAGE_MODEL_SV
`define COVERAGE_MODEL_SV

class coverage_model extends uvm_subscriber #(ahb_seq_item);
    
    // 覆盖率组
    covergroup ahb_protocol_cg;
        option.per_instance = 1;
        option.comment = "AHB 协议功能覆盖率";
        
        // 传输类型
        trans_type: coverpoint tr.htrans {
            bins idle    = {2'b00};
            bins nonseq  = {2'b10};
            bins seq     = {2'b11};
        }
        
        // 传输大小
        trans_size: coverpoint tr.hsize {
            bins byte  = {3'b000};
            bins half  = {3'b001};
            bins word  = {3'b010};
        }
        
        // 突发类型
        trans_burst: coverpoint tr.hburst {
            bins single = {3'b000};
            bins incr   = {3'b001};
            bins wrap4  = {3'b010};
            bins incr4  = {3'b011};
        }
        
        // 读写
        trans_write: coverpoint tr.hwrite {
            bins read  = {0};
            bins write = {1};
        }
        
        // 地址区域
        addr_region: coverpoint tr.haddr[31:28] {
            bins flash = {4'h0};
            bins sram  = {4'h2};
            bins ahb_pp = {4'h4};
        }
        
        // 响应
        trans_resp: coverpoint tr.hresp {
            bins okay   = {0};
            bins error  = {1};
        }
        
        // 交叉覆盖
        trans_x: cross trans_type, trans_size, trans_write;
        region_x:  cross addr_region, trans_write;
    endgroup
    
    // APB 覆盖率
    covergroup apb_protocol_cg;
        option.per_instance = 1;
        option.comment = "APB 协议功能覆盖率";
        
        apb_write: coverpoint apb_tr.pwrite {
            bins read  = {0};
            bins write = {1};
        }
        
        apb_region: coverpoint apb_tr.paddr[15:12] {
            bins gpio   = {4'h0};
            bins uart   = {4'h1};
            bins timer  = {4'h2};
            bins wdt    = {4'h3};
            bins i2c    = {4'h5};
            bins spi    = {4'h6};
            bins adc    = {4'h7};
            bins flash  = {4'h9};
            bins rcc    = {4'hA};
            bins pwr    = {4'hB};
        }
    endgroup
    
    // 寄存器访问覆盖率
    covergroup reg_access_cg;
        option.per_instance = 1;
        option.comment = "寄存器访问覆盖率";
        
        gpio_regs: coverpoint gpio_addr[3:0] {
            bins moder   = {4'h0};
            bins otyper  = {4'h1};
            bins ospeedr = {4'h2};
            bins pupdr   = {4'h3};
            bins idr     = {4'h4};
            bins odr     = {4'h5};
            bins bsrr    = {4'h6};
        }
        
        uart_regs: coverpoint uart_addr[3:0] {
            bins cr1  = {4'h0};
            bins cr2  = {4'h1};
            bins cr3  = {4'h2};
            bins brr  = {4'h3};
            bins sr   = {4'h4};
            bins dr   = {4'h5};
        }
    endgroup
    
    // 事务句柄
    ahb_seq_item tr;
    apb_seq_item apb_tr;
    
    // GPIO/UART 地址跟踪
    bit [31:0] gpio_addr;
    bit [31:0] uart_addr;
    
    // UVM 宏
    `uvm_component_utils(coverage_model)
    
    // 构造函数
    function new(string name = "coverage_model", uvm_component parent = null);
        super.new(name, parent);
        ahb_protocol_cg = new();
        apb_protocol_cg = new();
        reg_access_cg   = new();
        tr      = new();
        apb_tr  = new();
    endfunction
    
    // 写方法
    function void write(ahb_seq_item t);
        tr = t;
        ahb_protocol_cg.sample();
        
        // 跟踪 GPIO/UART 访问
        if (tr.haddr[31:28] == 4'h5) begin  // APB 区域
            if (tr.haddr[15:12] == 4'h0) begin
                gpio_addr = tr.haddr[11:0];
                reg_access_cg.sample();
            end else if (tr.haddr[15:12] == 4'h1) begin
                uart_addr = tr.haddr[11:0];
                reg_access_cg.sample();
            end
        end
    endfunction
    
    // APB 写方法
    function void write_apb(apb_seq_item t);
        apb_tr = t;
        apb_protocol_cg.sample();
    endfunction
    
    // 获取覆盖率
    function real get_coverage();
        return ahb_protocol_cg.get_coverage();
    endfunction
    
    // 报告覆盖率
    function void report_coverage();
        $display("===========================================");
        $display("AHB Protocol Coverage: %0.2f%%", ahb_protocol_cg.get_coverage());
        $display("APB Protocol Coverage: %0.2f%%", apb_protocol_cg.get_coverage());
        $display("Register Access Coverage: %0.2f%%", reg_access_cg.get_coverage());
        $display("===========================================");
    endfunction
    
endclass

`endif
