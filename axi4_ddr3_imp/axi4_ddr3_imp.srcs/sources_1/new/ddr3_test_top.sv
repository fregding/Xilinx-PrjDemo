//-----------------------------------------------------------------------------
// File name : ddr3_test_top.sv
// Description : DDR3 AXI 读写数据校验顶层
//   - traffic_gen  (Producer) : CQE 协议写流量，先写数据块再写 CQE 通知字节
//   - traffic_check(Consumer) : 轮询 CQE，命中后读回数据块逐字校验
//   - 两者共用 MIG ddr3_0 的 S_AXI 口：Producer 独占 AW/W/B，Consumer 独占 AR/R
//   - start 由 c0_init_calib_complete 电平门控（校准完成后自动开始）
//   - 板级观测：led_calib / led_done / led_error
//-----------------------------------------------------------------------------
module ddr3_test_top
    import axi_pkg::*;
#(
    parameter int NUM_BLOCKS  = 15  // CQE 协议块数（idx 0 ~ NUM_BLOCKS-1）
)(
// 系统时钟（差分 70MHz）与复位（高有效）
    input  logic         c0_sys_clk_p,
    input  logic         c0_sys_clk_n,
    input  logic         sys_rst,

// DDR3 物理接口
    output logic [14:0]  c0_ddr3_addr,
    output logic [2:0]   c0_ddr3_ba,
    output logic         c0_ddr3_cas_n,
    output logic [0:0]   c0_ddr3_cke,
    output logic [0:0]   c0_ddr3_ck_n,
    output logic [0:0]   c0_ddr3_ck_p,
    output logic [0:0]   c0_ddr3_cs_n,
    output logic [0:0]   c0_ddr3_dm,
    inout  tri   [7:0]   c0_ddr3_dq,
    inout  tri   [0:0]   c0_ddr3_dqs_n,
    inout  tri   [0:0]   c0_ddr3_dqs_p,
    output logic [0:0]   c0_ddr3_odt,
    output logic         c0_ddr3_ras_n,
    output logic         c0_ddr3_reset_n,
    output logic         c0_ddr3_we_n,

// 状态观测 LED
    output logic         led_calib,    // DDR3 初始化校准完成
    output logic         led_done,     // 写读校验全部完成
    output logic         led_error     // 数据校验出错
);

//--------------------------------------------------------------------------------
// MIG 用户接口时钟/复位
//--------------------------------------------------------------------------------
logic ui_clk;           // MIG 输出用户时钟，全部用户逻辑工作于此
logic ui_clk_sync_rst;  // MIG 输出，ui_clk 域同步复位（高有效）
logic init_calib_complete;
logic aresetn;          // MIG S_AXI 域复位输入（低有效）

logic rst_n;
assign rst_n = ~ui_clk_sync_rst;

// 校准完成后保持启动（电平）
logic start;
assign start = init_calib_complete;

//--------------------------------------------------------------------------------
// AXI 写通道（traffic_gen -> MIG S_AXI）
//--------------------------------------------------------------------------------
logic                        s_axi_awvalid;
logic                        s_axi_awready;
logic [AXI_ID_W      -1:0]   s_axi_awid;
logic [AXI_ADDR_W    -1:0]   s_axi_awaddr;
logic [AXI_LEN_W     -1:0]   s_axi_awlen;
logic [AXI_SIZE_W    -1:0]   s_axi_awsize;
logic [AXI_BURST_W   -1:0]   s_axi_awburst;

logic                        s_axi_wvalid;
logic                        s_axi_wready;
logic [AXI_DATA_W    -1:0]   s_axi_wdata;
logic [AXI_DATA_W/8  -1:0]   s_axi_wstrb;
logic                        s_axi_wlast;

logic                        s_axi_bvalid;
logic                        s_axi_bready;
logic [AXI_ID_W      -1:0]   s_axi_bid;
logic [AXI_RESP_W    -1:0]   s_axi_bresp;

//--------------------------------------------------------------------------------
// AXI 读通道（traffic_check -> MIG S_AXI）
//--------------------------------------------------------------------------------
logic                        s_axi_arvalid;
logic                        s_axi_arready;
logic [AXI_ID_W      -1:0]   s_axi_arid;
logic [AXI_ADDR_W    -1:0]   s_axi_araddr;
logic [AXI_LEN_W     -1:0]   s_axi_arlen;
logic [AXI_SIZE_W    -1:0]   s_axi_arsize;
logic [AXI_BURST_W   -1:0]   s_axi_arburst;

