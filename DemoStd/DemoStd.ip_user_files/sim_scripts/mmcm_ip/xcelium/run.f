-makelib xcelium_lib/xpm -sv \
  "C:/Xilinx/Vivado/2020.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
-endlib
-makelib xcelium_lib/xpm \
  "C:/Xilinx/Vivado/2020.1/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../DemoStd.srcs/sources_1/ip/mmcm_ip/mmcm_ip_clk_wiz.v" \
  "../../../../DemoStd.srcs/sources_1/ip/mmcm_ip/mmcm_ip.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  glbl.v
-endlib

