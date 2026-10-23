//-----------------------------------------------------------------------------
// File name : axi_master_rd.sv
// Description : AXI4 读通道主控制器（由 easyaxi_mst_rd_ctrl.v 迁移为 SystemVerilog）
//   - 支持 outstanding 事务（深度由 OST_DEPTH 配置，2 的幂）
//   - 上层以字节数发起请求，内部自动换算为 AxSIZE/AxLEN
//   - AXI_DATA_W bit 的 R 拍自动收集为本地数据块（LOCAL_DATA_W bit）
//   相对原版变更：
//   - 删除 USER 通道（MIG S_AXI 无 USER 信号）
//   - 删除从未使用的信号（rd_resp_err、MAX_REQ_NUM/REQ_CNT_W 等）
//   - 修复响应合并循环越界：LOCAL_DATA_W=128 时 beat>=4 会越界写 m_rd_resp_data_r，
//     循环上界改为 LOCAL_DATA_W/AXI_DATA_W
//   - 去除综合不支持的 #DLY；reg/wire -> logic；always -> always_ff/always_comb
//-----------------------------------------------------------------------------
module axi_master_rd
    import axi_pkg::*;
#(
    parameter int OST_DEPTH    = 16,  // outstanding 事务深度（2 的幂）
    parameter int LOCAL_DATA_W = 512  // 上层本地数据位宽
)(
// Global
    input  logic                        clk,
    input  logic                        rst_n,

// Master Request Interface
    input  logic                        m_rd_req_en,
    input  logic [AXI_ID_W      -1:0]   m_rd_req_id,
    input  logic [AXI_ADDR_W    -1:0]   m_rd_req_addr,
    input  logic [7:0]                  m_rd_req_size,   // 字节数
    input  logic [1:0]                  m_rd_req_burst,

// Master Response Interface
    output logic                        m_rd_resp_en,
    output logic [AXI_ID_W      -1:0]   m_rd_resp_id,
    output logic [LOCAL_DATA_W  -1:0]   m_rd_resp_data,
    output logic [AXI_RESP_W    -1:0]   m_rd_resp_resp,

// AXI AR Channel
    output logic                        axi_mst_arvalid,
    input  logic                        axi_mst_arready,
    output logic [AXI_ID_W      -1:0]   axi_mst_arid,
    output logic [AXI_ADDR_W    -1:0]   axi_mst_araddr,
    output logic [AXI_LEN_W     -1:0]   axi_mst_arlen,
    output logic [AXI_SIZE_W    -1:0]   axi_mst_arsize,
    output logic [AXI_BURST_W   -1:0]   axi_mst_arburst,

// AXI R Channel
    input  logic                        axi_mst_rvalid,
    output logic                        axi_mst_rready,
    input  logic [AXI_ID_W      -1:0]   axi_mst_rid,
    input  logic [AXI_DATA_W    -1:0]   axi_mst_rdata,
    input  logic [AXI_RESP_W    -1:0]   axi_mst_rresp,
    input  logic                        axi_mst_rlast
);

// Burst 配置
localparam int MAX_BURST_LEN = 16;  // 单事务最大 16 拍（512bit 数据）
localparam int BURST_CNT_W   = $clog2(MAX_BURST_LEN);
localparam int OST_CNT_W     = OST_DEPTH == 1 ? 1 : $clog2(OST_DEPTH);

//--------------------------------------------------------------------------------
// 内部信号
//--------------------------------------------------------------------------------
logic                     rd_buff_set;
logic                     rd_buff_clr;
logic                     rd_buff_full;

// outstanding 状态标志
logic                     rd_valid_buff_r [OST_DEPTH-1:0];
logic                     rd_req_buff_r   [OST_DEPTH-1:0];
logic                     rd_comp_buff_r  [OST_DEPTH-1:0];
logic                     rd_clear_buff_r [OST_DEPTH-1:0];

// 状态标志的位向量视图
logic [OST_DEPTH    -1:0] rd_valid_bits;
logic [OST_DEPTH    -1:0] rd_set_bits;
logic [OST_DEPTH    -1:0] rd_req_bits;
logic [OST_DEPTH    -1:0] rd_clear_bits;

