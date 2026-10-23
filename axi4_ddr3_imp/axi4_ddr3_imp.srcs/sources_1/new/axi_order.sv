//-----------------------------------------------------------------------------
// File name : axi_order.sv
// Description : AXI 事务保序控制器（由 easyaxi_order.v 迁移为 SystemVerilog）
//   - 每个 ID 一个 FIFO，按请求顺序保存 outstanding 指针
//   - pop（带 last）时释放该 ID 队头指针
//   - order_ptr 输出 pop_id 对应队头指针；order_bits 为全部 outstanding 位图
//-----------------------------------------------------------------------------
module axi_order #(
    parameter int OST_DEPTH = 16,
    parameter int ID_WIDTH  = 4
)(
    input  logic                         clk,
    input  logic                         rst_n,

    input  logic                         push,
    input  logic [ID_WIDTH-1:0]          push_id,
    input  logic [$clog2(OST_DEPTH)-1:0] push_ptr,

    input  logic                         pop,
    input  logic [ID_WIDTH-1:0]          pop_id,
    input  logic                         pop_last,

    output logic [$clog2(OST_DEPTH)-1:0] order_ptr,
    output logic [OST_DEPTH-1:0]         order_bits,
    output logic                         order_empty  // pop_id 对应 FIFO 为空
);

localparam int ID_NUM    = 2**ID_WIDTH;
localparam int PTR_WIDTH = $clog2(OST_DEPTH);

logic [PTR_WIDTH-1:0] fifo_data_out [ID_NUM-1:0];
logic                 fifo_empty    [ID_NUM-1:0];
logic                 fifo_wr       [ID_NUM-1:0];
logic                 fifo_rd       [ID_NUM-1:0];
logic [PTR_WIDTH-1:0] fifo_data_in  [ID_NUM-1:0];
logic [OST_DEPTH-1:0] fifo_bitmap   [ID_NUM-1:0];

// 每 ID 例化一个 FIFO
genvar i;
generate
    for (i = 0; i < ID_NUM; i++) begin : gen_order_fifo
        sync_fifo #(
            .DATA_WIDTH(PTR_WIDTH),
            .DEPTH     (OST_DEPTH)
        ) u_sync_fifo (
            .clk     (clk             ),
            .rst_n   (rst_n           ),
            .wr      (fifo_wr      [i]),
            .rd      (fifo_rd      [i]),
            .data_in (fifo_data_in [i]),
            .data_out(fifo_data_out[i]),
            .empty   (fifo_empty   [i]),
            .full    (              )
        );
    end
endgenerate

// 请求时 push，最后一拍响应时 pop
always_comb begin
    for (int j = 0; j < ID_NUM; j++) begin
        fifo_wr[j]      = 1'b0;
        fifo_rd[j]      = 1'b0;
        fifo_data_in[j] = '0;
    end
    if (push) begin
        fifo_wr[push_id]      = 1'b1;
        fifo_data_in[push_id] = push_ptr;
    end
    if (pop && ~fifo_empty[pop_id] && pop_last) begin
        fifo_rd[pop_id] = 1'b1;
    end
end

always_comb begin
    order_ptr   = fifo_data_out[pop_id];
    order_empty = fifo_empty[pop_id];
end

// 每 FIFO 队头指针转 onehot 位图
generate
    for (i = 0; i < ID_NUM; i++) begin : gen_fifo_bitmap
        assign fifo_bitmap[i] = fifo_empty[i] ? {OST_DEPTH{1'b0}}
                                              : (OST_DEPTH'(1) << fifo_data_out[i]);
    end
endgenerate

// 全部位图 OR 输出
always_comb begin
    order_bits = '0;
    for (int k = 0; k < ID_NUM; k++) begin
        order_bits = order_bits | fifo_bitmap[k];
    end
end

endmodule
