// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.1 (win64) Build 2902540 Wed May 27 19:54:49 MDT 2020
// Date        : Wed Oct 14 21:15:00 2026
// Host        : tidytong running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               d:/code/SystemVerilog/DemoStd/DemoStd.srcs/sources_1/ip/native_ddr3_bfm/native_ddr3_bfm_stub.v
// Design      : native_ddr3_bfm
// Purpose     : Stub declaration of top-level module interface
// Device      : xcku115-flva1517-2-e
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "ddr3_v1_4_9,Vivado 2020.1" *)
module native_ddr3_bfm(sys_rst, c0_sys_clk_i, c0_ddr3_addr, 
  c0_ddr3_ba, c0_ddr3_ras_n, c0_ddr3_cas_n, c0_ddr3_we_n, c0_ddr3_cke, c0_ddr3_odt, 
  c0_ddr3_cs_n, c0_ddr3_ck_p, c0_ddr3_ck_n, c0_ddr3_reset_n, c0_ddr3_dm, c0_ddr3_dq, 
  c0_ddr3_dqs_p, c0_ddr3_dqs_n, c0_init_calib_complete, c0_ddr3_ui_clk, 
  c0_ddr3_ui_clk_sync_rst, dbg_clk, c0_ddr3_app_addr, c0_ddr3_app_cmd, c0_ddr3_app_en, 
  c0_ddr3_app_hi_pri, c0_ddr3_app_wdf_data, c0_ddr3_app_wdf_end, c0_ddr3_app_wdf_mask, 
  c0_ddr3_app_wdf_wren, c0_ddr3_app_rd_data, c0_ddr3_app_rd_data_end, 
  c0_ddr3_app_rd_data_valid, c0_ddr3_app_rdy, c0_ddr3_app_wdf_rdy, dbg_bus)
/* synthesis syn_black_box black_box_pad_pin="sys_rst,c0_sys_clk_i,c0_ddr3_addr[13:0],c0_ddr3_ba[2:0],c0_ddr3_ras_n,c0_ddr3_cas_n,c0_ddr3_we_n,c0_ddr3_cke[0:0],c0_ddr3_odt[0:0],c0_ddr3_cs_n[0:0],c0_ddr3_ck_p[0:0],c0_ddr3_ck_n[0:0],c0_ddr3_reset_n,c0_ddr3_dm[3:0],c0_ddr3_dq[31:0],c0_ddr3_dqs_p[3:0],c0_ddr3_dqs_n[3:0],c0_init_calib_complete,c0_ddr3_ui_clk,c0_ddr3_ui_clk_sync_rst,dbg_clk,c0_ddr3_app_addr[26:0],c0_ddr3_app_cmd[2:0],c0_ddr3_app_en,c0_ddr3_app_hi_pri,c0_ddr3_app_wdf_data[255:0],c0_ddr3_app_wdf_end,c0_ddr3_app_wdf_mask[31:0],c0_ddr3_app_wdf_wren,c0_ddr3_app_rd_data[255:0],c0_ddr3_app_rd_data_end,c0_ddr3_app_rd_data_valid,c0_ddr3_app_rdy,c0_ddr3_app_wdf_rdy,dbg_bus[511:0]" */;
  input sys_rst;
  input c0_sys_clk_i;
  output [13:0]c0_ddr3_addr;
  output [2:0]c0_ddr3_ba;
  output c0_ddr3_ras_n;
  output c0_ddr3_cas_n;
  output c0_ddr3_we_n;
  output [0:0]c0_ddr3_cke;
  output [0:0]c0_ddr3_odt;
  output [0:0]c0_ddr3_cs_n;
  output [0:0]c0_ddr3_ck_p;
  output [0:0]c0_ddr3_ck_n;
  output c0_ddr3_reset_n;
  output [3:0]c0_ddr3_dm;
  inout [31:0]c0_ddr3_dq;
  inout [3:0]c0_ddr3_dqs_p;
  inout [3:0]c0_ddr3_dqs_n;
  output c0_init_calib_complete;
  output c0_ddr3_ui_clk;
  output c0_ddr3_ui_clk_sync_rst;
  output dbg_clk;
  input [26:0]c0_ddr3_app_addr;
  input [2:0]c0_ddr3_app_cmd;
  input c0_ddr3_app_en;
  input c0_ddr3_app_hi_pri;
  input [255:0]c0_ddr3_app_wdf_data;
  input c0_ddr3_app_wdf_end;
  input [31:0]c0_ddr3_app_wdf_mask;
  input c0_ddr3_app_wdf_wren;
  output [255:0]c0_ddr3_app_rd_data;
  output c0_ddr3_app_rd_data_end;
  output c0_ddr3_app_rd_data_valid;
  output c0_ddr3_app_rdy;
  output c0_ddr3_app_wdf_rdy;
  output [511:0]dbg_bus;
endmodule
