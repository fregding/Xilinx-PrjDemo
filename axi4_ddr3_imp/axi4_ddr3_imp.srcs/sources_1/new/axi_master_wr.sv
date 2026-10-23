//-----------------------------------------------------------------------------
// File name : axi_master_wr.sv
// Description : AXI4 写通道主控制器（由 easyaxi_mst_wr_ctrl.v 迁移为 SystemVerilog）
//   - 支持 outstanding 事务（深度由 OST_DEPTH 配置，2 的幂）
//   - 上层以字节数发起请求，内部自动换算为 AxSIZE/AxLEN
//   - 本地数据块（LOCAL_DATA_W bit）自动拆分为 AXI_DATA_W bit 的 burst 拍
//   相对原版变更：
//   - 删除 USER 通道（MIG S_AXI 无 USER 信号）
//   - 删除从未驱动的死信号（burst 地址计算、wrap 跟踪、数据可得计数等）
//   - 去除综合不支持的 #DLY；reg/wire -> logic；always -> always_ff/always_comb
//-----------------------------------------------------------------------------
module axi_master_wr
    import axi_pkg::*;
#(
    parameter int OST_DEPTH    = 16,  // outstanding 事务深度（2 的幂）
    parameter int LOCAL_DATA_W = 512  // 上层本地数据位宽
)(
// Global
    input  logic                        clk,
    input  logic                        rst_n,

// Master Request Interface
    input  logic                        m_wr_req_en,
    input  logic [AXI_ID_W      -1:0]   m_wr_req_id,
    input  logic [AXI_ADDR_W    -1:0]   m_wr_req_addr,
    input  logic [7:0]                  m_wr_req_size,   // 字节数
    input  logic [1:0]                  m_wr_req_burst,
    input  logic [LOCAL_DATA_W  -1:0]   m_wr_req_data,
    input  logic [LOCAL_DATA_W/8-1:0]   m_wr_req_strb,

// Master Response Interface
    output logic                        m_wr_resp_en,
    output logic [AXI_ID_W      -1:0]   m_wr_resp_id,
    output logic [AXI_RESP_W    -1:0]   m_wr_resp_resp,

// AXI AW Channel
    output logic                        axi_mst_awvalid,
    input  logic                        axi_mst_awready,
    output logic [AXI_ID_W      -1:0]   axi_mst_awid,
    output logic [AXI_ADDR_W    -1:0]   axi_mst_awaddr,
    output logic [AXI_LEN_W     -1:0]   axi_mst_awlen,
    output logic [AXI_SIZE_W    -1:0]   axi_mst_awsize,
    output logic [AXI_BURST_W   -1:0]   axi_mst_awburst,

// AXI W Channel
    output logic                        axi_mst_wvalid,
    input  logic                        axi_mst_wready,
    output logic [AXI_DATA_W    -1:0]   axi_mst_wdata,
    output logic [AXI_DATA_W/8  -1:0]   axi_mst_wstrb,
    output logic                        axi_mst_wlast,

// AXI B Channel
    input  logic                        axi_mst_bvalid,
    output logic                        axi_mst_bready,
    input  logic [AXI_ID_W      -1:0]   axi_mst_bid,
    input  logic [AXI_RESP_W    -1:0]   axi_mst_bresp
);

// Burst 配置
localparam int MAX_BURST_LEN = 16;  // 单事务最大 16 拍（512bit 数据）
localparam int BURST_CNT_W   = $clog2(MAX_BURST_LEN);
localparam int OST_CNT_W     = OST_DEPTH == 1 ? 1 : $clog2(OST_DEPTH);

//--------------------------------------------------------------------------------
// 内部信号
//--------------------------------------------------------------------------------
logic                     wr_buff_set;
logic                     wr_buff_clr;
logic                     wr_buff_full;
logic                     wr_buff_set_r;

