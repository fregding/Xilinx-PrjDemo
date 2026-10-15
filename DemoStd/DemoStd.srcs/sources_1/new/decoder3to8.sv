`timescale 1ns / 1ps

// 3-8译码器：将3位输入译为高电平有效的8位独热输出
module decoder3to8 (
    input  logic [2:0] in,   // 3位二进制输入，范围为0到7
    output logic [7:0] out   // 8位译码输出，同一时刻仅一位为1
);
    always_comb begin
        out = 8'b0000_0001 << in;
    end
endmodule
