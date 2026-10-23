//-----------------------------------------------------------------------------
// File name : axi_slave_mem.sv
// Description : AXI4 ??????????????????
//   ?????????????"??????"???????????? MIG ?????????????
//     - OOO_EN=1      : ??????? ID ????????? read interleaving / ????
//     - RAND_STALL=1  : ???????????????? VALID/READY ????????????
//     - ??????? FIXED / INCR / WRAP ???? burst ???????
//     - ????????????AxSIZE < ????????????????????????? lane ???
//   ?洢??MEM_BYTES ????????? MEM_BYTES-1 ?????2 ?????
//
//   ???????????? AXI4 ?淶??????
//     FIXED : ?????????
//     INCR  : ?????????????? size ??磬?????? +2^AxSIZE
//     WRAP  : ?? (AxLEN+1)<<AxSIZE ????С????
//   ??????WSTRB[k] ?????? (AxADDR ????????????) + k
//-----------------------------------------------------------------------------
`timescale 1ns / 1ps

module axi_slave_mem
    import axi_pkg::*;
#(
    parameter int  MEM_BYTES  = 8192, // ?洢??????2 ?????????
    parameter int  R_LAT      = 4,    // ??????????????????????????
    parameter int  QDEPTH     = 16,   // д????/B ??????????
    parameter int  RDEPTH     = 16    // ?? outstanding ???
)(
// Global
    input  logic                          aclk,
    input  logic                          aresetn,

// ??????????????????tb ????濪???????
    input  logic                          cfg_ooo_en,      // 1=??????? ID ?????
    input  logic                          cfg_rand_stall,  // 1=???????????
    input  logic                          cfg_demo_timing, // 1=??????????EXP1 ???????

// AXI4 Write Address Channel
    input  logic                          s_axi_awvalid,
    output logic                          s_axi_awready,
    input  logic [AXI_ID_W      -1:0]     s_axi_awid,
    input  logic [AXI_ADDR_W    -1:0]     s_axi_awaddr,
    input  logic [AXI_LEN_W     -1:0]     s_axi_awlen,
    input  logic [AXI_SIZE_W    -1:0]     s_axi_awsize,
    input  logic [AXI_BURST_W   -1:0]     s_axi_awburst,

// AXI4 Write Data Channel
    input  logic                          s_axi_wvalid,
    output logic                          s_axi_wready,
    input  logic [AXI_DATA_W    -1:0]     s_axi_wdata,
    input  logic [AXI_DATA_W/8  -1:0]     s_axi_wstrb,
    input  logic                          s_axi_wlast,

// AXI4 Write Response Channel
    output logic                          s_axi_bvalid,
    input  logic                          s_axi_bready,
    output logic [AXI_ID_W      -1:0]     s_axi_bid,
    output logic [AXI_RESP_W    -1:0]     s_axi_bresp,

// AXI4 Read Address Channel
    input  logic                          s_axi_arvalid,
    output logic                          s_axi_arready,
    input  logic [AXI_ID_W      -1:0]     s_axi_arid,
    input  logic [AXI_ADDR_W    -1:0]     s_axi_araddr,
    input  logic [AXI_LEN_W     -1:0]     s_axi_arlen,
    input  logic [AXI_SIZE_W    -1:0]     s_axi_arsize,
    input  logic [AXI_BURST_W   -1:0]     s_axi_arburst,

// AXI4 Read Data Channel
    output logic                          s_axi_rvalid,
    input  logic                          s_axi_rready,
    output logic [AXI_ID_W      -1:0]     s_axi_rid,
    output logic [AXI_DATA_W    -1:0]     s_axi_rdata,
    output logic [AXI_RESP_W    -1:0]     s_axi_rresp,
    output logic                          s_axi_rlast
);

localparam int BUS_BYTES = AXI_DATA_W / 8;               // ???????????4??
localparam int MEM_MASK  = MEM_BYTES - 1;

//--------------------------------------------------------------------------------
// ?洢??
//--------------------------------------------------------------------------------
logic [7:0] mem [0:MEM_BYTES-1];

integer mi;
initial begin
    for (mi = 0; mi < MEM_BYTES; mi = mi + 1) mem[mi] = 8'h00;
end

//--------------------------------------------------------------------------------
// ?????????????? LFSR??????????
//--------------------------------------------------------------------------------
logic [15:0] lfsr;

wire stall_aw = cfg_rand_stall && (lfsr[5:3]  == 3'b000);
wire stall_w  = cfg_rand_stall && (lfsr[8:6]  == 3'b000);
wire stall_b  = cfg_rand_stall && (lfsr[11:9] == 3'b000);
wire stall_ar = cfg_rand_stall && (lfsr[2:0]  == 3'b000);
wire stall_r  = cfg_rand_stall && (lfsr[14:12]== 3'b000);

always_ff @(posedge aclk) begin
    if (!aresetn) lfsr <= 16'hACE1;
    else          lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
end

//--------------------------------------------------------------------------------
// ??????????
//--------------------------------------------------------------------------------
function automatic logic [AXI_ADDR_W-1:0] next_addr(
    input logic [AXI_ADDR_W  -1:0] cur,
    input logic [AXI_SIZE_W  -1:0] size,
    input logic [AXI_LEN_W   -1:0] len,
    input logic [AXI_BURST_W -1:0] burst
);
    int size_bytes;
    int block;
    int lower;
    int cur_i;
    begin
        size_bytes = 1 << size;
        cur_i      = int'(cur);
        case (burst)
            AXI_BURST_FIXED: begin
                next_addr = cur;
            end
            AXI_BURST_WRAP: begin
                block     = (int'(len) + 1) << size;
                lower     = cur_i & ~(block - 1);
                next_addr = AXI_ADDR_W'(lower + ((cur_i - lower + size_bytes) % block));
            end
            default: begin  // INCR
                if ((cur_i % size_bytes) != 0)
                    next_addr = AXI_ADDR_W'(cur_i + (size_bytes - (cur_i % size_bytes)));
                else
                    next_addr = AXI_ADDR_W'(cur_i + size_bytes);
            end
        endcase
    end
endfunction

//--------------------------------------------------------------------------------
// д??????У?AW??
//--------------------------------------------------------------------------------
logic [AXI_ID_W   -1:0] awq_id    [0:QDEPTH-1];
logic [AXI_ADDR_W -1:0] awq_addr  [0:QDEPTH-1];
logic [AXI_LEN_W  -1:0] awq_len   [0:QDEPTH-1];
logic [AXI_SIZE_W -1:0] awq_size  [0:QDEPTH-1];
logic [AXI_BURST_W-1:0] awq_burst [0:QDEPTH-1];

int awq_wp, awq_rp, awq_cnt;

// W ?????
int                     w_beat;    // ??? burst ????????????
logic [AXI_ADDR_W-1:0]  w_addr_q;  // ????????????????

wire [AXI_ADDR_W-1:0] w_base  = (w_beat == 0) ? awq_addr[awq_rp] : w_addr_q;
wire [AXI_SIZE_W-1:0] w_size  = awq_size [awq_rp];
wire [AXI_LEN_W -1:0] w_len   = awq_len  [awq_rp];
wire [AXI_BURST_W-1:0] w_burst= awq_burst[awq_rp];

// B ???????
logic [AXI_ID_W-1:0] bq_id [0:QDEPTH-1];
int bq_wp, bq_rp, bq_cnt;

//--------------------------------------------------------------------------------
// ???????????
//--------------------------------------------------------------------------------
int cyc_cnt;

//--------------------------------------------------------------------------------
// 演示握手时序（EXP1 专用，模拟教材式 AXI4 波形）
//   AW/AR：VALID 先拉高保持 2 拍，READY 在第 2 拍才出现（延迟 1 拍）
//   W    ：4-beat burst 的第 2 个 beat（index=1）握手后，插入 1 拍气泡
//          让 w_ready 精准地在中间下凹一次
//   R    ：握手后 LAT=2 就出数（参考图里 AR→R 延迟明显比 AW→W 短）
//   只有 cfg_demo_timing 时才生效，不影响功能正确性
//--------------------------------------------------------------------------------
logic [1:0] aw_wait;
logic [1:0] ar_wait;

// VALID 需保持 2 拍 → aw_wait 从 0 加到 1 时（看到 VALID 后过了 1 拍）READY 才拉高
wire demo_aw_ok = (aw_wait >= 2'd1);
wire demo_ar_ok = (ar_wait >= 2'd1);

// W 通道精准气泡：跟踪 W beat index，第 1 号 beat（即第 2 拍数据）握手后，
// 下一拍让 w_ready=0（单拍气泡），其余拍都 ready
logic w_bubble_pulse;

always_ff @(posedge aclk) begin
    if (!aresetn || !cfg_demo_timing) begin
        aw_wait <= 2'd0;
        ar_wait <= 2'd0;
        w_bubble_pulse <= 1'b0;
    end else begin
        // AW 等待计数：VALID 期间累积，握手或 VALID 撤销时清零
        if (!s_axi_awvalid || (s_axi_awvalid && s_axi_awready))
            aw_wait <= 2'd0;
        else if (aw_wait != 2'd1)
            aw_wait <= aw_wait + 2'd1;

        // AR 同理
        if (!s_axi_arvalid || (s_axi_arvalid && s_axi_arready))
            ar_wait <= 2'd0;
        else if (ar_wait != 2'd1)
            ar_wait <= ar_wait + 2'd1;

        // W 气泡：第 1 号 beat（index 1）握手后，下一拍产生单拍气泡
        // 用 w_beat==1 且本次握手不是 WLAST 来判断
        if (s_axi_wvalid && s_axi_wready && w_beat == 1 && !s_axi_wlast)
            w_bubble_pulse <= 1'b1;
        else
            w_bubble_pulse <= 1'b0;
    end
end

wire demo_w_ok = !w_bubble_pulse;

//--------------------------------------------------------------------------------
// ????
//--------------------------------------------------------------------------------
assign s_axi_awready = aresetn && (awq_cnt < QDEPTH) && !stall_aw
                       && (!cfg_demo_timing || demo_aw_ok);
assign s_axi_wready  = aresetn && (awq_cnt > 0)       && !stall_w
                       && (!cfg_demo_timing || demo_w_ok);
assign s_axi_bvalid  = aresetn && (bq_cnt  > 0)       && !stall_b;
assign s_axi_bid     = bq_id[bq_rp];
assign s_axi_bresp   = AXI_RESP_OKAY;

wire aw_hs   = s_axi_awvalid && s_axi_awready;
wire w_hs    = s_axi_wvalid  && s_axi_wready;
wire w_done  = w_hs && s_axi_wlast;
wire b_hs    = s_axi_bvalid  && s_axi_bready;

//--------------------------------------------------------------------------------
// AW / W / B ???
//--------------------------------------------------------------------------------
always_ff @(posedge aclk) begin
    if (!aresetn) begin
        awq_wp   <= 0;
        awq_rp   <= 0;
        awq_cnt  <= 0;
        w_beat   <= 0;
        w_addr_q <= '0;
    end else begin
        // ---- AW ??? ----
        if (aw_hs) begin
            awq_id   [awq_wp] <= s_axi_awid;
            awq_addr [awq_wp] <= s_axi_awaddr;
            awq_len  [awq_wp] <= s_axi_awlen;
            awq_size [awq_wp] <= s_axi_awsize;
            awq_burst[awq_wp] <= s_axi_awburst;
            awq_wp            <= (awq_wp == QDEPTH-1) ? 0 : awq_wp + 1;
        end
        // ---- ???м??? ----
        awq_cnt <= awq_cnt + (aw_hs ? 1 : 0) - (w_done ? 1 : 0);

        // ---- W ??????? burst ----
        if (w_done) begin
            awq_rp <= (awq_rp == QDEPTH-1) ? 0 : awq_rp + 1;
            w_beat <= 0;
        end

        // ---- W ????? ----
        if (w_hs && !s_axi_wlast) begin
            w_beat   <= w_beat + 1;
            w_addr_q <= next_addr(w_base, w_size, w_len, w_burst);
        end
    end
end

//--------------------------------------------------------------------------------
// ???д??WSTRB ??????????????? lane??
//--------------------------------------------------------------------------------
always_ff @(posedge aclk) begin
    if (w_hs) begin
        for (int k = 0; k < BUS_BYTES; k++) begin
            if (s_axi_wstrb[k]) begin
                mem[((int'(w_base) & ~(BUS_BYTES-1)) + k) & MEM_MASK] <= s_axi_wdata[k*8 +: 8];
            end
        end
    end
end

//--------------------------------------------------------------------------------
// B ?????? / ????
//--------------------------------------------------------------------------------
always_ff @(posedge aclk) begin
    if (!aresetn) begin
        bq_wp  <= 0;
        bq_rp  <= 0;
        bq_cnt <= 0;
    end else begin
        if (w_done) begin
            bq_id[bq_wp] <= awq_id[awq_rp];
            bq_wp        <= (bq_wp == QDEPTH-1) ? 0 : bq_wp + 1;
        end
        bq_cnt <= bq_cnt + (w_done ? 1 : 0) - (b_hs ? 1 : 0);
        if (b_hs) bq_rp <= (bq_rp == QDEPTH-1) ? 0 : bq_rp + 1;
    end
end

//--------------------------------------------------------------------------------
// ????????AR??
//--------------------------------------------------------------------------------
logic [RDEPTH-1:0]      arq_pend;
logic [AXI_ID_W   -1:0] arq_id   [0:RDEPTH-1];
logic [AXI_ADDR_W -1:0] arq_addr [0:RDEPTH-1];
logic [AXI_LEN_W  -1:0] arq_len  [0:RDEPTH-1];
logic [AXI_SIZE_W -1:0] arq_size [0:RDEPTH-1];
logic [AXI_BURST_W-1:0] arq_burst[0:RDEPTH-1];
int                     arq_rem  [0:RDEPTH-1]; // ???????
int                     arq_cyc  [0:RDEPTH-1]; // ????????????????
int                     arq_seq  [0:RDEPTH-1]; // ?????????

int seq_cnt;   // AR ???????

int ar_free;

always_comb begin
    ar_free = -1;
    for (int i = RDEPTH-1; i >= 0; i--)
        if (!arq_pend[i]) ar_free = i;
end

assign s_axi_arready = aresetn && (ar_free >= 0) && !stall_ar
                       && (!cfg_demo_timing || demo_ar_ok);

wire ar_hs = s_axi_arvalid && s_axi_arready;

// ? ID ???и??????? ?? ?????????????AXI4 ? ID ?????????
function automatic bit has_older_same(input int idx);
    bit found;
    begin
        found = 1'b0;
        for (int j = 0; j < RDEPTH; j++) begin
            if (arq_pend[j] && (arq_id[j] == arq_id[idx]) && (arq_seq[j] < arq_seq[idx]))
                found = 1'b1;
        end
        has_older_same = found;
    end
endfunction

//--------------------------------------------------------------------------------
// ?????????????
//--------------------------------------------------------------------------------
int r_sel;     // ??е???-1 ?????
int r_idx;     // ?????????r_sel<0 ?? 0??
int r_best_cyc;
int r_best_seq;

always_comb begin
    r_sel      = -1;
    r_best_cyc = 32'h7FFF_FFFF;
    r_best_seq = 32'h7FFF_FFFF;

    for (int i = RDEPTH-1; i >= 0; i--) begin
        if (arq_pend[i] && (arq_cyc[i] <= cyc_cnt) && !has_older_same(i)) begin
            if (cfg_ooo_en) begin
                // ???????絽????????????????????????????
                if ((arq_cyc[i] < r_best_cyc) ||
                    ((arq_cyc[i] == r_best_cyc) && (arq_seq[i] < r_best_seq))) begin
                    r_best_cyc = arq_cyc[i];
                    r_best_seq = arq_seq[i];
                    r_sel      = i;
                end
            end else begin
                // ?????????????
                if (arq_seq[i] < r_best_seq) begin
                    r_best_cyc = arq_cyc[i];
                    r_best_seq = arq_seq[i];
                    r_sel      = i;
                end
            end
        end
    end

    r_idx = (r_sel >= 0) ? r_sel : 0;
end

// R ????????????????????? lane ???Ч????
logic [AXI_ADDR_W-1:0] r_cur;
logic [AXI_DATA_W-1:0] r_data_v;
int                    r_off;

always_comb begin
    r_cur = arq_addr[r_idx];
    r_off = (int'(r_cur) & MEM_MASK) & ~(BUS_BYTES-1);
    for (int k = 0; k < BUS_BYTES; k++)
        r_data_v[k*8 +: 8] = mem[(r_off + k) & MEM_MASK];
end

assign s_axi_rvalid = aresetn && (r_sel >= 0);
assign s_axi_rid    = arq_id[r_idx];
assign s_axi_rdata  = r_data_v;
assign s_axi_rresp  = AXI_RESP_OKAY;
assign s_axi_rlast  = (r_sel >= 0) && (arq_rem[r_idx] == 1);

wire r_hs = s_axi_rvalid && s_axi_rready;

//--------------------------------------------------------------------------------
// AR ??? / R ???? / ???????
//--------------------------------------------------------------------------------
always_ff @(posedge aclk) begin
    if (!aresetn) begin
        arq_pend <= '0;
        cyc_cnt  <= 0;
        seq_cnt  <= 0;
    end else begin
        cyc_cnt <= cyc_cnt + 1;

        if (ar_hs) begin
            arq_pend [ar_free] <= 1'b1;
            arq_id   [ar_free] <= s_axi_arid;
            arq_addr [ar_free] <= s_axi_araddr;
            arq_len  [ar_free] <= s_axi_arlen;
            arq_size [ar_free] <= s_axi_arsize;
            arq_burst[ar_free] <= s_axi_arburst;
            arq_rem  [ar_free] <= int'(s_axi_arlen) + 1;
            // ????????ID ?????緵?????????????????У?
            arq_cyc  [ar_free] <= cyc_cnt + (cfg_demo_timing ? 2 : R_LAT) +
                                  (cfg_ooo_en ? ((1 << AXI_ID_W) - 1 - int'(s_axi_arid)) * 4 : 0);
            arq_seq  [ar_free] <= seq_cnt;
            seq_cnt            <= seq_cnt + 1;
        end

        if (r_hs) begin
            if (arq_rem[r_sel] == 1) begin
                arq_pend[r_sel] <= 1'b0;
            end else begin
                arq_rem [r_sel] <= arq_rem[r_sel] - 1;
                arq_addr[r_sel] <= next_addr(arq_addr[r_sel], arq_size[r_sel],
                                             arq_len [r_sel], arq_burst[r_sel]);
            end
        end
    end
end

endmodule : axi_slave_mem
