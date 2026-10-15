set root /tb_ddr3_native_demo
set curr_wave [current_wave_config]
if {[string length $curr_wave] == 0} {
    create_wave_config
}
set overview [add_wave_group {01 Overview}]
add_wave -into $overview $root/ui_clk $root/calib_done $root/done $root/pass $root/error_count
add_wave -into $overview -radix unsigned $root/write_cmd_count $root/w_count $root/read_cmd_count $root/read_chunk_count $root/r_count

set write_cmd [add_wave_group {02 Write command}]
add_wave -into $write_cmd $root/app_en $root/app_rdy $root/write_fire
add_wave -into $write_cmd -radix hex $root/app_cmd $root/app_addr

set write_data [add_wave_group {03 Write data (256-bit)}]
add_wave -into $write_data $root/app_wdf_wren $root/app_wdf_rdy $root/write_fire $root/app_wdf_end
add_wave -into $write_data -radix hex $root/app_wdf_mask $root/app_wdf_data
add_wave -into $write_data $root/write_word_fire
add_wave -into $write_data -radix unsigned $root/write_lane $root/write_word_number $root/write_word_data

set read_cmd [add_wave_group {04 Read command}]
add_wave -into $read_cmd $root/app_en $root/app_rdy $root/read_cmd_fire
add_wave -into $read_cmd -radix hex $root/app_cmd $root/app_addr

set read_data [add_wave_group {05 Read data and check}]
add_wave -into $read_data $root/app_rd_data_valid $root/app_rd_data_end $root/read_fire
add_wave -into $read_data -radix hex $root/app_rd_data
add_wave -into $read_data $root/read_word_fire
add_wave -into $read_data -radix unsigned $root/read_lane $root/read_word_number $root/read_word_data $root/read_word_expected
add_wave -into $read_data $root/read_word_ok

set physical [add_wave_group {06 DDR model}]
add_wave -into $physical $root/sys_rst $root/ui_rst $root/native_resetn $root/ddr_reset_n $root/ddr_ck_p $root/model_ck_p $root/ddr_cke
run 20 us
