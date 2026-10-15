// (c) Copyright 1995-2026 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
// DO NOT MODIFY THIS FILE.

// IP VLNV: xilinx.com:ip:ddr3:1.4
// IP Revision: 9

// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
native_ddr3_bfm your_instance_name (
  .c0_init_calib_complete(c0_init_calib_complete),        // output wire c0_init_calib_complete
  .dbg_clk(dbg_clk),                                      // output wire dbg_clk
  .c0_sys_clk_i(c0_sys_clk_i),                            // input wire c0_sys_clk_i
  .dbg_bus(dbg_bus),                                      // output wire [511 : 0] dbg_bus
  .c0_ddr3_addr(c0_ddr3_addr),                            // output wire [13 : 0] c0_ddr3_addr
  .c0_ddr3_ba(c0_ddr3_ba),                                // output wire [2 : 0] c0_ddr3_ba
  .c0_ddr3_cas_n(c0_ddr3_cas_n),                          // output wire c0_ddr3_cas_n
  .c0_ddr3_cke(c0_ddr3_cke),                              // output wire [0 : 0] c0_ddr3_cke
  .c0_ddr3_ck_n(c0_ddr3_ck_n),                            // output wire [0 : 0] c0_ddr3_ck_n
  .c0_ddr3_ck_p(c0_ddr3_ck_p),                            // output wire [0 : 0] c0_ddr3_ck_p
  .c0_ddr3_cs_n(c0_ddr3_cs_n),                            // output wire [0 : 0] c0_ddr3_cs_n
  .c0_ddr3_dm(c0_ddr3_dm),                                // output wire [3 : 0] c0_ddr3_dm
  .c0_ddr3_dq(c0_ddr3_dq),                                // inout wire [31 : 0] c0_ddr3_dq
  .c0_ddr3_dqs_n(c0_ddr3_dqs_n),                          // inout wire [3 : 0] c0_ddr3_dqs_n
  .c0_ddr3_dqs_p(c0_ddr3_dqs_p),                          // inout wire [3 : 0] c0_ddr3_dqs_p
  .c0_ddr3_odt(c0_ddr3_odt),                              // output wire [0 : 0] c0_ddr3_odt
  .c0_ddr3_ras_n(c0_ddr3_ras_n),                          // output wire c0_ddr3_ras_n
  .c0_ddr3_reset_n(c0_ddr3_reset_n),                      // output wire c0_ddr3_reset_n
  .c0_ddr3_we_n(c0_ddr3_we_n),                            // output wire c0_ddr3_we_n
  .c0_ddr3_ui_clk(c0_ddr3_ui_clk),                        // output wire c0_ddr3_ui_clk
  .c0_ddr3_ui_clk_sync_rst(c0_ddr3_ui_clk_sync_rst),      // output wire c0_ddr3_ui_clk_sync_rst
  .c0_ddr3_app_en(c0_ddr3_app_en),                        // input wire c0_ddr3_app_en
  .c0_ddr3_app_hi_pri(c0_ddr3_app_hi_pri),                // input wire c0_ddr3_app_hi_pri
  .c0_ddr3_app_wdf_end(c0_ddr3_app_wdf_end),              // input wire c0_ddr3_app_wdf_end
  .c0_ddr3_app_wdf_wren(c0_ddr3_app_wdf_wren),            // input wire c0_ddr3_app_wdf_wren
  .c0_ddr3_app_rd_data_end(c0_ddr3_app_rd_data_end),      // output wire c0_ddr3_app_rd_data_end
  .c0_ddr3_app_rd_data_valid(c0_ddr3_app_rd_data_valid),  // output wire c0_ddr3_app_rd_data_valid
  .c0_ddr3_app_rdy(c0_ddr3_app_rdy),                      // output wire c0_ddr3_app_rdy
  .c0_ddr3_app_wdf_rdy(c0_ddr3_app_wdf_rdy),              // output wire c0_ddr3_app_wdf_rdy
  .c0_ddr3_app_addr(c0_ddr3_app_addr),                    // input wire [26 : 0] c0_ddr3_app_addr
  .c0_ddr3_app_cmd(c0_ddr3_app_cmd),                      // input wire [2 : 0] c0_ddr3_app_cmd
  .c0_ddr3_app_wdf_data(c0_ddr3_app_wdf_data),            // input wire [255 : 0] c0_ddr3_app_wdf_data
  .c0_ddr3_app_wdf_mask(c0_ddr3_app_wdf_mask),            // input wire [31 : 0] c0_ddr3_app_wdf_mask
  .c0_ddr3_app_rd_data(c0_ddr3_app_rd_data),              // output wire [255 : 0] c0_ddr3_app_rd_data
  .sys_rst(sys_rst)                                      // input wire sys_rst
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

// You must compile the wrapper file native_ddr3_bfm.v when simulating
// the core, native_ddr3_bfm. When compiling the wrapper file, be sure to
// reference the Verilog simulation library.

