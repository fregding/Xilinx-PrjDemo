`timescale 1ns / 1ps

module async_fifo #(
    parameter int WIDTH = 8,
    parameter int DEPTH = 16,
    parameter int ADDR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1
) (
    input  logic                 wr_clk,
    input  logic                 rd_clk,
    input  logic                 rst,
    input  logic                 wr_en,
    input  logic [WIDTH-1:0]     wr_data,
    output logic                 full,
    input  logic                 rd_en,
    output logic [WIDTH-1:0]     rd_data,
    output logic                 empty
);
    // 指针最高位区分回绕状态；跨时钟域只同步 Gray 码以降低亚稳态风险
    localparam int PTR_WIDTH = ADDR_WIDTH + 1;
    localparam logic [PTR_WIDTH-1:0] FULL_MASK = (PTR_WIDTH'(1) << (PTR_WIDTH - 1)) |
                                                        (PTR_WIDTH'(1) << (PTR_WIDTH - 2));

    logic [WIDTH-1:0] mem [0:DEPTH-1];
    logic [PTR_WIDTH-1:0] wr_bin, wr_gray;
    logic [PTR_WIDTH-1:0] rd_bin, rd_gray;
    logic [PTR_WIDTH-1:0] rd_gray_sync1, rd_gray_sync2;
    logic [PTR_WIDTH-1:0] wr_gray_sync1, wr_gray_sync2;
    logic [PTR_WIDTH-1:0] wr_bin_next, wr_gray_next;
    logic [PTR_WIDTH-1:0] rd_bin_next, rd_gray_next;
    logic full_next, empty_next;

    function automatic logic [PTR_WIDTH-1:0] bin_to_gray(
        input logic [PTR_WIDTH-1:0] binary
    );
        return (binary >> 1) ^ binary;
    endfunction

    initial begin
        if (WIDTH < 1)
            $fatal(1, "async_fifo: WIDTH must be positive");
        if (DEPTH < 2 || (DEPTH & (DEPTH - 1)) != 0)
            $fatal(1, "async_fifo: DEPTH must be a power of two and >= 2");
        if (ADDR_WIDTH != $clog2(DEPTH))
            $fatal(1, "async_fifo: ADDR_WIDTH must equal $clog2(DEPTH)");
    end

    always_comb begin
        wr_bin_next = wr_bin + ((wr_en && !full) ? 1'b1 : 1'b0);
        wr_gray_next = bin_to_gray(wr_bin_next);
        // Gray 指针高两位翻转后相等表示写满
        full_next = (wr_gray_next == (rd_gray_sync2 ^ FULL_MASK));

        rd_bin_next = rd_bin + ((rd_en && !empty) ? 1'b1 : 1'b0);
        rd_gray_next = bin_to_gray(rd_bin_next);
        // 读指针追上同步后的写指针时 FIFO 为空
        empty_next = (rd_gray_next == wr_gray_sync2);
    end

    // 将读指针同步到写时钟域
    always_ff @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            rd_gray_sync1 <= '0;
            rd_gray_sync2 <= '0;
        end else begin
            rd_gray_sync1 <= rd_gray;
            rd_gray_sync2 <= rd_gray_sync1;
        end
    end

    // 将写指针同步到读时钟域
    always_ff @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            wr_gray_sync1 <= '0;
            wr_gray_sync2 <= '0;
        end else begin
            wr_gray_sync1 <= wr_gray;
            wr_gray_sync2 <= wr_gray_sync1;
        end
    end

    // 写端：二进制指针寻址存储器，Gray 指针跨时钟域同步
    always_ff @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            wr_bin  <= '0;
            wr_gray <= '0;
            full    <= 1'b0;
        end else begin
            if (wr_en && !full)
                mem[wr_bin[ADDR_WIDTH-1:0]] <= wr_data;
            wr_bin  <= wr_bin_next;
            wr_gray <= wr_gray_next;
            full    <= full_next;
        end
    end

    // 读端：同步读数据，空时保持输出不变
    always_ff @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            rd_bin  <= '0;
            rd_gray <= '0;
            rd_data <= '0;
            empty   <= 1'b1;
        end else begin
            if (rd_en && !empty) begin
                rd_data <= mem[rd_bin[ADDR_WIDTH-1:0]];
                rd_bin  <= rd_bin_next;
                rd_gray <= rd_gray_next;
            end
            empty <= empty_next;
        end
    end
endmodule
