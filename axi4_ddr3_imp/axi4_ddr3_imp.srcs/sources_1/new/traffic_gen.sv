//-----------------------------------------------------------------------------
// File name : traffic_gen.sv
// Description : CQE Producer 写流量发生器（由 easyaxi_prod.v 迁移为 SystemVerilog）
//   - 依次写 NUM_BLOCKS 个数据块，每块写完后再写对应的 CQE 通知字节
//   - 数据块[idx] 地址 = DATA_BLK_BASE + idx*16（16B 对齐），块大小按 idx%5 变化（1/2/4/8/16B）
//   - CQE[idx] 地址 = CQE_BASE + idx，1 字节 = {SIZE_CODE[3:0], 3'b000, VALID}
//   - 数据字格式 = {SIZE_CODE[3:0], BYTE_OFS[7:0], 16'h0000, IDX[3:0]}
//   - AXI ID = idx；块与块之间插入生产间隔，模拟真实 Producer 节奏
//   相对原版变更：
//   - 删除 USER 通道（MIG S_AXI 无 USER 信号）
//   - 地址位宽 16bit -> 28bit，匹配 MIG ddr3_0
//   - 修复 CQE 窄写字节通道：CQE 地址非 4B 对齐时，按 addr[1:0] 把数据字节和 wstrb
//     移到对应字节通道（AXI 规范要求 WSTRB 指示的字节通道与地址一致，否则 MIG 写错位置）
//   - 去除综合不支持的 #DLY；reg/wire -> logic；状态机改用 enum
//-----------------------------------------------------------------------------
module traffic_gen
    import axi_pkg::*;
