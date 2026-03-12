// Cortex-M3 CPU Blackbox for Synthesis
module cortex_m3(
    input  wire        HCLK,
    input  wire        HRESETn,
    input  wire [31:0] HADDR,
    input  wire [2:0]  HBURST,
    input  wire        HMASTLOCK,
    input  wire [3:0]  HPROT,
    input  wire [2:0]  HSIZE,
    input  wire [1:0]  HTRANS,
    input  wire        HWRITE,
    input  wire [31:0] HWDATA,
    output wire [31:0] HRDATA,
    output wire        HREADY,
    output wire        HRESP,
    input  wire [31:0] IRQ,
    input  wire        NMI,
    input  wire        TCK,
    input  wire        TMS,
    input  wire        TDI,
    output wire        TDO,
    input  wire        nTRST,
    output wire        SWV
);
    // Blackbox - ARM Cortex-M3 IP
endmodule
