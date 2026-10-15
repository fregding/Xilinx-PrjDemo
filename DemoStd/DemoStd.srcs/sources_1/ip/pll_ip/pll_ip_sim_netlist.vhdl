-- Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2020.1 (win64) Build 2902540 Wed May 27 19:54:49 MDT 2020
-- Date        : Sun Oct 11 17:26:03 2026
-- Host        : tidytong running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode funcsim
--               d:/code/SystemVerilog/DemoStd/DemoStd.srcs/sources_1/ip/pll_ip/pll_ip_sim_netlist.vhdl
-- Design      : pll_ip
-- Purpose     : This VHDL netlist is a functional simulation representation of the design and should not be modified or
--               synthesized. This netlist cannot be used for SDF annotated simulation.
-- Device      : xcku115-flva1517-2-e
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity pll_ip_pll_ip_clk_wiz is
  port (
    clk_out1 : out STD_LOGIC;
    clk_out2 : out STD_LOGIC;
    reset : in STD_LOGIC;
    locked : out STD_LOGIC;
    clk_in1 : in STD_LOGIC
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of pll_ip_pll_ip_clk_wiz : entity is "pll_ip_clk_wiz";
end pll_ip_pll_ip_clk_wiz;

architecture STRUCTURE of pll_ip_pll_ip_clk_wiz is
  signal clk_in1_pll_ip : STD_LOGIC;
  signal clk_out1_pll_ip : STD_LOGIC;
  signal clk_out2_pll_ip : STD_LOGIC;
  signal NLW_plle3_adv_inst_CLKFBIN_UNCONNECTED : STD_LOGIC;
  signal NLW_plle3_adv_inst_CLKFBOUT_UNCONNECTED : STD_LOGIC;
  signal NLW_plle3_adv_inst_CLKOUT0B_UNCONNECTED : STD_LOGIC;
  signal NLW_plle3_adv_inst_CLKOUT1B_UNCONNECTED : STD_LOGIC;
  signal NLW_plle3_adv_inst_CLKOUTPHY_UNCONNECTED : STD_LOGIC;
  signal NLW_plle3_adv_inst_DRDY_UNCONNECTED : STD_LOGIC;
  signal NLW_plle3_adv_inst_DO_UNCONNECTED : STD_LOGIC_VECTOR ( 15 downto 0 );
  attribute BOX_TYPE : string;
  attribute BOX_TYPE of clkin1_ibuf : label is "PRIMITIVE";
  attribute CAPACITANCE : string;
  attribute CAPACITANCE of clkin1_ibuf : label is "DONT_CARE";
  attribute IBUF_DELAY_VALUE : string;
  attribute IBUF_DELAY_VALUE of clkin1_ibuf : label is "0";
  attribute IFD_DELAY_VALUE : string;
  attribute IFD_DELAY_VALUE of clkin1_ibuf : label is "AUTO";
  attribute BOX_TYPE of clkout1_buf : label is "PRIMITIVE";
  attribute XILINX_LEGACY_PRIM : string;
  attribute XILINX_LEGACY_PRIM of clkout1_buf : label is "BUFG";
  attribute BOX_TYPE of clkout2_buf : label is "PRIMITIVE";
  attribute XILINX_LEGACY_PRIM of clkout2_buf : label is "BUFG";
  attribute BOX_TYPE of plle3_adv_inst : label is "PRIMITIVE";
  attribute OPT_MODIFIED : string;
  attribute OPT_MODIFIED of plle3_adv_inst : label is "MLO";
begin
clkin1_ibuf: unisim.vcomponents.IBUF
    generic map(
      IOSTANDARD => "DEFAULT"
    )
        port map (
      I => clk_in1,
      O => clk_in1_pll_ip
    );
clkout1_buf: unisim.vcomponents.BUFGCE
    generic map(
      CE_TYPE => "ASYNC",
      SIM_DEVICE => "ULTRASCALE"
    )
        port map (
      CE => '1',
      I => clk_out1_pll_ip,
      O => clk_out1
    );
clkout2_buf: unisim.vcomponents.BUFGCE
    generic map(
      CE_TYPE => "ASYNC",
      SIM_DEVICE => "ULTRASCALE"
    )
        port map (
      CE => '1',
      I => clk_out2_pll_ip,
      O => clk_out2
    );
plle3_adv_inst: unisim.vcomponents.PLLE3_ADV
    generic map(
      CLKFBOUT_MULT => 6,
      CLKFBOUT_PHASE => 0.000000,
      CLKIN_PERIOD => 10.000000,
      CLKOUT0_DIVIDE => 6,
      CLKOUT0_DUTY_CYCLE => 0.500000,
      CLKOUT0_PHASE => 0.000000,
      CLKOUT1_DIVIDE => 24,
      CLKOUT1_DUTY_CYCLE => 0.500000,
      CLKOUT1_PHASE => 90.000000,
      CLKOUTPHY_MODE => "VCO_2X",
      COMPENSATION => "INTERNAL",
      DIVCLK_DIVIDE => 1,
      IS_CLKFBIN_INVERTED => '0',
      IS_CLKIN_INVERTED => '0',
      IS_PWRDWN_INVERTED => '0',
      IS_RST_INVERTED => '0',
      REF_JITTER => 0.010000,
      STARTUP_WAIT => "FALSE"
    )
        port map (
      CLKFBIN => NLW_plle3_adv_inst_CLKFBIN_UNCONNECTED,
      CLKFBOUT => NLW_plle3_adv_inst_CLKFBOUT_UNCONNECTED,
      CLKIN => clk_in1_pll_ip,
      CLKOUT0 => clk_out1_pll_ip,
      CLKOUT0B => NLW_plle3_adv_inst_CLKOUT0B_UNCONNECTED,
      CLKOUT1 => clk_out2_pll_ip,
      CLKOUT1B => NLW_plle3_adv_inst_CLKOUT1B_UNCONNECTED,
      CLKOUTPHY => NLW_plle3_adv_inst_CLKOUTPHY_UNCONNECTED,
      CLKOUTPHYEN => '0',
      DADDR(6 downto 0) => B"0000000",
      DCLK => '0',
      DEN => '0',
      DI(15 downto 0) => B"0000000000000000",
      DO(15 downto 0) => NLW_plle3_adv_inst_DO_UNCONNECTED(15 downto 0),
      DRDY => NLW_plle3_adv_inst_DRDY_UNCONNECTED,
      DWE => '0',
      LOCKED => locked,
      PWRDWN => '0',
      RST => reset
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity pll_ip is
  port (
    clk_out1 : out STD_LOGIC;
    clk_out2 : out STD_LOGIC;
    reset : in STD_LOGIC;
    locked : out STD_LOGIC;
    clk_in1 : in STD_LOGIC
  );
  attribute NotValidForBitStream : boolean;
  attribute NotValidForBitStream of pll_ip : entity is true;
end pll_ip;

architecture STRUCTURE of pll_ip is
begin
inst: entity work.pll_ip_pll_ip_clk_wiz
     port map (
      clk_in1 => clk_in1,
      clk_out1 => clk_out1,
      clk_out2 => clk_out2,
      locked => locked,
      reset => reset
    );
end STRUCTURE;