// outstanding 指针
logic [OST_CNT_W    -1:0] rd_set_ptr;
logic [OST_CNT_W    -1:0] rd_clr_ptr;
logic [OST_CNT_W    -1:0] rd_req_ptr;
logic [OST_CNT_W    -1:0] rd_result_ptr;

// AR 负载缓存
logic [AXI_ID_W     -1:0] rd_id_buff_r    [OST_DEPTH-1:0];
logic [AXI_ADDR_W   -1:0] rd_addr_buff_r  [OST_DEPTH-1:0];
logic [AXI_LEN_W    -1:0] rd_len_buff_r   [OST_DEPTH-1:0];
logic [AXI_SIZE_W   -1:0] rd_size_buff_r  [OST_DEPTH-1:0];
logic [AXI_BURST_W  -1:0] rd_burst_buff_r [OST_DEPTH-1:0];

logic [AXI_ADDR_W   -1:0] rd_addr_buff    [OST_DEPTH-1:0];
logic [AXI_LEN_W    -1:0] rd_len_buff     [OST_DEPTH-1:0];
logic [AXI_SIZE_W   -1:0] rd_size_buff    [OST_DEPTH-1:0];
logic [AXI_BURST_W  -1:0] rd_burst_buff   [OST_DEPTH-1:0];

// R 数据缓存（每条目缓存 MAX_BURST_LEN 拍）
logic [AXI_DATA_W*MAX_BURST_LEN    -1:0] rd_data_buff_r [OST_DEPTH-1:0];
logic [BURST_CNT_W                 -1:0] rd_data_cnt_r  [OST_DEPTH-1:0];
logic [AXI_RESP_W                  -1:0] rd_resp_buff_r [OST_DEPTH-1:0];

// AXI 握手
logic                   rd_req_en;
logic                   rd_result_en;
logic                   rd_result_last;

//--------------------------------------------------------------------------------
// 指针管理
//--------------------------------------------------------------------------------
assign rd_set_bits = ~rd_valid_bits;

axi_arbiter #(
    .DEEP_NUM(OST_DEPTH)
) u_arb_set (
    .clk      (clk          ),
    .rst_n    (rst_n        ),
    .queue_i  (rd_set_bits  ),
    .sche_en  (rd_buff_set  ),
    .pointer_o(rd_set_ptr   )
);

axi_arbiter #(
    .DEEP_NUM(OST_DEPTH)
) u_arb_clear (
    .clk      (clk          ),
    .rst_n    (rst_n        ),
    .queue_i  (rd_clear_bits),
    .sche_en  (rd_buff_clr  ),
    .pointer_o(rd_clr_ptr   )
);

axi_arbiter #(
    .DEEP_NUM(OST_DEPTH)
) u_arb_req (
    .clk      (clk        ),
    .rst_n    (rst_n      ),
    .queue_i  (rd_req_bits),
    .sche_en  (rd_req_en  ),
    .pointer_o(rd_req_ptr )
);

//--------------------------------------------------------------------------------
// 主控制
//--------------------------------------------------------------------------------
assign rd_buff_set = ~rd_buff_full & m_rd_req_en;
assign rd_buff_clr = rd_valid_buff_r[rd_clr_ptr] & ~rd_req_buff_r[rd_clr_ptr] & ~rd_comp_buff_r[rd_clr_ptr];

