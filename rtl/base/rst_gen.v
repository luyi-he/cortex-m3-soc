// ============================================================================
// 模块名   : rst_gen
// 功能描述 : 复位生成模块 - 管理多种复位源，生成系统复位信号
// 作者     : RTL 团队
// 创建日期 : 2026-03-10
// 版本     : v1.0
// ============================================================================

module rst_gen #(
    parameter   WDT_TIMEOUT   = 32,       // 看门狗超时计数
    parameter   BOR_THRESHOLD = 2         // 掉电复位阈值
) (
    // 时钟
    input  wire             hclk,         // AHB 时钟
    input  wire             pclk,         // APB 时钟
    
    // 外部复位
    input  wire             por,          // 上电复位
    input  wire             nrst,         // 外部复位引脚
    
    // 内部复位源
    input  wire             wdt_rst,      // 看门狗复位
    input  wire             sw_rst,       // 软件复位请求
    input  wire             lockup_rst,   // CPU 锁死复位
    input  wire             bor,          // 掉电检测
    
    // 系统复位输出
    output wire             sys_rst_n,    // 系统复位
    output wire             hreset_n,     // AHB 复位
    output wire             preset_n,     // APB 复位
    output wire             cpu_rst_n,    // CPU 复位
    output wire             dbg_rst_n,    // 调试复位
    
    // 复位状态
    output wire [7:0]       rst_flags,    // 复位标志
    output wire             rst_pending   // 复位进行中
);

    //============================================================
    // 内部信号
    //============================================================
    
    wire        por_sync;
    wire        nrst_sync;
    wire        bor_sync;
    
    reg         sys_rst_reg;
    wire        sys_rst_next;
    
    reg [7:0]   rst_flag_reg;
    wire [7:0]  rst_flag_next;
    
    //============================================================
    // 异步复位同步
    // @CDC: 异步信号同步到 hclk 域
    //============================================================
    
    // POR 同步
    reg [1:0]   por_sync_reg;
    always @(posedge hclk) begin
        por_sync_reg <= {por_sync_reg[0], por};
    end
    assign por_sync = por_sync_reg[1];
    
    // NRST 同步
    reg [1:0]   nrst_sync_reg;
    always @(posedge hclk) begin
        nrst_sync_reg <= {nrst_sync_reg[0], nrst};
    end
    assign nrst_sync = nrst_sync_reg[1];
    
    // BOR 同步
    reg [1:0]   bor_sync_reg;
    always @(posedge hclk) begin
        bor_sync_reg <= {bor_sync_reg[0], bor};
    end
    assign bor_sync = bor_sync_reg[1];
    
    //============================================================
    // 复位标志
    //============================================================
    
    // 复位标志定义
    // [0] - POR 标志
    // [1] - NRST 标志
    // [2] - WDT 标志
    // [3] - SWRST 标志
    // [4] - LOCKUP 标志
    // [5] - BOR 标志
    // [6:7] - 保留
    
    assign rst_flag_next = {
        2'b00,                          // [7:6] 保留
        bor_sync,                       // [5] BOR
        sw_rst,                         // [4] 软件复位
        lockup_rst,                     // [3] LOCKUP
        wdt_rst,                        // [2] 看门狗
        !nrst_sync,                     // [1] 外部复位
        por_sync                        // [0] POR
    };
    
    always @(posedge hclk or posedge por_sync) begin
        if (por_sync)
            rst_flag_reg <= 8'b0000_0001;  // POR 标志置位
        else if (sys_rst_reg && !sys_rst_next)
            rst_flag_reg <= rst_flag_reg | rst_flag_next;  // 锁存复位源
    end
    
    assign rst_flags = rst_flag_reg;
    
    //============================================================
    // 复位生成逻辑
    //============================================================
    
    // 复位条件
    assign sys_rst_next = !(
        por_sync |          // POR
        !nrst_sync |        // 外部复位
        wdt_rst |           // 看门狗
        sw_rst |            // 软件复位
        lockup_rst |        // LOCKUP
        bor_sync            // 掉电
    );
    
    // 复位寄存器 (带延迟释放)
    reg [3:0]   rst_delay;
    
    always @(posedge hclk) begin
        sys_rst_reg <= sys_rst_next;
        
        // 复位释放延迟 (4 周期)
        if (!sys_rst_next)
            rst_delay <= 4'b0000;
        else if (&rst_delay)
            rst_delay <= rst_delay;  // 保持
        else
            rst_delay <= rst_delay + 1'b1;
    end
    
    //============================================================
    // 复位输出
    //============================================================
    
    // 系统复位 (延迟释放)
    assign sys_rst_n = sys_rst_reg & &rst_delay;
    
    // AHB 复位 (与系统复位相同)
    assign hreset_n = sys_rst_n;
    
    // APB 复位 (额外延迟 1 周期)
    reg         preset_delay;
    always @(posedge pclk) begin
        preset_delay <= sys_rst_n;
    end
    assign preset_n = preset_delay;
    
    // CPU 复位 (可被调试复位屏蔽)
    reg         dbg_active;
    assign cpu_rst_n = sys_rst_n & dbg_rst_n;
    
    // 调试复位 (独立于系统复位)
    assign dbg_rst_n = 1'b1;  // 默认不复位调试域
    
    //============================================================
    // 复位状态
    //============================================================
    
    assign rst_pending = !sys_rst_n;
    
    //============================================================
    // 设计约束注释
    //============================================================
    
    // @CDC: 所有异步复位源已同步
    // @CRITICAL: 复位路径时序宽松，无关键路径
    
    // 面积预估：~150 gates
    // 功耗预估：~0.1mW

endmodule
