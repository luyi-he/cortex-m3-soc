// Flash Controller Blackbox for Synthesis
module flash_ctrl #(
    parameter   FLASH_ADDR_WIDTH    = 20,
    parameter   FLASH_DATA_WIDTH    = 32,
    parameter   FLASH_WAIT_STATES   = 3,
    parameter   PREFETCH_DEPTH      = 4
) (
    input  wire             hclk,
    input  wire             hreset_n,
    input  wire [31:0]      haddr,
    input  wire [2:0]       hburst,
    input  wire [3:0]       hprot,
    input  wire [2:0]       hsize,
    input  wire [1:0]       htrans,
    input  wire             hwrite,
    input  wire [31:0]      hwdata,
    output wire [31:0]      hrdata,
    output wire             hready,
    output wire             hresp,
    input  wire             hsel,
    output wire [19:0]      flash_addr_o,
    inout  wire [31:0]      flash_data_io,
    output wire             flash_ce_n,
    output wire             flash_oe_n
);
    // Blackbox - implementation not available for synthesis
endmodule
