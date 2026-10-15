`timescale 1ns / 1ps

module tb_ddr3_native_demo;
    logic sys_clk = 1'b0;
    logic sys_rst = 1'b0;
    wire ui_clk;
    wire ui_rst;
    wire calib_done;
    wire native_resetn;
    wire done;
    wire pass;
    wire [15:0] error_count;

    wire [13:0] ddr_addr;
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

    wire [26:0] app_addr;
    wire [2:0] app_cmd;
    wire app_en;
    wire app_rdy;
    wire [255:0] app_wdf_data;
    wire [31:0] app_wdf_mask;
    wire app_wdf_wren;
    wire app_wdf_end;
    wire app_wdf_rdy;
    wire [255:0] app_rd_data;
    wire app_rd_data_valid;
    wire app_rd_data_end;
    wire write_fire;
    wire read_cmd_fire;
    wire read_fire;
    wire write_word_fire;
    wire read_word_fire;
    wire [63:0] expected_wdata;
    wire [63:0] expected_rdata;
    wire read_match;
    logic [255:0] write_chunk_data = 256'd0;
    logic [255:0] read_chunk_data = 256'd0;
    logic [1:0] write_lane = 2'd0;
    logic [1:0] read_lane = 2'd0;
    logic [7:0] write_cmd_count = 8'd0;
    logic [7:0] read_cmd_count = 8'd0;
    logic [7:0] read_chunk_count = 8'd0;
    logic [7:0] w_count = 8'd0;
    logic [7:0] r_count = 8'd0;
    logic [7:0] write_word_number = 8'd0;
    logic [63:0] write_word_data = 64'd0;
    logic [7:0] read_word_number = 8'd0;
    logic [63:0] read_word_data = 64'd0;
    logic [63:0] read_word_expected = 64'd0;
    logic read_word_ok = 1'b0;
    wire [2:0] write_burst_beats = w_count[2:0];
    wire [2:0] read_burst_beats = r_count[2:0];

    always #7.143 sys_clk = ~sys_clk;

    initial begin
        #200;
        sys_rst = 1'b1;
        #200;
        sys_rst = 1'b0;
    end

    assign native_resetn = ~ui_rst;
    assign #0.100 model_ck_p = ddr_ck_p;
    assign #0.100 model_ck_n = ddr_ck_n;
    assign write_fire = app_en && app_rdy && app_cmd == 3'b000 &&
                        app_wdf_wren && app_wdf_rdy;
    assign read_cmd_fire = app_en && app_rdy && app_cmd == 3'b001;
    assign read_fire = app_rd_data_valid;
    assign write_word_fire = w_count < write_cmd_count * 4;
    assign read_word_fire = r_count < read_chunk_count * 4;
    assign expected_wdata = {56'd0, w_count} + 64'd1;
    assign expected_rdata = {56'd0, r_count} + 64'd1;
    assign read_match = read_chunk_data[read_lane*64 +: 64] === expected_rdata;

    ddr3_native_demo demo (
        .clk(ui_clk), .rst_n(native_resetn), .init_calib_complete(calib_done),
        .done(done), .pass(pass), .error_count(error_count),
        .app_addr(app_addr), .app_cmd(app_cmd), .app_en(app_en), .app_rdy(app_rdy),
        .app_wdf_data(app_wdf_data), .app_wdf_mask(app_wdf_mask),
        .app_wdf_wren(app_wdf_wren), .app_wdf_end(app_wdf_end),
        .app_wdf_rdy(app_wdf_rdy), .app_rd_data(app_rd_data),
        .app_rd_data_valid(app_rd_data_valid), .app_rd_data_end(app_rd_data_end)
    );

    native_ddr3_bfm mig (
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
        .dbg_clk(), .dbg_bus(), .c0_ddr3_app_addr(app_addr),
        .c0_ddr3_app_cmd(app_cmd), .c0_ddr3_app_en(app_en),
        .c0_ddr3_app_hi_pri(1'b0), .c0_ddr3_app_rdy(app_rdy),
        .c0_ddr3_app_wdf_data(app_wdf_data), .c0_ddr3_app_wdf_end(app_wdf_end),
        .c0_ddr3_app_wdf_mask(app_wdf_mask), .c0_ddr3_app_wdf_wren(app_wdf_wren),
        .c0_ddr3_app_wdf_rdy(app_wdf_rdy), .c0_ddr3_app_rd_data(app_rd_data),
        .c0_ddr3_app_rd_data_end(app_rd_data_end),
        .c0_ddr3_app_rd_data_valid(app_rd_data_valid)
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

    always @(posedge ui_clk) begin
        if (!native_resetn) begin
            write_cmd_count <= 8'd0;
            read_cmd_count <= 8'd0;
            read_chunk_count <= 8'd0;
            w_count <= 8'd0;
            r_count <= 8'd0;
            write_lane <= 2'd0;
            read_lane <= 2'd0;
            write_chunk_data <= 256'd0;
            read_chunk_data <= 256'd0;
            write_word_number <= 8'd0;
            write_word_data <= 64'd0;
            read_word_number <= 8'd0;
            read_word_data <= 64'd0;
            read_word_expected <= 64'd0;
            read_word_ok <= 1'b0;
        end else begin
            if (write_fire) begin
                if (!calib_done || write_cmd_count >= 16 ||
                    app_addr !== ({19'd0, write_cmd_count} << 3) ||
                    app_wdf_mask !== 32'd0 || app_wdf_end !== 1'b1 ||
                    w_count != write_cmd_count * 4)
                    $fatal(1, "Native write command error: count=%0d addr=%h", write_cmd_count, app_addr);
                write_chunk_data <= app_wdf_data;
                write_cmd_count <= write_cmd_count + 8'd1;
            end
            if (write_word_fire) begin
                write_word_number <= w_count + 8'd1;
                write_word_data <= write_chunk_data[write_lane*64 +: 64];
                if (w_count >= 64 || write_chunk_data[write_lane*64 +: 64] !== expected_wdata)
                    $fatal(1, "Native W error: word=%0d data=%h expected=%h", w_count,
                           write_chunk_data[write_lane*64 +: 64], expected_wdata);
                w_count <= w_count + 8'd1;
                write_lane <= write_lane + 2'd1;
            end
            if (read_cmd_fire) begin
                if (write_cmd_count != 16 || w_count != 64 || read_cmd_count >= 16 ||
                    read_cmd_count != read_chunk_count ||
                    app_addr !== ({19'd0, read_cmd_count} << 3))
                    $fatal(1, "Native read command error: count=%0d addr=%h", read_cmd_count, app_addr);
                read_cmd_count <= read_cmd_count + 8'd1;
            end
            if (read_fire) begin
                if (read_chunk_count >= 16 || read_cmd_count != read_chunk_count + 1 ||
                    r_count != read_chunk_count * 4 || app_rd_data_end !== 1'b1)
                    $fatal(1, "Native read response error: count=%0d end=%b", read_chunk_count, app_rd_data_end);
                read_chunk_data <= app_rd_data;
                read_chunk_count <= read_chunk_count + 8'd1;
            end
            if (read_word_fire) begin
                read_word_number <= r_count + 8'd1;
                read_word_data <= read_chunk_data[read_lane*64 +: 64];
                read_word_expected <= expected_rdata;
                read_word_ok <= read_match;
                if (r_count >= 64 || !read_match)
                    $fatal(1, "Native R error: word=%0d data=%h expected=%h", r_count,
                           read_chunk_data[read_lane*64 +: 64], expected_rdata);
                r_count <= r_count + 8'd1;
                read_lane <= read_lane + 2'd1;
            end
        end
    end

    initial begin
        wait (calib_done === 1'b1);
        $display("DDR3 calibration complete at %0t", $time);
        wait (done === 1'b1);
        #1;
        if (write_cmd_count != 16 || read_cmd_count != 16 || read_chunk_count != 16 ||
            w_count != 64 || r_count != 64 || pass !== 1'b1 || error_count != 0 ||
            write_word_number != 64 || write_word_data !== 64'd64 ||
            read_word_number != 64 || read_word_data !== 64'd64 ||
            read_word_expected !== 64'd64 || read_word_ok !== 1'b1)
            $fatal(1, "DDR3 Native FAIL: WC=%0d RC=%0d RD=%0d W=%0d R=%0d errors=%0d",
                   write_cmd_count, read_cmd_count, read_chunk_count, w_count, r_count, error_count);
        $display("DDR3 Native PASS: WC=16 W=64 RC=16 RD=16 R=64, 64 words verified");
        #100;
        $finish;
    end

    initial begin
        #100_000;
        if (calib_done !== 1'b1)
            $fatal(1, "DDR3 calibration timeout");
        $fatal(1, "DDR3 Native transaction timeout");
    end
endmodule
