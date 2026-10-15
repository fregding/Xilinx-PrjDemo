/******************************************************************************
// (c) Copyright 2013 - 2014 Xilinx, Inc. All rights reserved.
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
******************************************************************************/
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor             : Xilinx
// \   \   \/     Version            : 1.0
//  \   \         Application        : MIG
//  /   /         Filename           : ddr3_v1_4_9_ddr3_assert.vh
// /___/   /\     Date Last Modified : $Date: 2014/09/14 $
// \   \  /  \    Date Created       : Fri Jul 25 2014
//  \___\/\___\
//
// Device           : UltraScale
// Design Name      : DDR3 SDRAM
// Purpose          : To Check the correctness of MIG Generated parameters w.r.to JEDEC Specification. 
//                   
// Reference        :
// Revision History :
//*****************************************************************************

`ifdef MODEL_TECH
    `ifndef CALIB_SIM
       `define SIMULATION
     `endif
`elsif INCA
    `ifndef CALIB_SIM
       `define SIMULATION
     `endif
`elsif VCS
    `ifndef CALIB_SIM
       `define SIMULATION
     `endif
`elsif _VCP 
    `ifndef CALIB_SIM
       `define SIMULATION
     `endif
`elsif XILINX_SIMULATOR 
    `ifndef CALIB_SIM
       `define SIMULATION
     `endif
`endif

`ifdef SKIP_PHY_TOP
   `define PATH u_ddr3_phy
`else
   `define PATH u_mig_ddr3_phy.inst
   `define XIP_PATH u_mig_ddr3_phy.inst.generate_block1.u_ddr_xiphy
