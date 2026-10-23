//-----------------------------------------------------------------------------
// File name : axi_arbiter.sv
// Description : 轮询（round-robin）仲裁器（由 easyaxi_arb.v 迁移为 SystemVerilog）
//   - 深度由 DEEP_NUM 配置
//   - 通过 req_power 掩码保证公平性
//   - 输出 onehot grant 对应的二进制指针；无请求时输出 0
//-----------------------------------------------------------------------------
module axi_arbiter #(
    parameter int DEEP_NUM = 8
)(
    input  logic                        clk,
    input  logic                        rst_n,
    input  logic [DEEP_NUM        -1:0] queue_i,
    input  logic                        sche_en,
    output logic [$clog2(DEEP_NUM)-1:0] pointer_o
);

logic [DEEP_NUM-1:0] req_power;
logic [DEEP_NUM-1:0] req_after_power;

// 递归掩码：old_mask 从请求队列当前位置向后展开（合法的组合逻辑自引用模式）
logic [DEEP_NUM-1:0] old_mask;
logic [DEEP_NUM-1:0] new_mask;

logic                old_grant_work;
logic [DEEP_NUM-1:0] old_grant;
logic [DEEP_NUM-1:0] new_grant;
logic [DEEP_NUM-1:0] grant;

assign req_after_power = queue_i & req_power;

assign old_mask = {req_after_power[DEEP_NUM-2:0] | old_mask[DEEP_NUM-2:0], 1'b0};
assign new_mask = {queue_i[DEEP_NUM-2:0]         | new_mask[DEEP_NUM-2:0], 1'b0};

assign old_grant_work = (|req_after_power);
assign old_grant      = ~old_mask & req_after_power;
assign new_grant      = ~new_mask & queue_i;
assign grant          = old_grant_work ? old_grant : new_grant;

function automatic logic [$clog2(DEEP_NUM)-1:0] onehot_to_index(input logic [DEEP_NUM-1:0] onehot);
    onehot_to_index = '0;
    for (int i = 0; i < DEEP_NUM; i++) begin
        if (onehot[i]) begin
            onehot_to_index = i[$clog2(DEEP_NUM)-1:0];
        end
    end
endfunction

always_comb begin
    if (|queue_i) pointer_o = onehot_to_index(grant);
    else          pointer_o = '0;
end

always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        req_power <= {DEEP_NUM{1'b1}};
    end
    else if (sche_en) begin
        if (old_grant_work) begin
            req_power <= old_mask;
        end
        else if (|queue_i) begin
            req_power <= new_mask;
        end
    end
end

endmodule
