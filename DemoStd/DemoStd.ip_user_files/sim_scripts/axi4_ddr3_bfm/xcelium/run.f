-makelib xcelium_lib/xpm -sv \
  "C:/Xilinx/Vivado/2020.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \
-endlib
-makelib xcelium_lib/xpm \
  "C:/Xilinx/Vivado/2020.1/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib xcelium_lib/microblaze_v11_0_3 \
  "../../../ipstatic/hdl/microblaze_v11_0_vh_rfs.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/bd_0/ip/ip_0/sim/bd_994a_microblaze_I_0.vhd" \
-endlib
-makelib xcelium_lib/lib_cdc_v1_0_2 \
  "../../../ipstatic/hdl/lib_cdc_v1_0_rfs.vhd" \
-endlib
-makelib xcelium_lib/proc_sys_reset_v5_0_13 \
  "../../../ipstatic/hdl/proc_sys_reset_v5_0_vh_rfs.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/bd_0/ip/ip_1/sim/bd_994a_rst_0_0.vhd" \
-endlib
-makelib xcelium_lib/lmb_v10_v3_0_11 \
  "../../../ipstatic/hdl/lmb_v10_v3_0_vh_rfs.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/bd_0/ip/ip_2/sim/bd_994a_ilmb_0.vhd" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/bd_0/ip/ip_3/sim/bd_994a_dlmb_0.vhd" \
-endlib
-makelib xcelium_lib/lmb_bram_if_cntlr_v4_0_18 \
  "../../../ipstatic/hdl/lmb_bram_if_cntlr_v4_0_vh_rfs.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/bd_0/ip/ip_4/sim/bd_994a_dlmb_cntlr_0.vhd" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/bd_0/ip/ip_5/sim/bd_994a_ilmb_cntlr_0.vhd" \
-endlib
-makelib xcelium_lib/blk_mem_gen_v8_4_4 \
  "../../../ipstatic/simulation/blk_mem_gen_v8_4.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/bd_0/ip/ip_6/sim/bd_994a_lmb_bram_I_0.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/bd_0/ip/ip_7/sim/bd_994a_second_dlmb_cntlr_0.vhd" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/bd_0/ip/ip_8/sim/bd_994a_second_ilmb_cntlr_0.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/bd_0/ip/ip_9/sim/bd_994a_second_lmb_bram_I_0.v" \
-endlib
-makelib xcelium_lib/iomodule_v3_1_6 \
  "../../../ipstatic/hdl/iomodule_v3_1_vh_rfs.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/bd_0/ip/ip_10/sim/bd_994a_iomodule_0_0.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/bd_0/sim/bd_994a.v" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/ip_0/sim/axi4_ddr3_bfm_microblaze_mcs.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib -sv \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/phy/axi4_ddr3_bfm_phy_ddr3.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/phy/ddr3_phy_v1_4_xiphy_behav.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/phy/ddr3_phy_v1_4_xiphy.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/iob/ddr3_phy_v1_4_iob_byte.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/iob/ddr3_phy_v1_4_iob.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/clocking/ddr3_phy_v1_4_pll.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/xiphy_files/ddr3_phy_v1_4_xiphy_tristate_wrapper.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/xiphy_files/ddr3_phy_v1_4_xiphy_riuor_wrapper.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/xiphy_files/ddr3_phy_v1_4_xiphy_control_wrapper.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/xiphy_files/ddr3_phy_v1_4_xiphy_byte_wrapper.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/xiphy_files/ddr3_phy_v1_4_xiphy_bitslice_wrapper.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/ip_top/axi4_ddr3_bfm_phy.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_wtr.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_ref.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_rd_wr.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_periodic.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_group.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_ecc_merge_enc.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_ecc_gen.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_ecc_fi_xor.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_ecc_dec_fix.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_ecc_buf.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_ecc.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_ctl.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_cmd_mux_c.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_cmd_mux_ap.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_arb_p.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_arb_mux_p.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_arb_c.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_arb_a.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_act_timer.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_act_rank.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/ui/ddr3_v1_4_ui_wr_data.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/ui/ddr3_v1_4_ui_rd_data.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/ui/ddr3_v1_4_ui_cmd.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/ui/ddr3_v1_4_ui.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_ar_channel.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_aw_channel.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_b_channel.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_cmd_arbiter.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_cmd_fsm.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_cmd_translator.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_fifo.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_incr_cmd.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_r_channel.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_w_channel.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_wr_cmd_fsm.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_wrap_cmd.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_a_upsizer.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_register_slice.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_upsizer.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axic_register_slice.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_carry_and.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_carry_latch_and.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_carry_latch_or.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_carry_or.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_command_fifo.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_comparator.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_comparator_sel.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_comparator_sel_static.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_r_upsizer.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_w_upsizer.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi_ctrl/ddr3_v1_4_axi_ctrl_addr_decode.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi_ctrl/ddr3_v1_4_axi_ctrl_read.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi_ctrl/ddr3_v1_4_axi_ctrl_reg_bank.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi_ctrl/ddr3_v1_4_axi_ctrl_reg.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi_ctrl/ddr3_v1_4_axi_ctrl_top.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi_ctrl/ddr3_v1_4_axi_ctrl_write.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/clocking/ddr3_v1_4_infrastructure.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_xsdb_bram.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_write.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_wr_byte.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_wr_bit.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_sync.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_read.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_rd_en.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_pi.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_odt.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_mc_odt.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_debug_microblaze.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_cplx_data.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_cplx.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_config_rom.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_bfifo.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_addr_decode.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_top.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_xsdb_arbiter.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_chipscope_xsdb_slave.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_dp_AB9.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/ip_top/axi4_ddr3_bfm_ddr3.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/ip_top/axi4_ddr3_bfm_ddr3_mem_intfc.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/axi4_ddr3_bfm_ddr3_cal_riu.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/ip_top/axi4_ddr3_bfm.sv" \
  "../../../../DemoStd.srcs/sources_1/ip/axi4_ddr3_bfm/tb/microblaze_mcs_0.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  glbl.v
-endlib