`endif


/* Ceiling function :: To calculate ceil value  */
function integer ceil(input integer a,b);
   begin
      if(a % b != 0  ) 
         ceil = a / b + 1;
      else
         ceil = a / b;
   end
  //  $display(" ceil value %d", ceil );
endfunction
/* Ceiling function :: To calculate ceil value  */
function longint ceil_1(input longint a,b);
   begin
      if(a % b != 0  ) 
         ceil_1 = a / b + 1;
      else
         ceil_1 = a / b;
   end
  //  $display(" ceil value %d", ceil );
endfunction

/* Max function :: To calculate Max of two inputs*/
function integer max(input integer a,b);
   begin
      if(a > b)
         max =a;
      else 
         max = b;
   end
endfunction

/* clogb2 :: To calculate log of base2 of a input*/
function integer clogb2 (input integer size);
  begin
    size = size - 1;
    for (clogb2 = 0; size>0 ; clogb2=clogb2+1)
      size = size >> 1;
  end
endfunction // clogb2

/*row_col_trfc task :: 
  To calculate row_width,col_width and trfc 
  based on Memory Density and Memory Width */
task row_col_trfc;
   output [5:0] row_width,col_width;//Expected Row width and column width
   output [8:0] trfc;//Expected trfc
   begin
   case(MEMORY_DENSITY)
      "1Gb":begin
         case(MEMORY_WIDTH)
            "4":begin row_width = 14; col_width = 11; end
            "8":begin row_width = 14; col_width = 10; end
            "16":begin row_width = 13; col_width = 10; end
         endcase
         trfc = ceil(110000,tCK);           
      end
      "2Gb":begin
         case(MEMORY_WIDTH)
            "4":begin row_width = 15; col_width = 11; end
            "8":begin row_width = 15; col_width = 10; end
            "16":begin row_width = 14; col_width = 10; end
         endcase
         trfc = ceil(160000,tCK);
      end
      "4Gb":begin
         case(MEMORY_WIDTH)
            "4":begin row_width = 16; col_width = 11; end
            "8":begin row_width = 16; col_width = 10; end
            "16":begin row_width = 15; col_width = 10; end
         endcase
         trfc = ceil( 260000,tCK);
      end
      "8Gb":begin
         case(MEMORY_WIDTH)
            "4": col_width = 12; 
            "8": col_width = 11; 
            "16": col_width = 10;
         endcase
         row_width = 16;
         trfc = ceil(350000,tCK);
      end
      default: trfc = 0;
   endcase
   end
endtask
 
/* trrd_tfaw_trcd task :: 
   To calculate trrd,tfaw,trcd and trp 
   based on Memory Speed Grade and Memory Width */
task trrd_tfaw_trcd; 
   output [5:0] trrd,tfaw,trcd,trp,tras;//Expected trrd,tfaw,trcd,trp,tras 
   begin
   case(MEMORY_SPEED_GRADE)
      "25","25E":begin
         if(MEMORY_DENSITY == "8Gb")begin 
            trrd = max(4,(ceil(10000,tCK))); tfaw = ceil(50000,tCK);
         end
         else begin
           case(MEMORY_WIDTH) 
            "4","8": begin trrd = max(4,(ceil(10000,tCK))); tfaw = ceil(40000,tCK);end
            "16": begin trrd = max(4,(ceil(10000,tCK))); tfaw = ceil(50000,tCK);end
           endcase 
         end
         case(MEMORY_SPEED_GRADE)
           "25" : trcd = ceil(15000,tCK);
           "25E": trcd = ceil(12500,tCK);
         endcase
        tras = ceil(37500,tCK);
      end
      "187","187E":begin
         if(MEMORY_DENSITY == "8Gb")begin 
            trrd = max(4,(ceil(10000,tCK))); tfaw = ceil(50000,tCK);
         end
         else begin
           case(MEMORY_WIDTH) 
             "4","8" : begin trrd = max(4,(ceil(7500,tCK))); tfaw = ceil(37500,tCK);end
             "16" : begin trrd = max(4,(ceil(10000,tCK))); tfaw = ceil(50000,tCK);end
           endcase 
         end
         case(MEMORY_SPEED_GRADE)
            "187" : trcd = ceil(15000,tCK);
            "187E": trcd = ceil(13125,tCK);
         endcase
        tras = ceil(37500,tCK);
      end
      "15","15E","15F":begin
         if(MEMORY_DENSITY == "8Gb")begin 
            trrd = max(4,(ceil(7500,tCK))); tfaw = ceil(45000,tCK);
         end
         else begin
           case(MEMORY_WIDTH) 
              "4","8":begin trrd = max(4,(ceil(6000,tCK))); tfaw = ceil(30000,tCK);end
              "16":begin trrd = max(4,(ceil(7500,tCK))); tfaw = ceil(45000,tCK);end
           endcase 
         end
         case(MEMORY_SPEED_GRADE)
            "15" :  trcd = ceil(15000,tCK);
            "15E":  trcd = ceil(13500,tCK);
            "15F":  trcd = ceil(12000,tCK);
         endcase
        tras = ceil(36000,tCK);
      end
      "125","125E":begin
         if(MEMORY_DENSITY == "8Gb")begin 
            trrd = max(4,(ceil(7500,tCK))); tfaw = ceil(40000,tCK);
         end
         else begin
            case(MEMORY_WIDTH) 
               "4","8":begin trrd = max(4,(ceil(6000,tCK))); tfaw = ceil(30000,tCK);end
               "16":begin trrd = max(4,(ceil(7500,tCK))); tfaw = ceil(40000,tCK);end
            endcase 
         end
         case(MEMORY_SPEED_GRADE)
            "125" : trcd = ceil(13750,tCK);
            "125E": trcd = ceil(12500,tCK);
         endcase
        tras = ceil(35000,tCK);
      end
      "107","107E":begin
         if(MEMORY_DENSITY == "8Gb")begin 
            trrd = max(4,(ceil(6000,tCK))); tfaw = ceil(35000,tCK);
         end
         else begin
            case(MEMORY_WIDTH) 
               "4","8":begin trrd = max(4,(ceil(5000,tCK))); tfaw = ceil(27000,tCK);end
               "16":begin trrd = max(4,(ceil(6000,tCK))); tfaw = ceil(35000,tCK);end
            endcase
         end  
         case(MEMORY_SPEED_GRADE)
            "107": trcd = ceil(13910,tCK);
            "107E": trcd = ceil(12840,tCK);
         endcase
        tras = ceil(34000,tCK);
      end
      "093":begin
         if(MEMORY_DENSITY == "8Gb")begin 
            trrd = max(4,(ceil(6000,tCK))); tfaw = ceil(35000,tCK);
         end
         else begin
            case(MEMORY_WIDTH) 
               "4","8":begin trrd = max(4,(ceil(5000,tCK))); tfaw = ceil(25000,tCK);end
               "16":begin trrd = max(4,(ceil(6000,tCK))); tfaw = ceil(35000,tCK);end
            endcase
         end
         trcd = ceil(13090,tCK);
         tras = ceil(33000,tCK);
         end
      default : trcd = 0; 
   endcase
   trp = trcd; 
   end
endtask

/*txpr_cal task :: 
  To calculate txpr 
  based on Memory Density and tCK */
task txpr_cal;
   output [7:0] txpr;//Expected txpr
   begin
   case(MEMORY_DENSITY)
      "1Gb":begin
         txpr = ceil(max(5,(ceil(120000,tCK))),4);
      end
      "2Gb":begin
         txpr = ceil(max(5,(ceil(170000,tCK))),4);
      end
      "4Gb":begin
         txpr = ceil(max(5,(ceil(270000,tCK))),4);
      end
      "8Gb":begin
         txpr = ceil(max(5,(ceil(360000,tCK))),4);
      end
      default : txpr = 0; 
   endcase
   end
endtask

/*axi_addr_width_cal task :: 
  To calculate axi_addr_width 
  based on INTERFACE and MEMORY_WIDTH */
task axi_addr_width_cal;
   output [6:0] axi_addr_width;//Expected axi_addr_width
   input [5:0]row_width,col_width;//row width and column width for a given density
   begin
      if((INTERFACE == "AXI"))begin
         axi_addr_width = clogb2(RANKS) + row_width + col_width + BANK_WIDTH + clogb2(PAYLOAD_WIDTH) - 3;
      end
      else 
         axi_addr_width = 0;
   end
endtask

/*tck_cal task :: 
  To calculate tck range(i.e tck_min and tck_max) 
  based on Memory Speed Grade,CL and CWL */
task tck_cal;
   output [13:0]tck_min,tck_max;//Expected tck range
   input [7:0] cl_cwl;//{CL,CWL} from Mode Registers
   begin
   case(cl_cwl)
      8'h55:begin
         case(MEMORY_SPEED_GRADE)
           "25E","15F","125E":begin tck_min = 2500; tck_max = 3300;end
           "25","187E","187","15","15E","125":begin tck_min = 3000; tck_max = 3300;end
           default:begin tck_min = 0 ; tck_max = 0 ; end  
         endcase
      end

      8'h65:begin 
         case(MEMORY_SPEED_GRADE)
            "25E","15F","125E","25","187E","187","15E","125","107","107E","093","15":
                    begin tck_min = 2500; tck_max = 3300; end
            default:begin tck_min = 0 ; tck_max = 0 ; end  
         endcase
      end

      8'h76:begin
         case(MEMORY_SPEED_GRADE)
            "187E","15F","15E","125E","125","107","107E","093":
                    begin tck_min = 1875; tck_max = 2499; end 
            default:begin tck_min = 0 ; tck_max = 0 ; end  
         endcase
      end
      
      8'h86:begin
         case(MEMORY_SPEED_GRADE)
            "187E","187","15F","15E","125E","125","107","107E","093","15":
                    begin tck_min = 1875; tck_max = 2499; end 
            default:begin tck_min = 0 ; tck_max = 0 ; end  
         endcase
      end

      8'h87:begin
         case(MEMORY_SPEED_GRADE)
            "15F":begin tck_min = 1500; tck_max = 1874; end 
            default:begin tck_min = 0 ; tck_max = 0 ; end  
         endcase
      end

      8'h97:begin
         case(MEMORY_SPEED_GRADE)
            "15E","15F","125E","125","107","107E","093":
                    begin tck_min = 1500; tck_max = 1874; end 
            default:begin tck_min = 0 ; tck_max = 0 ; end  
         endcase
      end
      
      8'ha7:begin
         case(MEMORY_SPEED_GRADE)
            "15E","15F","125E","125","107","107E","093","15":
                    begin tck_min = 1500; tck_max = 1874; end 
            default:begin tck_min = 0 ; tck_max = 0 ; end  
         endcase
      end

      8'ha8:begin
         case(MEMORY_SPEED_GRADE)
            "125E": begin tck_min = 1250; tck_max = 1499; end 
            default:begin tck_min = 0 ; tck_max = 0 ; end  
         endcase
      end

      8'hb8:begin
         case(MEMORY_SPEED_GRADE)
            "125E","125","107","107E","093": begin tck_min = 1250; tck_max = 1499; end 
            default:begin tck_min = 0 ; tck_max = 0 ; end  
         endcase
      end

      8'hc9:begin
         case(MEMORY_SPEED_GRADE)
            "107E":begin tck_min = 1070; tck_max = 1249; end 
            default:begin tck_min = 0 ; tck_max = 0 ; end  
         endcase
      end
      
      8'hd9:begin
         case(MEMORY_SPEED_GRADE)
            "107","107E","093":begin tck_min = 1070; tck_max = 1249; end 
            default:begin tck_min = 0 ; tck_max = 0 ; end  
         endcase
      end

      8'hea:begin
         case(MEMORY_SPEED_GRADE)
            "093":begin tck_min = 938; tck_max = 1069; end 
            default:begin tck_min = 0 ; tck_max = 0 ; end  
         endcase
      end

      default:begin tck_min = 0 ; tck_max = 0 ; end  
   endcase
   end
endtask

/*Extra_cmd_delay task:: 
  To calculate Extra_Cmd_Delay 
  based on CL,CWL and AL */
task Extra_cmd_delay;
   output [1:0] E_C_D;//Expected Extra_cmd_delay
   input  [7:0] cl_cwl;//{CL,CWL} from Mode Registers
   begin
   casex(cl_cwl)
      8'h55:begin
         case(MR1[4:3])
            0,2:begin
              if((RANKS == 1) && (ECC == "OFF"))
                 E_C_D = 1;
                 else if((RANKS > 1) || ((RANKS == 1) && (ECC == "ON")))
                     E_C_D = 2;
                     else
                     E_C_D = 0;
              end
            1:begin
                if((RANKS == 1) && (ECC == "OFF"))
                   E_C_D = 0;
                   else if((RANKS > 1) || ((RANKS == 1) && (ECC == "ON")))
                     E_C_D = 1;
                     else
                     E_C_D = 0;
                end
         endcase
      end

      8'h65,8'h66,8'h76:begin
         case(MR1[4:3])
            0:begin
              if((RANKS == 1) && (ECC == "OFF"))
                 E_C_D = 1;
                 else if((RANKS > 1) || ((RANKS == 1) && (ECC == "ON")))
                     E_C_D = 2;
                     else
                     E_C_D = 0;
              end
            1,2:begin
                if((RANKS == 1) && (ECC == "OFF"))
                   E_C_D = 0;
                   else if((RANKS > 1) || ((RANKS == 1) && (ECC == "ON")))
                     E_C_D = 1;
                     else
                     E_C_D = 0;
                end
         endcase
      end

      8'h86,8'h77:begin
         case(MR1[4:3])
            0:begin
              if((RANKS == 1) && (ECC == "OFF"))
                 E_C_D = 1;
                 else if((RANKS > 1) || ((RANKS == 1) && (ECC == "ON")))
                     E_C_D = 2;
                     else
                     E_C_D = 0;
              end
            1:E_C_D = 0;
            2:begin
              if((RANKS == 1) && (ECC == "OFF"))
                 E_C_D = 0;
                 else if((RANKS > 1) || ((RANKS == 1) && (ECC == "ON")))
                   E_C_D = 1;
                   else
                   E_C_D = 0;
              end
         endcase
      end

      8'h87,8'h97,8'ha7,8'h88,8'h98,8'ha8,8'hb8:begin
         case(MR1[4:3])
            0:begin
              if((RANKS == 1) && (ECC == "OFF"))
                 E_C_D = 1;
                 else if((RANKS > 1) || ((RANKS == 1) && (ECC == "ON")))
                     E_C_D = 2;
                     else
                     E_C_D = 0;
            end
            1,2:begin
                 E_C_D = 0;
            end
         endcase
      end

      8'h?9,8'h?a,8'h?b,8'h?c:begin
         case(MR1[4:3])
            0:begin
              if((RANKS == 1) && (ECC == "OFF"))
                 E_C_D = 0;
                 else if((RANKS > 1) || ((RANKS == 1) && (ECC == "ON")))
                     E_C_D = 1;
                     else
                     E_C_D = 0;
              end
            1,2:begin
                 E_C_D = 0;
               end
         endcase
      end
      default:    E_C_D = 0;
   endcase
   end
endtask

/* tfabric_tddr3_ck_cal task:
   fabric and memory clock period calculation based 
   on div_clk,ddr3_ck_p and div_clk_rst */
task tfabric_tddr3_ck_cal;
   output [16:0] tfabric1,tfabric2;//Expected tfabric range
   output [16:0] tddr3_ck_1,tddr3_ck_2;//Expected ddr3_ck range
   output [16:0] triu_clk_1,triu_clk_2;//Expected riu_clk range
   output [16:0] tpll_clk_1,tpll_clk_2;//Expected pll_clk range
   begin
   time t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12;
      repeat(1)@(negedge div_clk_rst);
      fork
      begin
      @(posedge div_clk);
         t1 = $time;
         repeat(100)@(posedge div_clk);
         t2 = $time;
         t3 = (t2 - t1)/100;
         tfabric1 = t3 - t3/100;
         tfabric2 = t3 + t3/100;
      end
      begin
         @(posedge ddr3_ck_p[0]);
          t4 = $time;
          repeat(100)@(posedge ddr3_ck_p[0]);
          t5 = $time;
          t6 = (t5 -t4)/100 ;
          tddr3_ck_1 = t6 - t6/100;
          tddr3_ck_2 = t6 + t6/100;
      end
      begin
         @(posedge riu_clk);
          t7 = $time;
          repeat(100)@(posedge riu_clk);
          t8 = $time;
          t9 = (t8 -t7)/100 ;
          triu_clk_1 = t9 - t9/100;
          triu_clk_2 = t9 + t9/100;
      end
       begin
         @(posedge `PATH.u_ddr3_phy_pll.pll_clk[0]);
          t10 = $time;
          repeat(100)@(posedge `PATH.u_ddr3_phy_pll.pll_clk[0]);
          t11 = $time;
          t12 = (t11 -t10)/100 ;
          tpll_clk_1 = t12 - t12/100;
          tpll_clk_2 = t12 + t12/100;
      end
      join
   end
endtask

/*twr_cal task:
  twr calculation based on MR0 supported values*/
task twr_cal;
   output [5:0] twr;//Expected twr based on MR0 supported values. 
   input  [5:0] twr1;//Actual twr MR0 not considered.
   begin
   case(twr1)
      9:twr = 10;
      11:twr = 12;
      13:twr = 14;
      15:twr = 16;
      default:twr = twr1;
   endcase
   end
endtask

`ifndef SKIP_PHY_TOP
`ifdef MODEL_TECH
//XI-PHY Related 
/*Data bytes position calculation in IOBTYPE*/
function bit[`PATH.BYTES -1:0] databyte (bit [`PATH.BYTES*39-1:0] iobtype) ;
  for(int i = 0 ; i < `PATH.BYTES ; i++)begin
    if((((iobtype) >> ((i*13 + 6)*3)) & 3'h7) == 3'h7)
      databyte[i] = 1 ;
    else  
      databyte[i] = 0 ;
  end
endfunction

function bit dynamic_dci ( ) ;
  begin
    case(DEVICE)
       "xcku040-es1":dynamic_dci = 0;
       "xcvu095-es1":dynamic_dci = 0;
       "xcku060-es2":dynamic_dci = 0;
       "xcku115-es2":dynamic_dci = 0;
       "xcvu440-es2":dynamic_dci = 0;
       default:dynamic_dci = 1;
   endcase
  end
endfunction

/*RXTX_BITSLICE_EN calculation from IOB Type*/
function bit[`PATH.BYTES*13 -1:0] rxtx_bitslice_en(bit [`PATH.BYTES*39-1:0] iobtype) ;
  for(int i = 0 ; i < (`PATH.BYTES*39)/3 ; i++)begin
    if((((iobtype) >> (i*3)) & 3'h7) != 0 )begin
      if((((iobtype) >> (i*3)) & 3'h4) == 3'h4)begin
       //rxtx_bitslice_en[i] = ((i / 13) % 2)? ((i%2)?0:1):((i%2)?1:0) ; 
       rxtx_bitslice_en[i] = (((i % 13) % 2)? 0:1);
      end
      else
      rxtx_bitslice_en[i] = 1 ;
    end
    else  
      rxtx_bitslice_en[i] = 0 ;
  end
endfunction

/*Expected EN_OTHER_P_CLK,EN_OTHER_NCLK,RX_CLK_PHASE_P,RX_CLK_PHASE_N,
TX_GATING,RX_GATING,EN_DYN_ODLY_MODE calculation based on Data bytes*/
task en_other_p_n_clk;
   output [2*`PATH.BYTES - 1:0] en_other_pclk,en_other_nclk,
                                rx_clk_phase_p,rx_clk_phase_n,
                                tx_gating,rx_gating,en_dyn_odly_mode;
   input  [`PATH.BYTES - 1:0] data_bytes;
   begin
      for(int i = 0 ; i < `PATH.BYTES ; i++)begin
        if((data_bytes[i] == 1))begin 
         if(MEMORY_WIDTH != "4")begin
            en_other_pclk[(2*i) +:2] = 2'b01;
            en_other_nclk[(2*i) +:2] = 2'b01;
         end else begin
            en_other_pclk[(2*i) +:2]  = 2'b00;
            en_other_nclk[(2*i) +:2]  = 2'b00;
         end
           rx_clk_phase_p[(2*i) +:2] = 2'b11;
           rx_clk_phase_n[(2*i) +:2] = 2'b11;
           tx_gating[(2*i) +:2]      = 2'b11;
           rx_gating[(2*i) +:2]      = 2'b11;
           en_dyn_odly_mode[(2*i) +:2] = 2'b11;
        end
        else begin
           en_other_pclk[(2*i) +:2]  = 2'b00;
           en_other_nclk[(2*i) +:2]  = 2'b00;
           rx_clk_phase_p[(2*i) +:2] = 2'b00;
           rx_clk_phase_n[(2*i) +:2] = 2'b00;
           tx_gating[(2*i) +:2]      = 2'b00;
           rx_gating[(2*i) +:2]      = 2'b00;
           en_dyn_odly_mode[(2*i) +:2] = 2'b00;
        end
      end 
   end 
endtask

/*Expected DQ_WIDTH,CK_WIDTH,TX_OUTPUT_PHASE_90,
RX_DATA_TYPE calculation based on IOBTYPE*/
task data_ck_width_cal;
   output integer datawidth,ckwidth;
   output [`PATH.BYTES*13 - 1:0] tx_output_phase_90;
   output [`PATH.BYTES*15 - 1:0] rx_data_type;
   input  [`PATH.BYTES - 1:0] data_bytes;
   bit [2:0] iobmap;
   begin
     datawidth = 0;
     ckwidth = 0;
    //Expected RX_DATA_TYPE Calculation based on IOB TYPE and data_bytes. 
     for(int j = 0 ; j < `PATH.BYTES ; j++)begin
       for(int i = 0 ; i < 13 ; i++)begin
         iobmap = ((((`PATH.IOBTYPE) >> ((i+(j*13))*3)) & 3'h7));
         if(i == 0) begin
           rx_data_type[(i+(j*13) + (2*j))] =  (iobmap!= 0)?1'b1:1'b0; 
           rx_data_type[i + (j*13) + 1 + (2*j)] = (iobmap!= 0)?(((DM_DBI == "DM_NODBI")&&(data_bytes[j]))?0:1):0 ;  
         end else if(i == 1) begin
           rx_data_type[i+(j*13) + 1 + (2*j)] =  ((((((`PATH.IOBTYPE) >> (((i-1)+(j*13))*3)) & 3'h7))!= 3'h7) && (iobmap!= 0))?1:0 ;   
         end else if((i > 1) && (i < 6))begin
           rx_data_type[i+(j*13) + 1 + (2*j)] = (iobmap!= 0)?1:0 ;   
         end else if(i == 6)begin
           rx_data_type[(i+(j*13)+ 1 + (2*j))+:2] =  (iobmap!= 0)?2'b11:2'b00 ;  
         end else if(i == 7)begin
           rx_data_type[i+(j*13) + 2 + (2*j)] = ((((((`PATH.IOBTYPE) >> (((i-1)+(j*13))*3)) & 3'h7))!= 3'h7) && (iobmap!= 0))?1:0 ;   
         end else if((i > 7) && (i < 13))begin
           rx_data_type[i+(j*13) + 2 + (2*j)] =  (iobmap!= 0)?1:0 ; 
         end
       end
     end

    //Expected TX_OUTPUT_PHASE_90 Calculation based on IOB TYPE and DM_DBI. 
     for(int i = 0 ; i < (`PATH.BYTES*13) ; i++)begin
       if((((`PATH.IOBTYPE) >> (i*3)) & 3'h7) != 0)begin
         if((((`PATH.IOBTYPE) >> (i*3)) & 3'h7) == 3'b011)
           tx_output_phase_90[i] = 1'b0; 
         else tx_output_phase_90[i] = ((DM_DBI == "DM_NODBI") &&(data_bytes[i/13]))?((i%13)? 1'b1:1'b0):1'b1; 
         end 
       else begin
            tx_output_phase_90[i] = 1'b0; 
       end
     end
     
    //Expected DQ_WIDTH and CK_WIDTH Calculation based on IOB TYPE. 
     for(int i = 0 ; i < `PATH.BYTES*13 ; i++)begin
       if((((`PATH.IOBTYPE) >> (i*3)) & 3'h7) == 3'h3)
         datawidth = datawidth + 1 ;
       else if((((`PATH.IOBTYPE) >> (i*3)) & 3'h7) == 3'h5)
         ckwidth = ckwidth + 1 ;
     end
   end
endtask     
//End of XI-PHY Related
`endif
`endif

reg [7:0] trtp,txpr,twtr,tmrd,tmod,tzqcs,cl_cwl,twr_mr0;
reg [8:0] trfc,tzqinit;
reg [5:0] row_width,col_width,trrd,tfaw,trcd,tras,trp,twr1,twr;
reg [13:0] tck_min,tck_max;
reg [3:0] cl_min,cl_max,trtw,CL,CWL;
reg [2:0] wr_min,wr_max,cwl_min,cwl_max,rtt_nom;
reg [12:0] mr0_1,mr0_2,mr1_1,mr2_1,mr2_2;
reg [18:0]t200,t500;
reg [1:0] E_C_D,rtt_wr;
reg [16:0] trefi,tfabric1,tfabric2,tddr3_ck_1,tddr3_ck_2,triu_clk_1,triu_clk_2,tpll_clk_1,tpll_clk_2;
reg [33:0] zqintvl,axi_addr_width;
parameter save_restore = (SAVE_RESTORE == "true") ? 1 : 0;
parameter self_refresh = (SELF_REFRESH == "true") ? 1 : 0;

`ifndef SKIP_PHY_TOP
`ifdef MODEL_TECH
//XI-PHY Related declarations
reg [`PATH.BYTES -1 :0] data_bytes;
integer datawidth;
integer ckwidth;
bit dynamicdci;
reg [13*`PATH.BYTES-1:0] fifo_sync_mode       = {(13*`PATH.BYTES){1'b0}};
reg [45*`PATH.BYTES-1:0] gclk_src             = {(45*`PATH.BYTES){1'b0}};
reg [2*`PATH.BYTES-1:0]  tri_output_phase_90  = {(`PATH.BYTES*2){1'b1}};
reg [2*`PATH.BYTES-1:0]  serial_mode          = {`PATH.BYTES{2'b00}};
reg [2*`PATH.BYTES-1:0]  inv_rxclk            = {`PATH.BYTES{2'b00}};
reg [2*`PATH.BYTES-1:0]  en_clk_to_ext_north  = {`PATH.BYTES{2'b00}};
reg [2*`PATH.BYTES-1:0]  en_clk_to_ext_south  = {`PATH.BYTES{2'b00}};
reg [13*`PATH.BYTES-1:0] dci_src              = {(`PATH.BYTES*13){1'b1}};
reg [2*`PATH.BYTES-1:0]  idly_vt_track        = {(2*`PATH.BYTES){1'b1}};
reg [2*`PATH.BYTES-1:0]  odly_vt_track        = {(2*`PATH.BYTES){1'b1}};
reg [2*`PATH.BYTES-1:0]  qdly_vt_track        = {(2*`PATH.BYTES){1'b1}};
reg [2*`PATH.BYTES-1:0]  rxgate_extend        = {(2*`PATH.BYTES){1'b0}};
reg [15*`PATH.BYTES-1:0] init                 = {(15*`PATH.BYTES){1'b1}};
reg [13*`PATH.BYTES-1:0] native_odelay_bypass = {(13*`PATH.BYTES){1'b0}};         
reg [13*`PATH.BYTES-1:0] tx_output_phase_90;            
reg [2*`PATH.BYTES-1:0]  en_other_pclk;                  
reg [2*`PATH.BYTES-1:0]  en_other_nclk;                  
reg [2*`PATH.BYTES-1:0]  rx_clk_phase_p;                 
reg [2*`PATH.BYTES-1:0]  rx_clk_phase_n;                 
reg [2*`PATH.BYTES-1:0]  tx_gating;                      
reg [2*`PATH.BYTES-1:0]  rx_gating;                      
reg [2*`PATH.BYTES-1:0]  en_dyn_odly_mode;               
reg [13*`PATH.BYTES-1:0] rxtx_bitslice_en_1;
reg [15*`PATH.BYTES-1:0] rx_data_type;
reg [1:0] refclk_src                          = 2'b00;
integer rx_delay_val     [12:0]                   = '{0,0,0,0,0,0,0,0,0,0,0,0,0};
integer tx_delay_val     [12:0]                   = '{0,0,0,0,0,0,0,0,0,0,0,0,0};
integer tri_delay_val    [1:0]                    = '{0, 0};
integer read_idle_count  [1:0]                = '{31, 31};
integer rounding_factor  [1:0]                = '{16, 16};
reg [1:0] ctrl_clk                            = 2'b11; 
//End of XI-PHY related declarations 
`endif
`endif

initial
   begin
     
    /*Reference parameters tck_min and tck_max are calculated 
      based on CL,CWL and Speed grade w.r.to JEDEC Specification */
   if(MR0[2] == 0) 
      CL = MR0[6:4] + 4'b0100 ;
     else 
      CL = MR0[6:4] + 4'b1100;

   CWL = MR2[5:3] + 4'b0101;
   cl_cwl = {CL,CWL};
   tck_cal(tck_min,tck_max,cl_cwl);

   Extra_cmd_delay(E_C_D,cl_cwl);
  
   if(MR0[11]== 1)
      twr_mr0 = MR0[10]*4 + MR0[9]*2 + 8;
      else
      begin
         if(MR0[11:9] == 0)
            twr_mr0 = 16;
            else
            twr_mr0 = MR0[10]*2 + MR0[9] + 4;
      end 
   
   /*Reference parameters tfaw,trrd,trp and trcd are calculated 
     based on Speed Grade and Memory Width w.r.to Jedec Specification*/
   trrd_tfaw_trcd(trrd,tfaw,trcd,trp,tras);
   
   /*Timing parameters which are independent of speed grade,
     memory width and memory density are calculated w.r.to Jedec Specification*/
   tzqinit = ceil(max(512,(ceil(640000,tCK))),4);
   tzqcs = max(64,(ceil (80000,tCK)));
   trtp = max(4,(ceil(7500 ,tCK)));
   twtr = trtp;
   twr1 =  ceil(15000,tCK);
   twr_cal(twr,twr1);
   tmrd = 1;
   tmod = ceil(max(12,(ceil(15000,tCK))),4);
   txpr_cal(txpr);
   if(RANKS > 1)
      trtw = CL + 'h4 + 4 - CWL;
   else
      trtw = CL + 'h4 + 2 - CWL;
   if((ADV_USER_REQ == "ZQCS_REF") || (ADV_USER_REQ == "AP_ZQCS_REF"))
      trefi = 0;
   else
      trefi = (NUMREF*7800000)/tCK;
   zqintvl = ceil_1(64'd1000000000000,tCK);
   `ifdef SIMULATION
       t200 = 100;
       t500 = 150;
    `else 
       t200 = ceil(ceil(200000000,tCK),4);
       t500 = ceil(ceil(500000000,tCK),4);
    `endif

   /*Fabric and memory clock period calculation based 
     on div_clk,ddr3_ck_p and div_clk_rst*/
   tfabric_tddr3_ck_cal(tfabric1,tfabric2,tddr3_ck_1,tddr3_ck_2,triu_clk_1,triu_clk_2,tpll_clk_1,tpll_clk_2);

   /*Reference parameters row_width , col_width and trfc are calculated 
     based on Memory Density and Memory Width w.r.to JEDEC Specification*/
   row_col_trfc(row_width,col_width,trfc);

   axi_addr_width_cal(axi_addr_width,row_width,col_width);
   
   /*Reference Mode Registers values are calculated w.r.to JEDEC Specification*/
   cl_min = 4'b0001;
   cl_max = 4'b1010;
   wr_min = 3'b000;
   wr_max = 3'b111;
   cwl_min = 3'b000;
   cwl_max = 3'b111;
   
   if(MEMORY_CONFIGURATION == "COMPONENT" && RANKS == 2)begin
      rtt_nom  = 3'b011;
      rtt_wr   = 2'b00;
   end else if(NUM_SLOT == 1 && RANK_SLOT == 1)begin
      rtt_nom   = 3'b011;
      rtt_wr    = 2'b00;
   end else if(NUM_SLOT == 2 && RANK_SLOT == 1)begin
      rtt_nom   = 3'b011;
      rtt_wr    = 2'b01;
   end else if(NUM_SLOT == 1 && RANK_SLOT == 2)begin
      rtt_nom  = 3'b010;
      rtt_wr   = 2'b01;
   end else if(NUM_SLOT == 2 && RANK_SLOT == 2)begin
      rtt_nom  = 3'b001;
      rtt_wr   = 2'b10;
   end else if(NUM_SLOT == 1 && RANK_SLOT == 4)begin
      rtt_nom  = 3'b010;
      rtt_wr   = 2'b01;
   end 

   mr0_1 = {1'b0,wr_min,1'b1,1'b0,cl_min[3:1],1'b0,cl_min[0],2'b00};
   mr0_2 = {1'b0,wr_max,1'b1,1'b0,cl_max[3:1],1'b0,cl_max[0],2'b00};
   mr1_1 = {3'b0,rtt_nom[2],2'b0,rtt_nom[1],3'b0,rtt_nom[0],2'b0};
   mr2_1 = {2'b0,rtt_wr,3'b0,cwl_min,3'b0};
   mr2_2 = {2'b0,rtt_wr,3'b0,cwl_max,3'b0};

   `ifndef SKIP_PHY_TOP
   `ifdef MODEL_TECH
   //XI-PHY Related

   /*Data bytes calcultion based on IOBTYPE*/ 
   data_bytes = databyte(`PATH.IOBTYPE);
  
   dynamicdci = dynamic_dci();

   /*Expected Data and CK width calcultion based on IOBTYPE*/ 
   data_ck_width_cal(datawidth,ckwidth,tx_output_phase_90,rx_data_type,data_bytes);

   /*Expected rxtx_bitslice_en calculation based on IOBTYPE*/ 
   rxtx_bitslice_en_1 = rxtx_bitslice_en(`PATH.IOBTYPE);
   
   /*Expected en_other_p_clk,en_other_nclk,rx_clk_phase_p,rx_clk_phase_n,
   tx_gating,rx_gating,en_dyn_odly_mode calculation based on Data bytes*/
   en_other_p_n_clk(en_other_nclk,en_other_pclk,rx_clk_phase_p,rx_clk_phase_n,
                    tx_gating,rx_gating,en_dyn_odly_mode,data_bytes);

   //End of XI-PHY related 
   `endif 
   `endif 

   if(INTERFACE != "PHY") begin

   /*tFAW,tRRD,tRP and tRCD Verification
     Reference parameters tfaw,trrd,trp and trcd are calculated 
     based on Speed Grade and Memory Width w.r.to Jedec Specification */
   A_TRP:assert (trp  == tRP) 
      else $display("INCORRECT_PARAMETER: tRP       \
         Expected value is 'd%0d Generated value is 'd%0d",trp,tRP);
   
   A_TFAW:assert (tfaw == tFAW) 
      else $display("INCORRECT_PARAMETER: tFAW      \
         Expected value is 'd%0d and Generated value is 'd%0d",tfaw,tFAW);

   A_TRCD:assert (trcd == tRCD) 
      else $display("INCORRECT_PARAMETER: tRCD      \
         Expected value is 'd%0d Generated value is 'd%0d",trcd,tRCD);
   
   A_TRAS:assert (tras == tRAS) 
      else $display("INCORRECT_PARAMETER: tRAS      \
         Expected value is 'd%0d Generated value is 'd%0d",tras,tRAS);
   
   A_TRRD:assert (trrd == tRRD) 
      else $display("INCORRECT_PARAMETER: tRRD      \
         Expected value is 'd%0d Generated value is 'd%0d",trrd,tRRD);

   /*tRFC Verification
     Reference parameter trfc are calculated 
     based on Memory Density w.r.to Jedec Specification*/
   A_TRFC:assert (trfc ==  tRFC)
      else $display("INCORRECT_PARAMETER: tRFC      \
         Expected value  is 'd%0d Generated value  is 'd%0d",trfc,tRFC);

     /*Timing parameters which are independent of speed grade,
     memory width and memory density are calculated w.r.to Jedec Specification
     and compared with MIG generated one*/
   A_TWR:assert(twr == tWR) 
      else $display("INCORRECT_PARAMETER: tWR       \
         Expected value is 'd%0d Generated value is 'd%0d",twr,tWR);
   
   A_TWR_MR0:assert(twr_mr0 == tWR) 
      else $display("INCORRECT_PARAMETER: tWR_MR0   \
         Expected value is 'd%0d Generated value is 'd%0d",twr_mr0,tWR);

   A_TRTP:assert (trtp ==  tRTP) 
      else $display("INCORRECT_PARAMETER: tRTP      \
         Expected value is 'd%0d Generated value is 'd%0d",trtp,tRTP);

   A_TWTR:assert (twtr ==  tWTR) 
      else $display("INCORRECT_PARAMETER: tWTR      \
         Expected value is 'd%0d Generated value is 'd%0d",twtr,tWTR);

   A_TRTW:assert (trtw ==  tRTW) 
      else $display("INCORRECT_PARAMETER: tRTW      \
         Expected value is 'd%0d Generated value is 'd%0d",trtw,tRTW);
   
   
   A_TZQCS:assert (tzqcs ==  tZQCS) 
      else $display("INCORRECT_PARAMETER: tZQCS     \
         Expected value is 'd%0d Generated value is 'd%0d",tzqcs,tZQCS);

   A_TREFI:assert (trefi ==  tREFI) 
      else $display("INCORRECT_PARAMETER: tREFI     \
         Expected value is 'd%0d Generated value is 'd%0d",trefi,tREFI); 

   A_ZQINTVL:assert (ZQINTVL == zqintvl) 
      else $display("INCORRECT_PARAMETER: ZQINTVL   \
         Expected value is 'd%0d Generated value is 'd%0d",zqintvl,ZQINTVL);
  
   A_TMRD:assert (tmrd == tMRD) 
      else $display("INCORRECT_PARAMETER: tMRD      \
         Expected value is 'd%0d Generated value is 'd%0d",tmrd,tMRD);

   A_TMOD:assert (tmod ==  tMOD) 
      else $display("INCORRECT_PARAMETER: tMOD      \
         Expected value is 'd%0d Generated value is 'd%0d",tmod,tMOD);

   A_TXPR:assert (txpr ==  tXPR)
      else $display("INCORRECT_PARAMETER: tXPR      \
         Expected value is 'd%0d Generated value is 'd%0d",txpr,tXPR);

   A_TZQINIT:assert (tzqinit == tZQINIT) 
      else $display("INCORRECT_PARAMETER: tZQINIT   \
         Expected value is 'd%0d Generated value is 'd%0d",tzqinit,tZQINIT);

   A_T200:assert (t200 == t200us )  
      else $display("INCORRECT_PARAMETER: t200us    \
         Expected value is 'd%0d Generated value is 'd%0d",t200,t200us); 

   A_T500:assert (t500 == t500us)  
      else $display("INCORRECT_PARAMETER: t500us    \
         Expected value is 'd%0d Generated value is 'd%0d",t500,t500us); 

 /*Mode Registers Verification
      MR0 is tested for 
        1.CL and WR range supported by JEDEC
        2.DLL Reset is set to yes  
        3.all other bits are set to zero*/
   A_MR0:assert (({MR0[12],MR0[7],MR0[3],MR0[1:0]} == 5'b00000) && 
                       ((cl_min <= {MR0[6:4],MR0[2]} <= cl_max) || 
                        ({MR0[6:4],MR0[2]} == 4'b1100) || 
                        ({MR0[6:4],MR0[2]} == 4'b1110)) && 
                        (wr_min <= MR0[11:9] <= wr_max) && MR0[8] == 1)
      else $display("INCORRECT_PARAMETER: MODE_REGISTER0 \
         Supported range is from 'b%0b to 'b%0b, Generated value is 'b%0b",mr0_1,mr0_2,MR0);
    
   /*MR1 is tested for Rtt_Nom range supported by JEDEC,
     all other bits are set to zero*/
   A_MR1:assert (MR1 == mr1_1)
      else $display("INCORRECT_PARAMETER: MODE_REGISTER1 \
         Expected value is 'b%0b, Generated value is 'b%0b",mr1_1,MR1);
   
   /*MR2 is tested only for CWL range supported by JEDEC,
     all other bits are set to zero */
   A_MR2:assert(({MR2[12:11],MR2[8:6],MR2[2:0]} == 8'b0)&& (MR2[10:9] == rtt_wr) 
             && (cwl_min <= MR2[5:3] <= cwl_max))
      else $display("INCORRECT_PARAMETER: MODE_REGISTER2 \
         Supported range is from 'b%0b to 'b%0b, Generated value is 'b%0b",mr2_1,mr2_2,MR2);
   
   /*MR3 is tested for default values i.e, all bits of MR3 are zero*/
   A_MR3:assert (MR3 == 13'b0)
      else $display("INCORRECT_PARAMETER: MODE_REGISTER3 \
         Expected value is 'b%0b Generated value is 'b%0b",13'h0,MR3);
  
   /*EXTRA_CMD_DELAY parameter verification based on CL,CWL and AL*/
   A_E_C_DELAY:assert (EXTRA_CMD_DELAY == E_C_D)
      else $display("INCORRECT_PARAMETER: EXTRA_CMD_DELAY \
         Expected value is 'd%0d Generated value is 'd%0d",E_C_D,EXTRA_CMD_DELAY);

   /*tCK Verification
     Reference parameters tck_min and tck_max are 
     calculated based on CL,CWL and Speed grade w.r.to JEDEC Specification */
   if(tck_min == 0) begin
        $display("INCORRECT_PARAMETER: tCK        \
           Generated tCK = 'd%0d is not supported for a given CL = 'd%0d, CWL = 'd%0d \
and %0s MEMORY SPEED GRADE",tCK,CL,CWL,MEMORY_SPEED_GRADE);
   end
   else begin  
   A_TCK:assert (tck_min <= tCK <= tck_max) 
      else $display("INCORRECT_PARAMETER: tCK       \
         Supported range is from 'd%0d to 'd%0d,Generated value is \
'd%0d",tck_min,tck_max,tCK);
   end

   /*ROW_WIDTH,BANK_WIDTH and COLUMN_WIDTH Verification 
     reference parameters row_width , col_width and bank_width are calculated 
     based on Memory Density and Memory Width w.r.to JEDEC Specification  */
   A_ROW:assert (row_width == ROW_WIDTH) 
      else $display("INCORRECT_PARAMETER: ROW_WIDTH \
         Expected value is 'd%0d Generated value is 'd%0d",row_width,ROW_WIDTH);

   A_COL:assert (col_width == COL_WIDTH) 
      else $display("INCORRECT_PARAMETER: COL_WIDTH \
         Expected value is 'd%0d Generated value is 'd%0d",col_width,COL_WIDTH);

   A_BANK:assert (BANK_WIDTH == 3 ) 
      else $display("INCORRECT_PARAMETER: BANK_WIDTH \
         Expected value is 'd%0d Generated value is 'd%0d",3,BANK_WIDTH);

   /*DATA_BUF_ADDR_WIDTH parameter verification with default value*/ 
   A_D_B_WIDTH:assert (DATA_BUF_ADDR_WIDTH == 5)  
      else $display("INCORRECT_PARAMETER: DATA_BUF_ADDR_WIDTH \
         Expected value is 'd%0d Generated value is 'd%0d",5,DATA_BUF_ADDR_WIDTH);
   
   if(INTERFACE == "AXI") begin
   A_AXI_A_WIDTH:assert (C_S_AXI_ADDR_WIDTH == axi_addr_width)  
      else $display("INCORRECT_PARAMETER: C_S_AXI_ADDR_WIDTH  \
         Expected value is 'd%0d Generated value is 'd%0d",axi_addr_width,C_S_AXI_ADDR_WIDTH); 
   end

   A_ui_clk_Check:assert ((tfabric1 <= tCK*nCK_PER_CLK) && (tCK*nCK_PER_CLK <= tfabric2))  
      else $display("INCORRECT_PARAMETER: Fabric clock period is not \
equal to tCK*nCK_PER_CLK \
         valid range is from 'd%0d to 'd%0d, Generated value is \
'd%0d",tfabric1,tfabric2,tCK*nCK_PER_CLK); 
 
   A_pll_clk_Check:assert ((tpll_clk_1 <= tCK/2) && (tCK/2 <= tpll_clk_2))  
      else $display("INCORRECT_PARAMETER: RIU clock period is not \
equal to tCK/2 \
         valid range is from 'd%0d to 'd%0d, Generated value is \
'd%0d",tpll_clk_1,tpll_clk_2,tCK/2); 
  
   A_ddr3_cK_Check:assert ((tddr3_ck_1  <= tCK) && (tCK <= tddr3_ck_2 ))  
      else $display("INCORRECT_PARAMETER: ddr3_ck_p period is not equal to tCK \
         valid range is from 'd%0d to 'd%0d, Generated value is \
'd%0d",tddr3_ck_1,tddr3_ck_2,tCK); 
 
   end

 //     /*DATA_BUF_ADDR_WIDTH parameter verification with default value*/ 
 //  P_D_B_WIDTH:assert (`PATH.DATA_BUF_ADDR_WIDTH == 5)  
 //     else $display("INCORRECT_PARAMETER: DATA_BUF_ADDR_WIDTH \
 //        Expected value is 'd%0d Generated value is 'd%0d",5,`PATH.DATA_BUF_ADDR_WIDTH);
     
   /*ROW_WIDTH,BANK_WIDTH and COLUMN_WIDTH Verification 
     reference parameters row_width , col_width and bank_width are calculated 
     based on Memory Density and Memory Width w.r.to JEDEC Specification  */

   P_COL:assert (col_width == `PATH.COL_WIDTH) 
      else $display("INCORRECT_PARAMETER: COL_WIDTH \
         Expected value is 'd%0d Generated value is 'd%0d",col_width,`PATH.COL_WIDTH);

   P_BANK:assert (`PATH.BANK_WIDTH == 3 ) 
      else $display("INCORRECT_PARAMETER: BANK_WIDTH \
         Expected value is 'd%0d Generated value is 'd%0d",3,`PATH.BANK_WIDTH);

   /*tCK Verification
     Reference parameters tck_min and tck_max are 
     calculated based on CL,CWL and Speed grade w.r.to JEDEC Specification */
   if(tck_min == 0) begin
        $display("INCORRECT_PARAMETER: tCK        \
           Generated tCK = 'd%0d is not supported for a given CL = 'd%0d, CWL = 'd%0d \
and %0s MEMORY SPEED GRADE",`PATH.tCK,CL,CWL,MEMORY_SPEED_GRADE);
   end
   else begin  
   P_TCK:assert (tck_min <= `PATH.tCK <= tck_max) 
      else $display("INCORRECT_PARAMETER: tCK       \
         Supported range is from 'd%0d to 'd%0d,Generated value is \
'd%0d",tck_min,tck_max,`PATH.tCK);
   end


   if(SELF_REFRESH == "true") begin
	   A_SAVE_RESTORE : assert(save_restore == self_refresh)
      		else $display("INCORRECT_PARAMETER: SAVE_RESTORE \
		         Expected value is 'd%0d Generated value is 'd%0d",self_refresh,save_restore);
   end  

//SINGLE SLOT
  if(NUM_SLOT == 1) begin
    //for single slot SLOTn_* values should be 0

      A_NUM_SLOT1_CONFIG : assert(SLOT1_CONFIG == 8'b0000_0000)
        		else $display("INCORRECT_PARAMETER: SLOT1_CONFIG \
	  	         Expected value is %8b Generated value is %8b",0,SLOT1_CONFIG);

      A_NUM_SLOT1_FUNC_CS : assert(SLOT1_FUNC_CS == 8'b0000_0000)
        		else $display("INCORRECT_PARAMETER: SLOT1_FUNC_CS \
	  	         Expected value is '%8b Generated value is %8b",0,SLOT1_FUNC_CS);

      if(RANKS == 1) begin
          A_NUM_SLOT0_FUNC_CS : assert(SLOT0_FUNC_CS == 8'b0000_0001)
          		else $display("INCORRECT_PARAMETER: SLOT0_FUNC_CS \
	  	           Expected value is '%8b Generated value is %8b",8'b0000_0001,SLOT0_FUNC_CS);

         if(MEMORY_CONFIGURATION == "RDIMM") begin
           A_NUM_SLOT0_CONFIG_RDIMM : assert(SLOT0_CONFIG == 8'b0000_0011)
             		else $display("INCORRECT_PARAMETER: SLOT0_CONFIG \
   	  	           Expected value is %8b Generated value is %8b",8'b0000_0101,SLOT0_CONFIG);
         end

         else begin
           A_NUM_SLOT0_CONFIG : assert(SLOT0_CONFIG == 8'b0000_0001)
             		else $display("INCORRECT_PARAMETER: SLOT0_CONFIG \
   	  	           Expected value is %8b Generated value is %8b",8'b0000_0001,SLOT0_CONFIG);
          end
      end
      else if(RANKS == 2) begin   //Single Slot Dual Rank
      A_SSDR_NUM_SLOT0_FUNC_CS : assert(SLOT0_FUNC_CS == 8'b0000_0011)
        		else $display("INCORRECT_PARAMETER: SLOT0_FUNC_CS \
	  	         Expected value is '%8b Generated value is %8b",8'b0000_0011,SLOT0_FUNC_CS);
   
      A_SSDR_NUM_SLOT0_CONFIG : assert(SLOT0_CONFIG == 8'b0000_0011)
        		else $display("INCORRECT_PARAMETER: SLOT0_CONFIG \
    	         Expected value is %8b Generated value is %8b",8'b0000_0011,SLOT0_CONFIG);
   
      end
      else if(RANKS == 4) begin   //single slot quad rank
      A_SSQR_NUM_SLOT0_FUNC_CS : assert(SLOT0_FUNC_CS == 8'b0000_1111)
        		else $display("INCORRECT_PARAMETER: SLOT0_FUNC_CS \
	  	         Expected value is '%8b Generated value is %8b",8'b0000_1111,SLOT0_FUNC_CS);
   
      A_SSQR_NUM_SLOT0_CONFIG : assert(SLOT0_CONFIG == 8'b0000_1111)
        		else $display("INCORRECT_PARAMETER: SLOT0_CONFIG \
    	         Expected value is %8b Generated value is %8b",8'b0000_1111,SLOT0_CONFIG);
   
      end

  end       

//SINGLE RANK DUAL SLOT
  if(NUM_SLOT == 2) begin
        if(RANKS == 2 && RANK_SLOT == 1) begin
          if(MEMORY_CONFIGURATION == "RDIMM") begin
             A_SINGLE_RANK_SLOT0_CONFIG_RDIMM : assert(SLOT0_CONFIG == 8'b0000_0101)
               		else $display("INCORRECT_PARAMETER: SLOT0_CONFIG \
         		         Expected value is %8b Generated value is %8b",8'b0000_0101,SLOT0_CONFIG);
         
             A_SINGLE_RANK_SLOT1_CONFIG_RDIMM : assert(SLOT1_CONFIG == 8'b0000_1010)
               		else $display("INCORRECT_PARAMETER: SLOT1_CONFIG \
         		         Expected value is %8b Generated value is %8b",8'b0000_1010,SLOT1_CONFIG);
          end     
          else begin
             A_SINGLE_RANK_SLOT0_CONFIG : assert(SLOT0_CONFIG == 8'b0000_0001)
               		else $display("INCORRECT_PARAMETER: SLOT0_CONFIG \
         		         Expected value is %8b Generated value is %8b",8'b0000_0001,SLOT0_CONFIG);
         
             A_SINGLE_RANK_SLOT1_CONFIG : assert(SLOT1_CONFIG == 8'b0000_0010)
               		else $display("INCORRECT_PARAMETER: SLOT1_CONFIG \
         		         Expected value is %8b Generated value is %8b",8'b0000_0010,SLOT1_CONFIG);

          end  
             A_SINGLE_RANK_SLOT0_FUNC_CS : assert(SLOT0_FUNC_CS == 8'b0000_0001)
               		else $display("INCORRECT_PARAMETER: SLOT0_FUNC_CS \
         		         Expected value is '%8b Generated value is %8b",8'b0000_0001,SLOT0_FUNC_CS);
         
             A_SINGLE_RANK_SLOT1_FUNC_CS : assert(SLOT1_FUNC_CS == 8'b0000_0010)
               		else $display("INCORRECT_PARAMETER: SLOT1_FUNC_CS \
         		         Expected value is '%8b Generated value is %8b",8'b0000_0010,SLOT1_FUNC_CS);
       end   
       //DUAL RANK DUAL SLOT   
       else if(RANKS == 4 && RANK_SLOT == 2) begin
          A_DUAL_RANK_SLOT0_CONFIG : assert(SLOT0_CONFIG == 8'b0000_0011)
            		else $display("INCORRECT_PARAMETER: SLOT0_CONFIG \
      		         Expected value is %8b Generated value is %8b",8'b0000_0011,SLOT0_CONFIG);
      
          A_DUAL_RANK_SLOT1_CONFIG : assert(SLOT1_CONFIG == 8'b0000_1100)
            		else $display("INCORRECT_PARAMETER: SLOT1_CONFIG \
      		         Expected value is %8b Generated value is %8b",8'b0000_1100,SLOT1_CONFIG);
      
          A_DUAL_RANK_SLOT0_FUNC_CS : assert(SLOT0_FUNC_CS == 8'b0000_0011)
            		else $display("INCORRECT_PARAMETER: SLOT0_FUNC_CS \
      		         Expected value is '%8b Generated value is %8b",8'b0000_0011,SLOT0_FUNC_CS);
      
          A_DUAL_RANK_SLOT1_FUNC_CS : assert(SLOT1_FUNC_CS == 8'b0000_1100)
            		else $display("INCORRECT_PARAMETER: SLOT1_FUNC_CS \
      		         Expected value is '%8b Generated value is %8b",8'b0000_1100,SLOT1_FUNC_CS);
       end
 end  


  /*XI-PHY Paramters checks*/
  
`ifndef SKIP_PHY_TOP
`ifdef MODEL_TECH

   if(CALIB_HIGH_SPEED == "TRUE") begin
   A_riu_clk_Check_1:assert ((triu_clk_1 <= tCK*2*nCK_PER_CLK))  
      else $display("INCORRECT_PARAMETER: RIU clock period is not \
equal to tCK*2*nCK_PER_CLK \
         valid range is from 'd%0d to 'd%0d, Generated value is \
'd%0d",triu_clk_1,triu_clk_2,tCK*2*nCK_PER_CLK); 
   end
   else begin
   A_riu_clk_Check:assert ((triu_clk_1 <= tCK*2*nCK_PER_CLK) && (tCK*2*nCK_PER_CLK <= triu_clk_2))  
      else $display("INCORRECT_PARAMETER: RIU clock period is not \
equal to tCK*2*nCK_PER_CLK \
         valid range is from 'd%0d to 'd%0d, Generated value is \
'd%0d",triu_clk_1,triu_clk_2,tCK*2*nCK_PER_CLK); 
   end
  
  XIP_DQ_WIDTH:assert (`PATH.DQ_WIDTH == datawidth) 
      else $display("INCORRECT_PARAMETER: DQ_WIDTH \
         Expected value is 'd%0d Generated value is 'd%0d",datawidth,`PATH.DQ_WIDTH);

  
 if(SELF_REFRESH == "false") begin
  XIP_CK_WIDTH:assert (`PATH.CK_WIDTH == ckwidth/2 ) 
      else $display("INCORRECT_PARAMETER: CK_WIDTH  \
         Expected value is 'd%0d Generated value is 'd%0d",ckwidth/2,`PATH.CK_WIDTH);
 end

  XIP_PLLCLK_SRC:assert (`PATH.PLLCLK_SRC == 1'b0) 
      else $display("INCORRECT_PARAMETER: PLLCLK_SRC \
         Expected value is 'd%0d Generated value is 'd%0d",0,`PATH.PLLCLK_SRC);

  XIP_DBYTES:assert (`PATH.DBYTES == `PATH.DQ_WIDTH/8) 
      else $display("INCORRECT_PARAMETER: DBYTES \
         Expected value is 'd%0d Generated value is 'd%0d",`PATH.DQ_WIDTH/8,`PATH.DBYTES);

  XIP_BYTES:assert (`PATH.BYTES >= `PATH.DBYTES + 2) 
      else $display("INCORRECT_PARAMETER: BYTES \
         Expected value is 'd%0d Generated value is 'd%0d",`PATH.DBYTES + 2,`PATH.BYTES);
  
  if(SELF_REFRESH == "false") begin
  XIP_INIT:assert (`PATH.INIT == init) 
      else $display("INCORRECT_PARAMETER: INIT \
         Expected value is 'd%0d Generated value is 'd%0d",init,`PATH.INIT);
  end    

  XIP_DYNAMIC_DCI:assert (`PATH.USE_DYNAMIC_DCI == dynamicdci) 
      else $display("INCORRECT_PARAMETER: USE_DYNAMIC_DCI \
         Expected value is 'd%0d Generated value is 'd%0d",dynamicdci,`PATH.USE_DYNAMIC_DCI);


  XIP_NATIVE_ODELAY_BYPASS:assert (`PATH.NATIVE_ODELAY_BYPASS == native_odelay_bypass) 
      else $display("INCORRECT_PARAMETER: NATIVE_ODELAY_BYPASS \
         Expected value is 'd%0d Generated value is 'd%0d",native_odelay_bypass,`PATH.INIT);

  XIP_CTRL_CLK:assert (`PATH.CTRL_CLK == ctrl_clk) 
      else $display("INCORRECT_PARAMETER: CTRL_CLK  \
         Expected value is 'd%0d Generated value is 'd%0d",ctrl_clk,`PATH.CTRL_CLK);

  XIP_DATA_WIDTH:assert (`PATH.DATA_WIDTH == 8) 
      else $display("INCORRECT_PARAMETER: DATA_WIDTH \
         Expected value is 'd%0d Generated value is 'd%0d",8,`PATH.DATA_WIDTH);

  XIP_DIV_MODE:assert (`PATH.DIV_MODE == 2'b00) 
      else $display("INCORRECT_PARAMETER: DIV_MODE \
         Expected value is 'd%0d Generated value is 'd%0d",0,`PATH.DIV_MODE);

  XIP_TX_OUTPUT_PHASE_90:assert (`PATH.TX_OUTPUT_PHASE_90 == tx_output_phase_90) 
      else $display("INCORRECT_PARAMETER: TX_OUTPUT_PHASE_90  \
         Expected value is 'b%0b Generated value is 'b%0b",tx_output_phase_90,`PATH.TX_OUTPUT_PHASE_90);

  XIP_RX_DATA_TYPE:assert (`PATH.RX_DATA_TYPE == rx_data_type) 
      else $display("INCORRECT_PARAMETER: RX_DATA_TYPE \
         Expected value is 'b%0b Generated value is 'b%0b",rx_data_type,`PATH.RX_DATA_TYPE);

  XIP_EN_OTHER_PCLK:assert (`PATH.EN_OTHER_PCLK == en_other_pclk) 
      else $display("INCORRECT_PARAMETER: EN_OTHER_PCLK  \
         Expected value is 'b%0b Generated value is 'b%0b",en_other_pclk,`PATH.EN_OTHER_PCLK);

  XIP_EN_OTHER_NCLK:assert (`PATH.EN_OTHER_NCLK == en_other_nclk) 
      else $display("INCORRECT_PARAMETER: EN_OTHER_NCLK  \
         Expected value is 'b%0b Generated value is 'b%0b",en_other_nclk,`PATH.EN_OTHER_NCLK);

  XIP_RX_CLK_PHASE_P:assert (`PATH.RX_CLK_PHASE_P == rx_clk_phase_p ) 
      else $display("INCORRECT_PARAMETER: RX_CLK_PHASE_P  \
         Expected value is 'b%0b Generated value is 'b%0b",rx_clk_phase_p,`PATH.RX_CLK_PHASE_P);

  XIP_RX_CLK_PHASE_N:assert (`PATH.RX_CLK_PHASE_N == rx_clk_phase_n) 
      else $display("INCORRECT_PARAMETER: RX_CLK_PHASE_N \
         Expected value is 'b%0b Generated value is 'b%0b",rx_clk_phase_n,`PATH.RX_CLK_PHASE_N);

  XIP_TX_GATING:assert (`PATH.TX_GATING == tx_gating) 
      else $display("INCORRECT_PARAMETER: TX_GATING  \
         Expected value is 'b%0b Generated value is 'b%0b",tx_gating,`PATH.TX_GATING);

  XIP_RX_GATING:assert (`PATH.RX_GATING == rx_gating) 
      else $display("INCORRECT_PARAMETER: RX_GATING  \
         Expected value is 'b%0b Generated value is 'b%0b",rx_gating,`PATH.RX_GATING);

  XIP_RXTX_BITSLICE_EN:assert (`PATH.RXTX_BITSLICE_EN == rxtx_bitslice_en_1 ) 
      else $display("INCORRECT_PARAMETER: RXTX_BITSLICE_EN  \
         Expected value is 'b%0b Generated value is 'b%0b",rxtx_bitslice_en_1,`PATH.RXTX_BITSLICE_EN);

  XIP_EN_DYN_ODLY_MODE:assert (`PATH.EN_DYN_ODLY_MODE == en_dyn_odly_mode ) 
      else $display("INCORRECT_PARAMETER: EN_DYN_ODLY_MODE  \
         Expected value is 'b%0b Generated value is 'b%0b",en_dyn_odly_mode,`PATH.EN_DYN_ODLY_MODE);

  XIP_REFCLK_SRC:assert (`XIP_PATH.REFCLK_SRC == refclk_src ) 
      else $display("INCORRECT_PARAMETER: REFCLK_SRC \
         Expected value is 'd%0d Generated value is 'd%0d",refclk_src,`XIP_PATH.REFCLK_SRC);

  XIP_TBYTE_CTL:assert (`XIP_PATH.TBYTE_CTL == "TBYTE_IN") 
      else $display("INCORRECT_PARAMETER: TBYTE_CTL \
         Expected value is %0s Generated value is %0s","TBYTE_IN",`XIP_PATH.TBYTE_CTL);

  XIP_DELAY_TYPE:assert (`XIP_PATH.DELAY_TYPE == "FIXED") 
      else $display("INCORRECT_PARAMETER: DELAY_TYPE  \
         Expected value is %0s Generated value is %0s","FIXED",`XIP_PATH.DELAY_TYPE);
  
  XIP_DELAY_FORMAT:assert (`XIP_PATH.DELAY_FORMAT == "TIME") 
      else $display("INCORRECT_PARAMETER: DELAY_FORMAT \
         Expected value is %0s Generated value is %0s","TIME",`XIP_PATH.DELAY_FORMAT);

  XIP_UPDATE_MODE:assert (`XIP_PATH.UPDATE_MODE == "ASYNC") 
      else $display("INCORRECT_PARAMETER: UPDATE_MODE \
         Expected value is %0s Generated value is %0s","ASYNC",`XIP_PATH.UPDATE_MODE);

  XIP_FIFO_SYNC_MODE:assert (`XIP_PATH.FIFO_SYNC_MODE == fifo_sync_mode) 
      else $display("INCORRECT_PARAMETER: FIFO_SYNC_MODE \
         Expected value is 'd%0d Generated value is 'd%0d",fifo_sync_mode,`XIP_PATH.FIFO_SYNC_MODE);

  XIP_GCLK_SRC:assert (`XIP_PATH.GCLK_SRC == gclk_src) 
      else $display("INCORRECT_PARAMETER: GCLK_SRC  \
         Expected value is 'd%0d Generated value is 'd%0d",gclk_src,`XIP_PATH.GCLK_SRC);

  XIP_TRI_OUTPUT_PHASE_90:assert (`XIP_PATH.TRI_OUTPUT_PHASE_90 == tri_output_phase_90 ) 
      else $display("INCORRECT_PARAMETER: TRI_OUTPUT_PHASE_90 \
         Expected value is 'd%0d Generated value is 'd%0d",tri_output_phase_90,`XIP_PATH.TRI_OUTPUT_PHASE_90);

  XIP_SERIAL_MODE:assert (`XIP_PATH.SERIAL_MODE == serial_mode ) 
      else $display("INCORRECT_PARAMETER: SERIAL_MODE \
         Expected value is 'd%0d Generated value is 'd%0d",serial_mode,`XIP_PATH.SERIAL_MODE);

  XIP_INV_RXCLK:assert (`XIP_PATH.INV_RXCLK == inv_rxclk) 
      else $display("INCORRECT_PARAMETER: INV_RXCLK  \
         Expected value is 'd%0d Generated value is 'd%0d",inv_rxclk,`XIP_PATH.INV_RXCLK);

  XIP_EN_CLK_TO_EXT_NORTH:assert (`XIP_PATH.EN_CLK_TO_EXT_NORTH == en_clk_to_ext_north ) 
      else $display("INCORRECT_PARAMETER: EN_CLK_TO_EXT_NORTH \
         Expected value is 'd%0d Generated value is 'd%0d",en_clk_to_ext_north,`XIP_PATH.EN_CLK_TO_EXT_NORTH);

  XIP_EN_CLK_TO_EXT_SOUTH:assert (`XIP_PATH.EN_CLK_TO_EXT_SOUTH == en_clk_to_ext_south  ) 
      else $display("INCORRECT_PARAMETER: EN_CLK_TO_EXT_SOUTH \
         Expected value is 'd%0d Generated value is 'd%0d",en_clk_to_ext_south,`XIP_PATH.EN_CLK_TO_EXT_SOUTH);

  XIP_RX_DELAY_VAL:assert (`XIP_PATH.RX_DELAY_VAL == rx_delay_val ) 
      else $display("INCORRECT_PARAMETER: RX_DELAY_VAL  \
         Expected value is %0p Generated value is %0p",rx_delay_val,`XIP_PATH.RX_DELAY_VAL);

  XIP_TX_DELAY_VAL:assert (`XIP_PATH.TX_DELAY_VAL == tx_delay_val) 
      else $display("INCORRECT_PARAMETER: TX_DELAY_VAL  \
         Expected value is %0p Generated value is %0p",tx_delay_val,`XIP_PATH.TX_DELAY_VAL);

  XIP_TRI_DELAY_VAL:assert (`XIP_PATH.TRI_DELAY_VAL == tri_delay_val) 
      else $display("INCORRECT_PARAMETER: TRI_DELAY_VAL  \
         Expected value is %0p Generated value is %0p",tri_delay_val,`XIP_PATH.TRI_DELAY_VAL);

  XIP_READ_IDLE_COUNT:assert (`XIP_PATH.READ_IDLE_COUNT == read_idle_count ) 
      else $display("INCORRECT_PARAMETER: READ_IDLE_COUNT  \
         Expected value is %0p Generated value is %0p",read_idle_count,`XIP_PATH.READ_IDLE_COUNT);

  XIP_ROUNDING_FACTOR:assert (`XIP_PATH.ROUNDING_FACTOR == rounding_factor) 
      else $display("INCORRECT_PARAMETER: ROUNDING_FACTOR \
         Expected value is %0p Generated value is %0p",rounding_factor,`XIP_PATH.ROUNDING_FACTOR);

  XIP_REFCLK_FREQ:assert (`XIP_PATH.REFCLK_FREQ == 300.0) 
      else $display("INCORRECT_PARAMETER: REFCLK_FREQ  \
         Expected value is 'd%0d Generated value is %0f",300,`XIP_PATH.REFCLK_FREQ);

  XIP_DCI_SRC:assert (`XIP_PATH.DCI_SRC == dci_src) 
      else $display("INCORRECT_PARAMETER: DCI_SRC  \
         Expected value is 'd%0d Generated value is 'd%0d",dci_src,`XIP_PATH.DCI_SRC);

  XIP_IDLY_VT_TRACK:assert (`XIP_PATH.IDLY_VT_TRACK == idly_vt_track ) 
      else $display("INCORRECT_PARAMETER: IDLY_VT_TRACK \
         Expected value is 'd%0d Generated value is 'd%0d",idly_vt_track,`XIP_PATH.IDLY_VT_TRACK);

  XIP_ODLY_VT_TRACK:assert (`XIP_PATH.ODLY_VT_TRACK == odly_vt_track) 
      else $display("INCORRECT_PARAMETER: ODLY_VT_TRACK  \
         Expected value is 'd%0d Generated value is 'd%0d",odly_vt_track,`XIP_PATH.ODLY_VT_TRACK);

  XIP_QDLY_VT_TRACK:assert (`XIP_PATH.QDLY_VT_TRACK == qdly_vt_track) 
      else $display("INCORRECT_PARAMETER: QDLY_VT_TRACK  \
         Expected value is 'd%0d Generated value is 'd%0d",qdly_vt_track,`XIP_PATH.QDLY_VT_TRACK);

  XIP_RXGATE_EXTEND:assert (`XIP_PATH.RXGATE_EXTEND == rxgate_extend) 
      else $display("INCORRECT_PARAMETER: RXGATE_EXTEND  \
         Expected value is 'd%0d Generated value is 'd%0d",rxgate_extend,`XIP_PATH.RXGATE_EXTEND); 

  $display("DDR3 assertions executed in simulation");     
`endif
`endif
end
 /*ODT PARAMETERS VERIFICATION */
//  A_ODTWR:assert (ODTWR == 16'h8421 )  
//     else $display("INCORRECT_PARAMETER: ODTWR     \
//        Expected value is 'h%0h Generated value is 'h%0h",16'h8421,ODTWR); 
//
//  A_ODTRD:assert (ODTRD == 16'h0000 ) 
//     else $display("INCORRECT_PARAMETER: ODTRD     \
//        Expected value is 'h%0h Generated value is 'h%0h",16'h0000,ODTRD);
//
//  A_ODTWRDEL:assert (ODTWRDEL == CWL)  
//     else $display("INCORRECT_PARAMETER: ODTWRDEL  \
//        Expected value is 'd%0d Generated value is 'd%0d",CWL,ODTWRDEL);
//
//  A_ODTRDDEL:assert (ODTRDDEL == CL) 
//     else $display("INCORRECT_PARAMETER: ODTRDDEL  \
//        Expected value is 'd%0d Generated value is 'd%0d",CL,ODTRDDEL); 
// 
//  A_ODTWRDUR:assert (6 <= ODTWRDUR <= 14)  
//     else $display("INCORRECT_PARAMETER: ODTWRDUR  \
//        Supported range is from %d to %d,Generated value is 'd%0d",6,14,ODTWRDUR); 
//
//  A_ODTRDDUR:assert (6 <= ODTRDDUR <= 14) 
//     else $display("INCORRECT_PARAMETER: ODTRDDUR  \
//        Supported range is from %d to %d,Generated value is 'd%0d",6,14,ODTRDDUR); 
//  
//  A_ODTWRODEL:assert (ODTWRODEL ==  5'h9)  
//     else $display("INCORRECT_PARAMETER: ODTWRODEL \
//        Expected value is 'd%0d Generated value is 'd%0d ",'h9,ODTWRODEL);
//
//  A_ODTRDODEL:assert (ODTRDODEL == 'h9) 
//     else $display("INCORRECT_PARAMETER: ODTRDODEL \
//        Expected value is 'd%0d Generated value is 'd%0d",'h9,ODTRDODEL); 
//  
//  A_ODTWRODUR:assert (ODTWRODUR == 'h6 ) 
//     else $display("INCORRECT_PARAMETER: ODTWRODUR \
//        Expected value is 'd%0d Generated value is 'd%0d",'h6,ODTWRODUR);
//
//  A_ODTRDODUR:assert (ODTRDODUR == 'h6)  
//     else $display("INCORRECT_PARAMETER: ODTRDODUR \
//        Expected value is 'd%0d Generated value is 'd%0d",'h6,ODTRDODUR); 
//
//  A_ODTNOP:assert (ODTNOP == 16'h0000)  
//     else $display("INCORRECT_PARAMETER: ODTNOP    \
//        Expected value is 'h%0h Generated value is 'h%0h",16'h0000,ODTNOP); 
/*ODT PARAMETERS VERIFICATION */
//  P_ODTWR:assert (`PATH.ODTWR == 16'h8421 )  
//     else $display("INCORRECT_PARAMETER: ODTWR     \
//        Expected value is 'h%0h Generated value is 'h%0h",16'h8421,`PATH.ODTWR); 
//
//  P_ODTRD:assert (`PATH.ODTRD == 16'h0000 ) 
//     else $display("INCORRECT_PARAMETER: ODTRD     \
//        Expected value is 'h%0h Generated value is 'h%0h",16'h0000,`PATH.ODTRD);
//
//  P_ODTWRDEL:assert (`PATH.ODTWRDEL == CWL)  
//     else $display("INCORRECT_PARAMETER: ODTWRDEL  \
//        Expected value is 'd%0d Generated value is 'd%0d",CWL,`PATH.ODTWRDEL);
//
//  P_ODTRDDEL:assert (`PATH.ODTRDDEL == CL) 
//     else $display("INCORRECT_PARAMETER: ODTRDDEL  \
//        Expected value is 'd%0d Generated value is 'd%0d",CL,`PATH.ODTRDDEL); 
// 
//  P_ODTWRDUR:assert (6 <= `PATH.ODTWRDUR <= 14)  
//     else $display("INCORRECT_PARAMETER: ODTWRDUR  \
//        Supported range is from %d to %d,Generated value is 'd%0d",6,14,`PATH.ODTWRDUR); 
//
//  P_ODTRDDUR:assert (6 <= `PATH.ODTRDDUR <= 14) 
//     else $display("INCORRECT_PARAMETER: ODTRDDUR  \
//        Supported range is from %d to %d,Generated value is 'd%0d",6,14,`PATH.ODTRDDUR); 
//  
//  P_ODTWRODEL:assert (`PATH.ODTWRODEL ==  5'h9)  
//     else $display("INCORRECT_PARAMETER: ODTWRODEL \
//        Expected value is 'd%0d Generated value is 'd%0d ",'h9,`PATH.ODTWRODEL);
//
//  P_ODTRDODEL:assert (`PATH.ODTRDODEL == 'h9) 
//     else $display("INCORRECT_PARAMETER: ODTRDODEL \
//        Expected value is 'd%0d Generated value is 'd%0d",'h9,`PATH.ODTRDODEL); 
//  
//  P_ODTWRODUR:assert (`PATH.ODTWRODUR == 'h6 ) 
//     else $display("INCORRECT_PARAMETER: ODTWRODUR \
//        Expected value is 'd%0d Generated value is 'd%0d",'h6,`PATH.ODTWRODUR);
//
//  P_ODTRDODUR:assert (`PATH.ODTRDODUR == 'h6)  
//     else $display("INCORRECT_PARAMETER: ODTRDODUR \
//        Expected value is 'd%0d Generated value is 'd%0d",'h6,`PATH.ODTRDODUR); 
//
//  P_ODTNOP:assert (`PATH.ODTNOP == 16'h0000)  
//     else $display("INCORRECT_PARAMETER: ODTNOP    \
//        Expected value is 'h%0h Generated value is 'h%0h",16'h0000,`PATH.ODTNOP); 
   

