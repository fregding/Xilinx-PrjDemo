//-----------------------------------------------------------------------------
// File name : sync_fifo.sv
// Description : 同步 FIFO（由 easyaxi_fifo.v 迁移为 SystemVerilog）
//   - 数据位宽 (DATA_WIDTH) 与深度 (DEPTH) 可配
//   - 读写指针带 wrap 位，wrap 位不同且指针相同为满，指针与 wrap 均相同为空
//-----------------------------------------------------------------------------
module sync_fifo #(
    parameter int DATA_WIDTH = 4,
    parameter int DEPTH      = 16
)(
    input  logic                  clk,
    input  logic                  rst_n,

    input  logic                  wr,
    input  logic                  rd,
    input  logic [DATA_WIDTH-1:0] data_in,
    output logic [DATA_WIDTH-1:0] data_out,
    output logic                  empty,
    output logic                  full
);

localparam int PTR_WIDTH = $clog2(DEPTH);

logic [DATA_WIDTH-1:0] fifo [DEPTH-1:0];
logic [PTR_WIDTH -1:0] wr_ptr, rd_ptr;
logic                  wr_wrap, rd_wrap;

logic ptr_equal, wrap_equal;

assign ptr_equal  = (wr_ptr == rd_ptr);
assign wrap_equal = (wr_wrap == rd_wrap);

assign empty    = ptr_equal && wrap_equal;
assign full     = ptr_equal && ~wrap_equal;
assign data_out = fifo[rd_ptr];

always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        wr_ptr  <= '0;
        wr_wrap <= 1'b0;
    end
    else if (wr) begin
        if (wr_ptr == DEPTH - 1) begin
            wr_ptr  <= '0;
            wr_wrap <= ~wr_wrap;
        end
        else begin
            wr_ptr <= wr_ptr + 1'b1;
        end
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        rd_ptr  <= '0;
        rd_wrap <= 1'b0;
    end
    else if (rd) begin
        if (rd_ptr == DEPTH - 1) begin
            rd_ptr  <= '0;
            rd_wrap <= ~rd_wrap;
        end
        else begin
            rd_ptr <= rd_ptr + 1'b1;
        end
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        for (int j = 0; j < DEPTH; j++) begin
            fifo[j] <= '0;
        end
    end
    else if (wr) begin
        fifo[wr_ptr] <= data_in;
    end
end

endmodule