// outstanding 状态标志
logic                     wr_valid_buff_r [OST_DEPTH-1:0];
logic                     wr_req_buff_r   [OST_DEPTH-1:0];
logic                     wr_dat_buff_r   [OST_DEPTH-1:0];
logic                     wr_comp_buff_r  [OST_DEPTH-1:0];
logic                     wr_clear_buff_r [OST_DEPTH-1:0];

// 状态标志的位向量视图
logic [OST_DEPTH    -1:0] wr_valid_bits;
logic [OST_DEPTH    -1:0] wr_set_bits;
logic [OST_DEPTH    -1:0] wr_req_bits;
logic [OST_DEPTH    -1:0] wr_clear_bits;

// outstanding 指针
logic [OST_CNT_W    -1:0] wr_set_ptr;
logic [OST_CNT_W    -1:0] wr_clr_ptr;
logic [OST_CNT_W    -1:0] wr_req_ptr;
logic [OST_CNT_W    -1:0] wr_data_ptr;
logic [OST_CNT_W    -1:0] wr_result_ptr;
logic [OST_CNT_W    -1:0] wr_set_ptr_r;

// AW 负载缓存
logic [AXI_ID_W     -1:0] wr_id_buff_r    [OST_DEPTH-1:0];
logic [AXI_ADDR_W   -1:0] wr_addr_buff_r  [OST_DEPTH-1:0];
logic [AXI_LEN_W    -1:0] wr_len_buff_r   [OST_DEPTH-1:0];
logic [AXI_SIZE_W   -1:0] wr_size_buff_r  [OST_DEPTH-1:0];
logic [AXI_BURST_W  -1:0] wr_burst_buff_r [OST_DEPTH-1:0];

logic [AXI_ADDR_W   -1:0] wr_addr_buff    [OST_DEPTH-1:0];
logic [AXI_LEN_W    -1:0] wr_len_buff     [OST_DEPTH-1:0];
logic [AXI_SIZE_W   -1:0] wr_size_buff    [OST_DEPTH-1:0];
logic [AXI_BURST_W  -1:0] wr_burst_buff   [OST_DEPTH-1:0];

// W 负载缓存
logic [MAX_BURST_LEN               -1:0] wr_data_vld_r  [OST_DEPTH-1:0];
logic [AXI_DATA_W*MAX_BURST_LEN    -1:0] wr_data_buff_r [OST_DEPTH-1:0];
logic [(AXI_DATA_W/8)*MAX_BURST_LEN-1:0] wr_strb_buff_r [OST_DEPTH-1:0];
logic [BURST_CNT_W                 -1:0] wr_data_cnt_r  [OST_DEPTH-1:0];
logic [AXI_RESP_W                  -1:0] wr_resp_buff_r [OST_DEPTH-1:0];

// AXI 握手
logic                   wr_req_en;
logic                   wr_data_en;
logic                   wr_data_last;
logic                   wr_result_en;

logic                   wr_data_order_empty;

//--------------------------------------------------------------------------------
// 指针管理
//--------------------------------------------------------------------------------
assign wr_set_bits = ~wr_valid_bits;

axi_arbiter #(
    .DEEP_NUM(OST_DEPTH)
) u_arb_set (
    .clk      (clk          ),
    .rst_n    (rst_n        ),
    .queue_i  (wr_set_bits  ),
    .sche_en  (wr_buff_set  ),
    .pointer_o(wr_set_ptr   )
);

always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        wr_buff_set_r <= 1'b0;
        wr_set_ptr_r  <= '0;
    end
    else begin
        wr_buff_set_r <= wr_buff_set;
        wr_set_ptr_r  <= wr_set_ptr;
    end
end

axi_arbiter #(
    .DEEP_NUM(OST_DEPTH)
) u_arb_clear (
    .clk      (clk          ),
    .rst_n    (rst_n        ),
    .queue_i  (wr_clear_bits),
    .sche_en  (wr_buff_clr  ),
    .pointer_o(wr_clr_ptr   )
);

