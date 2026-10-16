module ddr3_axi_top (
    input  logic        sys_clk_p,
    input  logic        sys_clk_n,
    input  logic        rst_n,
    output wire [14:0]  ddr_addr,
    output wire [2:0]   ddr_ba,
    output wire         ddr_ras_n,
    output wire         ddr_cas_n,
    output wire         ddr_we_n,
    output wire [0:0]   ddr_cke,
    output wire [0:0]   ddr_odt,
    output wire [0:0]   ddr_cs_n,
    output wire [0:0]   ddr_ck_p,
    output wire [0:0]   ddr_ck_n,
    output wire         ddr_reset_n,
    output wire [3:0]   ddr_dm,
    inout  wire [31:0]  ddr_dq,
    inout  wire [3:0]   ddr_dqs_p,
    inout  wire [3:0]   ddr_dqs_n
);
    wire sys_clk;
    wire ui_clk;
    wire ui_rst;
    wire calib_done;
    wire axi_resetn;
    wire done;
    wire pass;
    wire [15:0] error_count;

    wire [3:0] awid;
    wire [29:0] awaddr;
    wire [7:0] awlen;
    wire [2:0] awsize;
    wire [1:0] awburst;
    wire awlock;
    wire [3:0] awcache;
    wire [2:0] awprot;
    wire [3:0] awqos;
    wire awvalid;
    wire awready;
    wire [63:0] wdata;
    wire [7:0] wstrb;
    wire wlast;
    wire wvalid;
    wire wready;
    wire [3:0] bid;
    wire [1:0] bresp;
    wire bvalid;
    wire bready;
    wire [3:0] arid;
    wire [29:0] araddr;
    wire [7:0] arlen;
    wire [2:0] arsize;
    wire [1:0] arburst;
    wire arlock;
    wire [3:0] arcache;
    wire [2:0] arprot;
    wire [3:0] arqos;
    wire arvalid;
    wire arready;
    wire [3:0] rid;
    wire [63:0] rdata;
    wire [1:0] rresp;
    wire rlast;
    wire rvalid;
    wire rready;

    IBUFDS sys_clk_buf (
        .I(sys_clk_p),
        .IB(sys_clk_n),
        .O(sys_clk)
    );

    assign axi_resetn = ~ui_rst;

    ddr3_axi_demo demo (
        .clk(ui_clk), .rst_n(axi_resetn), .init_calib_complete(calib_done),
        .done(done), .pass(pass), .error_count(error_count),
        .awid(awid), .awaddr(awaddr), .awlen(awlen), .awsize(awsize),
        .awburst(awburst), .awlock(awlock), .awcache(awcache),
        .awprot(awprot), .awqos(awqos), .awvalid(awvalid), .awready(awready),
        .wdata(wdata), .wstrb(wstrb), .wlast(wlast), .wvalid(wvalid), .wready(wready),
        .bid(bid), .bresp(bresp), .bvalid(bvalid), .bready(bready),
        .arid(arid), .araddr(araddr), .arlen(arlen), .arsize(arsize),
        .arburst(arburst), .arlock(arlock), .arcache(arcache),
        .arprot(arprot), .arqos(arqos), .arvalid(arvalid), .arready(arready),
        .rid(rid), .rdata(rdata), .rresp(rresp), .rlast(rlast),
        .rvalid(rvalid), .rready(rready)
    );

    axi4_ddr3_bfm mig (
        .sys_rst(~rst_n), .c0_sys_clk_i(sys_clk),
        .c0_ddr3_addr(ddr_addr), .c0_ddr3_ba(ddr_ba),
        .c0_ddr3_ras_n(ddr_ras_n), .c0_ddr3_cas_n(ddr_cas_n),
        .c0_ddr3_we_n(ddr_we_n), .c0_ddr3_cke(ddr_cke),
        .c0_ddr3_odt(ddr_odt), .c0_ddr3_cs_n(ddr_cs_n),
        .c0_ddr3_ck_p(ddr_ck_p), .c0_ddr3_ck_n(ddr_ck_n),
        .c0_ddr3_reset_n(ddr_reset_n), .c0_ddr3_dm(ddr_dm),
        .c0_ddr3_dq(ddr_dq), .c0_ddr3_dqs_p(ddr_dqs_p),
        .c0_ddr3_dqs_n(ddr_dqs_n),
        .c0_init_calib_complete(calib_done),
        .c0_ddr3_ui_clk(ui_clk), .c0_ddr3_ui_clk_sync_rst(ui_rst),
        .dbg_clk(), .dbg_bus(), .c0_ddr3_aresetn(axi_resetn),
        .c0_ddr3_s_axi_awid(awid), .c0_ddr3_s_axi_awaddr(awaddr),
        .c0_ddr3_s_axi_awlen(awlen), .c0_ddr3_s_axi_awsize(awsize),
        .c0_ddr3_s_axi_awburst(awburst), .c0_ddr3_s_axi_awlock(awlock),
        .c0_ddr3_s_axi_awcache(awcache), .c0_ddr3_s_axi_awprot(awprot),
        .c0_ddr3_s_axi_awqos(awqos), .c0_ddr3_s_axi_awvalid(awvalid),
        .c0_ddr3_s_axi_awready(awready),
        .c0_ddr3_s_axi_wdata(wdata), .c0_ddr3_s_axi_wstrb(wstrb),
        .c0_ddr3_s_axi_wlast(wlast), .c0_ddr3_s_axi_wvalid(wvalid),
        .c0_ddr3_s_axi_wready(wready),
        .c0_ddr3_s_axi_bid(bid), .c0_ddr3_s_axi_bresp(bresp),
        .c0_ddr3_s_axi_bvalid(bvalid), .c0_ddr3_s_axi_bready(bready),
        .c0_ddr3_s_axi_arid(arid), .c0_ddr3_s_axi_araddr(araddr),
        .c0_ddr3_s_axi_arlen(arlen), .c0_ddr3_s_axi_arsize(arsize),
        .c0_ddr3_s_axi_arburst(arburst), .c0_ddr3_s_axi_arlock(arlock),
        .c0_ddr3_s_axi_arcache(arcache), .c0_ddr3_s_axi_arprot(arprot),
        .c0_ddr3_s_axi_arqos(arqos), .c0_ddr3_s_axi_arvalid(arvalid),
        .c0_ddr3_s_axi_arready(arready),
        .c0_ddr3_s_axi_rid(rid), .c0_ddr3_s_axi_rdata(rdata),
        .c0_ddr3_s_axi_rresp(rresp), .c0_ddr3_s_axi_rlast(rlast),
        .c0_ddr3_s_axi_rvalid(rvalid), .c0_ddr3_s_axi_rready(rready)
    );
endmodule
