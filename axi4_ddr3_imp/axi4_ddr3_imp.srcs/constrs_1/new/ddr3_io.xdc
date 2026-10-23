#-----------------------------------------------------------------------------
# File name : ddr3_io.xdc
# Description : 板级引脚与时钟约束（xcku115-flva1517-2-e）
#   - 系统时钟：差分 70MHz（周期 14.286ns），与 MIG InputClockPeriod=14286 一致
#   - DDR3 物理口：MIG 配为 8bit 单字节通道，接到板卡 32bit 总线的 lane0
#     （dq[7:0] / dm[0] / dqs_p[0] / dqs_n[0]），其余字节 lane 不接
#   - 引脚来源：DemoStd 板卡 DDRdemo.xdc（同器件、同颗粒 MT41J256M16）
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
# 系统时钟（差分 70MHz）与复位
#-----------------------------------------------------------------------------
create_clock -name sys_clk -period 14.286 [get_ports c0_sys_clk_p]

set_property PACKAGE_PIN AL17 [get_ports c0_sys_clk_p]
set_property PACKAGE_PIN AM17 [get_ports c0_sys_clk_n]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {c0_sys_clk_p c0_sys_clk_n}]

# 复位（高有效）
set_property PACKAGE_PIN AN16 [get_ports sys_rst]
set_property IOSTANDARD LVCMOS15 [get_ports sys_rst]

#-----------------------------------------------------------------------------
# DDR3 地址 / 命令 / 控制
#-----------------------------------------------------------------------------
set_property PACKAGE_PIN AL19 [get_ports {c0_ddr3_addr[0]}]
set_property PACKAGE_PIN AL18 [get_ports {c0_ddr3_addr[1]}]
set_property PACKAGE_PIN AJ16 [get_ports {c0_ddr3_addr[2]}]
set_property PACKAGE_PIN AK16 [get_ports {c0_ddr3_addr[3]}]
set_property PACKAGE_PIN AH17 [get_ports {c0_ddr3_addr[4]}]
set_property PACKAGE_PIN AH16 [get_ports {c0_ddr3_addr[5]}]
set_property PACKAGE_PIN AJ19 [get_ports {c0_ddr3_addr[6]}]
set_property PACKAGE_PIN AJ18 [get_ports {c0_ddr3_addr[7]}]
set_property PACKAGE_PIN AM16 [get_ports {c0_ddr3_addr[8]}]
set_property PACKAGE_PIN AG17 [get_ports {c0_ddr3_addr[9]}]
set_property PACKAGE_PIN AG16 [get_ports {c0_ddr3_addr[10]}]
set_property PACKAGE_PIN AH19 [get_ports {c0_ddr3_addr[11]}]
set_property PACKAGE_PIN AH18 [get_ports {c0_ddr3_addr[12]}]
set_property PACKAGE_PIN AD16 [get_ports {c0_ddr3_addr[13]}]
set_property PACKAGE_PIN AE16 [get_ports {c0_ddr3_addr[14]}]

set_property PACKAGE_PIN AE18 [get_ports {c0_ddr3_ba[0]}]
set_property PACKAGE_PIN AF18 [get_ports {c0_ddr3_ba[1]}]
set_property PACKAGE_PIN AE17 [get_ports {c0_ddr3_ba[2]}]

set_property PACKAGE_PIN AV17 [get_ports c0_ddr3_ras_n]
set_property PACKAGE_PIN AU20 [get_ports c0_ddr3_cas_n]
set_property PACKAGE_PIN AR17 [get_ports c0_ddr3_we_n]
set_property PACKAGE_PIN AD18 [get_ports c0_ddr3_reset_n]

set_property PACKAGE_PIN AF17 [get_ports {c0_ddr3_cs_n[0]}]
set_property PACKAGE_PIN AF19 [get_ports {c0_ddr3_cke[0]}]
set_property PACKAGE_PIN AG19 [get_ports {c0_ddr3_odt[0]}]

# DDR3 差分时钟
set_property PACKAGE_PIN AK18 [get_ports {c0_ddr3_ck_p[0]}]
set_property PACKAGE_PIN AK17 [get_ports {c0_ddr3_ck_n[0]}]

#-----------------------------------------------------------------------------
# DDR3 数据通道 lane0（8bit）
#-----------------------------------------------------------------------------
set_property PACKAGE_PIN AW20 [get_ports {c0_ddr3_dq[0]}]
set_property PACKAGE_PIN AW19 [get_ports {c0_ddr3_dq[1]}]
set_property PACKAGE_PIN AU17 [get_ports {c0_ddr3_dq[2]}]
set_property PACKAGE_PIN AU16 [get_ports {c0_ddr3_dq[3]}]
set_property PACKAGE_PIN AT18 [get_ports {c0_ddr3_dq[4]}]
set_property PACKAGE_PIN AT17 [get_ports {c0_ddr3_dq[5]}]
set_property PACKAGE_PIN AT19 [get_ports {c0_ddr3_dq[6]}]
set_property PACKAGE_PIN AU19 [get_ports {c0_ddr3_dq[7]}]

set_property PACKAGE_PIN AV18 [get_ports {c0_ddr3_dm[0]}]
set_property PACKAGE_PIN AV19 [get_ports {c0_ddr3_dqs_p[0]}]
set_property PACKAGE_PIN AW18 [get_ports {c0_ddr3_dqs_n[0]}]

#-----------------------------------------------------------------------------
# IOSTANDARD
#-----------------------------------------------------------------------------
set_property IOSTANDARD SSTL15 [get_ports {c0_ddr3_addr[*] c0_ddr3_ba[*] c0_ddr3_ras_n c0_ddr3_cas_n c0_ddr3_we_n c0_ddr3_cs_n[*] c0_ddr3_cke[*] c0_ddr3_odt[*] c0_ddr3_reset_n c0_ddr3_dm[*] c0_ddr3_dq[*]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {c0_ddr3_ck_p[*] c0_ddr3_ck_n[*] c0_ddr3_dqs_p[*] c0_ddr3_dqs_n[*]}]

#-----------------------------------------------------------------------------
# 状态 LED（引脚待按板卡补充）
#-----------------------------------------------------------------------------
# set_property PACKAGE_PIN xx [get_ports led_calib]
# set_property PACKAGE_PIN xx [get_ports led_done]
# set_property PACKAGE_PIN xx [get_ports led_error]
# set_property IOSTANDARD LVCMOS15 [get_ports {led_calib led_done led_error}]
