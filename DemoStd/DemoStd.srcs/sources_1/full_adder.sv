`timescale 1ns / 1ps

// 1位全加器：计算两个加数和一个进位输入的和
module full_adder (
    input  logic a,     // 加数A
    input  logic b,     // 加数B
    input  logic cin,   // 输入进位
    output logic sum,   // 求和结果
    output logic cout   // 输出进位
);
    // 全加器逻辑关系：和为三输入异或，进位为多数表决逻辑
    always_comb begin
        sum  = a ^ b ^ cin;
        cout = (a & b) | (a & cin) | (b & cin);
    end
endmodule
