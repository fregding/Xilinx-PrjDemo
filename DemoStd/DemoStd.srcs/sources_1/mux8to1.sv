`timescale 1ns / 1ps

// 8选1组合多路选择器：根据 sel 从 data_in 中选出一位
module mux8to1 (
    input  logic [7:0] data_in,  // 8路1位输入
    input  logic [2:0] sel,      // 3位选择信号，可表示0到7
    output logic       data_out  // 选中的输出
);
    // 组合逻辑：sel 的数值对应 data_in 的位下标
    always_comb begin
        data_out = data_in[sel];
    end
endmodule