logic                        s_axi_rvalid;
logic                        s_axi_rready;
logic [AXI_ID_W      -1:0]   s_axi_rid;
logic [AXI_DATA_W    -1:0]   s_axi_rdata;
logic [AXI_RESP_W    -1:0]   s_axi_rresp;
logic                        s_axi_rlast;

//--------------------------------------------------------------------------------
// Producer / Consumer
//--------------------------------------------------------------------------------
logic gen_done;
logic chk_done;
logic chk_error;

traffic_gen #(
    .NUM_BLOCKS (NUM_BLOCKS)
) u_traffic_gen (
    .clk             (ui_clk         ),
    .rst_n           (rst_n          ),

    .start           (start          ),
    .done            (gen_done       ),

    .axi_mst_awvalid (s_axi_awvalid  ),
    .axi_mst_awready (s_axi_awready  ),
    .axi_mst_awid    (s_axi_awid     ),
    .axi_mst_awaddr  (s_axi_awaddr   ),
    .axi_mst_awlen   (s_axi_awlen    ),
    .axi_mst_awsize  (s_axi_awsize   ),
    .axi_mst_awburst (s_axi_awburst  ),

    .axi_mst_wvalid  (s_axi_wvalid   ),
    .axi_mst_wready  (s_axi_wready   ),
    .axi_mst_wdata   (s_axi_wdata    ),
    .axi_mst_wstrb   (s_axi_wstrb    ),
    .axi_mst_wlast   (s_axi_wlast    ),

    .axi_mst_bvalid  (s_axi_bvalid   ),
    .axi_mst_bready  (s_axi_bready   ),
    .axi_mst_bid     (s_axi_bid      ),
    .axi_mst_bresp   (s_axi_bresp    )
);

traffic_check #(
    .NUM_BLOCKS (NUM_BLOCKS)
) u_traffic_check (
    .clk             (ui_clk         ),
    .rst_n           (rst_n          ),

    .start           (start          ),
    .done            (chk_done       ),
    .error           (chk_error      ),

    .axi_mst_arvalid (s_axi_arvalid  ),
    .axi_mst_arready (s_axi_arready  ),
    .axi_mst_arid    (s_axi_arid     ),
    .axi_mst_araddr  (s_axi_araddr   ),
    .axi_mst_arlen   (s_axi_arlen    ),
    .axi_mst_arsize  (s_axi_arsize   ),
    .axi_mst_arburst (s_axi_arburst  ),

    .axi_mst_rvalid  (s_axi_rvalid   ),
    .axi_mst_rready  (s_axi_rready   ),
    .axi_mst_rid     (s_axi_rid      ),
    .axi_mst_rdata   (s_axi_rdata    ),
    .axi_mst_rresp   (s_axi_rresp    ),
    .axi_mst_rlast   (s_axi_rlast    )
);

//--------------------------------------------------------------------------------
// 状态 LED
//--------------------------------------------------------------------------------
assign led_calib = init_calib_complete;
assign led_done  = gen_done & chk_done;
assign led_error = chk_error;

//--------------------------------------------------------------------------------
// MIG ddr3_0
//   S_AXI 无 USER 信号；lock/cache/prot/qos 在顶层 tie 常量
//--------------------------------------------------------------------------------
assign aresetn = ~sys_rst;  // sys_rst 高有效 -> aresetn 低有效

