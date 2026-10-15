`timescale 1ns / 1ps

// 例题1：带使能和同步复位的8位寄存器
module register_enable (
    input  logic       clk,       // 时钟
    input  logic       rst,       // 同步复位，高电平有效
    input  logic       en,        // 写入使能
    input  logic [7:0] data_in,   // 输入数据
    output logic [7:0] data_out   // 寄存器当前数据
);
    // 只有在时钟上升沿到来时，寄存器才会更新
    always_ff @(posedge clk) begin
        if (rst)
            data_out <= 8'h00;    // 复位时清零
        else if (en)
            data_out <= data_in;   // 使能有效时载入新数据
        // en无效时不赋值，寄存器保持原值
    end
endmodule
