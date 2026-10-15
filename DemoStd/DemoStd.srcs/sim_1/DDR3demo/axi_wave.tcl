set root /tb_ddr3_axi_demo
set curr_wave [current_wave_config]
if {[string length $curr_wave] == 0} {
    create_wave_config
}
set overview [add_wave_group {01 Overview}]
add_wave -into $overview $root/ui_clk $root/calib_done $root/done $root/pass $root/error_count
add_wave -into $overview -radix unsigned $root/aw_count $root/w_count $root/b_count $root/ar_count $root/r_count

set write [add_wave_group {02 Write AXI}]
add_wave -into $write $root/awvalid $root/awready $root/aw_fire
add_wave -into $write -radix hex $root/awaddr
add_wave -into $write -radix unsigned $root/awlen
add_wave -into $write $root/wvalid $root/wready $root/w_fire
add_wave -into $write -radix unsigned $root/write_word_number $root/write_word_data
add_wave -into $write $root/wlast $root/bvalid $root/bready $root/b_fire
add_wave -into $write -radix hex $root/bresp

set read [add_wave_group {03 Read AXI}]
add_wave -into $read $root/arvalid $root/arready $root/ar_fire
add_wave -into $read -radix hex $root/araddr
add_wave -into $read -radix unsigned $root/arlen
add_wave -into $read $root/rvalid $root/rready $root/r_fire
add_wave -into $read -radix unsigned $root/read_word_number $root/read_word_data $root/read_word_expected
add_wave -into $read $root/read_word_ok $root/rlast
add_wave -into $read -radix hex $root/rresp

set detail [add_wave_group {04 Burst details}]
add_wave -into $detail -radix unsigned $root/write_burst_beats $root/read_burst_beats
add_wave -into $detail -radix hex $root/awsize $root/awburst $root/wstrb $root/arsize $root/arburst
add_wave -into $detail $root/wdata $root/rdata

set physical [add_wave_group {05 DDR model}]
add_wave -into $physical $root/sys_rst $root/ui_rst $root/axi_resetn $root/ddr_reset_n $root/ddr_ck_p $root/model_ck_p $root/ddr_cke
run 20 us
