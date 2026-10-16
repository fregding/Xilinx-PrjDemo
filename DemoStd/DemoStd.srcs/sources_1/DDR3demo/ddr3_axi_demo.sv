`timescale 1ns / 1ps

module ddr3_axi_demo (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        init_calib_complete,
    output logic        done,
    output logic        pass,
    output logic [15:0] error_count,
    output logic [3:0]  awid,
    output logic [29:0] awaddr,
    output logic [7:0]  awlen,
    output logic [2:0]  awsize,
    output logic [1:0]  awburst,
    output logic        awlock,
    output logic [3:0]  awcache,
    output logic [2:0]  awprot,
    output logic [3:0]  awqos,
    output logic        awvalid,
    input  logic        awready,
    output logic [63:0] wdata,
    output logic [7:0]  wstrb,
    output logic        wlast,
    output logic        wvalid,
    input  logic        wready,
    input  logic [3:0]  bid,
    input  logic [1:0]  bresp,
    input  logic        bvalid,
    output logic        bready,
    output logic [3:0]  arid,
    output logic [29:0] araddr,
    output logic [7:0]  arlen,
    output logic [2:0]  arsize,
    output logic [1:0]  arburst,
    output logic        arlock,
    output logic [3:0]  arcache,
    output logic [2:0]  arprot,
    output logic [3:0]  arqos,
    output logic        arvalid,
    input  logic        arready,
    input  logic [3:0]  rid,
    input  logic [63:0] rdata,
    input  logic [1:0]  rresp,
    input  logic        rlast,
    input  logic        rvalid,
    output logic        rready
);
    // 等待校准后写入 8 个突发，再逐突发读回校验
    typedef enum logic [2:0] {
        WAIT_CALIB,
        WRITE_ADDR,
        WRITE_DATA,
        WRITE_RESP,
        READ_ADDR,
        READ_DATA,
        FINISHED
    } state_t;

    state_t state;
    logic [2:0] burst_index;
    logic [2:0] beat_index;
    logic [63:0] expected_data;

    // 每个突发包含 8 个 64 位数据拍，地址按突发递增
    assign awid    = 4'd0;
    assign awaddr  = {21'd0, burst_index, 6'd0};
    assign awlen   = 8'd7;
    assign awsize  = 3'd3;
    assign awburst = 2'b01;
    assign awlock  = 1'b0;
    assign awcache = 4'b0011;
    assign awprot  = 3'd0;
    assign awqos   = 4'd0;
    assign awvalid = state == WRITE_ADDR;

    // 写入数据由突发号和拍号生成，读回时使用同一规则比对
    assign expected_data = {58'd0, burst_index, beat_index} + 64'd1;
    assign wdata  = expected_data;
    assign wstrb  = 8'hff;
    assign wlast  = beat_index == 3'd7;
    assign wvalid = state == WRITE_DATA;
    assign bready = state == WRITE_RESP;

    assign arid    = 4'd0;
    assign araddr  = {21'd0, burst_index, 6'd0};
    assign arlen   = 8'd7;
    assign arsize  = 3'd3;
    assign arburst = 2'b01;
    assign arlock  = 1'b0;
    assign arcache = 4'b0011;
    assign arprot  = 3'd0;
    assign arqos   = 4'd0;
    assign arvalid = state == READ_ADDR;
    assign rready  = state == READ_DATA;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= WAIT_CALIB;
            burst_index <= 3'd0;
            beat_index  <= 3'd0;
            error_count <= 16'd0;
            done        <= 1'b0;
            pass        <= 1'b0;
        end else begin
            case (state)
                WAIT_CALIB: begin
                    if (init_calib_complete)
                        state <= WRITE_ADDR;
                end
                WRITE_ADDR: begin
                    if (awvalid && awready) begin
                        beat_index <= 3'd0;
                        state <= WRITE_DATA;
                    end
                end
                WRITE_DATA: begin
                    if (wvalid && wready) begin
                        if (beat_index == 3'd7)
                            state <= WRITE_RESP;
                        else
                            beat_index <= beat_index + 3'd1;
                    end
                end
                WRITE_RESP: begin
                    if (bvalid && bready) begin
                        // 写响应 ID 或状态异常时记录错误
                        if (bid != 4'd0 || bresp != 2'b00)
                            error_count <= error_count + 16'd1;
                        if (burst_index == 3'd7) begin
                            burst_index <= 3'd0;
                            state <= READ_ADDR;
                        end else begin
                            burst_index <= burst_index + 3'd1;
                            state <= WRITE_ADDR;
                        end
                    end
                end
                READ_ADDR: begin
                    if (arvalid && arready) begin
                        beat_index <= 3'd0;
                        state <= READ_DATA;
                    end
                end
                READ_DATA: begin
                    if (rvalid && rready) begin
                        // 同时检查读响应、数据内容及突发末拍标志
                        if (rid != 4'd0 || rresp != 2'b00 || rdata != expected_data ||
                            rlast != (beat_index == 3'd7))
                            error_count <= error_count + 16'd1;
                        if (beat_index == 3'd7) begin
                            if (burst_index == 3'd7) begin
                                done <= 1'b1;
                                pass <= error_count == 16'd0 && rid == 4'd0 &&
                                        rresp == 2'b00 && rdata == expected_data && rlast;
                                state <= FINISHED;
                            end else begin
                                burst_index <= burst_index + 3'd1;
                                state <= READ_ADDR;
                            end
                        end else begin
                            beat_index <= beat_index + 3'd1;
                        end
                    end
                end
                FINISHED: begin
                    state <= FINISHED;
                end
                default: begin
                    state <= WAIT_CALIB;
                end
            endcase
        end
    end
endmodule
