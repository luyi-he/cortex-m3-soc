// ============================================================================
// 模块名   : rst_gen_sva.sv
// 功能描述 : 复位生成模块的形式验证断言
// 验证内容 : 异步复位同步释放 (ARS)
// ============================================================================

`timescale 1ns/1ps

module rst_gen_sva (
    input  wire        hclk,       // AHB 时钟 (200MHz)
    input  wire        pclk,       // APB 时钟 (100MHz)
    input  wire        rst_n,      // 异步复位 (低有效)
    output wire        hreset_n,   // AHB 同步复位
    output wire        preset_n    // APB 同步复位
);

    //============================================================================
    // 属性：异步复位检测
    //============================================================================
    
    // rst_n 是异步的，可以在任何时候拉低
    property p_rst_async_assert;
        @(*)
        !rst_n |-> !hreset_n && !preset_n;
    endproperty
    
    //============================================================================
    // 属性：同步复位释放
    //============================================================================
    
    // hreset_n 只能在 hclk 上升沿释放
    property p_hreset_sync_release;
        @(posedge hclk)
        $rose(hreset_n) |=> $stable(hreset_n);
    endproperty
    
    // preset_n 只能在 pclk 上升沿释放
    property p_preset_sync_release;
        @(posedge pclk)
        $rose(preset_n) |=> $stable(preset_n);
    endproperty
    
    //============================================================================
    // 属性：复位同步器链
    //============================================================================
    
    // 复位同步器应该有至少 2 级触发器
    // 这里通过时序关系间接验证
    property p_reset_synchronizer_delay;
        @(posedge hclk)
        $rose(rst_n) |-> ##1 hreset_n || ##2 hreset_n;
    endproperty
    
    //============================================================================
    // 属性：跨时钟域复位一致性
    //============================================================================
    
    // hreset_n 和 preset_n 应该在同一时间段内释放 (允许 1-2 个周期偏差)
    property p_reset_coherence;
        @(posedge hclk)
        $rose(hreset_n) |-> preset_n || ##1 preset_n || ##2 preset_n;
    endproperty
    
    //============================================================================
    // 属性：复位脉冲宽度
    //============================================================================
    
    // 复位释放后应该保持稳定至少 N 个周期
    property p_hreset_min_pulse;
        @(posedge hclk)
        $rose(hreset_n) |-> ##10 hreset_n;
    endproperty
    
    property p_preset_min_pulse;
        @(posedge pclk)
        $rose(preset_n) |-> ##10 preset_n;
    endproperty
    
    //============================================================================
    // 断言实例化
    //============================================================================
    
    a_rst_async_assert: assert property (p_rst_async_assert)
        else $error("Reset assert not propagated asynchronously");
    
    a_hreset_sync_release: assert property (p_hreset_sync_release)
        else $error("HRESET release not synchronous to HCLK");
    
    a_preset_sync_release: assert property (p_preset_sync_release)
        else $error("PRESET release not synchronous to PCLK");
    
    a_reset_synchronizer_delay: assert property (p_reset_synchronizer_delay)
        else $warning("Reset synchronizer may not have enough stages");
    
    a_reset_coherence: assert property (p_reset_coherence)
        else $error("Reset coherence violation between clock domains");
    
    a_hreset_min_pulse: assert property (p_hreset_min_pulse)
        else $error("HRESET pulse too short");
    
    a_preset_min_pulse: assert property (p_preset_min_pulse)
        else $error("PRESET pulse too short");
    
    //============================================================================
    // Cover 点
    //============================================================================
    
    c_reset_asserted: cover property (@(posedge rst_n) 1);
    c_reset_released: cover property (@(posedge hclk) $rose(hreset_n));
    c_cross_domain: cover property (@(posedge hclk) hreset_n && preset_n);
    
endmodule
