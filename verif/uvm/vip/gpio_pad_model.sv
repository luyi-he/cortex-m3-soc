// ============================================================================
// 文件     : gpio_pad_model.sv
// 描述     : GPIO PAD 模型
// ============================================================================

`ifndef GPIO_PAD_MODEL_SV
`define GPIO_PAD_MODEL_SV

module gpio_pad_model #(
    parameter WIDTH = 64
) (
    input  wire [WIDTH-1:0]  gpio_o,
    input  wire [WIDTH-1:0]  gpio_oen,
    output wire [WIDTH-1:0]  gpio_i,
    output wire [WIDTH-1:0]  gpio_pado
);
    
    // 内部寄存器
    reg [WIDTH-1:0] gpio_i_reg;
    reg [WIDTH-1:0] gpio_pado_reg;
    
    // 外部激励 (可通过 force 注入)
    reg [WIDTH-1:0] gpio_ext;
    reg [WIDTH-1:0] gpio_ext_en;
    
    // 输出 PAD
    assign gpio_pado = gpio_pado_reg;
    
    // 输入 PAD (三态缓冲)
    assign gpio_i = (gpio_ext_en) ? gpio_ext : gpio_i_reg;
    
    // 输出锁存
    always @(*) begin
        gpio_pado_reg = gpio_o & ~gpio_oen;
    end
    
    // 输入采样 (当配置为输入时)
    always @(*) begin
        if (gpio_oen) begin
            gpio_i_reg = gpio_ext;
        end else begin
            gpio_i_reg = gpio_o;
        end
    end
    
    // 覆盖率
    `ifdef COVERAGE
    wire [WIDTH-1:0] input_mode  = gpio_oen;
    wire [WIDTH-1:0] output_mode = ~gpio_oen;
    
    covergroup gpio_cg;
        cp_input_pins:  coverpoint $countones(input_mode)  { bins i[0:WIDTH] = {[0:WIDTH]}; }
        cp_output_pins: coverpoint $countones(output_mode) { bins o[0:WIDTH] = {[0:WIDTH]}; }
    endgroup
    
    gpio_cg cov = new();
    
    always @(posedge) begin
        cov.sample();
    end
    `endif
    
    // 任务：设置外部输入
    task set_gpio_input;
        input [WIDTH-1:0] value;
        input [WIDTH-1:0] mask;
    begin
        gpio_ext     = value;
        gpio_ext_en  = mask;
    end
    endtask
    
    // 任务：清除外部输入
    task clear_gpio_input;
    begin
        gpio_ext     = '0;
        gpio_ext_en  = '0;
    end
    endtask
    
    initial begin
        gpio_ext    = '0;
        gpio_ext_en = '0;
    end
    
endmodule

`endif
