vlib work
vlib riviera

vlib riviera/xpm
vlib riviera/microblaze_v11_0_3
vlib riviera/xil_defaultlib
vlib riviera/lib_cdc_v1_0_2
vlib riviera/proc_sys_reset_v5_0_13
vlib riviera/lmb_v10_v3_0_11
vlib riviera/lmb_bram_if_cntlr_v4_0_18
vlib riviera/blk_mem_gen_v8_4_4
vlib riviera/iomodule_v3_1_6

vmap xpm riviera/xpm
vmap microblaze_v11_0_3 riviera/microblaze_v11_0_3
vmap xil_defaultlib riviera/xil_defaultlib
vmap lib_cdc_v1_0_2 riviera/lib_cdc_v1_0_2
vmap proc_sys_reset_v5_0_13 riviera/proc_sys_reset_v5_0_13
vmap lmb_v10_v3_0_11 riviera/lmb_v10_v3_0_11
vmap lmb_bram_if_cntlr_v4_0_18 riviera/lmb_bram_if_cntlr_v4_0_18
vmap blk_mem_gen_v8_4_4 riviera/blk_mem_gen_v8_4_4
vmap iomodule_v3_1_6 riviera/iomodule_v3_1_6

vlog -work xpm  -sv2k12 "+incdir+../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/map" "+incdir+../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/ip_top" "+incdir+../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal" \
"C:/Xilinx/Vivado/2020.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93 \
"C:/Xilinx/Vivado/2020.1/data/ip/xpm/xpm_VCOMP.vhd" \

vcom -work microblaze_v11_0_3 -93 \
"../../../ipstatic/hdl/microblaze_v11_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93 \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/bd_0/ip/ip_0/sim/bd_994a_microblaze_I_0.vhd" \

vcom -work lib_cdc_v1_0_2 -93 \
"../../../ipstatic/hdl/lib_cdc_v1_0_rfs.vhd" \

vcom -work proc_sys_reset_v5_0_13 -93 \
"../../../ipstatic/hdl/proc_sys_reset_v5_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93 \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/bd_0/ip/ip_1/sim/bd_994a_rst_0_0.vhd" \

vcom -work lmb_v10_v3_0_11 -93 \
"../../../ipstatic/hdl/lmb_v10_v3_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93 \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/bd_0/ip/ip_2/sim/bd_994a_ilmb_0.vhd" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/bd_0/ip/ip_3/sim/bd_994a_dlmb_0.vhd" \

vcom -work lmb_bram_if_cntlr_v4_0_18 -93 \
"../../../ipstatic/hdl/lmb_bram_if_cntlr_v4_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93 \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/bd_0/ip/ip_4/sim/bd_994a_dlmb_cntlr_0.vhd" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/bd_0/ip/ip_5/sim/bd_994a_ilmb_cntlr_0.vhd" \

vlog -work blk_mem_gen_v8_4_4  -v2k5 "+incdir+../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/map" "+incdir+../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/ip_top" "+incdir+../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal" \
"../../../ipstatic/simulation/blk_mem_gen_v8_4.v" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/map" "+incdir+../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/ip_top" "+incdir+../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/bd_0/ip/ip_6/sim/bd_994a_lmb_bram_I_0.v" \

vcom -work xil_defaultlib -93 \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/bd_0/ip/ip_7/sim/bd_994a_second_dlmb_cntlr_0.vhd" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/bd_0/ip/ip_8/sim/bd_994a_second_ilmb_cntlr_0.vhd" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/map" "+incdir+../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/ip_top" "+incdir+../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/bd_0/ip/ip_9/sim/bd_994a_second_lmb_bram_I_0.v" \

vcom -work iomodule_v3_1_6 -93 \
"../../../ipstatic/hdl/iomodule_v3_1_vh_rfs.vhd" \