#(
    parameter int         OST_DEPTH    = 16,             // outstanding 事务深度（2 的幂）
    parameter int         NUM_BLOCKS   = 15,             // 块数（idx 0 ~ NUM_BLOCKS-1）
    parameter logic [1:0] BURST_TYPE   = AXI_BURST_INCR, // burst 类型
    parameter bit         PROD_GAP_EN  = 1,              // 1=使能生产间隔，0=背靠背连发
    parameter bit         SIZE_MODE    = 0,              // 0=块大小按 idx 变化，1=固定 FIXED_SIZE
    parameter logic [7:0] FIXED_SIZE   = 8'd16           // SIZE_MODE=1 时的块字节数
)(
    input  logic                        clk,
    input  logic                        rst_n,

// 控制接口
    input  logic                        start,      // 启动（电平）
    output logic                        done,       // 全部写完成

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

// 地址映射
localparam logic [AXI_ADDR_W-1:0] CQE_BASE      = 'h00;  // CQE 表基址（每条目 1 字节）
localparam logic [AXI_ADDR_W-1:0] DATA_BLK_BASE = 'h10;  // 数据块基址（每块间隔 16B）

// 状态机：每个 idx 写一次数据块 + 一次 CQE，然后进入下一个 idx
typedef enum logic [3:0] {
    IDLE,        // 等待 start
    WRITE_DATA,  // 发起数据块写请求（m_wr_req_en 单拍）
    WAIT_BRESP,  // 等待数据块 B 响应
    WRITE_CQE,   // 发起 CQE 通知字节写请求
    WAIT_CQE,    // 等待 CQE B 响应
    NEXT,        // 判断是否还有下一块
    DONE,        // 全部完成
    PROD_GAP     // 生产间隔
} state_t;

state_t     state_r, state_n;
logic [3:0] idx_r;      // 当前块号
logic [7:0] gap_cnt_r;  // PROD_GAP 计数

// 生产间隔：20 + idx*18（idx 越大间隔越长，制造 Consumer 轮询 MISS）
logic [7:0] prod_interval;
assign prod_interval = PROD_GAP_EN ? 8'd20 + idx_r * 8'd18 : 8'd1;

// 上层请求信号（axi_master_wr 的简单 req/resp 接口）
logic                        m_wr_req_en_r;
logic [AXI_ID_W      -1:0]   m_wr_req_id_r;
logic [AXI_ADDR_W    -1:0]   m_wr_req_addr_r;
logic [7:0]                  m_wr_req_size_r;   // 字节数，由 axi_master_wr 换算 size/len
logic [1:0]                  m_wr_req_burst_r;
logic [127:0]                m_wr_req_data_r;   // 一次给出整块数据，控制器自动拆拍
logic [15:0]                 m_wr_req_strb_r;   // 字节选通

// 写完成响应
logic                        m_wr_resp_en;
logic [AXI_ID_W      -1:0]   m_wr_resp_id;
logic [AXI_RESP_W    -1:0]   m_wr_resp_resp;

logic cqe_written;  // 波形观测用：CQE 写完成拍
assign cqe_written = (state_r == WAIT_CQE) && m_wr_resp_en;

logic done_r;

// 生成一个数据块：每个 32bit 字 = {SIZE_CODE[3:0], BYTE_OFS[7:0], 16'h0000, IDX[3:0]}
function automatic logic [127:0] gen_block_data(
    input logic [3:0] idx,
    input logic [4:0] size,       // 块字节数
    input logic [3:0] size_code   // CQE 中记录的大小码
);
    gen_block_data = '0;
    for (int i = 0; i < size; i = i + 4) begin
        gen_block_data[(i*8)+:32] = {size_code, i[7:0], 16'h0000, idx};
    end
endfunction

//--------------------------------------------------------------------------------
// 状态机
//--------------------------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        state_r   <= IDLE;
        idx_r     <= 4'd0;
        gap_cnt_r <= 8'd0;
    end
    else begin
        state_r <= state_n;
        if (state_r == IDLE && start) begin
            idx_r     <= 4'd0;
            gap_cnt_r <= 8'd0;
        end
        else if (state_r == NEXT) begin
            idx_r     <= idx_r + 4'd1;
            gap_cnt_r <= 8'd0;
        end
        else if (state_r == PROD_GAP) begin
            gap_cnt_r <= gap_cnt_r + 8'd1;
        end
    end
end

// WRITE_DATA / WRITE_CQE 各持续 1 拍，发出单拍 m_wr_req_en 请求
always_comb begin
    state_n = state_r;
    case (state_r)
        IDLE:        if (start)                       state_n = WRITE_DATA;
        WRITE_DATA:                                   state_n = WAIT_BRESP;
        WAIT_BRESP:  if (m_wr_resp_en)                state_n = WRITE_CQE;
        WRITE_CQE:                                    state_n = WAIT_CQE;
        WAIT_CQE:    if (m_wr_resp_en)                state_n = NEXT;
        NEXT:        if (idx_r == NUM_BLOCKS - 1)     state_n = DONE;
                     else if (PROD_GAP_EN)            state_n = PROD_GAP;
                     else                             state_n = WRITE_DATA;
        PROD_GAP:    if (gap_cnt_r >= prod_interval - 1) state_n = WRITE_DATA;
        DONE:        if (~start)                      state_n = IDLE;
        default:                                      state_n = IDLE;
    endcase
end

//--------------------------------------------------------------------------------
// 请求生成
//--------------------------------------------------------------------------------
// 块大小：SIZE_MODE=0 时按 idx%5 取 1/2/4/8/16B，=1 时固定 FIXED_SIZE
logic [4:0] w_size;       // 块字节数
logic [3:0] w_size_code;  // 写入 CQE 的大小码（16 记为 15，4bit 上限）
assign w_size = SIZE_MODE ? FIXED_SIZE[4:0] :
                (idx_r % 5) == 0 ? 5'd1  :
                (idx_r % 5) == 1 ? 5'd2  :
                (idx_r % 5) == 2 ? 5'd4  :
                (idx_r % 5) == 3 ? 5'd8  : 5'd16;
assign w_size_code = SIZE_MODE ? FIXED_SIZE[3:0] :
                     (idx_r % 5) == 0 ? 4'd1  :
                     (idx_r % 5) == 1 ? 4'd2  :
                     (idx_r % 5) == 2 ? 4'd4  :
                     (idx_r % 5) == 3 ? 4'd8  : 4'd15;

always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        m_wr_req_en_r    <= 1'b0;
        m_wr_req_id_r    <= '0;
        m_wr_req_addr_r  <= '0;
        m_wr_req_size_r  <= 8'h40;
        m_wr_req_burst_r <= AXI_BURST_INCR;
        m_wr_req_data_r  <= '0;
        m_wr_req_strb_r  <= 16'h0;
    end
    else if (state_r == WRITE_DATA) begin
        // 写数据块[idx]：DATA_BLK_BASE + idx*16（16B 对齐），大小按 w_size
        m_wr_req_en_r    <= 1'b1;
        m_wr_req_id_r    <= idx_r;
        m_wr_req_addr_r  <= DATA_BLK_BASE + AXI_ADDR_W'({idx_r, 4'h0});
        m_wr_req_size_r  <= {3'b000, w_size};
        m_wr_req_burst_r <= BURST_TYPE;
        m_wr_req_data_r  <= gen_block_data(idx_r, w_size, w_size_code);
        // 选通：1B->16'h0001，2B->16'h0003，4B->16'h000F，8B->16'h00FF，16B->16'hFFFF
        case (w_size)
            5'd1:    m_wr_req_strb_r <= 16'h0001;
            5'd2:    m_wr_req_strb_r <= 16'h0003;
            5'd4:    m_wr_req_strb_r <= 16'h000F;
            5'd8:    m_wr_req_strb_r <= 16'h00FF;
            5'd16:   m_wr_req_strb_r <= 16'hFFFF;
            default: m_wr_req_strb_r <= 16'h0001;
        endcase
    end
    else if (state_r == WRITE_CQE) begin
        // 写 CQE[idx]：内容 {SIZE_CODE[3:0], 3'b000, VALID=1}
        // 地址对齐到 4B 整字（CQE_BASE + idx[3:2]*4），由 WSTRB 选出 idx[1:0] 对应的字节，
        // 避免 MIG 处理非对齐窄写
        m_wr_req_en_r    <= 1'b1;
        m_wr_req_id_r    <= idx_r;
        m_wr_req_addr_r  <= CQE_BASE + AXI_ADDR_W'({2'b00, idx_r[3:2], 2'b00});
        m_wr_req_size_r  <= 8'h04;
        m_wr_req_burst_r <= BURST_TYPE;
        m_wr_req_data_r  <= ({120'h0, w_size_code, 3'b000, 1'b1}) << (idx_r[1:0] * 8);
        m_wr_req_strb_r  <= 16'h0001 << idx_r[1:0];
    end
    else begin
        m_wr_req_en_r    <= 1'b0;
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

assign done = done_r;

//--------------------------------------------------------------------------------
// 写通道主控（内部管理 AW/W/B 握手与 outstanding）
//--------------------------------------------------------------------------------
axi_master_wr #(
    .OST_DEPTH    (OST_DEPTH),
    .LOCAL_DATA_W (128      )
) u_axi_master_wr (
    .clk             (clk             ),
    .rst_n           (rst_n           ),

    .m_wr_req_en     (m_wr_req_en_r   ),
    .m_wr_req_id     (m_wr_req_id_r   ),
    .m_wr_req_addr   (m_wr_req_addr_r ),
    .m_wr_req_size   (m_wr_req_size_r ),
    .m_wr_req_burst  (m_wr_req_burst_r),
    .m_wr_req_data   (m_wr_req_data_r ),
    .m_wr_req_strb   (m_wr_req_strb_r ),

    .m_wr_resp_en    (m_wr_resp_en    ),
    .m_wr_resp_id    (m_wr_resp_id    ),
    .m_wr_resp_resp  (m_wr_resp_resp  ),

    .axi_mst_awvalid (axi_mst_awvalid ),
    .axi_mst_awready (axi_mst_awready ),
    .axi_mst_awid    (axi_mst_awid    ),
    .axi_mst_awaddr  (axi_mst_awaddr  ),
    .axi_mst_awlen   (axi_mst_awlen   ),
    .axi_mst_awsize  (axi_mst_awsize  ),
    .axi_mst_awburst (axi_mst_awburst ),

    .axi_mst_wvalid  (axi_mst_wvalid  ),
    .axi_mst_wready  (axi_mst_wready  ),
    .axi_mst_wdata   (axi_mst_wdata   ),
    .axi_mst_wstrb   (axi_mst_wstrb   ),
    .axi_mst_wlast   (axi_mst_wlast   ),

    .axi_mst_bvalid  (axi_mst_bvalid  ),
    .axi_mst_bready  (axi_mst_bready  ),
    .axi_mst_bid     (axi_mst_bid     ),
    .axi_mst_bresp   (axi_mst_bresp   )
);

endmodule