ddr3_0 u_ddr3_0 (
  // 系统时钟与复位
  .c0_sys_clk_p                (c0_sys_clk_p           ),
  .c0_sys_clk_n                (c0_sys_clk_n           ),
  .sys_rst                     (sys_rst                ),

  // 用户接口时钟/复位/校准
  .c0_ddr3_ui_clk              (ui_clk                 ),
  .c0_ddr3_ui_clk_sync_rst     (ui_clk_sync_rst        ),
  .c0_ddr3_aresetn             (aresetn                ),
  .c0_init_calib_complete      (init_calib_complete    ),

  // 调试
  .dbg_clk                     (                       ),
  .dbg_bus                     (                       ),

  // AXI AW
  .c0_ddr3_s_axi_awid          (s_axi_awid             ),
  .c0_ddr3_s_axi_awaddr        (s_axi_awaddr           ),
  .c0_ddr3_s_axi_awlen         (s_axi_awlen            ),
  .c0_ddr3_s_axi_awsize        (s_axi_awsize           ),
  .c0_ddr3_s_axi_awburst       (s_axi_awburst          ),
  .c0_ddr3_s_axi_awlock        (1'b0                   ),
  .c0_ddr3_s_axi_awcache       (4'b0010                ),  // non-cacheable, bufferable
  .c0_ddr3_s_axi_awprot        (3'b000                 ),
  .c0_ddr3_s_axi_awqos         (4'b0000                ),
  .c0_ddr3_s_axi_awvalid       (s_axi_awvalid          ),
  .c0_ddr3_s_axi_awready       (s_axi_awready          ),

  // AXI W
  .c0_ddr3_s_axi_wdata         (s_axi_wdata            ),
  .c0_ddr3_s_axi_wstrb         (s_axi_wstrb            ),
  .c0_ddr3_s_axi_wlast         (s_axi_wlast            ),
  .c0_ddr3_s_axi_wvalid        (s_axi_wvalid           ),
  .c0_ddr3_s_axi_wready        (s_axi_wready           ),

  // AXI B
  .c0_ddr3_s_axi_bid           (s_axi_bid              ),
  .c0_ddr3_s_axi_bresp         (s_axi_bresp            ),
  .c0_ddr3_s_axi_bvalid        (s_axi_bvalid           ),
  .c0_ddr3_s_axi_bready        (s_axi_bready           ),

  // AXI AR
  .c0_ddr3_s_axi_arid          (s_axi_arid             ),
  .c0_ddr3_s_axi_araddr        (s_axi_araddr           ),
  .c0_ddr3_s_axi_arlen         (s_axi_arlen            ),
  .c0_ddr3_s_axi_arsize        (s_axi_arsize           ),
  .c0_ddr3_s_axi_arburst       (s_axi_arburst          ),
  .c0_ddr3_s_axi_arlock        (1'b0                   ),
  .c0_ddr3_s_axi_arcache       (4'b0010                ),  // non-cacheable, bufferable
  .c0_ddr3_s_axi_arprot        (3'b000                 ),
  .c0_ddr3_s_axi_arqos         (4'b0000                ),
  .c0_ddr3_s_axi_arvalid       (s_axi_arvalid          ),
  .c0_ddr3_s_axi_arready       (s_axi_arready          ),

  // AXI R
  .c0_ddr3_s_axi_rid           (s_axi_rid              ),
  .c0_ddr3_s_axi_rdata         (s_axi_rdata            ),
  .c0_ddr3_s_axi_rresp         (s_axi_rresp            ),
  .c0_ddr3_s_axi_rlast         (s_axi_rlast            ),
  .c0_ddr3_s_axi_rvalid        (s_axi_rvalid           ),
  .c0_ddr3_s_axi_rready        (s_axi_rready           ),

  // DDR3 物理接口
  .c0_ddr3_addr                (c0_ddr3_addr           ),
  .c0_ddr3_ba                  (c0_ddr3_ba             ),
  .c0_ddr3_cas_n               (c0_ddr3_cas_n          ),
  .c0_ddr3_cke                 (c0_ddr3_cke            ),
  .c0_ddr3_ck_n                (c0_ddr3_ck_n           ),
  .c0_ddr3_ck_p                (c0_ddr3_ck_p           ),
  .c0_ddr3_cs_n                (c0_ddr3_cs_n           ),
  .c0_ddr3_dm                  (c0_ddr3_dm             ),
  .c0_ddr3_dq                  (c0_ddr3_dq             ),
  .c0_ddr3_dqs_n               (c0_ddr3_dqs_n          ),
  .c0_ddr3_dqs_p               (c0_ddr3_dqs_p          ),
  .c0_ddr3_odt                 (c0_ddr3_odt            ),
  .c0_ddr3_ras_n               (c0_ddr3_ras_n          ),
  .c0_ddr3_reset_n             (c0_ddr3_reset_n        ),
  .c0_ddr3_we_n                (c0_ddr3_we_n           )
);

endmodule
