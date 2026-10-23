//-----------------------------------------------------------------------------
// File name : axi_protocol_checker.sv
// Description : AXI4 §¿??????
//   ??????<->???????????¡¤?????????????????????? ??1/??2/p7 ????/??2.4 ??
//   ?????
//     C01  AWVALID ??¦Ë????????????AWID/AWADDR/AWLEN/AWSIZE/AWBURST ??????
//     C02  WVALID  ??¦Ë???WDATA/WSTRB/WLAST ??????
//     C03  ARVALID ??¦Ë???ARID/ARADDR/ARLEN/ARSIZE/ARBURST ??????
//     C04  BVALID ?????????? ID ?? AW ????? WLAST ??????????
//     C05  BVALID??AWVALID ???????BID ??????? outstanding AWID
//     C06  RVALID ?????????? ID ?? AR ??????????
//     C07  R ???? == ARLEN+1??RLAST ??????¨®???????????
//     C08  AxSIZE ?? log2(AXI_DATA_W/8)??WRAP burst ?? len+1 ?? {2,4,8,16}
//     C09  4K ??»Ç??? burst ??????????????????????????? 4KB ?
//     C10  W ???? == AWLEN+1??WLAST ??????¨®???????????
//     C11  WSTRB ???????"??????§¹??? lane ????"?????????§Õ?? lane ??
//
//   ???§Õ????? $display ?????????? err_cnt / chk_cnt??
//
//   ???????
//     - AW ????FIFO ???? w_head ???"??????? W"??????WLAST ?????
//             outstanding ?????aw_outst[id] ?????????? C04/C05??
//     - AR ????FIFO ???? r_head ???"????¦Ä??? R"??????C06 ???? ID ???????
//-----------------------------------------------------------------------------
`timescale 1ns / 1ps

module axi_protocol_checker
    import axi_pkg::*;
#(
    parameter int CHK_DEPTH = 32   // ???¦Ä???? AW/AR ?????
)(
    input  logic                       aclk,
    input  logic                       aresetn,

    input  logic                       awvalid,
    input  logic                       awready,
    input  logic [AXI_ID_W    -1:0]    awid,
    input  logic [AXI_ADDR_W  -1:0]    awaddr,
    input  logic [AXI_LEN_W   -1:0]    awlen,
    input  logic [AXI_SIZE_W  -1:0]    awsize,
    input  logic [AXI_BURST_W -1:0]    awburst,

    input  logic                       wvalid,
    input  logic                       wready,
    input  logic [AXI_DATA_W  -1:0]    wdata,
    input  logic [AXI_DATA_W/8-1:0]    wstrb,
    input  logic                       wlast,

    input  logic                       bvalid,
    input  logic                       bready,
    input  logic [AXI_ID_W    -1:0]    bid,
    input  logic [AXI_RESP_W  -1:0]    bresp,

    input  logic                       arvalid,
    input  logic                       arready,
    input  logic [AXI_ID_W    -1:0]    arid,
    input  logic [AXI_ADDR_W  -1:0]    araddr,
    input  logic [AXI_LEN_W   -1:0]    arlen,
    input  logic [AXI_SIZE_W  -1:0]    arsize,
    input  logic [AXI_BURST_W -1:0]    arburst,

    input  logic                       rvalid,
    input  logic                       rready,
    input  logic [AXI_ID_W    -1:0]    rid,
    input  logic [AXI_DATA_W  -1:0]    rdata,
    input  logic [AXI_RESP_W  -1:0]    rresp,
    input  logic                       rlast,

    output int                          err_cnt,
    output int                          chk_cnt
);

localparam int BUS_BYTES = AXI_DATA_W / 8;
localparam int MAX_SIZE  = $clog2(BUS_BYTES);  // 32bit ???? -> 2
localparam int PTR_W     = (CHK_DEPTH > 1) ? $clog2(CHK_DEPTH) : 1;

//--------------------------------------------------------------------------------
// ??
//--------------------------------------------------------------------------------
// AW??FIFO??¦Â??????????????
logic [AXI_ID_W   -1:0] awtab_id    [0:CHK_DEPTH-1];
logic [AXI_ADDR_W -1:0] awtab_addr  [0:CHK_DEPTH-1];
logic [AXI_LEN_W  -1:0] awtab_len   [0:CHK_DEPTH-1];
logic [AXI_SIZE_W -1:0] awtab_size  [0:CHK_DEPTH-1];
logic [AXI_BURST_W-1:0] awtab_burst [0:CHK_DEPTH-1];
int                     awtab_wbeat [0:CHK_DEPTH-1];
logic [CHK_DEPTH-1:0]   awtab_v;     // ??¦Ë?????§¹
logic [CHK_DEPTH-1:0]   awtab_w_last;// ????? WLAST???? B??

int aw_head, aw_tail;

// ??? ID ?? outstanding §Õ??????????????? WLAST ??¦Ä??? B??
int aw_pend_b [0:(1<<AXI_ID_W)-1];

// AR??FIFO??¦Â???????? ID ???????¦Ä???
logic [AXI_ID_W   -1:0] artab_id    [0:CHK_DEPTH-1];
logic [AXI_ADDR_W -1:0] artab_addr  [0:CHK_DEPTH-1];
logic [AXI_LEN_W  -1:0] artab_len   [0:CHK_DEPTH-1];
logic [AXI_SIZE_W -1:0] artab_size  [0:CHK_DEPTH-1];
logic [AXI_BURST_W-1:0] artab_burst [0:CHK_DEPTH-1];
int                     artab_rbeat [0:CHK_DEPTH-1];
int                     artab_seq   [0:CHK_DEPTH-1];
logic [CHK_DEPTH-1:0]   artab_v;

int ar_head, ar_tail, ar_seq;

//--------------------------------------------------------------------------------
// VALID ??? payload ?????÷ÏC01/C02/C03??
//--------------------------------------------------------------------------------
logic                     aw_seen;
logic [AXI_ID_W   -1:0]   aw_id_q;
logic [AXI_ADDR_W -1:0]   aw_addr_q;
logic [AXI_LEN_W  -1:0]   aw_len_q;
logic [AXI_SIZE_W -1:0]   aw_size_q;
logic [AXI_BURST_W-1:0]   aw_burst_q;

logic                     w_seen;
logic [AXI_DATA_W -1:0]   w_data_q;
logic [AXI_DATA_W/8-1:0]  w_strb_q;
logic                     w_last_q;

logic                     ar_seen;
logic [AXI_ID_W   -1:0]   ar_id_q;
logic [AXI_ADDR_W -1:0]   ar_addr_q;
logic [AXI_LEN_W  -1:0]   ar_len_q;
logic [AXI_SIZE_W -1:0]   ar_size_q;
logic [AXI_BURST_W-1:0]   ar_burst_q;

//--------------------------------------------------------------------------------
// ??????? w_head ???? AW ???????????? W ??????
//--------------------------------------------------------------------------------
// w_head ?? awtab_v==1 ??¦Ä??? WLAST
wire w_aw_vld = (aw_head < CHK_DEPTH) && awtab_v[aw_head] && !awtab_w_last[aw_head];

// ????????? rid ????? seq ??§³??¦Ä??? AR ??
int r_ar_sel;
int r_ar_best_seq;
always_comb begin
    r_ar_sel      = -1;
    r_ar_best_seq = 32'h7FFF_FFFF;
    for (int i = 0; i < CHK_DEPTH; i++) begin
        if (artab_v[i] && (artab_id[i] == rid) && (artab_seq[i] < r_ar_best_seq)) begin
            r_ar_best_seq = artab_seq[i];
            r_ar_sel      = i;
        end
    end
end

//--------------------------------------------------------------------------------
// 4K ??? / WRAP len ??? / AxSIZE ?????C08/C09??
//--------------------------------------------------------------------------------
function automatic logic [AXI_ADDR_W-1:0] calc_last_addr(
    input logic [AXI_ADDR_W  -1:0] start,
    input logic [AXI_SIZE_W  -1:0] size,
    input logic [AXI_LEN_W   -1:0] len,
    input logic [AXI_BURST_W -1:0] burst
);
    int size_bytes;
    int beats;
    int block;
    int lower;
    int offset;
    begin
        size_bytes = 1 << size;
        beats      = int'(len) + 1;
        case (burst)
            AXI_BURST_FIXED: calc_last_addr = start;
            AXI_BURST_WRAP: begin
                block  = beats << size;
                lower  = int'(start) & ~(block - 1);
                offset = (int'(start) - lower + (beats - 1) * size_bytes) % block;
                calc_last_addr = AXI_ADDR_W'(lower + offset);
            end
            default: begin
                calc_last_addr = AXI_ADDR_W'(int'(start) + (beats - 1) * size_bytes);
            end
        endcase
    end
endfunction

function automatic logic [AXI_DATA_W/8-1:0] beat_strb_mask(
    input logic [AXI_ADDR_W  -1:0] addr,
    input logic [AXI_SIZE_W  -1:0] size,
    input logic [AXI_LEN_W   -1:0] len,
    input logic [AXI_BURST_W -1:0] burst,
    input int                     beat_idx
);
    int size_bytes;
    int lane0;
    int nbytes;
    logic [AXI_ADDR_W-1:0] cur_addr;
    logic [AXI_DATA_W/8-1:0] m;
    int block, lower, off, first_pad;
    begin
        size_bytes = 1 << size;
        if (burst == AXI_BURST_FIXED) begin
            cur_addr = addr;
        end else if (burst == AXI_BURST_WRAP) begin
            block = (int'(len) + 1) << size;
            lower = int'(addr) & ~(block - 1);
            off   = (int'(addr) - lower + beat_idx * size_bytes) % block;
            cur_addr = AXI_ADDR_W'(lower + off);
        end else begin
            // INCR???????????????? size ??´‘?????? first_pad ??????? size_bytes
            // ????????? size_bytes ??????????????????????????????????
            first_pad = size_bytes - (int'(addr) % size_bytes);
            if (beat_idx == 0) cur_addr = addr;
            else               cur_addr = AXI_ADDR_W'(int'(addr) + first_pad + (beat_idx - 1) * size_bytes);
        end
        lane0  = int'(cur_addr) % BUS_BYTES;
        nbytes = (size_bytes < (BUS_BYTES - lane0)) ? size_bytes : (BUS_BYTES - lane0);
        m      = '0;
        for (int k = 0; k < nbytes; k++) m[lane0 + k] = 1'b1;
        beat_strb_mask = m;
    end
endfunction

//--------------------------------------------------------------------------------
// ??????? / ????
//--------------------------------------------------------------------------------
task automatic chk_hit;
    chk_cnt = chk_cnt + 1;
endtask

task automatic chk_err(input string code, input string msg);
    err_cnt = err_cnt + 1;
    $display("[CHK][%0t] ERROR %s : %s", $time, code, msg);
endtask

//--------------------------------------------------------------------------------
// ??????
//--------------------------------------------------------------------------------
int i;

always_ff @(posedge aclk) begin
    if (!aresetn) begin
        err_cnt       = 0;
        chk_cnt       = 0;
        awtab_v      <= '0;
        awtab_w_last <= '0;
        artab_v      <= '0;
        aw_head       = 0;
        aw_tail       = 0;
        ar_head       = 0;
        ar_tail       = 0;
        ar_seq        = 0;
        aw_seen       = 0;
        w_seen        = 0;
        ar_seen       = 0;
        for (i = 0; i < CHK_DEPTH; i++) begin
            awtab_wbeat[i] = 0;
            artab_rbeat[i] = 0;
            artab_seq  [i] = 0;
        end
        for (i = 0; i < (1<<AXI_ID_W); i++) aw_pend_b[i] = 0;
    end else begin

        //------------------------------------------------
        // C01/C02/C03: VALID ??? payload ??????
        //------------------------------------------------
        if (awvalid && awready) begin
            aw_seen = 0;                    // ??????????????????? payload
        end else if (awvalid) begin
            if (aw_seen) begin
                if ((awid != aw_id_q) || (awaddr != aw_addr_q) ||
                    (awlen != aw_len_q) || (awsize != aw_size_q) ||
                    (awburst != aw_burst_q))
                    chk_err("C01", "AW payload ?? VALID ???¦Ä????");
            end else begin
                aw_seen    = 1;
                aw_id_q    = awid;
                aw_addr_q  = awaddr;
                aw_len_q   = awlen;
                aw_size_q  = awsize;
                aw_burst_q = awburst;
            end
        end else begin
            aw_seen = 0;
        end

        if (wvalid && wready) begin
            w_seen = 0;                     // ??????????????????? payload
        end else if (wvalid) begin
            if (w_seen) begin
                if ((wdata != w_data_q) || (wstrb != w_strb_q) || (wlast != w_last_q))
                    chk_err("C02", "W payload ?? VALID ???¦Ä????");
            end else begin
                w_seen   = 1;
                w_data_q = wdata;
                w_strb_q = wstrb;
                w_last_q = wlast;
            end
        end else begin
            w_seen = 0;
        end

        if (arvalid && arready) begin
            ar_seen = 0;                    // ??????????????????? payload
        end else if (arvalid) begin
            if (ar_seen) begin
                if ((arid != ar_id_q) || (araddr != ar_addr_q) ||
                    (arlen != ar_len_q) || (arsize != ar_size_q) ||
                    (arburst != ar_burst_q))
                    chk_err("C03", "AR payload ?? VALID ???¦Ä????");
            end else begin
                ar_seen    = 1;
                ar_id_q    = arid;
                ar_addr_q  = araddr;
                ar_len_q   = arlen;
                ar_size_q  = arsize;
                ar_burst_q = arburst;
            end
        end else begin
            ar_seen = 0;
        end

        //------------------------------------------------
        // C08: AxSIZE + WRAP ????
        //------------------------------------------------
        if (awvalid && awready) begin
            chk_hit();
            if (awsize > MAX_SIZE)
                chk_err("C08", $sformatf("AWSIZE %0d > %0d", awsize, MAX_SIZE));
            if ((awburst == AXI_BURST_WRAP) &&
                !((awlen+1 == 2) || (awlen+1 == 4) || (awlen+1 == 8) || (awlen+1 == 16)))
                chk_err("C08", $sformatf("WRAP ???? len+1=%0d ???", awlen+1));
        end
        if (arvalid && arready) begin
            chk_hit();
            if (arsize > MAX_SIZE)
                chk_err("C08", $sformatf("ARSIZE %0d > %0d", arsize, MAX_SIZE));
            if ((arburst == AXI_BURST_WRAP) &&
                !((arlen+1 == 2) || (arlen+1 == 4) || (arlen+1 == 8) || (arlen+1 == 16)))
                chk_err("C08", $sformatf("WRAP ???? len+1=%0d ???", arlen+1));
        end

        //------------------------------------------------
        // C09: 4K ???
        //------------------------------------------------
        if (awvalid && awready) begin
            logic [AXI_ADDR_W-1:0] last_a;
            last_a = calc_last_addr(awaddr, awsize, awlen, awburst);
            if (awaddr[AXI_ADDR_W-1:12] != last_a[AXI_ADDR_W-1:12])
                chk_err("C09", $sformatf("§Õ burst ?? 4K: %h -> %h", awaddr, last_a));
        end
        if (arvalid && arready) begin
            logic [AXI_ADDR_W-1:0] last_a;
            last_a = calc_last_addr(araddr, arsize, arlen, arburst);
            if (araddr[AXI_ADDR_W-1:12] != last_a[AXI_ADDR_W-1:12])
                chk_err("C09", $sformatf("?? burst ?? 4K: %h -> %h", araddr, last_a));
        end

        //------------------------------------------------
        // AW ???
        //------------------------------------------------
        if (awvalid && awready) begin
            if (awtab_v[aw_tail]) chk_err("C04", "AW ???????????????");
            awtab_id   [aw_tail] <= awid;
            awtab_addr [aw_tail] <= awaddr;
            awtab_len  [aw_tail] <= awlen;
            awtab_size [aw_tail] <= awsize;
            awtab_burst[aw_tail] <= awburst;
            awtab_wbeat[aw_tail]  = 0;
            awtab_w_last[aw_tail] <= 1'b0;
            awtab_v    [aw_tail] <= 1'b1;
            aw_tail              = (aw_tail == CHK_DEPTH-1) ? 0 : aw_tail + 1;
        end

        //------------------------------------------------
        // W ????????? FIFO ?????
        //------------------------------------------------
        if (wvalid && wready) begin
            chk_hit();
            if (!w_aw_vld) begin
                chk_err("C04", "W ???????¦Ä??? AW");
            end else begin
                logic [AXI_DATA_W/8-1:0] m;
                m = beat_strb_mask(awtab_addr[aw_head], awtab_size[aw_head],
                                   awtab_len [aw_head], awtab_burst[aw_head],
                                   awtab_wbeat[aw_head]);
                if ((wstrb & ~m) != '0)
                    chk_err("C11", $sformatf("WSTRB=%b ??? lane ???? %b", wstrb, m));
                awtab_wbeat[aw_head] = awtab_wbeat[aw_head] + 1;
                if (wlast) begin
                    if (awtab_wbeat[aw_head] != int'(awtab_len[aw_head]) + 1)
                        chk_err("C10", $sformatf("WLAST ????=%0d, AWLEN+1=%0d",
                                                 awtab_wbeat[aw_head],
                                                 int'(awtab_len[aw_head]) + 1));
                    awtab_w_last[aw_head] <= 1'b1;
                    aw_pend_b[awtab_id[aw_head]] = aw_pend_b[awtab_id[aw_head]] + 1;
                    aw_head = (aw_head == CHK_DEPTH-1) ? 0 : aw_head + 1;
                end
            end
        end

        //------------------------------------------------
        // C04/C05: BVALID ??? ID ??????"???? AW+W"???¦Ë
        //------------------------------------------------
        if (bvalid && bready) begin
            chk_hit();
            if (aw_pend_b[bid] <= 0) begin
                chk_err("C04", $sformatf("BID=%0d ?¦Ä?????? AW+W", bid));
            end else begin
                aw_pend_b[bid] = aw_pend_b[bid] - 1;
                // ????????¦Ë????????? w_last ??? ID ???
                begin
                    int found;
                    found = -1;
                    for (int j = 0; j < CHK_DEPTH; j++) begin
                        if (awtab_v[j] && awtab_w_last[j] && (awtab_id[j] == bid) && (found < 0))
                            found = j;
                    end
                    if (found >= 0) begin
                        awtab_v     [found] <= 1'b0;
                        awtab_w_last[found] <= 1'b0;
                    end
                end
            end
        end

        //------------------------------------------------
        // AR ???
        //------------------------------------------------
        if (arvalid && arready) begin
            if (artab_v[ar_tail]) chk_err("C06", "AR ???????????????");
            artab_id   [ar_tail] <= arid;
            artab_addr [ar_tail] <= araddr;
            artab_len  [ar_tail] <= arlen;
            artab_size [ar_tail] <= arsize;
            artab_burst[ar_tail] <= arburst;
            artab_rbeat[ar_tail]  = 0;
            artab_seq  [ar_tail]  = ar_seq;
            artab_v    [ar_tail] <= 1'b1;
            ar_tail              = (ar_tail == CHK_DEPTH-1) ? 0 : ar_tail + 1;
            ar_seq               = ar_seq + 1;
        end

        //------------------------------------------------
        // C06/C07: R
        //------------------------------------------------
        if (rvalid && rready) begin
            chk_hit();
            if (r_ar_sel < 0) begin
                chk_err("C06", $sformatf("RID=%0d ¦Ä????? AR", rid));
            end else begin
                artab_rbeat[r_ar_sel] = artab_rbeat[r_ar_sel] + 1;
                if (rlast) begin
                    if (artab_rbeat[r_ar_sel] != int'(artab_len[r_ar_sel]) + 1)
                        chk_err("C07", $sformatf("RLAST ????=%0d, ARLEN+1=%0d",
                                                 artab_rbeat[r_ar_sel],
                                                 int'(artab_len[r_ar_sel]) + 1));
                    artab_v[r_ar_sel] <= 1'b0;
                end else begin
                    if (artab_rbeat[r_ar_sel] == int'(artab_len[r_ar_sel]) + 1)
                        chk_err("C07", "??????¦Ä?? RLAST");
                end
            end
        end

    end
end

endmodule : axi_protocol_checker