always_comb begin : MST_RD_VLD_VEC
    rd_valid_bits = {OST_DEPTH{1'b0}};
    for (int i = 0; i < OST_DEPTH; i++) begin
        rd_valid_bits[i] = rd_valid_buff_r[i];
    end
end
assign rd_buff_full = &rd_valid_bits;

always_comb begin : MST_RD_REQ_VEC
    rd_req_bits = {OST_DEPTH{1'b0}};
    for (int i = 0; i < OST_DEPTH; i++) begin
        rd_req_bits[i] = rd_req_buff_r[i];
    end
end

always_comb begin : MST_RD_CLEAR_VEC
    rd_clear_bits = {OST_DEPTH{1'b0}};
    for (int i = 0; i < OST_DEPTH; i++) begin
        rd_clear_bits[i] = rd_clear_buff_r[i];
    end
end

assign rd_req_en      = axi_mst_arvalid & axi_mst_arready;  // AR 握手
assign rd_result_en   = axi_mst_rvalid  & axi_mst_rready;   // R 握手
assign rd_result_last = axi_mst_rlast;

genvar gi;
generate
for (gi = 0; gi < OST_DEPTH; gi++) begin : GEN_MST_RD_CTRL
    // Valid 标志
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            rd_valid_buff_r[gi] <= 1'b0;
        end
        else if (rd_buff_set && (rd_set_ptr == gi)) begin
            rd_valid_buff_r[gi] <= 1'b1;
        end
        else if (rd_buff_clr && (rd_clr_ptr == gi)) begin
            rd_valid_buff_r[gi] <= 1'b0;
        end
    end

    // 请求已发送标志
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            rd_req_buff_r[gi] <= 1'b0;
        end
        else if (rd_buff_set && (rd_set_ptr == gi)) begin
            rd_req_buff_r[gi] <= 1'b1;
        end
        else if (rd_req_en && (rd_req_ptr == gi)) begin
            rd_req_buff_r[gi] <= 1'b0;
        end
    end

    // 完成标志（等待 R 数据中）
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            rd_comp_buff_r[gi] <= 1'b0;
        end
        else if (rd_buff_set && (rd_set_ptr == gi)) begin
            rd_comp_buff_r[gi] <= 1'b1;
        end
        else if (rd_result_en && rd_result_last && (rd_result_ptr == gi)) begin
            rd_comp_buff_r[gi] <= 1'b0;
        end
    end

    // 清除标志
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            rd_clear_buff_r[gi] <= 1'b0;
        end
        else begin
            rd_clear_buff_r[gi] <= rd_valid_buff_r[gi] & ~rd_req_buff_r[gi] & ~rd_comp_buff_r[gi];
        end
    end

//--------------------------------------------------------------------------------
// AR 负载缓存
//--------------------------------------------------------------------------------
    always_comb begin
        rd_addr_buff [gi] = m_rd_req_addr;
        rd_burst_buff[gi] = m_rd_req_burst;

        // 字节数 -> AxSIZE 编码（单拍字节数不得超过 AXI 总线宽度 2**AXI_BUS_SIZE）
        if (m_rd_req_size <= 8'h01) begin
            rd_size_buff[gi] = AXI_SIZE_1B;               // 1B  -> 1 拍
            rd_len_buff [gi] = 8'h0;
        end
        else if (m_rd_req_size <= 8'h02) begin
            rd_size_buff[gi] = AXI_SIZE_2B;               // 2B  -> 1 拍
            rd_len_buff [gi] = 8'h0;
        end
        else begin
            rd_size_buff[gi] = AXI_SIZE_4B;               // 按总线宽度整拍传输
            rd_len_buff [gi] = 8'((m_rd_req_size >> 2) - 8'h1);  // 4B->1 拍, 8B->2, 16B->4
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            rd_id_buff_r    [gi] <= '0;
            rd_addr_buff_r  [gi] <= '0;
            rd_len_buff_r   [gi] <= '0;
            rd_size_buff_r  [gi] <= AXI_SIZE_1B;
            rd_burst_buff_r [gi] <= AXI_BURST_INCR;
        end
        else if (rd_buff_set && (rd_set_ptr == gi)) begin
            rd_id_buff_r    [gi] <= m_rd_req_id;
            rd_addr_buff_r  [gi] <= rd_addr_buff [gi];
            rd_burst_buff_r [gi] <= rd_burst_buff[gi];
            rd_len_buff_r   [gi] <= rd_len_buff  [gi];
            rd_size_buff_r  [gi] <= rd_size_buff [gi];
        end
    end

//--------------------------------------------------------------------------------
// R 负载缓存
//--------------------------------------------------------------------------------
    // 响应码缓存（取最差响应码）
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            rd_resp_buff_r[gi] <= '0;
        end
        else if (rd_result_en && (rd_result_ptr == gi)) begin
            rd_resp_buff_r[gi] <= (axi_mst_rresp > rd_resp_buff_r[gi]) ? axi_mst_rresp
                                                                       : rd_resp_buff_r[gi];
        end
    end

    // Burst 拍计数
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            rd_data_cnt_r[gi] <= '0;
        end
        else if (rd_buff_set && (rd_set_ptr == gi)) begin
            rd_data_cnt_r[gi] <= '0;
        end
        else if (rd_result_en && (rd_result_ptr == gi)) begin
            rd_data_cnt_r[gi] <= rd_data_cnt_r[gi] + 1'b1;
        end
    end

    // Burst 数据缓存
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            rd_data_buff_r[gi] <= '0;
        end
        else if (rd_buff_set && (rd_set_ptr == gi)) begin
            rd_data_buff_r[gi] <= '0;
        end
        else if (rd_result_en && (rd_result_ptr == gi)) begin
            rd_data_buff_r[gi][(rd_data_cnt_r[gi]*AXI_DATA_W) +: AXI_DATA_W] <= axi_mst_rdata;
        end
    end
end
endgenerate

//--------------------------------------------------------------------------------
// R 响应保序（按 ARID 匹配；数据按 AR 发出顺序返回）
//--------------------------------------------------------------------------------
axi_order #(
    .OST_DEPTH(OST_DEPTH),
    .ID_WIDTH (AXI_ID_W )
) u_order_resp (
    .clk        (clk                              ),
    .rst_n      (rst_n                            ),

    .push       (axi_mst_arvalid & axi_mst_arready),
    .push_id    (axi_mst_arid                     ),
    .push_ptr   (rd_req_ptr                       ),

    .pop        (axi_mst_rvalid & axi_mst_rready  ),
    .pop_id     (axi_mst_rid                      ),
    .pop_last   (axi_mst_rlast                    ),

    .order_ptr  (rd_result_ptr                    ),
    .order_bits (                                 ),
    .order_empty(                                 )
);

//--------------------------------------------------------------------------------
// 输出信号
//--------------------------------------------------------------------------------
assign axi_mst_arvalid = |rd_req_bits;
assign axi_mst_arid    = rd_id_buff_r    [rd_req_ptr];
assign axi_mst_araddr  = rd_addr_buff_r  [rd_req_ptr];
assign axi_mst_arlen   = rd_len_buff_r   [rd_req_ptr];
assign axi_mst_arsize  = rd_size_buff_r  [rd_req_ptr];
assign axi_mst_arburst = rd_burst_buff_r [rd_req_ptr];

assign axi_mst_rready  = 1'b1;  // 始终就绪，最大化吞吐

// 上层响应：条目清除时输出（R 拍合并为 LOCAL_DATA_W 本地数据块）
logic                        m_rd_resp_en_r;
logic [AXI_ID_W      -1:0]   m_rd_resp_id_r;
logic [LOCAL_DATA_W  -1:0]   m_rd_resp_data_r;
logic [AXI_RESP_W    -1:0]   m_rd_resp_resp_r;

always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        m_rd_resp_en_r   <= 1'b0;
        m_rd_resp_id_r   <= '0;
        m_rd_resp_data_r <= '0;
        m_rd_resp_resp_r <= '0;
    end
    else if (rd_buff_clr) begin
        m_rd_resp_en_r   <= 1'b1;
        m_rd_resp_id_r   <= rd_id_buff_r  [rd_clr_ptr];
        m_rd_resp_resp_r <= rd_resp_buff_r[rd_clr_ptr];
        // 合并 AXI 拍为本地数据块；循环上界 = LOCAL_DATA_W/AXI_DATA_W
        // （原版 beat<16 在 LOCAL_DATA_W=128 时会越界写 m_rd_resp_data_r）
        m_rd_resp_data_r <= '0;
        for (int beat = 0; beat < LOCAL_DATA_W/AXI_DATA_W; beat++) begin
            m_rd_resp_data_r[(beat*AXI_DATA_W) +: AXI_DATA_W] <=
                rd_data_buff_r[rd_clr_ptr][(beat*AXI_DATA_W) +: AXI_DATA_W];
        end
    end
    else begin
        m_rd_resp_en_r   <= 1'b0;
    end
end

assign m_rd_resp_en   = m_rd_resp_en_r;
assign m_rd_resp_id   = m_rd_resp_id_r;
assign m_rd_resp_data = m_rd_resp_data_r;
assign m_rd_resp_resp = m_rd_resp_resp_r;

endmodule
