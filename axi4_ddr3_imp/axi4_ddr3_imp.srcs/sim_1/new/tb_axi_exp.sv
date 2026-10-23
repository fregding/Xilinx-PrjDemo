//-----------------------------------------------------------------------------
// File name : tb_axi_exp.sv
// Description : AXI4 §¿????????????FPGA???????-????????????????èö??
//   ??? plusarg ?????ï“+EXP=1..6
//     EXP1 ???????       ??? ??1  : 5 ??? VALID/READY???????????????????
//     EXP2 ???? burst     ??? ??2.1: FIXED / INCR / WRAP ??????
//     EXP3 Outstanding    ??? ??2.1: serial vs pipelined §Õ??????
//     EXP4 ?????         ??? ??2.1: ??? ARID ?? ID ??????RID ????
//     EXP5 ??? lane      ??? ??2.2: size<???????? WSTRB lane ???/???
//     EXP6 ?????         ??? ??2.2: ???????? size ????????? lane ???
//
//   ???????? [EXPn] RESULT: PASS/FAIL????????ûs?? axi_slave_mem ????????
//   axi_protocol_checker ??¡¤??§µ?î•
//-----------------------------------------------------------------------------
`timescale 1ns / 1ps

module tb_axi_exp;

import axi_pkg::*;

//--------------------------------------------------------------------------------
// ????
//--------------------------------------------------------------------------------
localparam int MEM_BYTES = 8192;
localparam int MAX_LOG   = 64;

`include "exp_cfg.svh"