axi_arbiter #(
    .DEEP_NUM(OST_DEPTH)
) u_arb_req (
    .clk      (clk        ),
    .rst_n    (rst_n      ),
    .queue_i  (wr_req_bits),
    .sche_en  (wr_req_en  ),
    .pointer_o(wr_req_ptr )
);

//--------------------------------------------------------------------------------
// 主控制
//--------------------------------------------------------------------------------
assign wr_buff_set = ~wr_buff_full & m_wr_req_en;
assign wr_buff_clr = wr_valid_buff_r[wr_clr_ptr] & ~wr_req_buff_r[wr_clr_ptr] & ~wr_comp_buff_r[wr_clr_ptr];

always_comb begin : MST_WR_VLD_VEC
    wr_valid_bits = {OST_DEPTH{1'b0}};
    for (int i = 0; i < OST_DEPTH; i++) begin
        wr_valid_bits[i] = wr_valid_buff_r[i];
    end
end
assign wr_buff_full = &wr_valid_bits;

always_comb begin : MST_WR_REQ_VEC
    wr_req_bits = {OST_DEPTH{1'b0}};
    for (int i = 0; i < OST_DEPTH; i++) begin
        wr_req_bits[i] = wr_req_buff_r[i];
    end
end

always_comb begin : MST_WR_CLEAR_VEC
    wr_clear_bits = {OST_DEPTH{1'b0}};
    for (int i = 0; i < OST_DEPTH; i++) begin
        wr_clear_bits[i] = wr_clear_buff_r[i];
    end
end

assign wr_req_en    = axi_mst_awvalid & axi_mst_awready;
assign wr_data_en   = axi_mst_wvalid  & axi_mst_wready;
assign wr_data_last = axi_mst_wlast;
assign wr_result_en = axi_mst_bvalid  & axi_mst_bready;

genvar gi;
generate
for (gi = 0; gi < OST_DEPTH; gi++) begin : GEN_MST_WR_CTRL
    // Valid 标志
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            wr_valid_buff_r[gi] <= 1'b0;
        end
        else if (wr_buff_set && (wr_set_ptr == gi)) begin
            wr_valid_buff_r[gi] <= 1'b1;
        end
        else if (wr_buff_clr && (wr_clr_ptr == gi)) begin
            wr_valid_buff_r[gi] <= 1'b0;
        end
    end

    // 请求已发送标志
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            wr_req_buff_r[gi] <= 1'b0;
        end
        else if (wr_buff_set && (wr_set_ptr == gi)) begin
            wr_req_buff_r[gi] <= 1'b1;
        end
        else if (wr_req_en && (wr_req_ptr == gi)) begin
            wr_req_buff_r[gi] <= 1'b0;
        end
    end

    // 数据可发送标志（缓冲内还有未发数据时保持 1）
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            wr_dat_buff_r[gi] <= 1'b0;
        end
        else begin
            if (wr_buff_set && (wr_set_ptr == gi)) begin
                wr_dat_buff_r[gi] <= 1'b1;
            end
            else if (wr_data_en && ~wr_data_last && (wr_data_ptr == gi) && wr_data_vld_r[gi][wr_data_cnt_r[gi]+1]) begin
                wr_dat_buff_r[gi] <= 1'b1;
            end
            else if (wr_data_en && (wr_data_ptr == gi)) begin
                wr_dat_buff_r[gi] <= 1'b0;
            end
        end
    end

    // 完成标志（等待 B 响应中）
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            wr_comp_buff_r[gi] <= 1'b0;
        end
        else if (wr_buff_set && (wr_set_ptr == gi)) begin
            wr_comp_buff_r[gi] <= 1'b1;
        end
        else if (wr_result_en && (wr_result_ptr == gi)) begin
            wr_comp_buff_r[gi] <= 1'b0;
        end
    end

    // 清除标志
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            wr_clear_buff_r[gi] <= 1'b0;
        end
        else begin
            wr_clear_buff_r[gi] <= wr_valid_buff_r[gi] & ~wr_req_buff_r[gi] & ~wr_comp_buff_r[gi];
        end
    end

//--------------------------------------------------------------------------------
// AW 负载缓存
//--------------------------------------------------------------------------------
    always_comb begin
        wr_addr_buff [gi] = m_wr_req_addr;
        wr_burst_buff[gi] = m_wr_req_burst;

        // 字节数 -> AxSIZE 编码（单拍字节数不得超过 AXI 总线宽度 2**AXI_BUS_SIZE）
        if (m_wr_req_size <= 8'h01) begin
            wr_size_buff[gi] = AXI_SIZE_1B;               // 1B  -> 1 拍
            wr_len_buff [gi] = 8'h0;
        end
        else if (m_wr_req_size <= 8'h02) begin
            wr_size_buff[gi] = AXI_SIZE_2B;               // 2B  -> 1 拍
            wr_len_buff [gi] = 8'h0;
        end
        else begin
            wr_size_buff[gi] = AXI_SIZE_4B;               // 按总线宽度整拍传输
            wr_len_buff [gi] = 8'((m_wr_req_size >> 2) - 8'h1);  // 4B->1 拍, 8B->2, 16B->4
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            wr_id_buff_r    [gi] <= '0;
            wr_addr_buff_r  [gi] <= '0;
            wr_len_buff_r   [gi] <= '0;
            wr_size_buff_r  [gi] <= AXI_SIZE_1B;
            wr_burst_buff_r [gi] <= AXI_BURST_INCR;
        end
        else if (wr_buff_set && (wr_set_ptr == gi)) begin
            wr_id_buff_r    [gi] <= m_wr_req_id;
            wr_addr_buff_r  [gi] <= wr_addr_buff [gi];
            wr_burst_buff_r [gi] <= wr_burst_buff[gi];
            wr_len_buff_r   [gi] <= wr_len_buff  [gi];
            wr_size_buff_r  [gi] <= wr_size_buff [gi];
        end
    end

//--------------------------------------------------------------------------------
// W 负载缓存
//--------------------------------------------------------------------------------
    // Burst 拍计数
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            wr_data_cnt_r[gi] <= '0;
        end
        else if (wr_buff_set_r && (wr_set_ptr_r == gi)) begin
            wr_data_cnt_r[gi] <= '0;
        end
        else if (wr_data_en && (wr_data_ptr == gi)) begin
            wr_data_cnt_r[gi] <= wr_data_cnt_r[gi] + 1'b1;
        end
    end

    // Burst 数据缓存
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            wr_data_vld_r [gi] <= {MAX_BURST_LEN{1'b0}};
            wr_data_buff_r[gi] <= '0;
            wr_strb_buff_r[gi] <= '0;
        end
        else if (wr_buff_set && (wr_set_ptr == gi)) begin
            wr_data_vld_r [gi] <= {MAX_BURST_LEN{1'b1}};
            wr_data_buff_r[gi] <= m_wr_req_data;  // 低 LOCAL_DATA_W bit 有效，高位自动补 0
            wr_strb_buff_r[gi] <= m_wr_req_strb;
        end
    end

//--------------------------------------------------------------------------------
// B 响应缓存（取最差响应码）
//--------------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            wr_resp_buff_r[gi] <= '0;
        end
        else if (wr_result_en && (wr_result_ptr == gi)) begin
            wr_resp_buff_r[gi] <= (axi_mst_bresp > wr_resp_buff_r[gi]) ? axi_mst_bresp
                                                                       : wr_resp_buff_r[gi];
        end
    end
end
endgenerate

//--------------------------------------------------------------------------------
// W 通道保序（数据按 AW 发出顺序消费，单 ID=0 队列）
//--------------------------------------------------------------------------------
axi_order #(
    .OST_DEPTH(OST_DEPTH),
    .ID_WIDTH (AXI_ID_W )
) u_order_data (
    .clk        (clk                              ),
    .rst_n      (rst_n                            ),

    .push       (axi_mst_awvalid & axi_mst_awready),
    .push_id    ({AXI_ID_W{1'b0}}                 ),
    .push_ptr   (wr_req_ptr                       ),

    .pop        (axi_mst_wvalid & axi_mst_wready  ),
    .pop_id     ({AXI_ID_W{1'b0}}                 ),
    .pop_last   (axi_mst_wlast                    ),

    .order_ptr  (wr_data_ptr                      ),
    .order_bits (                                 ),
    .order_empty(wr_data_order_empty              )
);

//--------------------------------------------------------------------------------
// B 响应保序（按 AWID 匹配）
//--------------------------------------------------------------------------------
axi_order #(
    .OST_DEPTH(OST_DEPTH),
    .ID_WIDTH (AXI_ID_W )
) u_order_resp (
    .clk        (clk                              ),
    .rst_n      (rst_n                            ),

    .push       (axi_mst_awvalid & axi_mst_awready),
    .push_id    (axi_mst_awid                     ),
    .push_ptr   (wr_req_ptr                       ),

    .pop        (axi_mst_bvalid & axi_mst_bready  ),
    .pop_id     (axi_mst_bid                      ),
    .pop_last   (1'b1                             ),  // bresp 只来一次

    .order_ptr  (wr_result_ptr                    ),
    .order_bits (                                 ),
    .order_empty(                                 )
);

//--------------------------------------------------------------------------------
// 输出信号
//--------------------------------------------------------------------------------
assign axi_mst_awvalid = |wr_req_bits;
assign axi_mst_awid    = wr_id_buff_r    [wr_req_ptr];
assign axi_mst_awaddr  = wr_addr_buff_r  [wr_req_ptr];
assign axi_mst_awlen   = wr_len_buff_r   [wr_req_ptr];
assign axi_mst_awsize  = wr_size_buff_r  [wr_req_ptr];
assign axi_mst_awburst = wr_burst_buff_r [wr_req_ptr];

assign axi_mst_wvalid  = ~wr_data_order_empty & wr_valid_buff_r[wr_data_ptr] & wr_dat_buff_r[wr_data_ptr];
assign axi_mst_wdata   = wr_data_buff_r[wr_data_ptr][(wr_data_cnt_r[wr_data_ptr])*AXI_DATA_W +: AXI_DATA_W];
assign axi_mst_wstrb   = wr_strb_buff_r[wr_data_ptr][(wr_data_cnt_r[wr_data_ptr])*(AXI_DATA_W/8) +: (AXI_DATA_W/8)];
assign axi_mst_wlast   = axi_mst_wvalid & (wr_data_cnt_r[wr_data_ptr] == wr_len_buff_r[wr_data_ptr]);

assign axi_mst_bready  = 1'b1;

// 上层响应：条目清除时输出
logic                        m_wr_resp_en_r;
logic [AXI_ID_W      -1:0]   m_wr_resp_id_r;
logic [AXI_RESP_W    -1:0]   m_wr_resp_resp_r;

always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        m_wr_resp_en_r   <= 1'b0;
        m_wr_resp_id_r   <= '0;
        m_wr_resp_resp_r <= '0;
    end
    else if (wr_buff_clr) begin
        m_wr_resp_en_r   <= 1'b1;
        m_wr_resp_id_r   <= wr_id_buff_r  [wr_clr_ptr];
        m_wr_resp_resp_r <= wr_resp_buff_r[wr_clr_ptr];
    end
    else begin
        m_wr_resp_en_r   <= 1'b0;
    end
end

assign m_wr_resp_en   = m_wr_resp_en_r;
assign m_wr_resp_id   = m_wr_resp_id_r;
assign m_wr_resp_resp = m_wr_resp_resp_r;

endmodule
