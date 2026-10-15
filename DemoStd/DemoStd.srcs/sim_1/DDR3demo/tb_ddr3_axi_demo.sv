`timescale 1ns / 1ps

module tb_ddr3_axi_demo;
    logic sys_clk = 1'b0;
    logic sys_rst = 1'b0;
    wire ui_clk;
    wire ui_rst;
    wire calib_done;
    wire axi_resetn;
    wire done;
    wire pass;
    wire [15:0] error_count;

    wire [14:0] ddr_addr;
    wire [2:0] ddr_ba;
    wire ddr_ras_n;
    wire ddr_cas_n;
    wire ddr_we_n;
    wire [0:0] ddr_cke;
    wire [0:0] ddr_odt;
    wire [0:0] ddr_cs_n;
    wire [0:0] ddr_ck_p;
    wire [0:0] ddr_ck_n;
    wire ddr_reset_n;
    wire [3:0] ddr_dm;
    wire [31:0] ddr_dq;
    wire [3:0] ddr_dqs_p;
    wire [3:0] ddr_dqs_n;
    wire [0:0] model_ck_p;
    wire [0:0] model_ck_n;

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
    wire aw_fire;
    wire w_fire;
    wire b_fire;
    wire ar_fire;
    wire r_fire;
    wire [63:0] expected_wdata;
    wire [63:0] expected_rdata;
    wire read_match;
    logic [2:0] write_burst_beats = 3'd0;
    logic [2:0] read_burst_beats = 3'd0;
    logic [7:0] aw_count = 8'd0;
    logic [7:0] w_count = 8'd0;
    logic [7:0] b_count = 8'd0;
    logic [7:0] ar_count = 8'd0;
    logic [7:0] r_count = 8'd0;
    logic [7:0] write_word_number = 8'd0;
    logic [63:0] write_word_data = 64'd0;
    logic [7:0] read_word_number = 8'd0;
    logic [63:0] read_word_data = 64'd0;
    logic [63:0] read_word_expected = 64'd0;
    logic read_word_ok = 1'b0;

    // 测试平台连接 AXI 主控、MIG 仿真模型和两片 x16 DDR3 芯片
    always #7.143 sys_clk = ~sys_clk;

    initial begin
        #200;
        sys_rst = 1'b1;
        #200;
        sys_rst = 1'b0;
    end

    assign axi_resetn = ~ui_rst;
    assign #0.100 model_ck_p = ddr_ck_p;
    assign #0.100 model_ck_n = ddr_ck_n;
    // 仅在 VALID/READY 同时有效时统计一次 AXI 握手
    assign aw_fire = awvalid && awready;
    assign w_fire = wvalid && wready;
    assign b_fire = bvalid && bready;
    assign ar_fire = arvalid && arready;
    assign r_fire = rvalid && rready;
    assign expected_wdata = {56'd0, w_count} + 64'd1;
    assign expected_rdata = {56'd0, r_count} + 64'd1;
    assign read_match = r_fire && rdata === expected_rdata && rresp == 2'b00 &&
                        rid == 4'd0 && rlast == (read_burst_beats == 3'd7);

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
        .sys_rst(sys_rst), .c0_sys_clk_i(sys_clk),
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

    for (genvar i = 0; i < 2; i++) begin : memory
        ddr3 #(.check_strict_timing(0)) chip (
            .rst_n(ddr_reset_n), .ck(model_ck_p[0]), .ck_n(model_ck_n[0]),
            .cke(ddr_cke[0]), .cs_n(ddr_cs_n[0]), .ras_n(ddr_ras_n),
            .cas_n(ddr_cas_n), .we_n(ddr_we_n), .addr(ddr_addr), .ba(ddr_ba),
            .odt(ddr_odt[0]), .dm_tdqs(ddr_dm[i*2+:2]),
            .dq(ddr_dq[i*16+:16]), .dqs(ddr_dqs_p[i*2+:2]),
            .dqs_n(ddr_dqs_n[i*2+:2]), .tdqs_n()
        );
    end

    // 逐拍检查 AXI 协议、地址顺序和读写数据
    always @(posedge ui_clk) begin
        if (!axi_resetn) begin
            write_word_number <= 8'd0;
            write_word_data <= 64'd0;
            read_word_number <= 8'd0;
            read_word_data <= 64'd0;
            read_word_expected <= 64'd0;
            read_word_ok <= 1'b0;
        end else begin
            if (aw_fire) begin
                if (!calib_done || aw_count >= 8 || awaddr !== ({22'd0, aw_count} << 6) ||
                    awlen !== 8'd7 || awsize !== 3'd3 || awburst !== 2'b01)
                    $fatal(1, "AW protocol error: count=%0d addr=%h", aw_count, awaddr);
                aw_count <= aw_count + 8'd1;
            end
            if (w_fire) begin
                write_word_number <= w_count + 8'd1;
                write_word_data <= wdata;
                if (w_count >= 64 || aw_count != b_count + 1 || wdata !== expected_wdata ||
                    wstrb !== 8'hff || wlast !== (write_burst_beats == 3'd7))
                    $fatal(1, "W protocol error: beat=%0d data=%h expected=%h", w_count, wdata, expected_wdata);
                w_count <= w_count + 8'd1;
                write_burst_beats <= write_burst_beats + 3'd1;
            end
            if (b_fire) begin
                if (b_count >= 8 || aw_count != b_count + 1 ||
                    w_count != (b_count + 1) * 8 || write_burst_beats != 0 ||
                    bresp !== 2'b00 || bid !== 4'd0)
                    $fatal(1, "B protocol error: count=%0d resp=%h", b_count, bresp);
                b_count <= b_count + 8'd1;
            end
            if (ar_fire) begin
                if (b_count != 8 || ar_count >= 8 ||
                    araddr !== ({22'd0, ar_count} << 6) || arlen !== 8'd7 ||
                    arsize !== 3'd3 || arburst !== 2'b01)
                    $fatal(1, "AR protocol error: count=%0d addr=%h", ar_count, araddr);
                ar_count <= ar_count + 8'd1;
            end
            if (r_fire) begin
                read_word_number <= r_count + 8'd1;
                read_word_data <= rdata;
                read_word_expected <= expected_rdata;
                read_word_ok <= read_match;
                if (r_count >= 64 || ar_count != (r_count >> 3) + 1 || !read_match)
                    $fatal(1, "R protocol error: beat=%0d data=%h expected=%h last=%b", r_count, rdata, expected_rdata, rlast);
                r_count <= r_count + 8'd1;
                read_burst_beats <= read_burst_beats + 3'd1;
            end
        end
    end

    initial begin
        // 完成校准和全部事务后，核对握手数量及最后一个数据拍
        wait (calib_done === 1'b1);
        $display("DDR3 calibration complete at %0t", $time);
        wait (done === 1'b1);
        #1;
        if (aw_count != 8 || w_count != 64 || b_count != 8 ||
            ar_count != 8 || r_count != 64 || write_burst_beats != 0 || read_burst_beats != 0)
            $fatal(1, "Handshake counts incorrect: AW=%0d W=%0d B=%0d AR=%0d R=%0d",
                   aw_count, w_count, b_count, ar_count, r_count);
        if (pass !== 1'b1 || error_count != 16'd0)
            $fatal(1, "DDR3 AXI4 FAIL: error_count=%0d", error_count);
        if (write_word_number != 8'd64 || write_word_data !== 64'd64 ||
            read_word_number != 8'd64 || read_word_data !== 64'd64 ||
            read_word_expected !== 64'd64 || read_word_ok !== 1'b1)
            $fatal(1, "Captured last word incorrect: W=%0d/%h R=%0d/%h expected=%h ok=%b",
                   write_word_number, write_word_data, read_word_number,
                   read_word_data, read_word_expected, read_word_ok);
        $display("DDR3 AXI4 PASS: AW=%0d W=%0d B=%0d AR=%0d R=%0d, 64 words verified",
                 aw_count, w_count, b_count, ar_count, r_count);
        #100;
        $finish;
    end

    initial begin
        // 防止校准或 AXI 事务异常时仿真永久等待
        #100_000;
        if (calib_done !== 1'b1)
            $fatal(1, "DDR3 calibration timeout");
        $fatal(1, "DDR3 AXI4 transaction timeout");
    end
endmodule