localparam int EXP_ID = `AXI_EXP_ID;

// ????????????????????????????????????? EXP_ID ?§Ý???
logic                      cfg_ooo_en;
logic                      cfg_rand_stall;
logic                      cfg_demo_timing;

always_comb begin
    cfg_ooo_en      = (EXP_ID == 4);
    cfg_rand_stall  = (EXP_ID == 1);
    cfg_demo_timing = (EXP_ID == 1);   // EXP1 ??????????????????????
end

//--------------------------------------------------------------------------------
// ??? / ??¦Ë
//--------------------------------------------------------------------------------
logic aclk = 1'b0;
logic aresetn;

always #5 aclk = ~aclk;   // 100MHz

initial begin
    aresetn = 1'b0;
    repeat (8) @(posedge aclk);
    aresetn = 1'b1;
end

//--------------------------------------------------------------------------------
// ???????
//--------------------------------------------------------------------------------
logic                       m_awvalid;
logic                       m_awready;
logic [AXI_ID_W    -1:0]    m_awid;
logic [AXI_ADDR_W  -1:0]    m_awaddr;
logic [AXI_LEN_W   -1:0]    m_awlen;
logic [AXI_SIZE_W  -1:0]    m_awsize;
logic [AXI_BURST_W -1:0]    m_awburst;

logic                       m_wvalid;
logic                       m_wready;
logic [AXI_DATA_W  -1:0]    m_wdata;
logic [AXI_DATA_W/8-1:0]    m_wstrb;
logic                       m_wlast;

logic                       m_bvalid;
logic                       m_bready;
logic [AXI_ID_W    -1:0]    m_bid;
logic [AXI_RESP_W  -1:0]    m_bresp;

logic                       m_arvalid;
logic                       m_arready;
logic [AXI_ID_W    -1:0]    m_arid;
logic [AXI_ADDR_W  -1:0]    m_araddr;
logic [AXI_LEN_W   -1:0]    m_arlen;
logic [AXI_SIZE_W  -1:0]    m_arsize;
logic [AXI_BURST_W -1:0]    m_arburst;

logic                       m_rvalid;
logic                       m_rready;
logic [AXI_ID_W    -1:0]    m_rid;
logic [AXI_DATA_W  -1:0]    m_rdata;
logic [AXI_RESP_W  -1:0]    m_rresp;
logic                       m_rlast;

assign m_bready = 1'b1;
assign m_rready = 1'b1;

//--------------------------------------------------------------------------------
// DUT ???
//--------------------------------------------------------------------------------
axi_slave_mem #(
    .MEM_BYTES  (MEM_BYTES),
    .R_LAT      (4),
    .QDEPTH     (16),
    .RDEPTH     (16)
) u_slave (
    .aclk           (aclk),
    .aresetn        (aresetn),
    .cfg_ooo_en     (cfg_ooo_en),
    .cfg_rand_stall (cfg_rand_stall),
    .cfg_demo_timing(cfg_demo_timing),
    .s_axi_awvalid  (m_awvalid),
    .s_axi_awready  (m_awready),
    .s_axi_awid     (m_awid),
    .s_axi_awaddr   (m_awaddr),
    .s_axi_awlen    (m_awlen),
    .s_axi_awsize   (m_awsize),
    .s_axi_awburst  (m_awburst),
    .s_axi_wvalid   (m_wvalid),
    .s_axi_wready   (m_wready),
    .s_axi_wdata    (m_wdata),
    .s_axi_wstrb    (m_wstrb),
    .s_axi_wlast    (m_wlast),
    .s_axi_bvalid   (m_bvalid),
    .s_axi_bready   (m_bready),
    .s_axi_bid      (m_bid),
    .s_axi_bresp    (m_bresp),
    .s_axi_arvalid  (m_arvalid),
    .s_axi_arready  (m_arready),
    .s_axi_arid     (m_arid),
    .s_axi_araddr   (m_araddr),
    .s_axi_arlen    (m_arlen),
    .s_axi_arsize   (m_arsize),
    .s_axi_arburst  (m_arburst),
    .s_axi_rvalid   (m_rvalid),
    .s_axi_rready   (m_rready),
    .s_axi_rid      (m_rid),
    .s_axi_rdata    (m_rdata),
    .s_axi_rresp    (m_rresp),
    .s_axi_rlast    (m_rlast)
);

//--------------------------------------------------------------------------------
// §¿??????
//--------------------------------------------------------------------------------
int chk_err_cnt, chk_hit_cnt;

axi_protocol_checker #(.CHK_DEPTH(32)) u_chk (
    .aclk    (aclk),
    .aresetn (aresetn),
    .awvalid (m_awvalid), .awready(m_awready), .awid(m_awid),
    .awaddr  (m_awaddr),  .awlen  (m_awlen),   .awsize(m_awsize), .awburst(m_awburst),
    .wvalid  (m_wvalid),  .wready (m_wready),  .wdata (m_wdata),
    .wstrb   (m_wstrb),   .wlast  (m_wlast),
    .bvalid  (m_bvalid),  .bready (m_bready),  .bid   (m_bid),   .bresp (m_bresp),
    .arvalid (m_arvalid), .arready(m_arready), .arid  (m_arid),
    .araddr  (m_araddr),  .arlen  (m_arlen),   .arsize(m_arsize), .arburst(m_arburst),
    .rvalid  (m_rvalid),  .rready (m_rready),  .rid   (m_rid),
    .rdata   (m_rdata),   .rresp  (m_rresp),   .rlast (m_rlast),
    .err_cnt (chk_err_cnt),
    .chk_cnt (chk_hit_cnt)
);

//--------------------------------------------------------------------------------
// ?????????????????????
//--------------------------------------------------------------------------------
int cyc;
always_ff @(posedge aclk) begin
    if (!aresetn) cyc <= 0;
    else          cyc <= cyc + 1;
end

//--------------------------------------------------------------------------------
// ???????
//--------------------------------------------------------------------------------
function automatic logic [7:0] pat(input logic [AXI_ADDR_W-1:0] a);
    return a[7:0] ^ 8'h5A;
endfunction

// ?? 4 ?????????? byte0..byte3 ??? 32bit word
function automatic logic [AXI_DATA_W-1:0] pack4(
    input logic [7:0] b0, b1, b2, b3
);
    return {b3, b2, b1, b0};
endfunction

//--------------------------------------------------------------------------------
// ???? BFM ????
//--------------------------------------------------------------------------------
task automatic aw_send(
    input logic [AXI_ID_W    -1:0] id,
    input logic [AXI_ADDR_W  -1:0] addr,
    input logic [AXI_SIZE_W  -1:0] size,
    input logic [AXI_LEN_W   -1:0] len,
    input logic [AXI_BURST_W -1:0] burst
);
    m_awid    <= id;
    m_awaddr  <= addr;
    m_awsize  <= size;
    m_awlen   <= len;
    m_awburst <= burst;
    m_awvalid <= 1'b1;
    @(posedge aclk);
    while (!m_awready) @(posedge aclk);
    m_awvalid <= 1'b0;
endtask

// ??????? W??strb/data ????¡Â?????
task automatic w_send_beat(
    input logic [AXI_DATA_W  -1:0] data,
    input logic [AXI_DATA_W/8-1:0] strb,
    input logic                     last
);
    m_wdata  <= data;
    m_wstrb  <= strb;
    m_wlast  <= last;
    m_wvalid <= 1'b1;
    @(posedge aclk);
    while (!m_wready) @(posedge aclk);
    m_wvalid <= 1'b0;
    m_wlast  <= 1'b0;
endtask

task automatic b_wait(output logic [AXI_RESP_W-1:0] resp);
    while (!m_bvalid) @(posedge aclk);
    resp = m_bresp;
    @(posedge aclk);
endtask

// B ????????????m_bready=1 ??????B ??????????????????? b_wait ??????
// ??????????????????????? B ???????
int b_mon_cnt;
always_ff @(posedge aclk) begin
    if (!aresetn) b_mon_cnt <= 0;
    else if (m_bvalid && m_bready) b_mon_cnt <= b_mon_cnt + 1;
end

task automatic ar_send(
    input logic [AXI_ID_W    -1:0] id,
    input logic [AXI_ADDR_W  -1:0] addr,
    input logic [AXI_SIZE_W  -1:0] size,
    input logic [AXI_LEN_W   -1:0] len,
    input logic [AXI_BURST_W -1:0] burst
);
    m_arid    <= id;
    m_araddr  <= addr;
    m_arsize  <= size;
    m_arlen   <= len;
    m_arburst <= burst;
    m_arvalid <= 1'b1;
    @(posedge aclk);
    while (!m_arready) @(posedge aclk);
    m_arvalid <= 1'b0;
endtask

task automatic r_recv(
    output logic [AXI_ID_W    -1:0] id,
    output logic [AXI_DATA_W  -1:0] data,
    output logic                     last
);
    while (!m_rvalid) @(posedge aclk);
    id   = m_rid;
    data = m_rdata;
    last = m_rlast;
    @(posedge aclk);
endtask

//--------------------------------------------------------------------------------
// ???????????????§Õ burst
//  bytes   : ???????
//  pat_base: §Õ?????????? pat() ????
//--------------------------------------------------------------------------------
task automatic axi_write(
    input logic [AXI_ID_W    -1:0] id,
    input logic [AXI_ADDR_W  -1:0] addr,
    input int                     bytes,
    input logic [AXI_BURST_W -1:0] burst
);
    int size_b, len, beats;
    logic [AXI_SIZE_W-1:0] size_enc;
    logic [AXI_LEN_W -1:0] len_enc;
    logic [AXI_ADDR_W-1:0] cur;
    logic [AXI_DATA_W-1:0] data;
    logic [AXI_DATA_W/8-1:0] strb;

    // ???? size/len
    if      (bytes <= 1) begin size_enc = AXI_SIZE_1B; beats = bytes > 0 ? bytes : 1; end
    else if (bytes <= 2) begin size_enc = AXI_SIZE_2B; beats = (bytes + 1) >> 1;     end
    else                 begin size_enc = AXI_SIZE_4B; beats = (bytes + 3) >> 2;     end
    if (beats < 1) beats = 1;
    len_enc = beats - 1;
    size_b  = 1 << size_enc;

    aw_send(id, addr, size_enc, len_enc, burst);

    cur = addr;
    for (int b = 0; b < beats; b++) begin
        int lane0, nb;
        lane0 = int'(cur) % (AXI_DATA_W/8);
        nb    = (size_b < (AXI_DATA_W/8 - lane0)) ? size_b : (AXI_DATA_W/8 - lane0);
        strb  = '0;
        for (int k = 0; k < nb; k++) strb[lane0+k] = 1'b1;
        data  = '0;
        for (int k = 0; k < nb; k++) data[(lane0+k)*8 +: 8] = pat(cur + k);
        w_send_beat(data, strb, (b == beats-1));
        // ???
        if (burst == AXI_BURST_FIXED) cur = cur;
        else if (burst == AXI_BURST_WRAP) begin
            int block, lower, off;
            block = (int'(len_enc)+1) << size_enc;
            lower = int'(cur) & ~(block-1);
            off   = (int'(cur) - lower + size_b) % block;
            cur   = AXI_ADDR_W'(lower + off);
        end else begin
            if ((int'(cur) % size_b) != 0)
                cur = AXI_ADDR_W'(int'(cur) + (size_b - (int'(cur) % size_b)));
            else
                cur = AXI_ADDR_W'(int'(cur) + size_b);
        end
    end

    begin
        logic [AXI_RESP_W-1:0] resp;
        b_wait(resp);
    end
endtask

//--------------------------------------------------------------------------------
// EXP ??????
//--------------------------------------------------------------------------------
int exp_fail;
int exp_total;

task automatic check(input bit cond, input string msg);
    exp_total = exp_total + 1;
    if (!cond) begin
        exp_fail = exp_fail + 1;
        $display("[EXP][%0t] FAIL: %s", $time, msg);
    end
endtask

//--------------------------------------------------------------------------------
// ?????
//--------------------------------------------------------------------------------

// EXP1 ??????? ---------------------------------------------------------
task automatic exp1;
    int t_aw0, t_aw1, t_b0;
    int pipe_cnt, tot_cnt;
    logic [AXI_RESP_W-1:0] resp;
    begin
        $display("== EXP1: VALID/READY handshake & pipelining ==");
        // ???§Õ??????? checker ????????
        // ??? AW/W/B ??????????????????
        t_aw0  = cyc;  aw_send(4'h0, 28'h0000_0100, AXI_SIZE_4B, 8'd3, AXI_BURST_INCR);
        // W ?????? AW
        w_send_beat(pack4(pat(28'h100), pat(28'h101), pat(28'h102), pat(28'h103)),
                    4'b1111, 1'b0);
        w_send_beat(pack4(pat(28'h104), pat(28'h105), pat(28'h106), pat(28'h107)),
                    4'b1111, 1'b0);
        w_send_beat(pack4(pat(28'h108), pat(28'h109), pat(28'h10A), pat(28'h10B)),
                    4'b1111, 1'b0);
        w_send_beat(pack4(pat(28'h10C), pat(28'h10D), pat(28'h10E), pat(28'h10F)),
                    4'b1111, 1'b1);
        b_wait(resp);
        t_b0 = cyc;

        // ????§µ??
        ar_send(4'h0, 28'h0000_0100, AXI_SIZE_4B, 8'd3, AXI_BURST_INCR);
        begin
            logic [AXI_ID_W-1:0]   rid;
            logic [AXI_DATA_W-1:0] rd;
            logic                  rl;
            int kk;
            for (kk = 0; kk < 4; kk++) begin
                r_recv(rid, rd, rl);
                check(rd[ 7: 0] == pat(28'h100 + kk*4 + 0), "EXP1 byte0 mismatch");
                check(rd[15: 8] == pat(28'h100 + kk*4 + 1), "EXP1 byte1 mismatch");
                check(rd[23:16] == pat(28'h100 + kk*4 + 2), "EXP1 byte2 mismatch");
                check(rd[31:24] == pat(28'h100 + kk*4 + 3), "EXP1 byte3 mismatch");
                check(rl == (kk == 3), "EXP1 RLAST mismatch");
            end
        end
        $display("[EXP1] AW->B latency = %0d cyc; total handshake events = %0d",
                 t_b0 - t_aw0, chk_hit_cnt);
    end
endtask

// EXP2 ???? burst -------------------------------------------------------
task automatic exp2;
    logic [AXI_RESP_W-1:0] resp;
    int idx;
    logic [AXI_ADDR_W-1:0] exp_incr [0:3] = '{28'h100, 28'h104, 28'h108, 28'h10C};
    logic [AXI_ADDR_W-1:0] exp_fix  [0:3] = '{28'h110, 28'h110, 28'h110, 28'h110};
    logic [AXI_ADDR_W-1:0] exp_wrap [0:3] = '{28'h10C, 28'h100, 28'h104, 28'h108};
    begin
        $display("== EXP2: FIXED / INCR / WRAP burst ??????? ==");

        // INCR
        aw_send(4'h1, 28'h100, AXI_SIZE_4B, 8'd3, AXI_BURST_INCR);
        for (idx = 0; idx < 4; idx++) begin
            automatic logic [31:0] d = {pat(exp_incr[idx]+3), pat(exp_incr[idx]+2),
                                        pat(exp_incr[idx]+1), pat(exp_incr[idx]+0)};
            $display("[EXP2] INCR beat%0d addr=%h strb=1111", idx, exp_incr[idx]);
            w_send_beat(d, 4'b1111, (idx == 3));
        end
        b_wait(resp);

        // FIXED
        aw_send(4'h2, 28'h110, AXI_SIZE_4B, 8'd3, AXI_BURST_FIXED);
        for (idx = 0; idx < 4; idx++) begin
            automatic logic [31:0] d = {pat(exp_fix[idx]+3), pat(exp_fix[idx]+2),
                                        pat(exp_fix[idx]+1), pat(exp_fix[idx]+0)};
            $display("[EXP2] FIXED beat%0d addr=%h strb=1111", idx, exp_fix[idx]);
            w_send_beat(d, 4'b1111, (idx == 3));
        end
        b_wait(resp);

        // WRAP????? 0x10C?????????
        aw_send(4'h3, 28'h10C, AXI_SIZE_4B, 8'd3, AXI_BURST_WRAP);
        for (idx = 0; idx < 4; idx++) begin
            automatic logic [31:0] d = {pat(exp_wrap[idx]+3), pat(exp_wrap[idx]+2),
                                        pat(exp_wrap[idx]+1), pat(exp_wrap[idx]+0)};
            $display("[EXP2] WRAP beat%0d addr=%h strb=1111", idx, exp_wrap[idx]);
            w_send_beat(d, 4'b1111, (idx == 3));
        end
        b_wait(resp);

        // ????§µ?ï“???? 0x100 / 0x110 ????
        // INCR ????0x100..0x10F ?§Õ?? pat(0x100..0x10F)
        // WRAP ???????§Õ 0x100,0x104,0x108??exp_wrap[1..3]?????? WRAP §Õ???? INCR
        ar_send(4'h1, 28'h100, AXI_SIZE_4B, 8'd3, AXI_BURST_INCR);
        begin
            logic [AXI_ID_W-1:0]   rid;
            logic [AXI_DATA_W-1:0] rd;
            logic                  rl;
            logic [7:0] expb [0:15];
            // ????§Õ??????????
            //   addr 0x100-0x103: WRAP ?????exp_wrap[1]??
            //   addr 0x104-0x107: WRAP ?????exp_wrap[2]??
            //   addr 0x108-0x10B: WRAP ?????exp_wrap[3]??
            //   addr 0x10C-0x10F: INCR + WRAP ??????exp_wrap[0]??
            for (int i = 0; i < 16; i++) begin
                expb[i] = pat(28'h100 + i);
            end
            for (int kk = 0; kk < 4; kk++) begin
                r_recv(rid, rd, rl);
                check(rd[ 7: 0] == expb[kk*4+0], "EXP2 byte0 mismatch");
                check(rd[15: 8] == expb[kk*4+1], "EXP2 byte1 mismatch");
                check(rd[23:16] == expb[kk*4+2], "EXP2 byte2 mismatch");
                check(rd[31:24] == expb[kk*4+3], "EXP2 byte3 mismatch");
            end
        end
        $display("[EXP2] done");
    end
endtask

// EXP3 Outstanding ------------------------------------------------------
task automatic exp3;
    int t0, t1, t2;
    int serial_cyc, pipe_cyc;
    logic [AXI_RESP_W-1:0] resp;
    begin
        $display("== EXP3: Outstanding ????? ==");
        // (a) ???? 4 ??
        t0 = cyc;
        for (int k = 0; k < 4; k++) begin
            aw_send(4'h0, 28'h200 + 16*k, AXI_SIZE_4B, 8'd3, AXI_BURST_INCR);
            for (int bb = 0; bb < 4; bb++) begin
                automatic logic [AXI_ADDR_W-1:0] a = 28'h200 + 16*k + 4*bb;
                w_send_beat({pat(a+3), pat(a+2), pat(a+1), pat(a+0)},
                            4'b1111, (bb == 3));
            end
            b_wait(resp);
        end
        t1 = cyc;
        serial_cyc = t1 - t0;

        // (b) 4 ?? AW ??????????????? W??B ????? W ?????????????
        //     ??????? b_wait??B ???????? bready ???????????? B ?????????
        begin
            int b_base;
            b_base = b_mon_cnt;
            t1 = cyc;
            for (int k = 0; k < 4; k++) begin
                aw_send(4'h0, 28'h300 + 16*k, AXI_SIZE_4B, 8'd3, AXI_BURST_INCR);
            end
            for (int k = 0; k < 4; k++) begin
                for (int bb = 0; bb < 4; bb++) begin
                    automatic logic [AXI_ADDR_W-1:0] a = 28'h300 + 16*k + 4*bb;
                    w_send_beat({pat(a+3), pat(a+2), pat(a+1), pat(a+0)},
                                4'b1111, (bb == 3));
                end
            end
            wait (b_mon_cnt >= b_base + 4);
            @(posedge aclk);
            t2 = cyc;
        end
        pipe_cyc = t2 - t1;

        $display("[EXP3] serial 4 ??: %0d cyc, pipelined 4 ??: %0d cyc, speedup x%0.2f",
                 serial_cyc, pipe_cyc,
                 (pipe_cyc > 0) ? real'(serial_cyc)/real'(pipe_cyc) : 0.0);
        check(pipe_cyc <= serial_cyc, "EXP3 pipelined should be faster than serial");
    end
endtask

// EXP4 ????? -----------------------------------------------------------
task automatic exp4;
    logic [AXI_ID_W-1:0] exp_rid [0:7] = '{4'h3, 4'h3, 4'h2, 4'h2, 4'h1, 4'h1, 4'h0, 4'h0};
    logic [AXI_ADDR_W-1:0] exp_addr [0:3] = '{28'h400, 28'h410, 28'h420, 28'h430};
    logic [AXI_RESP_W-1:0] resp;
    begin
        $display("== EXP4: ?? ID ????????? ==");
        // ?????????
        for (int k = 0; k < 4; k++) begin
            aw_send(4'h0, exp_addr[k], AXI_SIZE_4B, 8'd1, AXI_BURST_INCR);
            for (int bb = 0; bb < 2; bb++) begin
                automatic logic [AXI_ADDR_W-1:0] a = exp_addr[k] + 4*bb;
                w_send_beat({pat(a+3), pat(a+2), pat(a+1), pat(a+0)},
                            4'b1111, (bb == 1));
            end
            b_wait(resp);
        end

        // 4 ?? AR????? ID??????????? ID ??????OOO_EN=1??
        for (int k = 0; k < 4; k++) begin
            ar_send(4'(k), exp_addr[k], AXI_SIZE_4B, 8'd1, AXI_BURST_INCR);
        end

        begin
            logic [AXI_ID_W-1:0]   rid;
            logic [AXI_DATA_W-1:0] rd;
            logic                  rl;
            for (int kk = 0; kk < 8; kk++) begin
                r_recv(rid, rd, rl);
                $display("[EXP4] R beat%0d: RID=%h rlast=%0d rdata=%h", kk, rid, rl, rd);
                check(rid == exp_rid[kk],
                      $sformatf("EXP4 RID[%0d] expect %h got %h", kk, exp_rid[kk], rid));
                // §µ???????beat kk/2 ???????????beat kk%2 ?????????
                begin
                    automatic int txn = kk / 2;
                    automatic int bt  = kk % 2;
                    automatic logic [AXI_ADDR_W-1:0] a = exp_addr[exp_rid[kk]]  // dummy
                                                          ; // ?¦Ë????¦Ä??Ó
                    a = exp_addr[3 - txn]; // ????exp_rid[kk] = 3-txn
                    a = a + 4*bt;
                    check(rd[ 7: 0] == pat(a+0), "EXP4 byte0");
                    check(rd[15: 8] == pat(a+1), "EXP4 byte1");
                    check(rd[23:16] == pat(a+2), "EXP4 byte2");
                    check(rd[31:24] == pat(a+3), "EXP4 byte3");
                end
            end
        end
    end
endtask

// EXP5 ??? lane --------------------------------------------------------
task automatic exp5;
    logic [AXI_RESP_W-1:0] resp;
    logic [AXI_ID_W-1:0]   rid;
    logic [AXI_DATA_W-1:0] rd;
    logic                  rl;
    begin
        $display("== EXP5: ??? (size<???????) INCR/FIXED ??? lane ==");

        // (a) INCR addr=0x200,size=1B,len=3 -> strb ? 0001/0010/0100/1000
        aw_send(4'h0, 28'h200, AXI_SIZE_1B, 8'd3, AXI_BURST_INCR);
        w_send_beat({24'h0, 3'h0, pat(28'h200)}, 4'b0001, 1'b0);
        w_send_beat({16'h0, 3'h0, pat(28'h201), 8'h00}, 4'b0010, 1'b0);
        w_send_beat({8'h00, 3'h0, pat(28'h202), 16'h0}, 4'b0100, 1'b0);
        w_send_beat({pat(28'h203), 24'h0},            4'b1000, 1'b1);
        b_wait(resp);
        $display("[EXP5] narrow INCR done: lane0->1->2->3");

        // (b) FIXED addr=0x210,size=1B,len=3 -> strb ?? 0001
        aw_send(4'h0, 28'h210, AXI_SIZE_1B, 8'd3, AXI_BURST_FIXED);
        for (int bb = 0; bb < 4; bb++) begin
            w_send_beat({24'h0, 3'h0, pat(28'h210)}, 4'b0001, (bb == 3));
        end
        b_wait(resp);
        $display("[EXP5] narrow FIXED done: lane0x4");

        // §µ?ï“0x200..0x203 = pat(0x200..0x203)??0x210 = pat(0x210)??0x211..0x213 = 0
        check(u_slave.mem[16'h200] == pat(28'h200), "EXP5 mem[0x200]");
        check(u_slave.mem[16'h201] == pat(28'h201), "EXP5 mem[0x201]");
        check(u_slave.mem[16'h202] == pat(28'h202), "EXP5 mem[0x202]");
        check(u_slave.mem[16'h203] == pat(28'h203), "EXP5 mem[0x203]");
        check(u_slave.mem[16'h210] == pat(28'h210), "EXP5 mem[0x210]");
        check(u_slave.mem[16'h211] == 8'h00,        "EXP5 mem[0x211] untouched");
        check(u_slave.mem[16'h212] == 8'h00,        "EXP5 mem[0x212] untouched");
        check(u_slave.mem[16'h213] == 8'h00,        "EXP5 mem[0x213] untouched");
    end
endtask

// EXP6 ????? -----------------------------------------------------------
task automatic exp6;
    logic [AXI_RESP_W-1:0] resp;
    begin
        $display("== EXP6: ??????????? INCR (size=4B,addr=0x307) ==");

        // addr=0x307, size=4B, len=3 -> ??????? 307, 308(A), 30C, 310; strb 1000,1111,1111,1111
        aw_send(4'h0, 28'h307, AXI_SIZE_4B, 8'd3, AXI_BURST_INCR);
        w_send_beat({pat(28'h307), 24'h0}, 4'b1000, 1'b0);  // ?? lane3
        w_send_beat({pat(28'h30B), pat(28'h30A), pat(28'h309), pat(28'h308)},
                    4'b1111, 1'b0);
        w_send_beat({pat(28'h30F), pat(28'h30E), pat(28'h30D), pat(28'h30C)},
                    4'b1111, 1'b0);
        w_send_beat({pat(28'h313), pat(28'h312), pat(28'h311), pat(28'h310)},
                    4'b1111, 1'b1);
        b_wait(resp);
        $display("[EXP6] unaligned write done");

        // §µ?ï“mem[0x300..0x306] == 0??mem[0x307..0x313] == pat(...)
        for (int a = 16'h300; a <= 16'h306; a++) begin
            check(u_slave.mem[a] == 8'h00,
                  $sformatf("EXP6 mem[%h] should be 0 (pre-align pad)", a));
        end
        for (int a = 16'h307; a <= 16'h313; a++) begin
            check(u_slave.mem[a] == pat(AXI_ADDR_W'(a)),
                  $sformatf("EXP6 mem[%h] pattern mismatch", a));
        end
    end
endtask

//--------------------------------------------------------------------------------
// ??????
//--------------------------------------------------------------------------------
initial begin
    // ??????
    m_awvalid = 0; m_wvalid = 0; m_arvalid = 0;
    m_awid = 0; m_awaddr = 0; m_awlen = 0; m_awsize = 0; m_awburst = 0;
    m_wdata = 0; m_wstrb = 0; m_wlast = 0;
    m_arid = 0; m_araddr = 0; m_arlen = 0; m_arsize = 0; m_arburst = 0;

    exp_fail = 0; exp_total = 0;

    wait (aresetn);
    repeat (4) @(posedge aclk);

    $display("===============================================================");
    $display("  AXI4 §¿?????  EXP_ID = %0d", EXP_ID);
    $display("===============================================================");

    case (EXP_ID)
        3'd1: exp1();
        3'd2: exp2();
        3'd3: exp3();
        3'd4: exp4();
        3'd5: exp5();
        3'd6: exp6();
        default: begin
            $display("[EXP] unknown EXP_ID=%0d, default to EXP3", EXP_ID);
            exp3();
        end
    endcase

    repeat (8) @(posedge aclk);

    $display("---------------------------------------------------------------");
    $display("  Checker: %0d events, %0d errors", chk_hit_cnt, chk_err_cnt);
    $display("  TB    : %0d checks, %0d failures", exp_total, exp_fail);

    if ((exp_fail == 0) && (chk_err_cnt == 0))
        $display("[EXP%0d] RESULT: PASS", EXP_ID);
    else
        $display("[EXP%0d] RESULT: FAIL", EXP_ID);
    $display("===============================================================");
    $finish;
end

// ???m?????
initial begin
    #200us;
    $display("[EXP] TIMEOUT");
    $finish;
end

endmodule : tb_axi_exp
