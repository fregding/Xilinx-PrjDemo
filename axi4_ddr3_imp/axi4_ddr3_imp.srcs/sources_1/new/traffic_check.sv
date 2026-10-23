//-----------------------------------------------------------------------------
// File name : traffic_check.sv
// Description : CQE Consumer 读校验模块（由 easyaxi_cons.v 迁移为 SystemVerilog）
//   - 每隔 POLL_INTERVAL 拍轮询 CQE 表（16B 一次整读）
//   - CQE[idx] VALID=1 时读取数据块[idx]，并逐字校验
//   - 校验规则：每个 32bit 字的 [3:0] 应等于 idx，[31:28] 应等于 CQE 大小码
//   相对原版变更：
//   - 删除 USER 通道（MIG S_AXI 无 USER 信号）
//   - 地址位宽 16bit -> 28bit，匹配 MIG ddr3_0
//   - 删除从未调用的 check_word 函数
//   - 去除综合不支持的 #DLY；reg/wire -> logic；状态机改用 enum
//-----------------------------------------------------------------------------
module traffic_check
    import axi_pkg::*;
#(
    parameter int         OST_DEPTH    = 16,             // outstanding 事务深度（2 的幂）
    parameter int         NUM_BLOCKS   = 15,             // 块数（idx 0 ~ NUM_BLOCKS-1）
    parameter logic [1:0] BURST_TYPE   = AXI_BURST_INCR, // burst 类型
    parameter bit         SIZE_MODE    = 0,              // 0=大小按 CQE 解码，1=固定 FIXED_SIZE
    parameter logic [7:0] FIXED_SIZE   = 8'd16           // SIZE_MODE=1 时的块字节数
)(
    input  logic                        clk,
    input  logic                        rst_n,

// 控制接口
    input  logic                        start,      // 启动（电平）
    output logic                        done,       // 全部读校验完成
    output logic                        error,      // 检测到数据不一致

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

localparam int POLL_INTERVAL = 16;  // CQE 轮询间隔（拍）

// 地址映射（与 traffic_gen 一致）
localparam logic [AXI_ADDR_W-1:0] CQE_BASE      = 'h00;  // CQE 表基址（每条目 1 字节）
localparam logic [AXI_ADDR_W-1:0] DATA_BLK_BASE = 'h10;  // 数据块基址（每块间隔 16B）

// 状态机：轮询 CQE -> 命中则读数据块 -> 校验 -> 下一个
typedef enum logic [3:0] {
    IDLE,        // 等待 start
    POLL_WAIT,   // 轮询间隔等待（16 拍）
    READ_CQE,    // 发起 CQE 表读请求（CQE_BASE 起 16B 整读）
    WAIT_CQE,    // 等待 CQE 读返回
    CHECK_CQE,   // 检查 CQE[idx] VALID 位（MISS 则回 POLL_WAIT 重试）
    READ_DATA,   // 命中，发起数据块读请求
    WAIT_DATA,   // 等待数据块读返回
    VERIFY,      // 逐字校验数据
    NEXT,        // 判断是否还有下一块
    DONE         // 全部完成
} state_t;

state_t     state_r, state_n;
logic [3:0] idx_r;          // 当前块号
logic [7:0] poll_cnt_r;     // 轮询间隔计数
logic [3:0] r_size_code_r;  // 从 CQE 读出的大小码

// 上层请求信号（axi_master_rd 的简单 req/resp 接口）
logic                        m_rd_req_en_r;
logic [AXI_ID_W      -1:0]   m_rd_req_id_r;
logic [AXI_ADDR_W    -1:0]   m_rd_req_addr_r;
logic [7:0]                  m_rd_req_size_r;   // 字节数，由 axi_master_rd 换算 size/len
logic [1:0]                  m_rd_req_burst_r;

// 读完成响应
logic                        m_rd_resp_en;
logic [AXI_ID_W      -1:0]   m_rd_resp_id;
logic [127:0]                m_rd_resp_data;    // R 拍合并后的整块数据
logic [AXI_RESP_W    -1:0]   m_rd_resp_resp;

// CQE 命中判断：128bit CQE 表中第 idx 字节的 bit0 为 VALID
logic cqe_valid;
logic cqe_invalid;  // 波形观测用：cqe_valid 取反，方便数 MISS
assign cqe_valid   = (state_r == CHECK_CQE) &&  m_rd_resp_data[(idx_r*8) +: 1];
assign cqe_invalid = (state_r == CHECK_CQE) && ~m_rd_resp_data[(idx_r*8) +: 1];

logic done_r;
logic error_r;

//--------------------------------------------------------------------------------
// 状态机
//--------------------------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        state_r       <= IDLE;
        idx_r         <= 4'd0;
        poll_cnt_r    <= 8'd0;
        r_size_code_r <= 4'd0;
    end
    else begin
        state_r <= state_n;
        if (state_r == IDLE && start) begin
            idx_r         <= 4'd0;
            poll_cnt_r    <= 8'd0;
            r_size_code_r <= 4'd0;
        end
        else if (state_r == POLL_WAIT) begin
            poll_cnt_r <= poll_cnt_r + 8'd1;
        end
        else if (state_r == CHECK_CQE) begin
            if (cqe_valid) begin
                r_size_code_r <= m_rd_resp_data[(idx_r*8)+7 -: 4];
            end
            else begin
                poll_cnt_r <= 8'd0;
            end
        end
        else if (state_r == NEXT) begin
            idx_r      <= idx_r + 4'd1;
            poll_cnt_r <= 8'd0;
        end
    end
end

always_comb begin
    state_n = state_r;
    case (state_r)
        IDLE:       if (start)                            state_n = POLL_WAIT;
        POLL_WAIT:  if (poll_cnt_r >= POLL_INTERVAL - 1)  state_n = READ_CQE;
        READ_CQE:                                         state_n = WAIT_CQE;
        WAIT_CQE:   if (m_rd_resp_en)                     state_n = CHECK_CQE;
        CHECK_CQE:  if (cqe_valid)                        state_n = READ_DATA;
                    else                                  state_n = POLL_WAIT;
        READ_DATA:                                        state_n = WAIT_DATA;
        WAIT_DATA:  if (m_rd_resp_en)                     state_n = VERIFY;
        VERIFY:                                           state_n = NEXT;
        NEXT:       if (idx_r == NUM_BLOCKS - 1)          state_n = DONE;
                    else                                  state_n = POLL_WAIT;
        DONE:       if (~start)                           state_n = IDLE;
        default:                                          state_n = IDLE;
    endcase
end

//--------------------------------------------------------------------------------
// 请求生成
//--------------------------------------------------------------------------------
// CQE 大小码 -> 实际字节数（SIZE_MODE=1 时直接用 FIXED_SIZE）
logic [4:0] r_size;
assign r_size = SIZE_MODE ? FIXED_SIZE[4:0] :
                (r_size_code_r == 4'd1)  ? 5'd1  :
                (r_size_code_r == 4'd2)  ? 5'd2  :
                (r_size_code_r == 4'd4)  ? 5'd4  :
                (r_size_code_r == 4'd8)  ? 5'd8  : 5'd16;

always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        m_rd_req_en_r    <= 1'b0;
        m_rd_req_id_r    <= '0;
        m_rd_req_addr_r  <= '0;
        m_rd_req_size_r  <= 8'h00;
        m_rd_req_burst_r <= BURST_TYPE;
    end
    else if (state_r == READ_CQE) begin
        // 整读 CQE 表：CQE_BASE 起 16B（一次取回全部 16 条目）
        m_rd_req_en_r    <= 1'b1;
        m_rd_req_id_r    <= idx_r;
        m_rd_req_addr_r  <= CQE_BASE;
        m_rd_req_size_r  <= 8'h10;
        m_rd_req_burst_r <= BURST_TYPE;
    end
    else if (state_r == READ_DATA) begin
        // 读数据块[idx]：DATA_BLK_BASE + idx*16，大小按 CQE 解码
        m_rd_req_en_r    <= 1'b1;
        m_rd_req_id_r    <= idx_r;
        m_rd_req_addr_r  <= DATA_BLK_BASE + AXI_ADDR_W'({idx_r, 4'h0});
        m_rd_req_size_r  <= {3'b000, r_size};
        m_rd_req_burst_r <= BURST_TYPE;
    end
    else begin
        m_rd_req_en_r    <= 1'b0;
    end
end

//--------------------------------------------------------------------------------
// 数据校验
//--------------------------------------------------------------------------------
// 每个 32bit 字：[3:0] 应等于 idx，[31:28] 应等于 CQE 大小码
// 只检查 wstrb 实际写入的字节（按 r_size 覆盖的 32bit 字）
always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        error_r <= 1'b0;
    end
    else if (state_r == IDLE && start) begin
        error_r <= 1'b0;
    end
    else if (state_r == VERIFY) begin
        if (m_rd_resp_resp != AXI_RESP_OKAY) begin
            $display("CONS ERROR [idx=%0d]: resp=%0d (expect OKAY=%0d)", idx_r, m_rd_resp_resp, AXI_RESP_OKAY);
            error_r <= 1'b1;
        end
        else begin
            if (r_size >= 5'd1 && m_rd_resp_data[3:0] !== idx_r) begin
                $display("CONS ERROR [idx=%0d, size=%0d]: byte0[3:0]=%0d (expect %0d)", idx_r, r_size, m_rd_resp_data[3:0], idx_r);
                error_r <= 1'b1;
            end
            if (r_size >= 5'd4 && m_rd_resp_data[31:28] !== r_size_code_r) begin
                $display("CONS ERROR [idx=%0d, size=%0d]: byte0[31:28]=%0d (expect SIZE=%0d)", idx_r, r_size, m_rd_resp_data[31:28], r_size_code_r);
                error_r <= 1'b1;
            end
            if (r_size >= 5'd5 && m_rd_resp_data[35:32] !== idx_r) begin
                $display("CONS ERROR [idx=%0d, size=%0d]: byte4[3:0]=%0d (expect %0d)", idx_r, r_size, m_rd_resp_data[35:32], idx_r);
                error_r <= 1'b1;
            end
            if (r_size >= 5'd8 && m_rd_resp_data[63:60] !== r_size_code_r) begin
                $display("CONS ERROR [idx=%0d, size=%0d]: byte4[31:28]=%0d (expect SIZE=%0d)", idx_r, r_size, m_rd_resp_data[63:60], r_size_code_r);
                error_r <= 1'b1;
            end
            if (r_size >= 5'd9 && m_rd_resp_data[67:64] !== idx_r) begin
                $display("CONS ERROR [idx=%0d, size=%0d]: byte8[3:0]=%0d (expect %0d)", idx_r, r_size, m_rd_resp_data[67:64], idx_r);
                error_r <= 1'b1;
            end
            if (r_size >= 5'd12 && m_rd_resp_data[95:92] !== r_size_code_r) begin
                $display("CONS ERROR [idx=%0d, size=%0d]: byte8[31:28]=%0d (expect SIZE=%0d)", idx_r, r_size, m_rd_resp_data[95:92], r_size_code_r);
                error_r <= 1'b1;
            end
            if (r_size >= 5'd13 && m_rd_resp_data[99:96] !== idx_r) begin
                $display("CONS ERROR [idx=%0d, size=%0d]: byte12[3:0]=%0d (expect %0d)", idx_r, r_size, m_rd_resp_data[99:96], idx_r);
                error_r <= 1'b1;
            end
            if (r_size >= 5'd16 && m_rd_resp_data[127:124] !== r_size_code_r) begin
                $display("CONS ERROR [idx=%0d, size=%0d]: byte12[31:28]=%0d (expect SIZE=%0d)", idx_r, r_size, m_rd_resp_data[127:124], r_size_code_r);
                error_r <= 1'b1;
            end
        end
    end
end

// done：DONE 状态置位，start 撤下后清零
always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        done_r <= 1'b0;
    end
    else if (state_r == DONE) begin
        done_r <= 1'b1;
    end
    else if (~start) begin
        done_r <= 1'b0;
    end
end

assign done  = done_r;
assign error = error_r;

//--------------------------------------------------------------------------------
// 读通道主控（内部管理 AR/R 握手、拍收集与 outstanding）
//--------------------------------------------------------------------------------
axi_master_rd #(
    .OST_DEPTH    (OST_DEPTH),
    .LOCAL_DATA_W (128      )
) u_axi_master_rd (
    .clk             (clk             ),
    .rst_n           (rst_n           ),

    .m_rd_req_en     (m_rd_req_en_r   ),
    .m_rd_req_id     (m_rd_req_id_r   ),
    .m_rd_req_addr   (m_rd_req_addr_r ),
    .m_rd_req_size   (m_rd_req_size_r ),
    .m_rd_req_burst  (m_rd_req_burst_r),

    .m_rd_resp_en    (m_rd_resp_en    ),
    .m_rd_resp_id    (m_rd_resp_id    ),
    .m_rd_resp_data  (m_rd_resp_data  ),
    .m_rd_resp_resp  (m_rd_resp_resp  ),

    .axi_mst_arvalid (axi_mst_arvalid ),
    .axi_mst_arready (axi_mst_arready ),
    .axi_mst_arid    (axi_mst_arid    ),
    .axi_mst_araddr  (axi_mst_araddr  ),
    .axi_mst_arlen   (axi_mst_arlen   ),
    .axi_mst_arsize  (axi_mst_arsize  ),
    .axi_mst_arburst (axi_mst_arburst ),

    .axi_mst_rvalid  (axi_mst_rvalid  ),
    .axi_mst_rready  (axi_mst_rready  ),
    .axi_mst_rid     (axi_mst_rid     ),
    .axi_mst_rdata   (axi_mst_rdata   ),
    .axi_mst_rresp   (axi_mst_rresp   ),
    .axi_mst_rlast   (axi_mst_rlast   )
);

endmodule
