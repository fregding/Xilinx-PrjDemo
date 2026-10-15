// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.1 (win64) Build 2902540 Wed May 27 19:54:49 MDT 2020
// Date        : Sun Oct 11 20:02:39 2026
// Host        : tidytong running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               d:/code/SystemVerilog/DemoStd/DemoStd.srcs/sources_1/ip/ram_256x8_simpledual/ram_256x8_simpledual_stub.v
// Design      : ram_256x8_simpledual
// Purpose     : Stub declaration of top-level module interface
// Device      : xcku115-flva1517-2-e
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_4,Vivado 2020.1" *)
module ram_256x8_simpledual(clka, ena, wea, addra, dina, clkb, enb, addrb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,ena,wea[0:0],addra[7:0],dina[7:0],clkb,enb,addrb[7:0],doutb[7:0]" */;
  input clka;
  input ena;
  input [0:0]wea;
  input [7:0]addra;
  input [7:0]dina;
  input clkb;
  input enb;
  input [7:0]addrb;
  output [7:0]doutb;
endmodule
