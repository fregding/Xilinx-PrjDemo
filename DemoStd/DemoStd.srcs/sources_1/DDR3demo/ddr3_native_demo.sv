`timescale 1ns / 1ps

module ddr3_native_demo (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         init_calib_complete,
    output logic         done,
    output logic         pass,
    output logic [15:0]  error_count,
    output logic [26:0]  app_addr,
    output logic [2:0]   app_cmd,
    output logic         app_en,
    input  logic         app_rdy,
    output logic [255:0] app_wdf_data,
    output logic [31:0]  app_wdf_mask,
    output logic         app_wdf_wren,
    output logic         app_wdf_end,
    input  logic         app_wdf_rdy,
    input  logic [255:0] app_rd_data,
    input  logic         app_rd_data_valid,
    input  logic         app_rd_data_end
);
    typedef enum logic [2:0] {
        WAIT_CALIB,
        WRITE_CMD,
        WRITE_WORDS,
        READ_CMD,
        READ_DATA,
        READ_WORDS,
        FINISHED
    } state_t;

    state_t state;
    logic [3:0] chunk_index;
    logic [1:0] word_index;
    logic [255:0] expected_data;
    logic read_match;

    assign app_addr = {20'd0, chunk_index, 3'd0};
    assign app_cmd = state == READ_CMD ? 3'b001 : 3'b000;
    assign app_en = (state == WRITE_CMD && app_wdf_rdy) || state == READ_CMD;
    assign app_wdf_wren = state == WRITE_CMD && app_rdy && app_wdf_rdy;
    assign app_wdf_end = app_wdf_wren;
    assign app_wdf_mask = 32'd0;
    assign app_wdf_data = {64'(chunk_index * 4 + 4), 64'(chunk_index * 4 + 3),
                           64'(chunk_index * 4 + 2), 64'(chunk_index * 4 + 1)};
    assign expected_data = app_wdf_data;
    assign read_match = app_rd_data === expected_data && app_rd_data_end === 1'b1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= WAIT_CALIB;
            chunk_index <= 4'd0;
            word_index <= 2'd0;
            error_count <= 16'd0;
            done <= 1'b0;
            pass <= 1'b0;
        end else begin
            case (state)
                WAIT_CALIB: begin
                    if (init_calib_complete)
                        state <= WRITE_CMD;
                end
                WRITE_CMD: begin
                    if (app_en && app_rdy && app_wdf_wren && app_wdf_rdy) begin
                        word_index <= 2'd0;
                        state <= WRITE_WORDS;
                    end
                end
                WRITE_WORDS: begin
                    if (word_index == 2'd3) begin
                        if (chunk_index == 4'd15) begin
                            chunk_index <= 4'd0;
                            state <= READ_CMD;
                        end else begin
                            chunk_index <= chunk_index + 4'd1;
                            state <= WRITE_CMD;
                        end
                    end else begin
                        word_index <= word_index + 2'd1;
                    end
                end
                READ_CMD: begin
                    if (app_en && app_rdy)
                        state <= READ_DATA;
                end
                READ_DATA: begin
                    if (app_rd_data_valid) begin
                        if (!read_match)
                            error_count <= error_count + 16'd1;
                        word_index <= 2'd0;
                        state <= READ_WORDS;
                    end
                end
                READ_WORDS: begin
                    if (word_index == 2'd3) begin
                        if (chunk_index == 4'd15) begin
                            done <= 1'b1;
                            pass <= error_count == 16'd0;
                            state <= FINISHED;
                        end else begin
                            chunk_index <= chunk_index + 4'd1;
                            state <= READ_CMD;
                        end
                    end else begin
                        word_index <= word_index + 2'd1;
                    end
                end
                FINISHED: state <= FINISHED;
                default: state <= WAIT_CALIB;
            endcase
        end
    end
endmodule
