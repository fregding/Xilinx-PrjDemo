-- Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2020.1 (win64) Build 2902540 Wed May 27 19:54:49 MDT 2020
-- Date        : Wed Oct 14 21:15:00 2026
-- Host        : tidytong running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               d:/code/SystemVerilog/DemoStd/DemoStd.srcs/sources_1/ip/native_ddr3_bfm/native_ddr3_bfm_stub.vhdl
-- Design      : native_ddr3_bfm
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xcku115-flva1517-2-e
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity native_ddr3_bfm is
  Port ( 
    sys_rst : in STD_LOGIC;
    c0_sys_clk_i : in STD_LOGIC;
    c0_ddr3_addr : out STD_LOGIC_VECTOR ( 13 downto 0 );
    c0_ddr3_ba : out STD_LOGIC_VECTOR ( 2 downto 0 );
    c0_ddr3_ras_n : out STD_LOGIC;
    c0_ddr3_cas_n : out STD_LOGIC;
    c0_ddr3_we_n : out STD_LOGIC;
    c0_ddr3_cke : out STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr3_odt : out STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr3_cs_n : out STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr3_ck_p : out STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr3_ck_n : out STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr3_reset_n : out STD_LOGIC;
    c0_ddr3_dm : out STD_LOGIC_VECTOR ( 3 downto 0 );
    c0_ddr3_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
    c0_ddr3_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    c0_ddr3_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    c0_init_calib_complete : out STD_LOGIC;
    c0_ddr3_ui_clk : out STD_LOGIC;
    c0_ddr3_ui_clk_sync_rst : out STD_LOGIC;
    dbg_clk : out STD_LOGIC;
    c0_ddr3_app_addr : in STD_LOGIC_VECTOR ( 26 downto 0 );
    c0_ddr3_app_cmd : in STD_LOGIC_VECTOR ( 2 downto 0 );
    c0_ddr3_app_en : in STD_LOGIC;
    c0_ddr3_app_hi_pri : in STD_LOGIC;
    c0_ddr3_app_wdf_data : in STD_LOGIC_VECTOR ( 255 downto 0 );
    c0_ddr3_app_wdf_end : in STD_LOGIC;
    c0_ddr3_app_wdf_mask : in STD_LOGIC_VECTOR ( 31 downto 0 );
    c0_ddr3_app_wdf_wren : in STD_LOGIC;
    c0_ddr3_app_rd_data : out STD_LOGIC_VECTOR ( 255 downto 0 );
    c0_ddr3_app_rd_data_end : out STD_LOGIC;
    c0_ddr3_app_rd_data_valid : out STD_LOGIC;
    c0_ddr3_app_rdy : out STD_LOGIC;
    c0_ddr3_app_wdf_rdy : out STD_LOGIC;
    dbg_bus : out STD_LOGIC_VECTOR ( 511 downto 0 )
  );

end native_ddr3_bfm;

architecture stub of native_ddr3_bfm is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "sys_rst,c0_sys_clk_i,c0_ddr3_addr[13:0],c0_ddr3_ba[2:0],c0_ddr3_ras_n,c0_ddr3_cas_n,c0_ddr3_we_n,c0_ddr3_cke[0:0],c0_ddr3_odt[0:0],c0_ddr3_cs_n[0:0],c0_ddr3_ck_p[0:0],c0_ddr3_ck_n[0:0],c0_ddr3_reset_n,c0_ddr3_dm[3:0],c0_ddr3_dq[31:0],c0_ddr3_dqs_p[3:0],c0_ddr3_dqs_n[3:0],c0_init_calib_complete,c0_ddr3_ui_clk,c0_ddr3_ui_clk_sync_rst,dbg_clk,c0_ddr3_app_addr[26:0],c0_ddr3_app_cmd[2:0],c0_ddr3_app_en,c0_ddr3_app_hi_pri,c0_ddr3_app_wdf_data[255:0],c0_ddr3_app_wdf_end,c0_ddr3_app_wdf_mask[31:0],c0_ddr3_app_wdf_wren,c0_ddr3_app_rd_data[255:0],c0_ddr3_app_rd_data_end,c0_ddr3_app_rd_data_valid,c0_ddr3_app_rdy,c0_ddr3_app_wdf_rdy,dbg_bus[511:0]";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "ddr3_v1_4_9,Vivado 2020.1";
begin
end;