vcom -work xil_defaultlib -93 \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/bd_0/ip/ip_10/sim/bd_994a_iomodule_0_0.vhd" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/map" "+incdir+../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/ip_top" "+incdir+../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/bd_0/sim/bd_994a.v" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/ip_0/sim/axi4_ddr3_bfm_microblaze_mcs.v" \

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/map" "+incdir+../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/ip_top" "+incdir+../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/phy/axi4_ddr3_bfm_phy_ddr3.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/phy/ddr3_phy_v1_4_xiphy_behav.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/phy/ddr3_phy_v1_4_xiphy.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/iob/ddr3_phy_v1_4_iob_byte.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/iob/ddr3_phy_v1_4_iob.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/clocking/ddr3_phy_v1_4_pll.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/xiphy_files/ddr3_phy_v1_4_xiphy_tristate_wrapper.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/xiphy_files/ddr3_phy_v1_4_xiphy_riuor_wrapper.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/xiphy_files/ddr3_phy_v1_4_xiphy_control_wrapper.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/xiphy_files/ddr3_phy_v1_4_xiphy_byte_wrapper.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/xiphy_files/ddr3_phy_v1_4_xiphy_bitslice_wrapper.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/ip_1/rtl/ip_top/axi4_ddr3_bfm_phy.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_wtr.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_ref.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_rd_wr.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_periodic.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_group.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_ecc_merge_enc.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_ecc_gen.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_ecc_fi_xor.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_ecc_dec_fix.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_ecc_buf.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_ecc.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_ctl.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_cmd_mux_c.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_cmd_mux_ap.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_arb_p.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_arb_mux_p.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_arb_c.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_arb_a.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_act_timer.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc_act_rank.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/controller/ddr3_v1_4_mc.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/ui/ddr3_v1_4_ui_wr_data.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/ui/ddr3_v1_4_ui_rd_data.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/ui/ddr3_v1_4_ui_cmd.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/ui/ddr3_v1_4_ui.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_ar_channel.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_aw_channel.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_b_channel.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_cmd_arbiter.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_cmd_fsm.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_cmd_translator.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_fifo.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_incr_cmd.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_r_channel.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_w_channel.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_wr_cmd_fsm.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_wrap_cmd.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_a_upsizer.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_register_slice.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axi_upsizer.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_axic_register_slice.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_carry_and.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_carry_latch_and.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_carry_latch_or.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_carry_or.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_command_fifo.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_comparator.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_comparator_sel.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_comparator_sel_static.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_r_upsizer.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi/ddr3_v1_4_w_upsizer.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi_ctrl/ddr3_v1_4_axi_ctrl_addr_decode.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi_ctrl/ddr3_v1_4_axi_ctrl_read.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi_ctrl/ddr3_v1_4_axi_ctrl_reg_bank.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi_ctrl/ddr3_v1_4_axi_ctrl_reg.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi_ctrl/ddr3_v1_4_axi_ctrl_top.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/axi_ctrl/ddr3_v1_4_axi_ctrl_write.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/clocking/ddr3_v1_4_infrastructure.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_xsdb_bram.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_write.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_wr_byte.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_wr_bit.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_sync.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_read.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_rd_en.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_pi.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_odt.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_mc_odt.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_debug_microblaze.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_cplx_data.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_cplx.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_config_rom.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_bfifo.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_addr_decode.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_top.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal_xsdb_arbiter.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_cal.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_chipscope_xsdb_slave.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/ddr3_v1_4_dp_AB9.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/ip_top/axi4_ddr3_bfm_ddr3.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/ip_top/axi4_ddr3_bfm_ddr3_mem_intfc.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/cal/axi4_ddr3_bfm_ddr3_cal_riu.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/rtl/ip_top/axi4_ddr3_bfm.sv" \
"../../../../axi4_ddr3_bfm_ex.srcs/sources_1/ip/axi4_ddr3_bfm/tb/microblaze_mcs_0.sv" \

vlog -work xil_defaultlib \
"glbl.v"

