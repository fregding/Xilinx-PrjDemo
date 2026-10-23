//-----------------------------------------------------------------------------
// File name : axi_pkg.sv
// Description : AXI4 常量包（由 easyaxi_define.v 宏定义迁移）
//   位宽与 MIG ddr3_0 配置一致：
//     - AXI 数据位宽 32bit（C0.DDR3_AXI_DATA_WIDTH=32）
//     - AXI 地址位宽 28bit（C0.DDR3_AXI_ADDR_WIDTH=28）
//     - AXI ID 位宽  4bit
//-----------------------------------------------------------------------------
package axi_pkg;

    localparam int AXI_ID_W    = 4;
    localparam int AXI_ADDR_W  = 28;
    localparam int AXI_DATA_W  = 32;   // 4B = 32 bits (AXI 总线宽度)
    localparam int AXI_LEN_W   = 8;
    localparam int AXI_SIZE_W  = 3;
    localparam int AXI_BURST_W = 2;
    localparam int AXI_RESP_W  = 2;

    // AxSIZE 编码（每拍字节数 = 2**AxSIZE）
    localparam logic [AXI_SIZE_W-1:0] AXI_SIZE_1B   = 3'b000;
    localparam logic [AXI_SIZE_W-1:0] AXI_SIZE_2B   = 3'b001;
    localparam logic [AXI_SIZE_W-1:0] AXI_SIZE_4B   = 3'b010;
    localparam logic [AXI_SIZE_W-1:0] AXI_SIZE_8B   = 3'b011;
    localparam logic [AXI_SIZE_W-1:0] AXI_SIZE_16B  = 3'b100;
    localparam logic [AXI_SIZE_W-1:0] AXI_SIZE_32B  = 3'b101;
    localparam logic [AXI_SIZE_W-1:0] AXI_SIZE_64B  = 3'b110;
    localparam logic [AXI_SIZE_W-1:0] AXI_SIZE_128B = 3'b111;

    // AxBURST 编码
    localparam logic [AXI_BURST_W-1:0] AXI_BURST_FIXED = 2'b00;
    localparam logic [AXI_BURST_W-1:0] AXI_BURST_INCR  = 2'b01;
    localparam logic [AXI_BURST_W-1:0] AXI_BURST_WRAP  = 2'b10;
    localparam logic [AXI_BURST_W-1:0] AXI_BURST_RSV   = 2'b11;

    // xRESP 编码
    localparam logic [AXI_RESP_W-1:0] AXI_RESP_OKAY   = 2'b00;
    localparam logic [AXI_RESP_W-1:0] AXI_RESP_EXOK   = 2'b01;
    localparam logic [AXI_RESP_W-1:0] AXI_RESP_SLVERR = 2'b10;
    localparam logic [AXI_RESP_W-1:0] AXI_RESP_DECERR = 2'b11;

endpackage : axi_pkg
