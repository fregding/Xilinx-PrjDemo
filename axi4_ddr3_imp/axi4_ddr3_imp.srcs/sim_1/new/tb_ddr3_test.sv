//-----------------------------------------------------------------------------
// File name : tb_ddr3_test.sv
// Description : ddr3_test_top 仿真测试平台
//   - 70MHz(14.286ns) 差分系统时钟 + 高有效 sys_rst 上电复位（与 MIG 输入时钟配置一致）
//   - 例化 Micron DDR3 行为模型（MT41J256M8 等效：2Gb / x8 / 15bit 行地址）
//   - 校准完成后自动开始 CQE 写读校验，按 led_done/led_error 判 PASS/FAIL
//   - 带校准超时与整体超时保护
//-----------------------------------------------------------------------------
`timescale 1ns / 1ps

module tb_ddr3_test;

//--------------------------------------------------------------------------------
// 时钟与复位
//--------------------------------------------------------------------------------
logic sys_clk_p = 1'b0;
logic sys_rst;

wire  sys_clk_n;
assign sys_clk_n = ~sys_clk_p;

// 70MHz 差分系统时钟（14.286ns）
always #7.143 sys_clk_p = ~sys_clk_p;

// sys_rst 高有效，上电保持 300ns
initial begin
    sys_rst = 1'b1;
    #300;
    sys_rst = 1'b0;
end

//--------------------------------------------------------------------------------
// DUT <-> DDR3 颗粒模型互连
//--------------------------------------------------------------------------------
wire [14:0] c0_ddr3_addr;
wire [2:0]  c0_ddr3_ba;
wire        c0_ddr3_cas_n;
wire [0:0]  c0_ddr3_cke;
wire [0:0]  c0_ddr3_ck_n;
wire [0:0]  c0_ddr3_ck_p;
wire [0:0]  c0_ddr3_cs_n;
wire [0:0]  c0_ddr3_dm;
wire [7:0]  c0_ddr3_dq;
wire [0:0]  c0_ddr3_dqs_n;
wire [0:0]  c0_ddr3_dqs_p;
wire [0:0]  c0_ddr3_odt;
wire        c0_ddr3_ras_n;
wire        c0_ddr3_reset_n;
wire        c0_ddr3_we_n;

wire        led_calib;
wire        led_done;
wire        led_error;

// 仿真 PHY 输出无延时，模型侧时钟整体后移 100ps 以满足建立/保持窗口
wire model_ck_p;
wire model_ck_n;
assign #0.100 model_ck_p = c0_ddr3_ck_p[0];
assign #0.100 model_ck_n = c0_ddr3_ck_n[0];

//--------------------------------------------------------------------------------
// DUT
//--------------------------------------------------------------------------------
ddr3_test_top u_dut (
    .c0_sys_clk_p     (sys_clk_p       ),
    .c0_sys_clk_n     (sys_clk_n       ),
    .sys_rst          (sys_rst         ),

    .c0_ddr3_addr     (c0_ddr3_addr    ),
    .c0_ddr3_ba       (c0_ddr3_ba      ),
    .c0_ddr3_cas_n    (c0_ddr3_cas_n   ),
    .c0_ddr3_cke      (c0_ddr3_cke     ),
    .c0_ddr3_ck_n     (c0_ddr3_ck_n    ),
    .c0_ddr3_ck_p     (c0_ddr3_ck_p    ),
    .c0_ddr3_cs_n     (c0_ddr3_cs_n    ),
    .c0_ddr3_dm       (c0_ddr3_dm      ),
    .c0_ddr3_dq       (c0_ddr3_dq      ),
    .c0_ddr3_dqs_n    (c0_ddr3_dqs_n   ),
    .c0_ddr3_dqs_p    (c0_ddr3_dqs_p   ),
    .c0_ddr3_odt      (c0_ddr3_odt     ),
    .c0_ddr3_ras_n    (c0_ddr3_ras_n   ),
    .c0_ddr3_reset_n  (c0_ddr3_reset_n ),
    .c0_ddr3_we_n     (c0_ddr3_we_n    ),

    .led_calib        (led_calib       ),
    .led_done         (led_done        ),
    .led_error        (led_error       )
);

//--------------------------------------------------------------------------------
// Micron DDR3 行为模型（密度/速率/位宽在 ddr3_sdram_model_wrapper.sv 中配置）
//--------------------------------------------------------------------------------
ddr3 #(
    .check_strict_timing (0)     // 关严格时序检查，避免理想 PHY 时序告警
) u_ddr3_model (
    .rst_n   (c0_ddr3_reset_n ),
    .ck      (model_ck_p      ),
    .ck_n    (model_ck_n      ),
    .cke     (c0_ddr3_cke[0]  ),
    .cs_n    (c0_ddr3_cs_n[0] ),
    .ras_n   (c0_ddr3_ras_n   ),
    .cas_n   (c0_ddr3_cas_n   ),
    .we_n    (c0_ddr3_we_n    ),
    .dm_tdqs (c0_ddr3_dm[0]   ),
    .ba      (c0_ddr3_ba      ),
    .addr    (c0_ddr3_addr    ),
    .dq      (c0_ddr3_dq      ),
    .dqs     (c0_ddr3_dqs_p[0]),
    .dqs_n   (c0_ddr3_dqs_n[0]),
    .tdqs_n  (                ),
    .odt     (c0_ddr3_odt[0]  )
);

//--------------------------------------------------------------------------------
// 测试流程：等校准 -> 等校验完成 -> PASS/FAIL
//--------------------------------------------------------------------------------
initial begin
    $display("[%0t] TB: waiting DDR3 calibration ...", $time);
    wait (led_calib === 1'b1);
    $display("[%0t] TB: calibration complete, CQE traffic start", $time);

    wait (led_done === 1'b1);
    #10;
    if (led_error === 1'b1)
        $display("[%0t] TB: *** DDR3 CQE TEST FAIL ***", $time);
    else
        $display("[%0t] TB: *** DDR3 CQE TEST PASS ***", $time);
    $finish;
end

// 校准超时保护（400us）
initial begin
    #400_000;
    if (led_calib !== 1'b1)
        $fatal(1, "[%0t] TB: calibration timeout", $time);
end

// 整体超时保护（1ms）
initial begin
    #1_000_000;
    $fatal(1, "[%0t] TB: test timeout, traffic not finished", $time);
end

endmodule
