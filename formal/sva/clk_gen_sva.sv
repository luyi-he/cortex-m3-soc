// ============================================================================
// 模块名   : clk_gen_sva.sv
// 功能描述 : 时钟生成模块的形式验证断言
// 验证内容 : CDC (跨时钟域) 检查
// ============================================================================

`timescale 1ns/1ps

module clk_gen_sva (
    input  wire        osc_clk,    // 25MHz 输入
    input  wire        rst_n,      // 异步复位
    output wire        hclk,       // 200MHz AHB 时钟
    output wire        pclk,       // 100MHz APB 时钟
    output wire        hreset_n,   // AHB 复位
    output wire        preset_n    // APB 复位
);

    //============================================================================
    // 时钟定义
    //============================================================================
    
    // 声明时钟
    `ifdef FORMAL
    `define FORMAL_HCLK `init_hclk
    `define FORMAL_PCLK `init_pclk
    `endif
    
    //============================================================================
    // 属性：时钟频率检查
    //============================================================================
    
    // hclk 应该是 200MHz (5ns 周期)
    property p_hclk_frequency;
        @(posedge osc_clk) disable iff (!rst_n)
        ##1 $stable(hclk) |-> ##4 $stable(hclk);
    endproperty
    
    // pclk 应该是 100MHz (10ns 周期)
    property p_pclk_frequency;
        @(posedge osc_clk) disable iff (!rst_n)
        ##1 $stable(pclk) |-> ##9 $stable(pclk);
    endproperty
    
    //============================================================================
    // 属性：时钟相位关系
    //============================================================================
    
    // hclk 和 pclk 应该同源 (从 osc_clk 分频)
    property p_clocks_synchronous;
        @(posedge osc_clk) disable iff (!rst_n)
        (hclk && pclk) |-> ##1 (!hclk && !pclk);
    endproperty
    
    //============================================================================
    // 属性：复位同步释放
    //============================================================================
    
    // hreset_n 应该在 hclk 的上升沿同步释放
    property p_hreset_sync;
        @(posedge hclk)
        $rose(hreset_n) |-> $stable(hreset_n);
    endproperty
    
    // preset_n 应该在 pclk 的上升沿同步释放
    property p_preset_sync;
        @(posedge pclk)
        $rose(preset_n) |-> $stable(preset_n);
    endproperty
    
    //============================================================================
    // 属性：复位时序关系
    //============================================================================
    
    // preset_n 应该在 hreset_n 之后释放 (或同时)
    property p_reset_order;
        @(posedge osc_clk)
        $rose(hreset_n) |-> preset_n || ##1 preset_n;
    endproperty
    
    //============================================================================
    // 断言实例化
    //============================================================================
    
    a_hclk_frequency: assert property (p_hclk_frequency)
        else $error("HCLK frequency violation: expected 200MHz");
    
    a_pclk_frequency: assert property (p_pclk_frequency)
        else $error("PCLK frequency violation: expected 100MHz");
    
    a_clocks_synchronous: assert property (p_clocks_synchronous)
        else $error("Clocks are not synchronous");
    
    a_hreset_sync: assert property (p_hreset_sync)
        else $error("HRESET not synchronous to HCLK");
    
    a_preset_sync: assert property (p_preset_sync)
        else $error("PRESET not synchronous to PCLK");
    
    a_reset_order: assert property (p_reset_order)
        else $error("Reset release order violation");
    
    //============================================================================
    // Cover 点 (用于验证覆盖率)
    //============================================================================
    
    c_hclk_rising: cover property (@(posedge hclk) 1);
    c_pclk_rising: cover property (@(posedge pclk) 1);
    c_reset_released: cover property (@(posedge hclk) $rose(hreset_n));
    
endmodule
